--!strict
-- Effects (ModuleScript)
-- Ort: ReplicatedStorage > VoidDice > Visual > ModelFactory > Effects
--
-- Aura, Level-Visual und Mutation auf einem fertigen ModelFactory-Model.
-- Alles ist idempotent: vorherige Effekte desselben Slots werden zuerst entfernt.
--
-- Slots (Attachments unter Root):
--   FX_Aura      Character-Aura (CharacterDef.AuraReference)
--   FX_Level     Level 5 "LevelGlow1", Level 10 "LevelGlow2", Level 15 "LevelMax"
--   FX_Mutation  MutationConfig.Effect
-- Pro Slot höchstens 1 ParticleEmitter -> max. 3 Emitter pro Model.
--
-- Zusätzliche Parts (zählen ins Budget, deshalb RESERVED_PARTS):
--   AuraRing / MutationRing  leuchtende Bodenscheibe (AuraLibrary-Eintrag mit Ring = true)
--   LevelRing + LevelStar    nur bei Level 15 (MAX)
--
-- LowDetail (Model-Attribut): keine ParticleEmitter und keine Lichter, nur Parts.

local Visual = script.Parent.Parent
local AuraLibrary = require(Visual:WaitForChild("AuraLibrary"))
local Config = Visual.Parent:WaitForChild("Config")
local MutationConfig = require(Config:WaitForChild("MutationConfig"))
local RarityConfig = require(Config:WaitForChild("RarityConfig"))

local Effects = {}

-- Parts, die der Builder für Effekte frei lässt (AuraRing, LevelRing, LevelStar, MutationRing)
Effects.RESERVED_PARTS = 4

Effects.LEVEL_STEPS = {
	{ Level = 15, Aura = "LevelMax", Strength = 1 },
	{ Level = 10, Aura = "LevelGlow2", Strength = 0.8 },
	{ Level = 5, Aura = "LevelGlow1", Strength = 0.6 },
}

local V3 = Vector3.new
local CF = CFrame.new
local ANG = CFrame.Angles
local UPRIGHT = ANG(0, 0, math.pi / 2)

local function getRoot(model: Model): BasePart?
	local root = model.PrimaryPart or model:FindFirstChild("Root")
	if root and root:IsA("BasePart") then
		return root
	end
	return nil
end

local function dims(model: Model): (number, number, number)
	local h = model:GetAttribute("Height")
	local w = model:GetAttribute("Width")
	local height = if type(h) == "number" then h else 5
	local width = if type(w) == "number" then w else 2
	local scale = math.clamp(height / 5, 0.5, 4)
	return height, width, scale
end

local function isLowDetail(model: Model): boolean
	return model:GetAttribute("LowDetail") == true
end

-- Entfernt Attachment + Parts eines Slots
local function clearSlot(model: Model, slot: string)
	local root = getRoot(model)
	if root then
		local att = root:FindFirstChild("FX_" .. slot)
		if att then
			att:Destroy()
		end
	end
	for _, inst in model:GetDescendants() do
		if inst:IsA("BasePart") and inst:GetAttribute("VDSlot") == slot then
			inst:Destroy()
		end
	end
end

local function fxParent(model: Model): Instance
	return model:FindFirstChild("Body") or model
end

local function fxPart(model: Model, slot: string, name: string, size: Vector3, cf: CFrame, color: Color3, transparency: number, shape: Enum.PartType?): BasePart
	local part = Instance.new("Part")
	part.Name = name
	if shape then
		part.Shape = shape
	end
	part.Size = size
	part.CFrame = cf
	part.Color = color
	part.Material = Enum.Material.Neon
	part.Transparency = transparency
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Massless = true
	part.CastShadow = false
	part:SetAttribute("VDRole", "FX")
	part:SetAttribute("VDSlot", slot)
	part.Parent = fxParent(model)
	return part
end

-- Leuchtende Bodenscheibe unter den Füßen
local function floorRing(model: Model, slot: string, color: Color3, diameter: number, lift: number, transparency: number)
	local root = getRoot(model)
	if not root then
		return
	end
	local ground = root.CFrame * CF(0, -root.Size.Y / 2 + lift, 0)
	fxPart(model, slot, slot .. "Ring", V3(0.06, diameter, diameter), ground * UPRIGHT, color, transparency, Enum.PartType.Cylinder)
end

local function makeAttachment(model: Model, slot: string, height: number): Attachment?
	local root = getRoot(model)
	if not root then
		return nil
	end
	local att = Instance.new("Attachment")
	att.Name = "FX_" .. slot
	att.Position = V3(0, height - root.Size.Y / 2, 0)
	att.Parent = root
	return att
end

