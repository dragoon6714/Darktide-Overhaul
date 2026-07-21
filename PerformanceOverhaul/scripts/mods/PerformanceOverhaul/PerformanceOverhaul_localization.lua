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

	-- Screen effects
	group_screenfx = {
		en = "Screen Effects",
	},
	group_screenfx_description = {
		en = "Per-category toggles for fullscreen overlay effects and camera shake. "
			.. "Unchecking a category hides its overlay particles; the subtle color/vignette "
			.. "part of these effects still shows.",
	},
	screenfx_enabled = {
		en = "Enable screen effect filtering",
	},
	screenfx_enabled_description = {
		en = "Master switch. Off = all screen effects and camera shake behave as vanilla.",
	},
	screenfx_suppression = {
		en = "Show suppression effects",
	},
	screenfx_suppression_description = {
		en = "Fullscreen blur/distortion when suppressed by gunfire. Unchecking improves "
			.. "visibility and saves GPU exactly during heavy ranged fights — but you lose "
			.. "the visual cue that you are suppressed.",
	},
	screenfx_damage = {
		en = "Show damage / low-health effects",
	},
	screenfx_damage_description = {
		en = "Blood-on-screen and warning overlays when hit, out of toughness, on last wound "
			.. "or knocked down. Unchecking removes distracting overlays but also weakens "
			.. "feedback about how much trouble you are in.",
	},
	screenfx_warp = {
		en = "Show psyker warp/peril effects",
	},
	screenfx_warp_description = {
		en = "Warp overlay effects as peril rises (your own character). Unchecking clears the "
			.. "screen at high peril; watch the peril meter instead so you do not explode.",
	},
	screenfx_corruption = {
		en = "Show corruption ambience effects",
	},
	screenfx_corruption_description = {
		en = "Corruption zone / daemonic proximity screen distortion. Unchecking removes an "
			.. "atmospheric (and GPU-costly) overlay; corrupted areas look more ordinary.",
	},
	screenfx_camera_shake = {
		en = "Allow camera shake",
	},
	screenfx_camera_shake_description = {
		en = "Unchecking blocks explosion/impact camera shake events for a steadier image. "
			.. "No performance cost either way; purely comfort/visibility.",
	},

	-- Lighting
	group_lighting = {
		en = "Brightness Boost",
	},
	group_lighting_description = {
		en = "Adds exposure on top of the game's lighting for visibility in dark areas. "
			.. "Note: this does NOT improve FPS — lighting cost is engine-side and cannot be "
			.. "reduced by mods.",
	},
	lighting_enabled = {
		en = "Enable brightness boost",
	},
	lighting_enabled_description = {
		en = "Master switch. Off = vanilla exposure. This is a visibility feature, not a "
			.. "performance one; it washes out the game's mood lighting when pushed high.",
	},
	lighting_exposure_boost = {
		en = "Extra exposure",
	},
	lighting_exposure_boost_description = {
		en = "How many stops of exposure to add (applied like the in-game gamma setting). "
			.. "1.0 lifts shadows noticeably; 3.0 approaches flat/fullbright and looks washed "
			.. "out. Zero performance impact either way.",
	},

	-- FOV
	group_fov = {
		en = "Field of View",
	},
	group_fov_description = {
		en = "Extra FOV multiplier applied on top of the in-game FOV slider, allowing values "
			.. "beyond the stock range.",
	},
	fov_enabled = {
		en = "Enable FOV multiplier",
	},
	fov_enabled_description = {
		en = "Master switch. Off = the in-game FOV setting applies unchanged.",
	},
	fov_multiplier = {
		en = "FOV multiplier",
	},
	fov_multiplier_description = {
		en = "Multiplies your effective FOV (1.00 = vanilla). Above 1.0 shows more of the "
			.. "battlefield but COSTS GPU (more on screen) and distorts edges; below 1.0 "
			.. "zooms in slightly and saves GPU.",
	},

	-- GC tuning
	group_gc = {
		en = "Lua GC Tuning",
	},
	group_gc_description = {
		en = "Tunes the game's Lua garbage collector to trade a little average CPU for fewer "
			.. "frame-time hitches. Advanced — leave on Vanilla unless you see periodic "
			.. "micro-stutter.",
	},
	gc_mode = {
		en = "GC mode",
	},
	gc_mode_description = {
		en = "Vanilla = untouched. Smooth = collect more eagerly in smaller chunks (slightly "
			.. "more total GC CPU, smaller spikes). Manual step additionally runs a small "
			.. "bounded collection step every frame. Wrong tuning can LOWER average FPS; "
			.. "verify with the diagnostics overlay.",
	},
	gc_mode_vanilla = {
		en = "Vanilla",
	},
	gc_mode_smooth = {
		en = "Smooth (eager increments)",
	},
	gc_mode_manual_step = {
		en = "Manual step (eager + per-frame step)",
	},
	gc_step_kb = {
		en = "Manual step size (KB)",
	},
	gc_step_kb_description = {
		en = "Only used in Manual step mode: how much garbage to collect per frame. Larger "
			.. "steps clean up faster but cost more per frame; 100 KB is a safe start.",
	},
}
