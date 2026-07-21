local mod = get_mod("PerformanceOverhaul")

-- FOV beyond game limits (AGENT.md §4.7).
-- Applies an extra multiplier on top of the game's FOV pipeline (in-game slider +
-- gameplay fov multiplier), letting users go beyond the stock range.
-- Map clutter culling was researched and is NOT feasible from Lua (see AGENT.md §4.7).

local enabled = false
local multiplier = 1.0

-- Target verified: scripts/managers/camera/camera_manager.lua
-- CameraManager._update_camera_properties(self, camera, shadow_cull_camera, camera_nodes,
-- camera_data, viewport_name); FOV is applied at :935 as
-- Camera.set_vertical_fov(camera, vertical_fov * self._fov_multiplier).
-- camera_data is a REUSED table: scale before func, restore after, or the value
-- compounds every frame.
mod:hook("CameraManager", "_update_camera_properties", function(func, self, camera, shadow_cull_camera, camera_nodes, camera_data, viewport_name)
	local original_fov = camera_data and camera_data.vertical_fov

	if enabled and original_fov and multiplier ~= 1.0 then
		camera_data.vertical_fov = original_fov * multiplier

		func(self, camera, shadow_cull_camera, camera_nodes, camera_data, viewport_name)

		camera_data.vertical_fov = original_fov

		return
	end

	return func(self, camera, shadow_cull_camera, camera_nodes, camera_data, viewport_name)
end)

local fov = {
	name = "fov",
}

fov.refresh_settings = function()
	enabled = mod:get("fov_enabled") or false
	multiplier = mod:get("fov_multiplier") or 1.0
end

fov.refresh_settings()
mod:info("fov hooks registered")

return fov
