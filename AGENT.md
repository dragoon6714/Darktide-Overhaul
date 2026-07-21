# AGENT.md — Darktide Performance Overhaul

This file is the complete project specification for the **Performance Overhaul** mod for
Warhammer 40,000: Darktide. It is written so that a coding agent with no prior context can
pick up any task, implement it, and verify it. Read this whole file before touching code.

---

## 1. Project overview

**What it is.** A Darktide Mod Framework (DMF) mod that maximizes FPS and frame-time
consistency on machines that already run well (~120 FPS average) by attacking the remaining
frame-time spikes: horde-time VFX/particle load, CPU-side ragdoll/corpse cost, decal
accumulation, audio event spam, screen-space overlay effects, and Lua GC hitches.

**Who it's for.** Players who want to trade specific visual effects for frames — on their
own terms. Competitive/high-refresh players, people chasing frame-time consistency for VRR,
and anyone who finds blood mist or suppression blur distracting.

**Philosophy: nothing forced, everything opt-in and tunable.**
- Every optimization ships **disabled or at a neutral default**. Installing the mod and
  touching nothing must be visually and behaviorally identical to vanilla.
- Every lever is a user-facing toggle or slider in DMF's Mod Options with a tooltip that
  explains the quality tradeoff.
- Disabling a module — or the whole mod — cleanly restores vanilla behavior (DMF disables
  all of a toggleable mod's hooks when the mod is toggled off; our hooks additionally
  self-gate on their module's enable setting).
- We never touch gameplay, networking, or anything another player could observe as a
  difference in *game state*. Visuals and local audio only. See §6 Guardrails.

**Hard constraint.** Mods are Lua-side only. They hook game functions through DMF. They
cannot patch the engine binary, shaders, or renderer internals. Everything here works by
hooking Lua functions that exist in the decompiled source (see §8 Reference checkouts).
If a feature cannot be reached from Lua, we document why (§4 records two such findings)
and do not fake it.

---

## 2. Architecture

### 2.1 Repo layout

```
/AGENT.md                      ← this file
/PerformanceOverhaul/          ← the mod, in Darktide-Mod-Builder layout; copy into game mods/
  PerformanceOverhaul.mod      ← DMF loader stub (new_mod call + file paths)
  scripts/mods/PerformanceOverhaul/
    PerformanceOverhaul.lua              ← entry point: shared state, module loading, dispatch
    PerformanceOverhaul_data.lua         ← mod_data: name/description + ALL option widgets
    PerformanceOverhaul_localization.lua ← ALL localization strings (en at minimum)
    modules/
      vfx_limiter.lua          ← Module 2: particle/VFX budget + category culling
      decal_control.lua        ← Module 3: decal pool caps + lifetime multiplier
      corpse_control.lua       ← Module 4: ragdoll cap + corpse max-age despawn
      audio_limiter.lua        ← Module 5: 3D sound event rate limiter
      screen_effects.lua       ← Module 6: mood overlay filtering + camera shake toggle
      lighting.lua             ← Module 7: exposure/brightness boost ("pseudo-fullbright")
      fov.lua                  ← Module 8: FOV multiplier beyond game limits
      gc_tuning.lua            ← Module 9: Lua GC step/pause tuning
      diagnostics.lua          ← Module 10: counters, /po_status command, HUD registration
      hud/diagnostics_hud_element.lua    ← HUD element class for the overlay
```

### 2.2 Entry point and module pattern

`PerformanceOverhaul.lua`:
1. `local mod = get_mod("PerformanceOverhaul")`
2. Creates the shared diagnostics counter table (`mod.counters`) via `mod:persistent_table`
   so counters survive mod reloads (Ctrl+Shift+R).
3. Loads each module with `mod:io_dofile("PerformanceOverhaul/scripts/mods/PerformanceOverhaul/modules/<name>")`.
4. Implements `mod.on_setting_changed(setting_id)` as a dispatcher: each module registers a
   `refresh_settings` function; the dispatcher calls all of them (settings are read rarely,
   cached in module-local upvalues — never call `mod:get()` in a per-frame path).
5. Implements `mod.update(dt)` as a dispatcher to modules that need per-frame work
   (corpse age scan, GC step, diagnostics window rollover). Modules register an `update`
   function only if needed; disabled modules must cost ~zero per frame (one boolean check).

**Module contract.** Each module file:
- is self-contained: all hooks for one optimization system live in that one file;
- caches its settings in locals, refreshed by its `refresh_settings()`;
- gates every hook body on its own `enabled` boolean first (settings default = off/neutral);
- increments `mod.counters.*` when it spawns/culls/drops something, so the diagnostics
  overlay can prove the lever moves;
- never assumes another module is loaded or enabled.

**Hook registration.** Hooks are registered once at file load using the *string* class-name
form (e.g. `mod:hook("FxSystem", "trigger_vfx", ...)`). DMF resolves string targets against
`_G` and then `_G.CLASS` (see `dmf/scripts/mods/dmf/modules/core/hooks.lua`,
`get_object_reference`), deferring until the class exists — this is the safe way to hook
game classes that load after mods. All game classes we target are registered via
`class("Name")` and reachable through `CLASS.<Name>`.

### 2.3 Settings, localization, keybinds

- All widgets are defined in `PerformanceOverhaul_data.lua` under `options.widgets`,
  organized as one `group` widget per module (see §5 for the widget schema).
- Every `setting_id` doubles as its title localization id; `<setting_id>_description` is
  the tooltip id. Both must exist in `PerformanceOverhaul_localization.lua` (English `en`
  required; other languages optional).
- The diagnostics overlay toggle is a `keybind` widget (`keybind_type = "function_call"`),
  unbound by default per DMF guidance.

---

## 3. Verified engine/game facts an agent must know

These were verified against the decompiled source (§8). Cite the decompiled file path in a
code comment above every hook you write.

- **Classes**: game classes are created with `class("Name")`
  (`scripts/foundation/utilities/class.lua`) and are hookable by string name via DMF.
- **`Managers` global** is readable from mods. Relevant paths:
  - `Managers.state.decal` — DecalManager instance (nil outside gameplay).
  - `Managers.state.blood` — BloodManager instance.
  - `Managers.state.minion_death` — MinionDeathManager; `:minion_ragdoll()` returns the
    MinionRagdoll instance (`scripts/managers/minion/minion_death_manager.lua:257`).
  - `Managers.state.minion_spawn` — **server-side only** (created inside `if is_server` in
    `scripts/game_states/game/gameplay_sub_states/gameplay_init_step_states/gameplay_init_step_managers.lua`).
    Always nil-check; on clients in online play it does not exist.
  - `Managers.time:time("gameplay")` — gameplay clock, use for timestamps (never
    `os.time`/`os.clock` for game logic).
- **Dedicated servers**: online missions run on Fatshark servers. Server-only code paths
  (anything calling `Managers.state.game_session:send_rpc_clients`) do **not** run on a
  modded client in online play; the client instead receives `rpc_*` methods on the same
  systems. Any limiter must therefore hook **both** the local/server-path method *and* the
  corresponding `rpc_*` client receive handler. The `rpc_*` handlers are pure-local (the
  network message was already received; dropping the local spawn affects no one else).
- **`collectgarbage` is exposed** in the game's Lua environment (used by the game itself in
  `scripts/managers/imgui/imgui_lua_memory_snapshot.lua:30`). Still guard with `pcall` on
  first use and disable the GC module if unavailable.
