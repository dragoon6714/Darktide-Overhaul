local mod = get_mod("PerformanceOverhaul")

return {
	name = mod:localize("mod_name"),
	description = mod:localize("mod_description"),
	is_togglable = true,
	options = {
		widgets = {
			{
				setting_id = "group_vfx",
				type = "group",
				sub_widgets = {
					{
						setting_id = "vfx_enabled",
						type = "checkbox",
						default_value = false,
					},
					{
						setting_id = "vfx_budget",
						type = "numeric",
						default_value = 200,
						range = { 25, 500 },
					},
					{
						setting_id = "vfx_cull_blood",
						type = "checkbox",
						default_value = false,
					},
					{
						setting_id = "vfx_cull_ambient",
						type = "checkbox",
						default_value = false,
					},
					{
						setting_id = "vfx_cull_weapon",
						type = "checkbox",
						default_value = false,
					},
				},
			},
			{
				setting_id = "group_decal",
				type = "group",
				sub_widgets = {
					{
						setting_id = "decal_enabled",
						type = "checkbox",
						default_value = false,
					},
					{
						setting_id = "decal_max_count",
						type = "numeric",
						default_value = 100,
						range = { 0, 100 },
					},
					{
						setting_id = "decal_lifetime_mult",
						type = "numeric",
						default_value = 1.0,
						range = { 0.1, 1.0 },
						decimals_number = 2,
					},
				},
			},
			{
				setting_id = "group_corpse",
				type = "group",
				sub_widgets = {
					{
						setting_id = "corpse_enabled",
						type = "checkbox",
						default_value = false,
					},
					{
						setting_id = "corpse_max_ragdolls",
						type = "numeric",
						default_value = 50,
						range = { 3, 50 },
					},
					{
						setting_id = "corpse_max_age",
						type = "numeric",
						default_value = 0,
						range = { 0, 60 },
					},
					{
						setting_id = "corpse_deletion_mode",
						type = "dropdown",
						default_value = "vanilla",
						options = {
							{ text = "corpse_deletion_vanilla", value = "vanilla" },
							{ text = "corpse_deletion_fast", value = "fast" },
							{ text = "corpse_deletion_instant", value = "instant" },
						},
					},
				},
			},
			{
				setting_id = "group_anim",
				type = "group",
				sub_widgets = {
					{
						setting_id = "anim_lod_distance",
						type = "numeric",
						default_value = 0,
						range = { 0, 30 },
					},
				},
			},
			{
				setting_id = "group_map",
				type = "group",
				sub_widgets = {
					{
						setting_id = "map_reducer_mode",
						type = "dropdown",
						default_value = "off",
						options = {
							{ text = "map_reducer_off", value = "off" },
							{ text = "map_reducer_conservative", value = "conservative" },
							{ text = "map_reducer_aggressive", value = "aggressive" },
						},
					},
				},
			},
			{
				setting_id = "group_audio",
				type = "group",
				sub_widgets = {
					{
						setting_id = "audio_enabled",
						type = "checkbox",
						default_value = false,
					},
					{
						setting_id = "audio_budget",
						type = "numeric",
						default_value = 100,
						range = { 10, 100 },
					},
				},
			},
			{
				setting_id = "group_screenfx",
				type = "group",
				sub_widgets = {
					{
						setting_id = "screenfx_enabled",
						type = "checkbox",
						default_value = false,
					},
					{
						setting_id = "screenfx_suppression",
						type = "checkbox",
						default_value = true,
					},
					{
						setting_id = "screenfx_damage",
						type = "checkbox",
						default_value = true,
					},
					{
						setting_id = "screenfx_warp",
						type = "checkbox",
						default_value = true,
					},
					{
						setting_id = "screenfx_corruption",
						type = "checkbox",
						default_value = true,
					},
					{
						setting_id = "screenfx_camera_shake",
						type = "checkbox",
						default_value = true,
					},
				},
			},
			{
				setting_id = "group_lighting",
				type = "group",
				sub_widgets = {
					{
						setting_id = "lighting_enabled",
						type = "checkbox",
						default_value = false,
					},
					{
						setting_id = "lighting_exposure_boost",
						type = "numeric",
						default_value = 1.0,
						range = { 0.0, 3.0 },
						decimals_number = 1,
					},
				},
			},
			{
				setting_id = "group_fov",
				type = "group",
				sub_widgets = {
					{
						setting_id = "fov_enabled",
						type = "checkbox",
						default_value = false,
					},
					{
						setting_id = "fov_multiplier",
						type = "numeric",
						default_value = 1.0,
						range = { 0.7, 1.4 },
						decimals_number = 2,
					},
				},
			},
			{
				setting_id = "group_gc",
				type = "group",
				sub_widgets = {
					{
						setting_id = "gc_mode",
						type = "dropdown",
						default_value = "vanilla",
						options = {
							{ text = "gc_mode_vanilla", value = "vanilla" },
							{ text = "gc_mode_smooth", value = "smooth" },
							{ text = "gc_mode_manual_step", value = "manual_step" },
						},
					},
					{
						setting_id = "gc_step_kb",
						type = "numeric",
						default_value = 100,
						range = { 10, 500 },
					},
				},
			},
			{
				setting_id = "group_diag",
				type = "group",
				sub_widgets = {
					{
						setting_id = "diag_enabled",
						type = "checkbox",
						default_value = false,
					},
					{
						setting_id = "diag_keybind",
						type = "keybind",
						default_value = {},
						keybind_trigger = "pressed",
						keybind_type = "function_call",
						function_name = "po_toggle_diagnostics",
					},
					{
						setting_id = "diag_log_interval",
						type = "numeric",
						default_value = 0,
						range = { 0, 60 },
					},
				},
			},
		},
	},
}
