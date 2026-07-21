local mod = get_mod("PerformanceOverhaul")

-- Animation throttling via the engine's existing bone-LOD system.
-- Beyond the bone-LOD out-distance, the engine already reduces minion bone animation
-- updates; vanilla thresholds are 7/8 meters (default_game_parameters.lua:51-52). We
-- override the distance the manager feeds the engine. The requested "update-rate
-- divisor" is INFEASIBLE from Lua: BoneLod.init takes one of three fixed engine modes
-- (USE_ALL_BONE_LOD etc.), no rate parameter — documented in AGENT.md §4.11.

local distance = 0

-- Target verified: scripts/managers/bone_lod/bone_lod_manager.lua:6-24
-- BoneLodManager.init reads GameParameters.bone_lod_in_distance/out_distance and calls
-- engine BoneLod.init once per gameplay world. Regular hook (not hook_safe) because the
-- values are read INSIDE func; we swap them around the call and restore immediately, so
-- GameParameters is never left mutated.
mod:hook("BoneLodManager", "init", function(func, self, world, is_dedicated_server, is_server)
	if distance <= 0 then
		return func(self, world, is_dedicated_server, is_server)
	end

	local game_parameters = GameParameters
	local original_in = game_parameters.bone_lod_in_distance
	local original_out = game_parameters.bone_lod_out_distance

	game_parameters.bone_lod_in_distance = math.max(1, distance - 1)
	game_parameters.bone_lod_out_distance = distance

	func(self, world, is_dedicated_server, is_server)

	game_parameters.bone_lod_in_distance = original_in
	game_parameters.bone_lod_out_distance = original_out

	mod:info("anim_throttle: bone LOD distance %d applied for this world", distance)
end)

local anim_throttle = {}

anim_throttle.apply = function(settings)
	distance = settings.anim_lod_distance or 0
	mod:info("anim_throttle: distance %d (0 = vanilla; takes effect at mission start)", distance)
end

anim_throttle.revert = function()
	distance = 0
	mod:info("anim_throttle: reverted to vanilla (takes effect at mission start)")
end

anim_throttle.on_setting_changed = function(setting_id, value)
	if setting_id == "anim_lod_distance" then
		distance = value or 0
		mod:info("anim_throttle: distance %d (takes effect at next mission start)", distance)
	end
end

return anim_throttle