- **`Application.user_setting(category, key)` / `Application.set_user_setting`** read/write
  the user's own game config. Do NOT permanently rewrite the user's vanilla settings —
  scale values in-flight inside hooks instead.
- **Engine C API** (`World.create_particles`, `Blood.spawn_blood_ball`,
  `EngineOptimizedManagers.*`, Wwise internals) is not hookable. Always hook the Lua
  wrapper above it.

---

## 4. Feature spec

Defaults marked **(neutral)** produce vanilla behavior until the user changes them.
"CPU" / "GPU" notes say where the frames come from.

### 4.1 Particle/VFX limiter — `modules/vfx_limiter.lua`

**What it does.** Caps the *rate* of one-shot particle spawns with a per-second budget and
culls by category priority (blood mist → ambient → weapon/muzzle → impacts → other) when
over budget. Also offers unconditional per-category culls. Active-particle count is not
readable from Lua, so the budget is a sliding 1-second spawn window — the correct proxy,
since horde spikes are spawn-rate spikes.

**Verified hook targets** (all fire-and-forget: no return values, no callers consume one):
- `FxSystem.trigger_vfx(self, vfx_name, position, optional_rotation)` —
  `scripts/extension_systems/fx/fx_system.lua:328` (solo/host path).
- `FxSystem.rpc_trigger_vfx(self, channel_id, vfx_id, position, optional_rotation)` —
  `fx_system.lua:530` (online client receive; map `vfx_id` back via `NetworkLookup.vfx`).
