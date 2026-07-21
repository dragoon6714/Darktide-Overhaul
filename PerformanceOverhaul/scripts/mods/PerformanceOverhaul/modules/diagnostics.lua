local mod = get_mod("PerformanceOverhaul")

-- Diagnostics overlay (AGENT.md §4.9).
-- Live frametime stats + this mod's own limiter counters, as a HUD overlay, a /po_status
-- chat command, and an optional periodic log line (the log-based verification path for
-- agents, AGENT.md §7B.6).

local counters = mod.counters

local enabled = false
local log_interval = 0

mod.diag_visible = false
mod.diag_text = ""

-- 60-frame ring of frame times.
local FRAME_WINDOW = 60
local frame_times = {}

for i = 1, FRAME_WINDOW do
	frame_times[i] = 0
end

local frame_index = 0
local text_accumulator = 0
local log_accumulator = 0

-- Per-second rate snapshots of the shared counters.
local rate_accumulator = 0
local last_snapshot = {}
local rates = {}

local RATE_KEYS = {
	"vfx_spawned",
	"vfx_culled",
	"blood_balls_culled",
	"audio_dropped",
	"corpses_despawned",
	"moods_filtered",
	"shakes_blocked",
}

for i = 1, #RATE_KEYS do
	local key = RATE_KEYS[i]

	last_snapshot[key] = counters[key] or 0
	rates[key] = 0
end

local function frame_stats()
	local sum = 0
	local max = 0

	for i = 1, FRAME_WINDOW do
		local ft = frame_times[i]

		sum = sum + ft

		if max < ft then
			max = ft
		end
	end

	local avg = sum / FRAME_WINDOW

	return avg, max
end

local function lua_memory_mb()
	local ok, kb = pcall(collectgarbage, "count")

	return ok and kb / 1024 or 0
end

local function live_game_counts()
	-- Instance paths verified: minion_death_manager.lua:257 (ragdoll manager),
	-- minion_spawn is server/solo only, decal manager caches pool config on self.
	local state = Managers.state
	local ragdolls, minions

	local death_manager = state and state.minion_death
	local minion_ragdoll = death_manager and death_manager:minion_ragdoll()

	if minion_ragdoll then
		ragdolls = minion_ragdoll._num_ragdolls
	end

	local spawn_manager = state and state.minion_spawn

	if spawn_manager then
		minions = spawn_manager:num_spawned_minions()
	end

	local decal_manager = state and state.decal
	local decal_info

	if decal_manager and decal_manager._lifetime then
		decal_info = string.format("%ds life, %s/%s/%s pools", decal_manager._lifetime,
			tostring(decal_manager._impact_pool_size), tostring(decal_manager._blood_pool_size),
			tostring(decal_manager._footstep_pool_size))
	end

	return ragdolls, minions, decal_info
end

local function build_status_text()
	local avg_ms, max_ms = frame_stats()
	local fps = avg_ms > 0 and 1 / avg_ms or 0
	local ragdolls, minions, decal_info = live_game_counts()

	return string.format(
		"Performance Overhaul\n"
			.. "FPS %.0f | frame %.2f ms avg / %.2f ms max | Lua %.1f MB\n"
			.. "ragdolls %s | minions %s\n"
			.. "decals: %s\n"
			.. "vfx spawned %d/s culled %d/s (total %d/%d)\n"
			.. "blood balls culled %d/s (total %d)\n"
			.. "audio dropped %d/s (total %d)\n"
			.. "corpses despawned %d/s (total %d)\n"
			.. "moods filtered %d | shakes blocked %d",
		fps, avg_ms * 1000, max_ms * 1000, lua_memory_mb(),
		ragdolls and tostring(ragdolls) or "-", minions and tostring(minions) or "-",
		decal_info or "-",
		rates.vfx_spawned, rates.vfx_culled, counters.vfx_spawned, counters.vfx_culled,
		rates.blood_balls_culled, counters.blood_balls_culled,
		rates.audio_dropped, counters.audio_dropped,
		rates.corpses_despawned, counters.corpses_despawned,
		counters.moods_filtered, counters.shakes_blocked)
end

local diagnostics = {
	name = "diagnostics",
}

diagnostics.refresh_settings = function()
	enabled = mod:get("diag_enabled") or false
	log_interval = mod:get("diag_log_interval") or 0
	mod.diag_visible = enabled
end

diagnostics.update = function(dt)
	frame_index = frame_index % FRAME_WINDOW + 1
	frame_times[frame_index] = dt

	rate_accumulator = rate_accumulator + dt

	if rate_accumulator >= 1 then
		rate_accumulator = 0

		for i = 1, #RATE_KEYS do
			local key = RATE_KEYS[i]
			local value = counters[key] or 0

			rates[key] = value - last_snapshot[key]
			last_snapshot[key] = value
		end
	end

	if enabled then
		text_accumulator = text_accumulator + dt

		if text_accumulator >= 0.25 then
			text_accumulator = 0
			mod.diag_text = build_status_text()
		end
	end

	if log_interval > 0 then
		log_accumulator = log_accumulator + dt

		if log_accumulator >= log_interval then
			log_accumulator = 0

			-- Single line, greppable: the log-based verification signal (AGENT.md §7B.6).
			mod:info("status | %s", (build_status_text():gsub("\n", " | ")))
		end
	end
end

-- Keybind widget target (function_call): toggles the overlay setting.
mod.po_toggle_diagnostics = function()
	mod:set("diag_enabled", not mod:get("diag_enabled"), true)
end

mod:command("po_status", "Print Performance Overhaul counters", function()
	mod:echo(build_status_text())
end)

-- Registration verified against DMF custom_hud_elements.lua: filename is added as a
-- require path and required by class_name; the file returns the class.
mod:register_hud_element({
	class_name = "PerfOverhaulDiagnostics",
	filename = "PerformanceOverhaul/scripts/mods/PerformanceOverhaul/modules/hud/diagnostics_hud_element",
	use_hud_scale = true,
	visibility_groups = {
		"alive",
	},
})

diagnostics.refresh_settings()
mod:info("diagnostics initialized (hud element registered)")

return diagnostics
