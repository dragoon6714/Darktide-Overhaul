return {
	mod_name = {
		en = "Performance Overhaul",
	},
	mod_description = {
		en = "Opt-in performance tuning: VFX/particle budgets, decal caps, corpse cleanup, "
			.. "audio event limiting, screen effect toggles, GC tuning and a diagnostics overlay. "
			.. "Every lever is off or neutral by default — vanilla until you opt in.",
	},

	-- VFX limiter
	group_vfx = {
		en = "Particle / VFX Limiter",
	},
	group_vfx_description = {
		en = "Caps how many one-shot particle effects may spawn per second. When over budget, "
			.. "low-priority effects (blood mist, ambient) are culled first; impact effects last.",
	},
	vfx_enabled = {
		en = "Enable VFX limiter",
	},
	vfx_enabled_description = {
		en = "Master switch for the particle budget. Off = vanilla particle behavior.",
	},
	vfx_budget = {
		en = "VFX budget (spawns per second)",
	},
	vfx_budget_description = {
		en = "Maximum one-shot particle spawns per second before culling kicks in. Lower = more "
			.. "FPS during hordes, fewer effects on screen. 200 is barely noticeable; 50-100 is "
			.. "aggressive. GPU-side savings mostly.",
	},
	vfx_cull_blood = {
		en = "Always cull blood mist",
	},
	vfx_cull_blood_description = {
		en = "Unconditionally removes blood mist puffs and flying blood blobs (also reduces the "
			.. "blood decals they leave). Biggest single horde-time particle saving; gore fans "
			.. "will miss it.",
	},
	vfx_cull_ambient = {
		en = "Always cull ambient VFX",
	},
	vfx_cull_ambient_description = {
		en = "Unconditionally removes ambient/environmental one-shot effects (steam, dust, "
			.. "mood particles). Small constant saving; slightly flatter-looking levels.",
	},
	vfx_cull_weapon = {
		en = "Always cull weapon smoke/muzzle VFX",
	},
	vfx_cull_weapon_description = {
		en = "Unconditionally removes muzzle smoke and weapon one-shot effects from all "
			.. "characters. Saves GPU in ranged fights; reduces visual feedback of gunfire.",
	},
}
