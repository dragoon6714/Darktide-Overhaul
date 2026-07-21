local mod = get_mod("PerformanceOverhaul")

-- Shared diagnostics counters. Persistent so Ctrl+Shift+R mod reloads keep history.
mod.counters = mod:persistent_table("counters", {
	vfx_spawned = 0,
	vfx_culled = 0,
	blood_balls_culled = 0,
	audio_dropped = 0,
	corpses_despawned = 0,
	moods_filtered = 0,
	shakes_blocked = 0,
})

local MODULE_ROOT = "PerformanceOverhaul/scripts/mods/PerformanceOverhaul/modules/"

-- One file per optimization system; keep in AGENT.md §9 order.
local MODULE_NAMES = {
	"vfx_limiter",
	"decal_control",
	"corpse_control",
	"audio_limiter",
}

-- Each module file returns a table that may define:
--   refresh_settings(setting_id_or_nil)  -- re-read mod settings into local caches
--   update(dt)                           -- per-frame work (must self-gate, near-zero cost when off)
--   on_enabled(initial_call) / on_disabled(initial_call)
--   on_game_state_changed(status, state_name)
local modules = {}

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

mod.modules = modules

mod.on_setting_changed = function(setting_id)
	for i = 1, #modules do
		local refresh = modules[i].refresh_settings

		if refresh then
			refresh(setting_id)
		end
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
end

mod.on_disabled = function(initial_call)
	for i = 1, #modules do
		local on_disabled = modules[i].on_disabled

		if on_disabled then
			on_disabled(initial_call)
		end
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

mod:info("loaded (%d modules)", #modules)
