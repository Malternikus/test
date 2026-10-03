--!strict
-- Format (ModuleScript)
-- Ort: ReplicatedStorage > VoidDice > Util > Format
--
-- Zahlen und Zeiten lesbar machen: $1.25M, 1 in 2.5M, 4m 05s.

local UIConfig = require(script.Parent.Parent:WaitForChild("Config"):WaitForChild("UIConfig"))

local Format = {}

local SUFFIXES = UIConfig.NumberSuffixes

-- 1234 -> "1,234"
function Format.commas(n: number): string
	local negative = n < 0
	local s = tostring(math.floor(math.abs(n)))
	local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	if out:sub(1, 1) == "," then
		out = out:sub(2)
	end
	return (if negative then "-" else "") .. out
end

-- 1234567 -> "1.23M"
function Format.short(n: number, decimals: number?): string
	if n ~= n then
		return "0"
	end
	if n == math.huge then
		return "∞"
	end
	local negative = n < 0
	n = math.abs(n)
	if n < 1000 then
		local s = if n == math.floor(n) or n >= 100 then tostring(math.floor(n)) else string.format("%.1f", n)
		return (if negative then "-" else "") .. s
	end
	local exponent = math.min(#SUFFIXES - 1, math.floor(math.log10(n) / 3))
	local value = n / 10 ^ (exponent * 3)
	local d = decimals or (if value < 10 then 2 elseif value < 100 then 1 else 0)
	local s = string.format("%." .. d .. "f", value)
	-- "1.50" -> "1.5", "2.00" -> "2"
	if s:find("%.") then
		s = s:gsub("0+$", ""):gsub("%.$", "")
	end
	if exponent >= #SUFFIXES - 1 and n >= 1e36 then
		return (if negative then "-" else "") .. string.format("%.2e", n)
	end
	return (if negative then "-" else "") .. s .. SUFFIXES[exponent + 1]
end

function Format.cash(n: number): string
	return "$" .. Format.short(n)
end

function Format.perSecond(n: number): string
	return "$" .. Format.short(n) .. "/s"
end

-- Wahrscheinlichkeit p -> "1 in 2.5M"
function Format.chance(p: number): string
	if p <= 0 then
		return "1 in ∞"
	end
	local x = 1 / p
	if x < 10 then
		return "1 in " .. string.format("%.1f", x):gsub("%.0$", "")
	end
	if x < 100000 then
		return "1 in " .. Format.commas(math.floor(x + 0.5))
	end
	return "1 in " .. Format.short(x)
end

-- "1 in X" direkt
function Format.oneIn(x: number): string
	if x < 100000 then
		return "1 in " .. Format.commas(math.floor(x + 0.5))
	end
	return "1 in " .. Format.short(x)
end

function Format.percent(p: number, decimals: number?): string
	return string.format("%." .. (decimals or 1) .. "f%%", p * 100)
end

-- 305 -> "5m 05s"
function Format.duration(seconds: number): string
	seconds = math.max(0, math.floor(seconds))
	local h = math.floor(seconds / 3600)
	local m = math.floor((seconds % 3600) / 60)
	local s = seconds % 60
	if h > 0 then
		return string.format("%dh %02dm", h, m)
	elseif m > 0 then
		return string.format("%dm %02ds", m, s)
	end
	return string.format("%ds", s)
end

function Format.multiplier(x: number): string
	if x >= 100 then
		return "x" .. Format.short(x)
	end
	local s = string.format("%.2f", x):gsub("0+$", ""):gsub("%.$", "")
	return "x" .. s
end

return Format
