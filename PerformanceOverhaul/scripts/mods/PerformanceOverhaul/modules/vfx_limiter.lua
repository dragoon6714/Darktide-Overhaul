local mod = get_mod("PerformanceOverhaul")

-- Particle/VFX limiter (AGENT.md §4.1).
-- Budgets one-shot particle spawns per second and culls by category priority when over
-- budget. Active-particle count is not readable from Lua, so a sliding 1-second spawn
-- window is the proxy. All hooked functions are fire-and-forget (no return values).

local counters = mod.counters
local string_find = string.find

-- Settings cache (refreshed via refresh_settings; never mod:get() in hook bodies).
local enabled = false
local budget = 200
local cull_blood = false
local cull_ambient = false
local cull_weapon = false

-- Sliding 1-second window: ten rotating 100 ms buckets, allocation-free.
local NUM_BUCKETS = 10
local buckets = {}

for i = 1, NUM_BUCKETS do
	buckets[i] = 0
end

local current_bucket = 1
local last_bucket_time = 0

local function spawns_last_second(t)
	-- Rotate buckets forward to t, zeroing skipped ones.
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

local function count_spawn()
	buckets[current_bucket] = buckets[current_bucket] + 1
	counters.vfx_spawned = counters.vfx_spawned + 1
end

local CAT_BLOOD, CAT_IMPACT, CAT_WEAPON, CAT_AMBIENT, CAT_OTHER = 1, 2, 3, 4, 5

local function classify(vfx_name)
	-- Names look like "content/fx/particles/impacts/weapons/..." — check blood first so
	-- blood-flavored impacts cull with the blood category.
	if string_find(vfx_name, "blood", 1, true) then
		return CAT_BLOOD
	elseif string_find(vfx_name, "/impacts/", 1, true) or string_find(vfx_name, "impact_", 1, true) then
		return CAT_IMPACT
	elseif string_find(vfx_name, "/weapons/", 1, true) or string_find(vfx_name, "muzzle", 1, true) then
		return CAT_WEAPON
	elseif string_find(vfx_name, "ambience", 1, true) or string_find(vfx_name, "ambient", 1, true)
		or string_find(vfx_name, "/environment/", 1, true) then
		return CAT_AMBIENT
	end

	return CAT_OTHER
end

local function now()
	local time_manager = Managers.time

	return time_manager and time_manager:time("main") or 0
end

-- Returns true if the one-shot may spawn; counts it into the window when allowed.
local function allow_oneshot(vfx_name)
	if not enabled or not vfx_name then
		return true
	end

	local category = classify(vfx_name)

	if (category == CAT_BLOOD and cull_blood)
		or (category == CAT_AMBIENT and cull_ambient)
		or (category == CAT_WEAPON and cull_weapon) then
		counters.vfx_culled = counters.vfx_culled + 1

		return false
	end

	local rate = spawns_last_second(now())

	-- Tiered eviction: cheapest-to-lose categories go first, impacts (hit feedback) last.
	if rate >= budget and (category == CAT_BLOOD or category == CAT_AMBIENT)
		or rate >= budget * 1.2 and (category == CAT_WEAPON or category == CAT_OTHER)
		or rate >= budget * 1.5 then
		counters.vfx_culled = counters.vfx_culled + 1

		return false
	end

	count_spawn()

	return true
end

-- Returns true if an impact fx call may run. Impacts are highest priority: dropped only
-- at 150% budget, never when the hit target is a player unit (hit feedback).
local function allow_impact(optional_target_unit)
	if not enabled then
		return true
	end

	local rate = spawns_last_second(now())

	if rate >= budget * 1.5 then
		local player_manager = Managers.player

		if not (optional_target_unit and player_manager and player_manager:player_by_unit(optional_target_unit)) then
			counters.vfx_culled = counters.vfx_culled + 1

			return false
		end
	end

	count_spawn()

	return true
end

-- Target verified: scripts/extension_systems/fx/fx_system.lua:328 FxSystem.trigger_vfx
-- (solo/host path; online clients receive rpc_trigger_vfx instead).
mod:hook("FxSystem", "trigger_vfx", function(func, self, vfx_name, position, optional_rotation)
	if allow_oneshot(vfx_name) then
		return func(self, vfx_name, position, optional_rotation)
	end
end)

-- Target verified: scripts/extension_systems/fx/fx_system.lua:530 FxSystem.rpc_trigger_vfx
-- (online client receive; calls World.create_particles directly, so trigger_vfx hook
-- does not cover it). Dropping a received rpc is pure-local.
mod:hook("FxSystem", "rpc_trigger_vfx", function(func, self, channel_id, vfx_id, position, optional_rotation)
	local vfx_name = NetworkLookup.vfx[vfx_id]

	if allow_oneshot(vfx_name) then
		return func(self, channel_id, vfx_id, position, optional_rotation)
	end
end)

-- Target verified: scripts/extension_systems/fx/fx_system.lua:203 FxSystem.play_impact_fx.
-- Covers both paths: rpc_play_impact_fx (fx_system.lua:482) calls this method locally.
mod:hook("FxSystem", "play_impact_fx", function(func, self, impact_fx, hit_position, attack_direction, source_parameters, attacking_unit, optional_target_unit, ...)
	if allow_impact(optional_target_unit) then
		return func(self, impact_fx, hit_position, attack_direction, source_parameters, attacking_unit, optional_target_unit, ...)
	end
end)

-- Target verified: scripts/extension_systems/fx/fx_system.lua:235
-- FxSystem.play_surface_impact_fx (rpc twin at :500 calls through). No target unit.
mod:hook("FxSystem", "play_surface_impact_fx", function(func, self, ...)
	if allow_impact(nil) then
		return func(self, ...)
	end
end)

-- Target verified: scripts/extension_systems/fx/fx_system.lua:275
-- FxSystem.play_shotshell_surface_impact_fx (rpc twin at :516 calls through). One blast
-- counts as one budget item.
mod:hook("FxSystem", "play_shotshell_surface_impact_fx", function(func, self, ...)
	if allow_impact(nil) then
		return func(self, ...)
	end
end)

-- Target verified: scripts/managers/blood/blood_manager.lua:102
-- BloodManager.queue_blood_ball (client-local; no rpc twin). Blood balls also produce
-- blood decals on collision, so the blood category cull reduces those too.
mod:hook("BloodManager", "queue_blood_ball", function(func, self, position, direction, blood_ball_unit, optional_damage_type)
	if enabled then
		if cull_blood then
			counters.blood_balls_culled = counters.blood_balls_culled + 1

			return
		end

		if spawns_last_second(now()) >= budget then
			counters.blood_balls_culled = counters.blood_balls_culled + 1

			return
		end

		count_spawn()
	end

	return func(self, position, direction, blood_ball_unit, optional_damage_type)
end)

local vfx_limiter = {
	name = "vfx_limiter",
}

vfx_limiter.refresh_settings = function()
	enabled = mod:get("vfx_enabled") or false
	budget = mod:get("vfx_budget") or 200
	cull_blood = mod:get("vfx_cull_blood") or false
	cull_ambient = mod:get("vfx_cull_ambient") or false
	cull_weapon = mod:get("vfx_cull_weapon") or false
end

vfx_limiter.refresh_settings()
mod:info("vfx_limiter hooks registered")

return vfx_limiter
