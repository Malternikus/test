--!strict
-- Context (ModuleScript)
-- Ort: ServerScriptService > VoidDiceServer > Logic > Context
--
-- Ein Context begleitet einen Logik-Aufruf (eine Spieleraktion oder einen Tick).
-- Er liefert Zeit und Zufall von außen (Server: echte Zeit/Random, Simulation:
-- simulierte Zeit/Seed) und sammelt, was sich geändert hat:
--   dirty       geänderte Top-Level-Keys des Profils -> Sync an den Client
--   dirtyChars  geänderte Characters (uid)
--   dirtyGear   geänderte Gear-Items (uid)
--   events      Meldungen für den Client (Toasts, Reveals, Ansagen)
--
-- Die Logik-Module sind dadurch reine Funktionen auf Tabellen und ohne
-- Roblox-Services testbar.

export type RNG = { NextNumber: (self: any) -> number, NextInteger: (self: any, number, number) -> number }

export type Context = {
	now: number,
	rng: RNG,
	userId: number,
	isStudio: boolean,
	events: { { Kind: string, Data: any } },
	dirty: { [string]: boolean },
	dirtyChars: { [string]: boolean },
	dirtyGear: { [string]: boolean },
}

local Context = {}

function Context.new(options: { now: number, rng: RNG, userId: number?, isStudio: boolean? }): Context
	return {
		now = options.now,
		rng = options.rng,
		userId = options.userId or 0,
		isStudio = options.isStudio == true,
		events = {},
		dirty = {},
		dirtyChars = {},
		dirtyGear = {},
	}
end

function Context.mark(ctx: Context, key: string)
	ctx.dirty[key] = true
end

function Context.markChar(ctx: Context, uid: string)
	ctx.dirtyChars[uid] = true
end

function Context.markGear(ctx: Context, uid: string)
	ctx.dirtyGear[uid] = true
end

function Context.event(ctx: Context, kind: string, data: any?)
	table.insert(ctx.events, { Kind = kind, Data = data })
end

return Context