-------------------------------------------------------------------------------
-- Aura
-------------------------------------------------------------------------------
function Effects.ApplyAura(model: Model, auraId: string?)
	clearSlot(model, "Aura")
	model:SetAttribute("Aura", auraId)
	if not auraId then
		return
	end
	local def = AuraLibrary.Get(auraId)
	if not def then
		warn("[ModelFactory.Effects] Unbekannte Aura: " .. tostring(auraId))
		return
	end
	local height, width, scale = dims(model)
	if not isLowDetail(model) then
		local rel = if def.Particles and def.Particles.Height then def.Particles.Height else 0.5
		local att = makeAttachment(model, "Aura", height * rel)
		if att then
			AuraLibrary.Apply(att, auraId, 1, { Scale = scale })
		end
	end
	if def.Ring then
		floorRing(model, "Aura", def.Color, math.max(width * 1.05, 2.5 * scale), 0.03, 0.55)
	end
end

-------------------------------------------------------------------------------
-- Level
-------------------------------------------------------------------------------
function Effects.LevelAuraId(level: number): (string?, number)
	for _, step in Effects.LEVEL_STEPS do
		if level >= step.Level then
			return step.Aura, step.Strength
		end
	end
	return nil, 0
end

function Effects.ApplyLevel(model: Model, level: number)
	clearSlot(model, "Level")
	model:SetAttribute("VisualLevel", level)
	local auraId, strength = Effects.LevelAuraId(level)
	if not auraId then
		return
	end
	local height, width, scale = dims(model)
	local rarityId = model:GetAttribute("Rarity")
	local rarity = if type(rarityId) == "string" then RarityConfig.ById[rarityId] else nil
	local color = if rarity then rarity.Color else Color3.new(1, 1, 1)
	local color2 = if rarity then rarity.Color2 else Color3.new(0.8, 0.8, 1)

	if not isLowDetail(model) then
		local att = makeAttachment(model, "Level", 0.15 * scale)
		if att then
			AuraLibrary.Apply(att, auraId, strength, { Scale = scale, Color = color, Color2 = color2 })
		end
	end

	if level >= 15 then
		floorRing(model, "Level", color, math.max(width * 1.3, 3 * scale), 0.05, 0.4)
		local root = getRoot(model)
		if root then
			local s = 0.45 * math.clamp(scale, 0.8, 2.5)
			local cf = root.CFrame * CF(0, -root.Size.Y / 2 + height + 0.5 * scale + s, 0) * ANG(math.pi / 4, 0, math.pi / 4)
			fxPart(model, "Level", "LevelStar", V3(s, s, s), cf, color, 0, nil)
		end
	end
end

-------------------------------------------------------------------------------
-- Mutation
-------------------------------------------------------------------------------
local function baseColor(part: BasePart): Color3
	local stored = part:GetAttribute("VDBaseColor")
	if typeof(stored) == "Color3" then
		return stored :: Color3
	end
	part:SetAttribute("VDBaseColor", part.Color)
	return part.Color
end

local function baseMaterial(part: BasePart): Enum.Material
	local stored = part:GetAttribute("VDBaseMaterial")
	if type(stored) == "string" then
		local ok, mat = pcall(function()
			return (Enum.Material :: any)[stored]
		end)
		if ok and mat then
			return mat
		end
	end
	part:SetAttribute("VDBaseMaterial", part.Material.Name)
	return part.Material
end

function Effects.ApplyMutation(model: Model, mutationId: string?)
	local def = MutationConfig.Get(mutationId)
	clearSlot(model, "Mutation")
	model:SetAttribute("Mutation", def.Id)
	local active = def.Id ~= MutationConfig.None and def.Tint ~= nil

	for _, inst in model:GetDescendants() do
		if inst:IsA("BasePart") and inst.Name ~= "Root" and inst.Name ~= "Joint" and inst.Transparency < 1 then
			local role = inst:GetAttribute("VDRole")
			if role ~= "FX" and role ~= "Eye" then
				local color0 = baseColor(inst)
				local material0 = baseMaterial(inst)
				if not active then
					inst.Color = color0
					inst.Material = material0
				elseif role == "Glow" then
					inst.Color = color0:Lerp(def.Color, 0.6)
					inst.Material = material0
				else
					inst.Color = color0:Lerp(def.Tint :: Color3, def.TintStrength)
					if def.Material and material0 ~= Enum.Material.Neon and material0 ~= Enum.Material.Glass then
						inst.Material = def.Material
					else
						inst.Material = material0
					end
				end
			end
		end
	end

	if not active or not def.Effect then
		return
	end
	local effectDef = AuraLibrary.Get(def.Effect)
	if not effectDef then
		warn("[ModelFactory.Effects] Unbekannter Mutations-Effekt: " .. tostring(def.Effect))
		return
	end
	local height, width, scale = dims(model)
	if not isLowDetail(model) then
		local rel = if effectDef.Particles and effectDef.Particles.Height then effectDef.Particles.Height else 0.5
		local att = makeAttachment(model, "Mutation", height * rel)
		if att then
			AuraLibrary.Apply(att, def.Effect, 1, { Scale = scale })
		end
	end
	if effectDef.Ring then
		floorRing(model, "Mutation", effectDef.Color, math.max(width * 1.15, 2.8 * scale), 0.04, 0.5)
	end
end

return Effects
