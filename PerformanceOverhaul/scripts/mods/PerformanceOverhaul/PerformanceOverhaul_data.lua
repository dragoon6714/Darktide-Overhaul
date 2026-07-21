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
		},
	},
}
