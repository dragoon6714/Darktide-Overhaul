local mod = get_mod("PerformanceOverhaul")

-- Decal manager (AGENT.md §4.2).
-- Scales decal pool sizes and lifetime on top of the game's own performance settings
-- without rewriting the user's config. DecalManager._check_new_user_settings
-- (scripts/managers/decal/decal_manager.lua:143) re-reads the game settings every frame
-- and calls init_settings when they change — our hook adjusts the values in-flight.

local enabled = false
local max_count = 100
local lifetime_mult = 1.0

local math_min = math.min
local math_max = math.max

-- Target verified: scripts/managers/decal/decal_manager.lua:24 DecalManager.init_settings
-- (self, lifetime, impact_pool_size, blood_pool_size, footstep_pool_size); values flow
-- into EngineOptimizedManagers.decal_manager_add_setting, which owns spawn/despawn.
mod:hook("DecalManager", "init_settings", function(func, self, lifetime, impact_pool_size, blood_pool_size, footstep_pool_size)
	if enabled then
		-- Engine pools need at least 1 slot; lifetime below ~1s makes decals pop visibly.
		lifetime = math_max(1, (lifetime or 0) * lifetime_mult)
		impact_pool_size = math_min(impact_pool_size or max_count, max_count)
		blood_pool_size = math_min(blood_pool_size or max_count, max_count)
		footstep_pool_size = math_min(footstep_pool_size or max_count, max_count)
	end

	return func(self, lifetime, impact_pool_size, blood_pool_size, footstep_pool_size)
end)

local function force_reapply()
	-- _check_new_user_settings only calls init_settings when a value differs from the
	-- cached one; poisoning the cache makes the next frame re-run it through our hook.
	local decal_manager = Managers.state and Managers.state.decal

	if decal_manager and decal_manager._lifetime then
		decal_manager._lifetime = -1
	end
end

local decal_control = {
	name = "decal_control",
}

decal_control.refresh_settings = function()
	local was_enabled = enabled
	local old_count = max_count
	local old_mult = lifetime_mult

	enabled = mod:get("decal_enabled") or false
	max_count = mod:get("decal_max_count") or 100
	lifetime_mult = mod:get("decal_lifetime_mult") or 1.0

	if enabled ~= was_enabled or max_count ~= old_count or lifetime_mult ~= old_mult then
		force_reapply()
	end
end

decal_control.on_enabled = function()
	force_reapply()
end

decal_control.on_disabled = function()
	-- Hook is disabled with the mod; poison the cache so vanilla values re-apply.
	force_reapply()
end

decal_control.refresh_settings()
mod:info("decal_control hooks registered")

return decal_control
