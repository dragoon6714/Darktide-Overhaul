local mod = get_mod("PerformanceOverhaul")

-- Shared diagnostics counters. Persistent so Ctrl+Shift+R mod reloads keep history.
local COUNTER_DEFAULTS = {
	vfx_spawned = 0,
	vfx_culled = 0,
	blood_balls_culled = 0,
	audio_dropped = 0,
	corpses_despawned = 0,
	moods_filtered = 0,
	shakes_blocked = 0,
	clutter_hidden = 0,
}

mod.counters = mod:persistent_table("counters", COUNTER_DEFAULTS)

-- A table persisted by an older mod version may lack newer keys; nil arithmetic inside
-- a regular hook would crash the game, so backfill defensively.
for key, value in pairs(COUNTER_DEFAULTS) do
	if mod.counters[key] == nil then
		mod.counters[key] = value
	end
end

local MODULE_ROOT = "PerformanceOverhaul/scripts/mods/PerformanceOverhaul/modules/"

-- One file per optimization system; keep in AGENT.md §9 order.
local MODULE_NAMES = {
	"vfx_limiter",
	"decal_control",
	"corpse_control",
	"audio_limiter",
	"screen_effects",
	"lighting",
	"fov",
	"gc_tuning",
	"diagnostics",
}

-- v2-contract modules export exactly: apply(settings), revert(), on_setting_changed(id, value).
local V2_MODULE_NAMES = {
	"corpse_deletion",
	"anim_throttle",
	"map_reducer",
}

-- Read-through settings view passed to v2 apply(); settings.foo == mod:get("foo").
local settings_view = setmetatable({}, {
	__index = function(_, setting_id)
		return mod:get(setting_id)
	end,
})

-- Each v1 module file returns a table that may define:
--   refresh_settings(setting_id_or_nil)  -- re-read mod settings into local caches
--   update(dt)                           -- per-frame work (must self-gate, near-zero cost when off)
--   on_enabled(initial_call) / on_disabled(initial_call)
--   on_game_state_changed(status, state_name)
local modules = {}
local v2_modules = {}

for i = 1, #MODULE_NAMES do
	local name = MODULE_NAMES[i]
	local module = mod:io_dofile(MODULE_ROOT .. name)

	if module then
		module.name = module.name or name
		modules[#modules + 1] = module
	else
		mod:error("module '%s' failed to load", name)
	end
end

for i = 1, #V2_MODULE_NAMES do
	local name = V2_MODULE_NAMES[i]
	local module = mod:io_dofile(MODULE_ROOT .. name)

	if module then
		v2_modules[#v2_modules + 1] = module
	else
		mod:error("module '%s' failed to load", name)
	end
end

mod.modules = modules
mod.v2_modules = v2_modules

mod.on_setting_changed = function(setting_id)
	for i = 1, #modules do
		local refresh = modules[i].refresh_settings

		if refresh then
			refresh(setting_id)
		end
	end

	local value = mod:get(setting_id)

	for i = 1, #v2_modules do
		v2_modules[i].on_setting_changed(setting_id, value)
	end
end

mod.update = function(dt)
	if not mod:is_enabled() then
		return
	end

	for i = 1, #modules do
		local update = modules[i].update

		if update then
			update(dt)
		end
	end
end

mod.on_enabled = function(initial_call)
	for i = 1, #modules do
		local on_enabled = modules[i].on_enabled

		if on_enabled then
			on_enabled(initial_call)
		end
	end

	for i = 1, #v2_modules do
		v2_modules[i].apply(settings_view)
	end
end

mod.on_disabled = function(initial_call)
	for i = 1, #modules do
		local on_disabled = modules[i].on_disabled

		if on_disabled then
			on_disabled(initial_call)
		end
	end

	for i = 1, #v2_modules do
		v2_modules[i].revert()
	end
end

mod.on_game_state_changed = function(status, state_name)
	for i = 1, #modules do
		local callback = modules[i].on_game_state_changed

		if callback then
			callback(status, state_name)
		end
	end
end

mod:info("loaded (%d modules)", #modules + #v2_modules)
