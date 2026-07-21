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
		},
	},
}
