-- harness.luau (Lune)
--
-- Kleiner Roblox-Emulator, damit die reinen Module (Configs, Util, Logic,
-- ModelFactory) ohne Roblox Studio getestet und simuliert werden können.
--
-- Was er kann:
--   * Baut aus default.project.json den Instanzbaum so nach, wie Rojo ihn baut
--     (Ordner, ModuleScripts, init.luau, .server/.client).
--   * `script`, `script.Parent.X`, `:WaitForChild()`, `:FindFirstChild()` und
--     `require(<ModuleScript>)` funktionieren wie in Roblox.
--   * Roblox-Datentypen (Color3, Vector3, CFrame, Instance, Enum ...) kommen aus
--     @lune/roblox. `Random` wird nachgebaut (deterministisch per Seed).
--
-- Was er NICHT kann: echte Services (DataStore, Players, RemoteEvents ...).
-- Deshalb werden nur Module geladen, die davon nichts brauchen.

local fs = require("@lune/fs")
local serde = require("@lune/serde")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")
local task = require("@lune/task")
local stdio = require("@lune/stdio")

local Harness = {}

-------------------------------------------------------------------------------
-- Random (Roblox-kompatibel genug: NextNumber, NextInteger, Clone)
-------------------------------------------------------------------------------
local RandomShim = {}
RandomShim.__index = RandomShim

-- xorshift32 auf zwei Hälften kombiniert -> ausreichend für Statistik-Tests
local function step(state: number): number
	state = bit32.bxor(state, bit32.lshift(state, 13))
	state = bit32.bxor(state, bit32.rshift(state, 17))
	state = bit32.bxor(state, bit32.lshift(state, 5))
	return state
end

function RandomShim.new(seed: number?)
	local s = math.floor(seed or (os.clock() * 1e6)) % 4294967291
	if s == 0 then
		s = 2463534242
	end
	local self = setmetatable({ _a = s, _b = bit32.bxor(s, 0x9E3779B9) }, RandomShim)
	if self._b == 0 then
		self._b = 1
	end
	for _ = 1, 8 do
		self:NextNumber()
	end
	return self
end

function RandomShim:NextNumber(min: number?, max: number?): number
	self._a = step(self._a)
	self._b = step(self._b)
	-- 52 Bit aus zwei 32-Bit-Zahlen
	local hi = bit32.rshift(self._a, 6) -- 26 Bit
	local lo = bit32.rshift(self._b, 6) -- 26 Bit
	local u = (hi * 67108864 + lo) / 4503599627370496
	if min ~= nil and max ~= nil then
		return min + (max - min) * u
	end
	return u
end

function RandomShim:NextInteger(min: number, max: number): number
	return min + math.floor(self:NextNumber() * (max - min + 1))
end

function RandomShim:Clone()
	local c = setmetatable({ _a = self._a, _b = self._b }, RandomShim)
	return c
end

Harness.Random = RandomShim

-------------------------------------------------------------------------------
-- Virtueller Instanzbaum
-------------------------------------------------------------------------------
local Node = {}

local NODE_METHODS = {}

function NODE_METHODS:FindFirstChild(name: string)
	return rawget(self, "_children")[name]
end

function NODE_METHODS:WaitForChild(name: string)
	local child = rawget(self, "_children")[name]
	if not child then
		error(string.format("[harness] WaitForChild: '%s' hat kein Kind '%s'", self:GetFullName(), name), 2)
	end
	return child
end

function NODE_METHODS:GetChildren()
	local out = {}
	for _, c in rawget(self, "_children") do
		table.insert(out, c)
	end
	table.sort(out, function(a, b)
		return rawget(a, "Name") < rawget(b, "Name")
	end)
	return out
end

function NODE_METHODS:IsA(class: string)
	local cn = rawget(self, "ClassName")
	if class == "LuaSourceContainer" then
		return cn == "ModuleScript" or cn == "Script" or cn == "LocalScript"
	end
	return cn == class
end

function NODE_METHODS:GetFullName()
	local parts = {}
	local n = self
	while n and rawget(n, "ClassName") ~= "DataModel" do
		table.insert(parts, 1, rawget(n, "Name"))
		n = rawget(n, "Parent")
	end
	return table.concat(parts, ".")
end

Node.__index = function(self, key)
	local m = NODE_METHODS[key]
	if m then
		return m
	end
	local child = rawget(self, "_children")[key]
	if child then
		return child
	end
	error(string.format("[harness] '%s' ist kein gültiges Mitglied von '%s'", tostring(key), self:GetFullName()), 2)
end
Node.__tostring = function(self)
	return rawget(self, "Name")
end

local function newNode(name: string, className: string, parent, file: string?)
	local n = setmetatable({ Name = name, ClassName = className, Parent = parent, _file = file, _children = {} }, Node)
	if parent then
		rawget(parent, "_children")[name] = n
	end
	return n
end

