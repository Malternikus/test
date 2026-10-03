--!strict
-- RebirthConfig (ModuleScript)
-- Ort: ReplicatedStorage > VoidDice > Config > RebirthConfig
--
-- Rebirth setzt NUR die Cash-Progression zurück:
--   * Cash und Vault -> 0
--   * Character-Level -> 1
-- Bleibt erhalten: alle Characters, Mutationen, Gear, Potions, Dice, Gebiete,
-- Index, Cosmetics, Titel, Käufe, Stats.
--
-- Jede Stufe hat Kosten (Cash, wird verbraucht) und Belohnungen. Belohnungen
-- sind kumulativ (Rebirth 3 hat auch alles von 1 und 2).
-- Nach der Tabelle geht es per Formel weiter (Cost * Growth, kleine Boni).

export type RebirthReward = {
	CashPct: number?,
	LuckPct: number?,
	BaseSlots: number?,
	FishingSlots: number?,
	GearSlots: number?,
	AutoCollect: boolean?,
	Title: string?,
}

export type RebirthStep = {
	Cost: number,
	Rewards: RebirthReward,
}

local RebirthConfig = {}

RebirthConfig.Steps = {
	[1] = { Cost = 220000, Rewards = { CashPct = 10, BaseSlots = 2, AutoCollect = true } },
	[2] = { Cost = 5700000, Rewards = { LuckPct = 10, FishingSlots = 1 } },
	[3] = { Cost = 32000000, Rewards = { CashPct = 15, BaseSlots = 2 } },
	[4] = { Cost = 69000000, Rewards = { LuckPct = 10, GearSlots = 1 } },
	[5] = { Cost = 280000000, Rewards = { CashPct = 15, BaseSlots = 2, Title = "RiftWalker" } },
	[6] = { Cost = 450000000, Rewards = { LuckPct = 15, FishingSlots = 1 } },
	[7] = { Cost = 1100000000, Rewards = { CashPct = 20, BaseSlots = 3 } },
	[8] = { Cost = 2400000000, Rewards = { LuckPct = 15 } },
	[9] = { Cost = 6700000000, Rewards = { CashPct = 20, FishingSlots = 1 } },
	[10] = { Cost = 19000000000, Rewards = { LuckPct = 20, BaseSlots = 4, Title = "VoidSeeker" } },
	[11] = { Cost = 53000000000, Rewards = { CashPct = 20 } },
	[12] = { Cost = 150000000000, Rewards = { LuckPct = 20, Title = "TheSurvivor" } },
} :: { [number]: RebirthStep }

RebirthConfig.TableSize = #RebirthConfig.Steps

-- Nach der Tabelle:
RebirthConfig.AfterTable = {
	CostGrowth = 2.8,
	Rewards = { CashPct = 10, LuckPct = 5 },
}

function RebirthConfig.GetStep(rebirthNumber: number): RebirthStep
	local step = RebirthConfig.Steps[rebirthNumber]
	if step then
		return step
	end
	local last = RebirthConfig.Steps[RebirthConfig.TableSize]
	local extra = rebirthNumber - RebirthConfig.TableSize
	return {
		Cost = math.floor(last.Cost * RebirthConfig.AfterTable.CostGrowth ^ extra),
		Rewards = RebirthConfig.AfterTable.Rewards,
	}
end

-- Summe aller Belohnungen bis einschließlich `rebirths`
function RebirthConfig.Accumulate(rebirths: number)
	local total = { CashPct = 0, LuckPct = 0, BaseSlots = 0, FishingSlots = 0, GearSlots = 0, AutoCollect = false, Titles = {} }
	for i = 1, rebirths do
		local r = RebirthConfig.GetStep(i).Rewards
		total.CashPct += r.CashPct or 0
		total.LuckPct += r.LuckPct or 0
		total.BaseSlots += r.BaseSlots or 0
		total.FishingSlots += r.FishingSlots or 0
		total.GearSlots += r.GearSlots or 0
		if r.AutoCollect then
			total.AutoCollect = true
		end
		if r.Title then
			table.insert(total.Titles, r.Title)
		end
	end
	return total
end

return RebirthConfig
