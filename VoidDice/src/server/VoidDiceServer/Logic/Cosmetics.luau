--!strict
-- Cosmetics (ModuleScript)
-- Ort: ServerScriptService > VoidDiceServer > Logic > Cosmetics

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CosmeticConfig = require(ReplicatedStorage:WaitForChild("VoidDice"):WaitForChild("Config"):WaitForChild("CosmeticConfig"))

local Context = require(script.Parent:WaitForChild("Context"))

local Cosmetics = {}

-- true wenn neu
function Cosmetics.grant(profile, ctx: Context.Context, id: string): boolean
	local def = CosmeticConfig.Get(id)
	if not def or profile.Cosmetics.Owned[id] then
		return false
	end
	profile.Cosmetics.Owned[id] = true
	Context.mark(ctx, "Cosmetics")
	Context.event(ctx, "Cosmetic", { Id = id, Kind = def.Kind, Name = def.DisplayName })
	return true
end

function Cosmetics.equip(profile, ctx: Context.Context, kind: string, id: string): (boolean, string?)
	local def = CosmeticConfig.Get(id)
	if not def or def.Kind ~= kind then
		return false, "Unknown cosmetic"
	end
	if not profile.Cosmetics.Owned[id] then
		return false, "Not owned"
	end
	profile.Cosmetics.Equipped[kind] = id
	Context.mark(ctx, "Cosmetics")
	return true, nil
end

function Cosmetics.unequip(profile, ctx: Context.Context, kind: string)
	local default = CosmeticConfig.Defaults[kind]
	profile.Cosmetics.Equipped[kind] = default
	Context.mark(ctx, "Cosmetics")
end

return Cosmetics
