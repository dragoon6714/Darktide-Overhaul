local mod = get_mod("PerformanceOverhaul")

-- Corpse/ragdoll control (AGENT.md §4.3).
-- (a) Enforces a lower ragdoll cap than the game's max_ragdolls setting, reusing the
-- game's own oldest-first eviction. (b) Optionally despawns corpses older than a max age.
-- Corpses are client-visual; despawning locally changes nothing for other players.

local counters = mod.counters

local enabled = false
local max_ragdolls = 50
local max_age = 0

local ragdoll_birth = {}
local scan_accumulator = 0
local SCAN_INTERVAL = 0.5

local function gameplay_time()
	local time_manager = Managers.time

	return time_manager and time_manager:time("gameplay")
end

-- Target verified: scripts/managers/minion/minion_ragdoll.lua:132
-- MinionRagdoll.create_ragdoll(self, death_data) — the game enforces its own
-- max_ragdolls cap here via _remove_ragdoll (oldest first); we tighten it the same way.
mod:hook("MinionRagdoll", "create_ragdoll", function(func, self, death_data)
	func(self, death_data)

	if not enabled then
		return
	end

	local unit = death_data and death_data.unit

	if unit and max_age > 0 then
		ragdoll_birth[unit] = gameplay_time()
	end

	local ragdolls = self._ragdolls

	while max_ragdolls < self._num_ragdolls and ragdolls[1] do
		self:_remove_ragdoll(ragdolls[1])

		counters.corpses_despawned = counters.corpses_despawned + 1
	end
end)

-- Target verified: scripts/managers/minion/minion_ragdoll.lua:163
-- MinionRagdoll._remove_ragdoll(self, unit) — bookkeeping only, so hook_safe.
mod:hook_safe("MinionRagdoll", "_remove_ragdoll", function(self, unit)
	ragdoll_birth[unit] = nil
end)

local corpse_control = {
	name = "corpse_control",
}

corpse_control.refresh_settings = function()
	enabled = mod:get("corpse_enabled") or false
	max_ragdolls = mod:get("corpse_max_ragdolls") or 50
	max_age = mod:get("corpse_max_age") or 0
end

corpse_control.update = function(dt)
	if not enabled or max_age <= 0 then
		return
	end

	scan_accumulator = scan_accumulator + dt

	if scan_accumulator < SCAN_INTERVAL then
		return
	end

	scan_accumulator = 0

	-- Instance path verified: scripts/managers/minion/minion_death_manager.lua:257
	local death_manager = Managers.state and Managers.state.minion_death
	local minion_ragdoll = death_manager and death_manager:minion_ragdoll()

	if not minion_ragdoll then
		return
	end

	local t = gameplay_time()

	if not t then
		return
	end

	local ragdolls = minion_ragdoll._ragdolls

	for i = minion_ragdoll._num_ragdolls, 1, -1 do
		local unit = ragdolls[i]
		local birth = unit and ragdoll_birth[unit]

		if birth and max_age < t - birth then
			minion_ragdoll:_remove_ragdoll(unit)

			counters.corpses_despawned = counters.corpses_despawned + 1
		end
	end
end

corpse_control.on_game_state_changed = function(status, state_name)
	if state_name == "StateGameplay" then
		-- Drop stale unit references between missions.
		ragdoll_birth = {}
		scan_accumulator = 0
	end
end

corpse_control.refresh_settings()
mod:info("corpse_control hooks registered")

return corpse_control
