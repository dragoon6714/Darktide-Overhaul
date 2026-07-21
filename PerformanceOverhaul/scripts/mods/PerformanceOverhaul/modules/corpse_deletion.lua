local mod = get_mod("PerformanceOverhaul")

-- Instant corpse deletion (Vanilla / Fast / Instant).
-- Drives the game's EXISTING despawn path: MinionRagdoll._remove_ragdoll ->
-- Managers.state.unit_spawner:mark_for_deletion. No parallel deletion system.
-- "Instant" evicts every ragdoll the moment it is created; "Fast" keeps a small pool.

local counters = mod.counters

local MODE_CAPS = {
	vanilla = nil,
	fast = 6,
	instant = 0,
}

local cap = nil

-- Target verified: scripts/managers/minion/minion_ragdoll.lua:132
-- MinionRagdoll.create_ragdoll(self, death_data); the eviction loop below mirrors the
-- game's own max_ragdolls enforcement at :139-145 (oldest first, same _remove_ragdoll).
-- hook_safe: runs after the original in protected mode; no return value to change.
mod:hook_safe("MinionRagdoll", "create_ragdoll", function(self, death_data)
	if not cap then
		return
	end

	local ragdolls = self._ragdolls

	while cap < self._num_ragdolls and ragdolls[1] do
		self:_remove_ragdoll(ragdolls[1])

		counters.corpses_despawned = counters.corpses_despawned + 1
	end
end)

local corpse_deletion = {}

corpse_deletion.apply = function(settings)
	local mode = settings.corpse_deletion_mode or "vanilla"

	cap = MODE_CAPS[mode]
	mod:info("corpse_deletion: mode %s (cap %s)", mode, tostring(cap))
end

corpse_deletion.revert = function()
	cap = nil
	mod:info("corpse_deletion: reverted to vanilla")
end

corpse_deletion.on_setting_changed = function(setting_id, value)
	if setting_id == "corpse_deletion_mode" then
		cap = MODE_CAPS[value]
		mod:info("corpse_deletion: mode %s (cap %s)", tostring(value), tostring(cap))
	end
end

return corpse_deletion
