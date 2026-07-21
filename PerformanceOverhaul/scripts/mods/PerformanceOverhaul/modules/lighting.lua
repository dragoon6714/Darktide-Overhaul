local mod = get_mod("PerformanceOverhaul")

-- Lighting / pseudo-fullbright (AGENT.md §4.6).
-- Honest scope: true fullbright (flat lighting) is engine-side and unreachable from Lua.
-- We inject extra exposure compensation into the shading environment each frame, exactly
-- like the game's own gamma offset (camera_manager.lua:313). This is a VISIBILITY
-- feature: it brightens dark areas but saves essentially no GPU.

local enabled = false
local exposure_boost = 1.0

-- Target verified: scripts/managers/camera/camera_manager.lua:254
-- CameraManager.shading_callback(self, world, shading_env, viewport,
-- default_shading_environment_resource) — engine-invoked per viewport before the shading
-- environment is applied; vanilla adds the user's gamma to "exposure_compensation" here.
mod:hook("CameraManager", "shading_callback", function(func, self, world, shading_env, viewport, default_shading_environment_resource)
	func(self, world, shading_env, viewport, default_shading_environment_resource)

	-- Mirror the function's own world gate; skip UI/other worlds.
	if enabled and exposure_boost ~= 0 and self._world == world then
		ShadingEnvironment.set_scalar(shading_env, "exposure_compensation",
			ShadingEnvironment.scalar(shading_env, "exposure_compensation") + exposure_boost)
	end
end)

local lighting = {
	name = "lighting",
}

lighting.refresh_settings = function()
	enabled = mod:get("lighting_enabled") or false
	exposure_boost = mod:get("lighting_exposure_boost") or 1.0
end

lighting.refresh_settings()
mod:info("lighting hooks registered")

return lighting
