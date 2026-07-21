local mod = get_mod("PerformanceOverhaul")

-- Audio event limiter (AGENT.md §4.4).
-- Honest scope: Wwise voice limiting is engine-side and unreachable from Lua. This module
-- rate-limits 3D *one-shot event triggers* at the Lua choke points instead, dropping
-- excess positional sounds during spam peaks. 2D/UI/music/dialogue paths are never
-- touched (they don't route through these hooks or carry no position/unit).

local counters = mod.counters

local enabled = false
local budget = 100

-- Sliding 1-second window: ten rotating 100 ms buckets (same pattern as vfx_limiter,
-- kept local — modules are self-contained by contract).
local NUM_BUCKETS = 10
local buckets = {}

for i = 1, NUM_BUCKETS do
	buckets[i] = 0
end

local current_bucket = 1
local last_bucket_time = 0

local function events_last_second()
	local time_manager = Managers.time
	local t = time_manager and time_manager:time("main") or 0
	local elapsed = t - last_bucket_time

	if elapsed >= 0.1 then
		local steps = math.floor(elapsed * 10)

		if steps >= NUM_BUCKETS then
			for i = 1, NUM_BUCKETS do
				buckets[i] = 0
			end

			current_bucket = 1
		else
			for _ = 1, steps do
				current_bucket = current_bucket % NUM_BUCKETS + 1
				buckets[current_bucket] = 0
			end
		end

		last_bucket_time = t
	end

	local sum = 0

	for i = 1, NUM_BUCKETS do
		sum = sum + buckets[i]
	end

	return sum
end

-- Returns true when a 3D one-shot may fire; counts it into the window when allowed.
local function allow_3d_event()
	if not enabled then
		return true
	end

	if events_last_second() >= budget then
		counters.audio_dropped = counters.audio_dropped + 1

		return false
	end

	buckets[current_bucket] = buckets[current_bucket] + 1

	return true
end

-- Target verified: scripts/extension_systems/fx/fx_system.lua:344
-- FxSystem.trigger_wwise_event (no return value; callers verified fire-and-forget).
-- Only positional/unit-attached (3D) events are ever dropped; 2D and ambisonics pass.
mod:hook("FxSystem", "trigger_wwise_event", function(func, self, event_name, optional_position, optional_unit, ...)
	if optional_position or optional_unit then
		if not allow_3d_event() then
			return
		end
	end

	return func(self, event_name, optional_position, optional_unit, ...)
end)

-- Target verified: scripts/extension_systems/fx/fx_system.lua:335
-- FxSystem.trigger_local_unit_wwise_event(self, event_name, unit, optional_node) —
-- local 3D unit foley, no return value.
mod:hook("FxSystem", "trigger_local_unit_wwise_event", function(func, self, event_name, unit, optional_node)
	if not allow_3d_event() then
		return
	end

	return func(self, event_name, unit, optional_node)
end)

-- Target verified: scripts/extension_systems/fx/fx_system.lua:542
-- FxSystem.rpc_trigger_wwise_event (online client receive; dropping is pure-local).
-- Ambisonics events (ambience beds) always pass.
mod:hook("FxSystem", "rpc_trigger_wwise_event", function(func, self, channel_id, event_id, optional_position, optional_unit_id, ...)
	if optional_position or optional_unit_id then
		if not allow_3d_event() then
			return
		end
	end

	return func(self, channel_id, event_id, optional_position, optional_unit_id, ...)
end)

local audio_limiter = {
	name = "audio_limiter",
}

audio_limiter.refresh_settings = function()
	enabled = mod:get("audio_enabled") or false
	budget = mod:get("audio_budget") or 100
end

audio_limiter.refresh_settings()
mod:info("audio_limiter hooks registered")

return audio_limiter
