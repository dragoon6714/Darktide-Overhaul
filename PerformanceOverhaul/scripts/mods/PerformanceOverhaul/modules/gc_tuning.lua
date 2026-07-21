local mod = get_mod("PerformanceOverhaul")

-- Lua GC tuning (AGENT.md §4.8).
-- collectgarbage is exposed in the game's Lua env (the game itself calls it in
-- scripts/managers/imgui/imgui_lua_memory_snapshot.lua:30). We tune the incremental
-- collector or amortize it with small manual steps. Tradeoff: slightly more average GC
-- CPU for fewer/smaller frame hitches. No hooks — pure collectgarbage calls.

-- LuaJIT defaults, restored on vanilla/disable.
local DEFAULT_STEPMUL = 200
local DEFAULT_PAUSE = 200
local SMOOTH_STEPMUL = 400
local SMOOTH_PAUSE = 150

local mode = "vanilla"
local step_kb = 100
local gc_available = nil

local function check_available()
	if gc_available == nil then
		gc_available = pcall(collectgarbage, "count") and true or false

		if not gc_available then
			mod:warning("collectgarbage unavailable in this environment; GC tuning disabled")
		end
	end

	return gc_available
end

local function apply_mode(new_mode)
	if not check_available() then
		return
	end

	if new_mode == "smooth" or new_mode == "manual_step" then
		pcall(collectgarbage, "setstepmul", SMOOTH_STEPMUL)
		pcall(collectgarbage, "setpause", SMOOTH_PAUSE)
	else
		pcall(collectgarbage, "setstepmul", DEFAULT_STEPMUL)
		pcall(collectgarbage, "setpause", DEFAULT_PAUSE)
	end
end

local gc_tuning = {
	name = "gc_tuning",
}

gc_tuning.refresh_settings = function()
	local new_mode = mod:get("gc_mode") or "vanilla"

	step_kb = mod:get("gc_step_kb") or 100

	if new_mode ~= mode then
		mode = new_mode

		apply_mode(mode)
		mod:info("gc mode set to %s", mode)
	end
end

gc_tuning.update = function(dt)
	if mode == "manual_step" and check_available() then
		-- Small bounded step each frame; amortizes collection work instead of letting the
		-- collector bunch it into hitches.
		pcall(collectgarbage, "step", step_kb)
	end
end

gc_tuning.on_enabled = function()
	apply_mode(mode)
end

gc_tuning.on_disabled = function()
	-- Leave the VM exactly as vanilla when the mod is toggled off.
	apply_mode("vanilla")
end

gc_tuning.refresh_settings()
mod:info("gc_tuning initialized (no hooks)")

return gc_tuning