- `FxSystem.play_impact_fx(...)` — `fx_system.lua:203`, plus
  `play_surface_impact_fx` (`:235`) and `play_shotshell_surface_impact_fx` (`:275`).
  Their `rpc_*` client receives (`:482`/`:500`/`:516`) **call through these local
  methods**, so hooking the three local methods covers both online and solo — do not
  also hook the rpc twins (double-counting). Impact fx are highest priority — only
  dropped above 150% of budget, never when the target is a player unit
  (`Managers.player:player_by_unit`, `scripts/foundation/managers/player/player_manager.lua:431`).
- `BloodManager.queue_blood_ball(self, position, direction, blood_ball_unit, optional_damage_type)`
  — `scripts/managers/blood/blood_manager.lua:102` (blood mist/balls; already
  client-local, no rpc twin needed).
- **Deliberately NOT hooked**: `FxSystem.start_template_effect` — its return value
  (`global_effect_id`) is consumed by callers to stop the effect later; dropping the start
  would leak nil ids into caller state. Do not hook it.

**Category classification** by name prefix/substring on `vfx_name`:
`blood` (`/blood`, `blood_`), `weapon` (`/weapons/`), `impact` (`/impacts/`, `/impact_`),
`ambient` (`/environment/`, `_ambience`, `/ambient`), else `other`.

**Settings**
| setting_id | widget | range | default |
|---|---|---|---|
| `vfx_enabled` | checkbox | — | `false` **(neutral)** |
| `vfx_budget` | numeric | 25–500 spawns/s | `200` |
| `vfx_cull_blood` | checkbox (always cull blood mist) | — | `false` |
| `vfx_cull_ambient` | checkbox | — | `false` |
| `vfx_cull_weapon` | checkbox | — | `false` |

**Perf impact.** GPU (overdraw from particle fill) + some CPU (particle sim). This is the
main horde-time lever.

### 4.2 Decal manager — `modules/decal_control.lua`

**What it does.** Caps decal pool sizes and scales decal lifetime *on top of* the game's
own settings, without rewriting the user's config. The game already exposes
`max_impact_decals`, `max_blood_decals`, `max_footstep_decals` (5–100) and
`decal_lifetime` (10–60 s) in `performance_settings`
(`scripts/settings/options/render_settings.lua:2152-2217`), and
`DecalManager._check_new_user_settings` (`scripts/managers/decal/decal_manager.lua:143`)
re-reads them **every frame**, calling `init_settings` when they change. We extend this
mechanism rather than reinvent it.

**Verified hook target.**
- `DecalManager.init_settings(self, lifetime, impact_pool_size, blood_pool_size, footstep_pool_size)`
  — `decal_manager.lua:24`. Regular `mod:hook`: multiply `lifetime` by our multiplier,
  `math.min` each pool size against our cap, then call `func` with the adjusted values
  (they flow into `EngineOptimizedManagers.decal_manager_add_setting`).
- **Re-apply trick**: when our settings change mid-session, set
  `Managers.state.decal._lifetime = -1` (nil-checked); the next frame's
  `_check_new_user_settings` sees a mismatch and re-runs `init_settings` through our hook.

**Settings**
| setting_id | widget | range | default |
|---|---|---|---|
| `decal_enabled` | checkbox | — | `false` **(neutral)** |
| `decal_max_count` | numeric (cap per pool) | 0–100 | `100` (no-op until lowered) |
| `decal_lifetime_mult` | numeric | 0.1–1.0, 2 decimals | `1.0` |

**Perf impact.** GPU (decal draw/fill on cluttered surfaces); minor CPU. Lifetime is the
stronger lever for long hordes in one room.

### 4.3 Corpse/ragdoll control — `modules/corpse_control.lua`

**What it does.** (a) Enforces a lower ragdoll cap than the game's setting; (b) despawns
corpses older than a max age, accelerating post-horde cleanup. The game's own cap
(`max_ragdolls`, 3–50, `render_settings.lua:2129-2145`, default 10) is enforced in
`MinionRagdoll.create_ragdoll` (`scripts/managers/minion/minion_ragdoll.lua:139`), which
reads `Application.user_setting("performance_settings", "max_ragdolls")` on every corpse
spawn and evicts oldest-first via `_remove_ragdoll` →
`Managers.state.unit_spawner:mark_for_deletion(unit)`. We extend that pipeline.