local function stripExt(fileName: string): (string?, string?)
	for _, ext in { ".server.luau", ".client.luau", ".luau", ".server.lua", ".client.lua", ".lua" } do
		if fileName:sub(-#ext) == ext then
			local base = fileName:sub(1, -#ext - 1)
			local class = if ext:find("server") then "Script" elseif ext:find("client") then "LocalScript" else "ModuleScript"
			return base, class
		end
	end
	return nil, nil
end

local function isDir(path: string): boolean
	local ok, meta = pcall(fs.metadata, path)
	return ok and meta.exists and meta.kind == "dir"
end

local function mountPath(name: string, path: string, parent)
	if isDir(path) then
		local initFile, initClass
		for _, candidate in { "init.luau", "init.server.luau", "init.client.luau", "init.lua" } do
			if fs.isFile(path .. "/" .. candidate) then
				initFile = path .. "/" .. candidate
				local _, cls = stripExt(candidate)
				initClass = cls
				break
			end
		end
		local node = newNode(name, initClass or "Folder", parent, initFile)
		for _, entry in fs.readDir(path) do
			local full = path .. "/" .. entry
			if isDir(full) then
				mountPath(entry, full, node)
			else
				local base, cls = stripExt(entry)
				if base and base ~= "init" then
					newNode(base, cls :: string, node, full)
				end
			end
		end
		return node
	else
		local base, cls = stripExt(path:match("[^/]+$") :: string)
		return newNode(name, cls or "ModuleScript", parent, path)
	end
end

local function mountTree(tree, name: string, parent, root: string)
	local className = tree["$className"] or "Folder"
	local node
	if tree["$path"] then
		node = mountPath(name, root .. "/" .. tree["$path"], parent)
	else
		node = newNode(name, className, parent, nil)
	end
	for key, value in tree do
		if type(key) == "string" and key:sub(1, 1) ~= "$" and type(value) == "table" then
			mountTree(value, key, node, root)
		end
	end
	return node
end

-------------------------------------------------------------------------------
-- Fake game + require
-------------------------------------------------------------------------------
local function makeServiceStub(name: string)
	local stub = {}
	if name == "RunService" then
		function stub:IsStudio()
			return true
		end
		function stub:IsServer()
			return true
		end
		function stub:IsClient()
			return false
		end
	elseif name == "HttpService" then
		local counter = 0
		function stub:GenerateGUID(_braces)
			counter += 1
			return string.format("00000000-0000-0000-0000-%012d", counter)
		end
		function stub:JSONEncode(v)
			return serde.encode("json", v)
		end
		function stub:JSONDecode(v)
			return serde.decode("json", v)
		end
	end
	return setmetatable(stub, {
		__index = function(_, key)
			error(string.format("[harness] Service '%s' hat im Test kein Mitglied '%s'", name, tostring(key)), 2)
		end,
	})
end

function Harness.load(projectRoot: string)
	local project = serde.decode("json", fs.readFile(projectRoot .. "/default.project.json"))
	local dataModel = mountTree(project.tree, "game", nil, projectRoot)

	local cache = {}
	local loading = {}
	local services = {}

	local fakeGame = setmetatable({}, {
		__index = function(_, key)
			if key == "GetService" then
				return function(_self, serviceName: string)
					local real = rawget(dataModel, "_children")[serviceName]
					if real then
						return real
					end
					services[serviceName] = services[serviceName] or makeServiceStub(serviceName)
					return services[serviceName]
				end
			end
			return dataModel[key]
		end,
	})

	local env

	local function requireNode(node)
		if type(node) == "string" then
			return require(node)
		end
		assert(type(node) == "table" and rawget(node, "_file"), "[harness] require braucht ein ModuleScript")
		if cache[node] ~= nil then
			return cache[node]
		end
		if loading[node] then
			error("[harness] Zyklischer require: " .. node:GetFullName())
		end
		loading[node] = true
		local file = rawget(node, "_file")
		local source = fs.readFile(file)
		local moduleEnv = table.clone(env)
		moduleEnv.script = node
		local fn = luau.load(source, { debugName = file, environment = moduleEnv, injectGlobals = true })
		local result = fn()
		loading[node] = nil
		cache[node] = result
		return result
	end

	env = {
		game = fakeGame,
		workspace = setmetatable({}, { __index = function() error("[harness] workspace ist im Test nicht verfügbar", 2) end }),
		require = requireNode,
		Random = RandomShim,
		task = task,
		warn = function(...)
			stdio.ewrite("[warn] " .. table.concat(table.pack(...) :: any, " ", 1, select("#", ...)) .. "\n")
		end,
		tick = os.clock,
		Color3 = roblox.Color3,
		Vector3 = roblox.Vector3,
		Vector2 = roblox.Vector2,
		CFrame = roblox.CFrame,
		UDim = roblox.UDim,
		UDim2 = roblox.UDim2,
		Enum = roblox.Enum,
		Instance = roblox.Instance,
		BrickColor = roblox.BrickColor,
		NumberSequence = roblox.NumberSequence,
		NumberSequenceKeypoint = roblox.NumberSequenceKeypoint,
		ColorSequence = roblox.ColorSequence,
		ColorSequenceKeypoint = roblox.ColorSequenceKeypoint,
		NumberRange = roblox.NumberRange,
		Rect = roblox.Rect,
		Font = roblox.Font,
		PhysicalProperties = roblox.PhysicalProperties,
		typeof = roblox.typeof or typeof,
	}

	return {
		game = fakeGame,
		root = dataModel,
		require = requireNode,
		-- Pfad wie "ReplicatedStorage.VoidDice.Config.RarityConfig"
		requirePath = function(path: string)
			local node = dataModel
			for part in path:gmatch("[^%.]+") do
				node = node:WaitForChild(part)
			end
			return requireNode(node)
		end,
	}
end

return Harness
