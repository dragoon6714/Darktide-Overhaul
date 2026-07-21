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

	-- Decal control
	group_decal = {
		en = "Decal Manager",
	},
	group_decal_description = {
		en = "Caps how many blood/impact/footstep decals can exist and how long they live, "
			.. "on top of your normal graphics settings.",
	},
	decal_enabled = {
		en = "Enable decal limits",
	},
	decal_enabled_description = {
		en = "Master switch. Off = the game's own decal settings apply unchanged.",
	},
	decal_max_count = {
		en = "Max decals per type",
	},
	decal_max_count_description = {
		en = "Hard cap on each decal pool (blood, impacts, footsteps), applied on top of the "
			.. "in-game setting — whichever is lower wins. Fewer decals = less GPU fill on "
			.. "gore-covered floors; scenes look cleaner/less battle-worn.",
	},
	decal_lifetime_mult = {
		en = "Decal lifetime multiplier",
	},
	decal_lifetime_mult_description = {
		en = "Scales how long decals stay before fading (1.00 = vanilla, 0.5 = half as long). "
			.. "Shorter lifetime keeps long fights in one room from accumulating painted "
			.. "surfaces; blood evidence of the battle disappears sooner.",
	},

	-- Corpse control
	group_corpse = {
		en = "Corpse / Ragdoll Control",
	},
	group_corpse_description = {
		en = "Limits how many dead bodies stay around and for how long. Local-visual only; "
			.. "other players see their own settings.",
	},
	corpse_enabled = {
		en = "Enable corpse limits",
	},
	corpse_enabled_description = {
		en = "Master switch. Off = the game's own Max Ragdolls setting applies unchanged.",
	},
	corpse_max_ragdolls = {
		en = "Max simultaneous corpses",
	},
	corpse_max_ragdolls_description = {
		en = "Caps ragdolls on top of the in-game Max Ragdolls setting — whichever is lower "
			.. "wins (oldest bodies vanish first). Big CPU/frame-time win right after hordes; "
			.. "battlefields look emptier.",
	},
	corpse_max_age = {
		en = "Corpse lifetime (seconds, 0 = vanilla)",
	},
	corpse_max_age_description = {
		en = "Force-despawns corpses older than this many seconds. 0 leaves despawning to the "
			.. "game. 10-20s clears horde aftermath quickly; bodies visibly disappear sooner.",
	},

	-- Audio limiter
	group_audio = {
		en = "Audio Event Limiter",
	},
	group_audio_description = {
		en = "Rate-limits 3D positional sound effects during spam peaks. Note: this limits how "
			.. "many sound events *start* per second (a Lua-side limit); the audio engine's own "
			.. "internal voice management is not reachable by mods.",
	},
	audio_enabled = {
		en = "Enable audio event limiter",
	},
	audio_enabled_description = {
		en = "Master switch. Off = all sound events fire as vanilla. Music, UI sounds, "
			.. "dialogue and ambience beds are never limited.",
	},
	audio_budget = {
		en = "3D sound events per second",
	},
	audio_budget_description = {
		en = "Maximum positional one-shot sounds per second; excess is silently dropped. "
			.. "100 = effectively off. 30-60 saves CPU in dense hordes; some overlapping "
			.. "hit/impact sounds will be missing.",
	},
}