**Verified hook targets.**
- `MinionRagdoll.create_ragdoll(self, death_data)` — `minion_ragdoll.lua` (~line 132).
  Regular hook: call `func(self, death_data)` first, then while our cap <
  `self._num_ragdolls`, call `self:_remove_ragdoll(self._ragdolls[1])` (same eviction the
  game uses). Also record `Managers.time:time("gameplay")` per unit for age tracking.
- `MinionRagdoll._remove_ragdoll(self, unit)` — `hook_safe` to clear our age entry.
- Age scan runs in `mod.update(dt)` (throttled to ~2×/s): reach the instance via
  `Managers.state.minion_death:minion_ragdoll()`, despawn units older than max age.

**Settings**
| setting_id | widget | range | default |
|---|---|---|---|
| `corpse_enabled` | checkbox | — | `false` **(neutral)** |
| `corpse_max_ragdolls` | numeric | 3–50 | `50` (no-op until lowered) |
| `corpse_max_age` | numeric, seconds; 0 = vanilla (never force) | 0–60 | `0` **(neutral)** |

**Perf impact.** CPU (physics/anim of settled ragdolls, corpse draw calls). Biggest
frame-time-consistency win right after a horde dies.

**Note.** Corpses are client-visual: online, ragdolls are simulated locally from death
events; despawning them locally does not alter game state for others.

### 4.4 Audio voice limiter — `modules/audio_limiter.lua`

**Finding (honest scope).** True Wwise voice limiting is engine-side and NOT reachable from
Lua — there is no Lua API to enumerate or cap active voices. What IS reachable: the Lua
choke points where 3D one-shot events are *triggered*. So this module is a **3D sound event
rate limiter**, not a voice cap; it drops excess positional one-shots during spam peaks
before they reach Wwise. This partial scope is intentional and documented to the user in
the tooltip.

**Verified hook targets** (no return values; callers verified fire-and-forget):
- `FxSystem.trigger_wwise_event(self, event_name, optional_position, optional_unit, ...)`
  — `fx_system.lua:344` (solo/host path). Only drop when `optional_position` or
  `optional_unit` is present (3D one-shots) — never 2D/UI/music paths.
- `FxSystem.trigger_local_unit_wwise_event(self, event_name, unit, optional_node)` —
  `fx_system.lua:335` (local 3D unit foley; no return value).
- `FxSystem.rpc_trigger_wwise_event(...)` — `fx_system.lua:542` (online client receive).
  Ambisonics events (ambience beds) always pass.
- Never hook dialogue/VO systems (`dialogues/`) — mission-critical audio.

**Settings**
| setting_id | widget | range | default |
|---|---|---|---|
| `audio_enabled` | checkbox | — | `false` **(neutral)** |
| `audio_budget` | numeric | 10–100 events/s | `100` (effectively no-op) |

**Perf impact.** CPU (Wwise voice setup/mixing). Modest; matters most on CPU-bound rigs
during hordes. Sliding 1-second window, same pattern as the VFX limiter.

### 4.5 Screen effect toggles — `modules/screen_effects.lua`

**What it does.** Filters Darktide's "mood" system — the per-player screen-state effects
(suppression, damage/blood-on-screen, corruption, psyker warp) — by category, and gates
camera shake.

**Verified hook targets.**
- Moods: `MoodHandler._update_particles(self, added_moods, removing_moods, removed_moods, moods_data)`
  — `scripts/managers/camera/mood_handler/mood_handler.lua:267`. Regular hook: build a
  filtered **copy** of `added_moods` (never mutate the original — it's shared with
  `_update_sounds` and `_blend_list` in `update_moods`, `mood_handler.lua:66`), dropping
  disabled mood types; pass `removing_moods`/`removed_moods` through untouched so cleanup
  of already-spawned effects always runs. Mood type names come from
  `scripts/settings/camera/mood/mood_settings.lua` (`table.enum` at top of file).
- Camera shake: `CameraManager.add_camera_effect_shake_event(self, event_name, optional_source_unit_data)`
  — `scripts/managers/camera/camera_manager.lua:689` and
  `CameraManager.add_camera_effect_sequence_event(self, event, start_time)` — `:651`.
  Regular hooks; early-return when disabled (mirrors the game's own
  `_camera_shake_enabled` early-out).

