local mod = get_mod("PerformanceOverhaul")

-- Screen effect toggles (AGENT.md §4.5).
-- Filters the "mood" system's fullscreen particle overlays by category and gates camera
-- shake. Only feedback overlays are filterable; ability/stealth state moods always show.
-- Mood shading blends (vignette/color grade) still apply — filtering moods_data itself
-- would desync the mood state machine.

local counters = mod.counters

local enabled = false
local shake_allowed = true
local show_category = {
	suppression = true,
	damage = true,
	warp = true,
	corruption = true,
}

-- Mood type names verified against scripts/settings/camera/mood/mood_settings.lua
-- (table.enum near top of file; enum values equal their names).
local MOOD_CATEGORY = {
	suppression_low = "suppression",
	suppression_high = "suppression",
	suppression_ongoing = "suppression",
	damage_taken = "damage",
	toughness_absorbed = "damage",
	toughness_absorbed_melee = "damage",
	toughness_broken = "damage",
	no_toughness = "damage",
	critical_health = "damage",
	last_wound = "damage",
	knocked_down = "damage",
	corruption_taken = "damage",
	warped = "warp",
	warped_low_to_high = "warp",
	warped_high_to_critical = "warp",
	warped_critical = "warp",
	corruption = "corruption",
	corruptor_proximity = "corruption",
}

-- Reused scratch table (single-threaded, consumed synchronously inside func).
local filtered_added = {}

-- Target verified: scripts/managers/camera/mood_handler/mood_handler.lua:267
-- MoodHandler._update_particles(self, added_moods, removing_moods, removed_moods,
-- moods_data). added_moods is shared with _update_sounds/_blend_list (update_moods,
-- mood_handler.lua:66) so we pass a filtered COPY, never mutate the original;
-- removing/removed pass through untouched so cleanup of spawned effects always runs.
mod:hook("MoodHandler", "_update_particles", function(func, self, added_moods, removing_moods, removed_moods, moods_data)
	if enabled then
		for mood in pairs(filtered_added) do
			filtered_added[mood] = nil
		end

		for mood, value in pairs(added_moods) do
			local category = MOOD_CATEGORY[mood]

			if category and not show_category[category] then
				counters.moods_filtered = counters.moods_filtered + 1
			else
				filtered_added[mood] = value
			end
		end

		return func(self, filtered_added, removing_moods, removed_moods, moods_data)
	end

	return func(self, added_moods, removing_moods, removed_moods, moods_data)
end)

-- Target verified: scripts/managers/camera/camera_manager.lua:689
-- CameraManager.add_camera_effect_shake_event (mirrors the game's own
-- _camera_shake_enabled early-out; no return value).
mod:hook("CameraManager", "add_camera_effect_shake_event", function(func, self, event_name, optional_source_unit_data)
	if enabled and not shake_allowed then
		counters.shakes_blocked = counters.shakes_blocked + 1

		return
	end

	return func(self, event_name, optional_source_unit_data)
end)

-- Target verified: scripts/managers/camera/camera_manager.lua:651
-- CameraManager.add_camera_effect_sequence_event (same gate in vanilla; no return value).
mod:hook("CameraManager", "add_camera_effect_sequence_event", function(func, self, event, start_time)
	if enabled and not shake_allowed then
		counters.shakes_blocked = counters.shakes_blocked + 1

		return
	end

	return func(self, event, start_time)
end)

local screen_effects = {
	name = "screen_effects",
}

screen_effects.refresh_settings = function()
	enabled = mod:get("screenfx_enabled") or false
	shake_allowed = mod:get("screenfx_camera_shake")
	show_category.suppression = mod:get("screenfx_suppression")
	show_category.damage = mod:get("screenfx_damage")
	show_category.warp = mod:get("screenfx_warp")
	show_category.corruption = mod:get("screenfx_corruption")

	-- Unset settings (nil) must mean "show" — only explicit false hides.
	if shake_allowed == nil then
		shake_allowed = true
	end

	for category, value in pairs(show_category) do
		if value == nil then
			show_category[category] = true
		end
	end
end

screen_effects.refresh_settings()
mod:info("screen_effects hooks registered")

return screen_effects