**Mood category mapping** (only feedback overlays; ability/stealth state moods are left
alone — hiding your own stealth/ability state is confusing, and they're cheap):
- `suppression`: `suppression_low`, `suppression_high`, `suppression_ongoing`
- `damage`: `damage_taken`, `toughness_absorbed`, `toughness_absorbed_melee`,
  `toughness_broken`, `no_toughness`, `critical_health`, `last_wound`, `knocked_down`,
  `corruption_taken`
- `warp`: `warped`, `warped_low_to_high`, `warped_high_to_critical`, `warped_critical`
- `corruption`: `corruption`, `corruptor_proximity`

**Known limitation (documented, acceptable).** Mood shading-environment blending
(vignette/color grade via `_blend_list`) still applies; we only suppress the particle
overlays, which are the expensive and visually noisy part. Filtering `moods_data` itself
would desync the mood state machine — do not.

**Settings** — `screenfx_enabled` master checkbox (default `false` **(neutral)**), plus
`screenfx_suppression`, `screenfx_damage`, `screenfx_warp`, `screenfx_corruption`
checkboxes ("show this category", default `true`), and `screenfx_camera_shake` checkbox
("allow camera shake", default `true`).

**Perf impact.** GPU (fullscreen particle overdraw exactly when you're already stressed —
suppressed mid-horde). Also a visibility/comfort feature.

### 4.6 Fullbright / lighting simplification — `modules/lighting.lua`

**Finding (honest scope).** True fullbright (flat lighting, lights off) is NOT achievable
from Lua — lighting/shading is engine-side. What IS achievable: injecting exposure
compensation into the shading environment each frame, exactly how the game applies its own
gamma offset. This brightens dark areas dramatically ("pseudo-fullbright" visibility) but
saves little GPU — it is sold to the user as a *visibility* feature, with the tooltip
saying so.

**Verified hook target.**
- `CameraManager.shading_callback(self, world, shading_env, viewport, default_shading_environment_resource)`
  — `scripts/managers/camera/camera_manager.lua` (~line 254; the function that already does
  `ShadingEnvironment.set_scalar(shading_env, "exposure_compensation",
  ShadingEnvironment.scalar(shading_env, "exposure_compensation") + gamma)`).
  Regular hook: call `func`, then add our offset to `exposure_compensation` the same way.

**Settings** — `lighting_enabled` checkbox (default `false` **(neutral)**),
`lighting_exposure_boost` numeric 0.0–3.0 (1 decimal, default `1.0`).

**Perf impact.** ~None (honest: visibility feature). Kept because the target audience
overlaps and it was specced; the tooltip must not promise FPS.

### 4.7 FOV beyond game limits + rendering extras — `modules/fov.lua`

**What it does.** Applies an extra FOV multiplier on top of the game's FOV pipeline,
exceeding the in-game slider's range.

**Verified hook target.**
- `CameraManager._update_camera_properties(self, camera, shadow_cull_camera, camera_nodes, camera_data, viewport_name)`
  — `scripts/managers/camera/camera_manager.lua` (FOV applied at `:935`:
  `Camera.set_vertical_fov(camera, vertical_fov * self._fov_multiplier)`).
  Regular hook: save `camera_data.vertical_fov`, scale it by our multiplier, call `func`,
  **restore the saved value** — `camera_data` is a reused table; leaving it scaled would
  compound every frame.

**Settings** — `fov_enabled` checkbox (default `false` **(neutral)**), `fov_multiplier`
numeric 0.70–1.40 (2 decimals, default `1.00`).

**Perf impact.** Wider FOV *costs* GPU (more on screen); narrower saves. This is a
preference feature; tooltip states the cost direction.

**Finding: map clutter culling is infeasible.** Scatter/prop density
(`lod_scatter_density`, `lod_object_multiplier`) is applied engine-side from
`render_settings`; there is no Lua-side per-unit clutter registry to cull from, and
`Unit.set_visibility` has no category enumeration for cosmetic props. The game's own
options already expose these two knobs; duplicating them adds nothing. **Not implemented —
by design.**

### 4.8 Lua GC tuning — `modules/gc_tuning.lua`

**What it does.** Addresses Lua GC frame hitches from the game's allocation churn. LuaJIT's
incremental collector can be tuned via `collectgarbage("setstepmul", n)` /
`collectgarbage("setpause", n)`, and/or amortized with small manual
`collectgarbage("step", kb)` calls per frame from `mod.update(dt)`.

**Verified availability.** `collectgarbage` exists in the game Lua env (game calls
`collectgarbage("collect")` in `scripts/managers/imgui/imgui_lua_memory_snapshot.lua:30`).
Wrap first use in `pcall`; if it errors, log once via `mod:warning` and disable the module.

**Settings** — `gc_mode` dropdown, default `"vanilla"` **(neutral)**:
- `"vanilla"` — touch nothing.
- `"smooth"` — `setstepmul 400` + `setpause 150`: collect more eagerly in smaller chunks;
  slightly more total GC CPU, fewer/smaller spikes. Restore LuaJIT defaults
  (stepmul 200 / pause 200) when switched back to vanilla or on `on_disabled`.
- `"manual_step"` — additionally run `collectgarbage("step", gc_step_kb)` each update;
  `gc_step_kb` numeric 10–500 KB, default `100`.

**Tooltip must explain the tradeoff:** trading average CPU for consistency; wrong values
can *lower* average FPS. Conservative default is vanilla.

**Perf impact.** CPU frame-time consistency (hitch reduction), not average FPS.

### 4.9 Diagnostics overlay — `modules/diagnostics.lua` + `modules/hud/diagnostics_hud_element.lua`

**What it does.** Optional HUD overlay proving which lever moves the needle: FPS +
frame-time (avg/max over a 60-frame window), Lua memory (`collectgarbage("count")`),
active ragdolls, alive minions (server/solo only), decal pool config, and this mod's own
counters (VFX spawned/culled per second, blood balls culled, audio events dropped, corpses
force-despawned). Also `/po_status` chat command printing the same numbers to chat/log —
this is the **log-based verification path** for agents (§7).

**Verified integration points.**
- HUD: `mod:register_hud_element({class_name, filename, visibility_groups = {"alive"}, use_hud_scale = true})`
  — DMF `dmf/scripts/mods/dmf/modules/gui/custom_hud_elements.lua`. Element class extends
  `"HudElementBase"` with scenegraph + text-widget definitions (see DMF wiki
  `hud-elements.md` example).
- Counters read: `Managers.state.minion_death:minion_ragdoll()._num_ragdolls`;
  `Managers.state.minion_spawn:num_spawned_minions()` (nil-check — server only);
  `Managers.state.decal._lifetime/_impact_pool_size/_blood_pool_size` (nil-check);
  `mod.counters` for our own tallies.
- Keybind widget toggles the overlay setting via `function_call`.

**Settings** — `diag_enabled` checkbox (default `false`), `diag_keybind` keybind (default
unbound), `diag_log_interval` numeric 0–60 s (0 = off, default `0`): when set, prints a
one-line status to the log every N seconds — lets an agent verify limiters numerically
from `console.log` without seeing the screen.

**Perf impact.** Slight cost when visible (text redraw). Off by default.

---

## 5. DMF conventions (verified against DMF source + wiki)

### 5.1 Mod skeleton

`PerformanceOverhaul.mod`:
```lua
return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`Performance Overhaul` encountered an error loading the Darktide Mod Framework.")
		new_mod("PerformanceOverhaul", {
			mod_script       = "PerformanceOverhaul/scripts/mods/PerformanceOverhaul/PerformanceOverhaul",
			mod_data         = "PerformanceOverhaul/scripts/mods/PerformanceOverhaul/PerformanceOverhaul_data",
			mod_localization = "PerformanceOverhaul/scripts/mods/PerformanceOverhaul/PerformanceOverhaul_localization",
		})
	end,
	packages = {},
}
```
Load order: localization → data → script.

### 5.2 Hooks
- `mod:hook(obj, "method", function(func, self, ...) ... return func(self, ...) end)` —
  regular chain hook; NOT protected — an error here **crashes the game**. May skip `func`
  to drop a call.
- `mod:hook_safe(obj, "method", function(self, ...) end)` — runs after the original, in
  protected mode; cannot change behavior. **Prefer whenever return/flow control is not
  needed** (we use it for bookkeeping like `_remove_ragdoll` cleanup).
- `mod:hook_origin` — full replacement, one per function across all mods. **Never use it
  in this project** (compatibility).
- `obj` as string (e.g. `"FxSystem"`) resolves via `_G` then `CLASS` and is deferred until
  the class exists — always use string form for game classes.
- One hook per (mod, function). All hooks auto-disable when the user toggles the mod off.

### 5.3 Options widgets (exact schema)
In `mod_data.options.widgets`. All except `group` need `setting_id` + `default_value`.
Types: `group` (with `sub_widgets`), `checkbox` (boolean), `dropdown`
(`options = {{text = <loc_id>, value = ...}, ...}`), `numeric`
(`range = {min, max}`, optional `decimals_number`, `unit_text`), `keybind`
(`default_value = {}`, `keybind_trigger = "pressed"`, `keybind_type = "function_call"`,
`function_name = "<name of function on mod object>"`), `text_input`.
Omit `title`/`tooltip` fields: DMF auto-localizes from `setting_id` and
`setting_id .. "_description"`.

### 5.4 Settings & lifecycle
- `mod:get(setting_id)` / `mod:set(setting_id, value, notify)`; widget changes fire
  `mod.on_setting_changed(setting_id)`. Cache values in locals; don't call `mod:get` per
  frame.
- Lifecycle callbacks used here: `update(dt)`, `on_setting_changed`, `on_enabled`,
  `on_disabled` (restore GC defaults!), `on_game_state_changed(status, state_name)`
  (reset per-mission counters on `"enter", "StateGameplay"`), `on_all_mods_loaded`.
- Settings persist in `%AppData%\Fatshark\Darktide\user_settings.config`.

### 5.5 Localization
`<name>_localization.lua` returns `{ [text_id] = { en = "...", ["zh-cn"] = "...", ... } }`.
Every widget needs `<setting_id>` and `<setting_id>_description` entries. `mod:localize`
falls back to `en`.

### 5.6 Logging
`mod:info/echo/warning/error/notify`, `mod:dump`/`mod:dtf`. Console output lands in the
game log (`%AppData%\Fatshark\Darktide\console.log`); DMF options control chat/log
routing. Use `mod:info` for verification lines (always logged), never spam per-frame.

---

## 6. Guardrails — what agents must NEVER do

1. **No network-touching hooks.** Never hook, wrap, or suppress anything that sends RPCs
   (`send_rpc_clients`, `RPC.*`, `Managers.state.game_session` senders), the chat/network
   managers, or DMF's network module. Hooking `rpc_*` *receive* handlers to skip a local
   visual spawn is allowed — the data already arrived; nothing is sent or altered.
2. **No gameplay-affecting changes.** Nothing that alters damage, hit registration, spawns,
   AI decisions, pacing, loot, XP, currencies, cosmetic unlocks, or player movement. Do not
   hook anything under `scripts/managers/backend`, damage/attack pipelines, buff templates'
   logic (reading names is fine), or spawner *logic* (reading counters is fine).
3. **Visual/audio/local-only.** Every hook must be justifiable as "another player's game
   is bit-identical whether or not I run this mod."
4. **Never remove or disable other mods' hooks**; never `hook_origin`; never mutate DMF
   internals or another mod's persistent tables.
5. **Never permanently rewrite the user's vanilla settings** (`Application.set_user_setting`)
   — scale values in-flight inside hooks so uninstalling the mod restores everything.
6. **Regular `mod:hook` bodies must be crash-proof**: no unguarded indexing of nil-able
   managers, no allocation-heavy per-frame work, always `return func(...)` on the
   fall-through path. When in doubt, use `hook_safe`.
7. **Neutral defaults** (§1). A fresh install must change nothing until the user opts in.
8. **Stay honest.** If a hook target doesn't exist in the decompiled source, the feature
   doesn't ship; record the finding in §4 instead of faking it.

---

## 7. Verification loop

Agents cannot see the screen; verification is file/log-based.

**A. Static (always available, incl. on this repo's dev machine):**
1. Syntax-check every Lua file: `luajit -bl <file> > /dev/null` (exit 0 = parses).
   LuaJIT is Lua 5.1 — no `goto`, no integer division, use 5.1 idioms.
2. Grep discipline: every `mod:hook*` call must be preceded by a comment citing the
   decompiled-source path + line of the target (drift check against
   `../darktide-refs/Darktide-Source-Code`).
3. Widget/localization cross-check: every `setting_id` in `_data.lua` has `<id>` and
   `<id>_description` keys in `_localization.lua` (script it with grep/awk).

**B. In-game (requires a Windows machine with Darktide + DML + DMF installed):**
1. Copy `PerformanceOverhaul/` into `<game>/mods/` (or use Darktide-Mod-Builder:
   `dmb.exe build PerformanceOverhaul` from a DMB workspace whose `mods/` contains it).
2. Add `PerformanceOverhaul` on its own line in `<game>/mods/mod_load_order.txt`.
3. Launch the game (mods patched in via `toggle_darktide_mods.bat`). In-session reloads:
   Ctrl+Shift+R with DMF Developer Mode on.
4. Check `%AppData%\Fatshark\Darktide\console.log` for:
   - no `[MOD ERROR]`/Lua error mentioning `PerformanceOverhaul`;
   - our startup line `[PerformanceOverhaul] loaded (N modules)` (`mod:info` at end of
     entry file);
   - each module logs `<module> hooks registered` once at load.
5. Confirm settings appear: open Mod Options → Performance Overhaul (or verify
   `user_settings.config` gains `PerformanceOverhaul` keys after toggling one widget).
6. Confirm hooks fire and levers move: enable the module + set `diag_log_interval = 10`;
   play Psykhanium (offline, safe) or the hub; the periodic status line shows non-zero
   `spawned/culled/dropped` counters when the corresponding limiter is enabled and load is
   generated. A limiter passes when its `culled`/`dropped` counter rises while its cap is
   set aggressively and stays 0 at neutral defaults.

**Definition of "verified" for a commit message:** static checks passed, and (if a game
machine is available) the console.log evidence above; otherwise say exactly which half ran.

---

## 8. Reference checkouts (already cloned on this machine)

Located at `/Users/smoghal/Documents/GitHub/darktide-refs/`:
- `Darktide-Source-Code/` — decompiled game Lua (Aussiemon). **Verify every hook here.**
- `Darktide-Mod-Framework/` — DMF source (`dmf/scripts/mods/dmf/modules/...`).
- `Darktide-Mod-Builder/` — scaffolding tool; template in `.template-dmf/`.
- `dmf-wiki/` — DMF documentation (source of https://dmf-docs.darkti.de).

---

## 9. Task breakdown (one agent session per task)

Each task: implement → static-verify (§7A) → update AGENT.md if reality diverged → commit
(`<module>: <summary> — <verification result>`).

1. **Scaffold.** Create `PerformanceOverhaul/` exactly as §2.1 with a working entry point
   (module loader + dispatchers, empty module list), minimal `_data.lua` (name,
   description, is_togglable), `_localization.lua` with `mod_name`/`mod_description`.
   *Done when:* all files pass `luajit -bl`; `.mod` paths match §5.1.
2. **VFX limiter** per §4.1. *Done when:* all hooks registered with source citations;
   sliding-window budget implemented allocation-free (ring buffer of timestamps);
   counters `vfx_spawned`, `vfx_culled`, `blood_balls_culled` wired; statics pass.
3. **Decal control** per §4.2, including the `_lifetime = -1` re-apply on setting change.
   *Done when:* hook cites `decal_manager.lua:24`; neutral defaults are no-ops; statics pass.
4. **Corpse control** per §4.3. *Done when:* cap enforcement reuses `_remove_ragdoll`;
   age table cleaned on removal (no unit-reference leak); update scan throttled; counter
   `corpses_despawned` wired; statics pass.
5. **Audio limiter** per §4.4. *Done when:* only positional events dropped; 2D/dialogue
   untouched; counter `audio_dropped` wired; statics pass.
6. **Screen effects** per §4.5. *Done when:* filtered copy (originals unmutated), cleanup
   paths untouched, all four category sets exactly as specced; shake gates both event
   entry points; statics pass.
7. **Lighting** per §4.6. *Done when:* offset applied post-`func` in `shading_callback`;
   zero offset at defaults; statics pass.
8. **FOV** per §4.7. *Done when:* `camera_data.vertical_fov` saved/restored around `func`
   (no compounding); statics pass.
9. **GC tuning** per §4.8. *Done when:* `pcall`-guarded; defaults restored on mode change
   AND `on_disabled`; statics pass.
10. **Diagnostics overlay** per §4.9. *Done when:* HUD element registers; `/po_status` and
    `diag_log_interval` print every counter above; keybind toggles; statics pass.

After task 10: full localization/widget cross-check (§7A.3), a final in-game verification
pass (§7B) on a game-equipped machine, and a README for end users.
