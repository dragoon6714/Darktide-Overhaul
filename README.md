# Performance Overhaul (Darktide mod)

Opt-in performance tuning for Warhammer 40,000: Darktide, built on the
[Darktide Mod Framework](https://dmf-docs.darkti.de). Aimed at machines that already run
well and want to squeeze out the remaining frame-time spikes — horde-time particles,
ragdoll pileups, decal accumulation, audio spam and Lua GC hitches.

**Nothing is forced.** Every lever is off or neutral by default; installing the mod
changes nothing until you opt in through Mod Options. Everything is local-visual/audio
only — no gameplay, balance, or network behavior is touched, in line with Fatshark's
mod policy.

## Features (each with its own toggle + sliders in Mod Options)

| Module | What it does | Frames from |
|---|---|---|
| Particle/VFX Limiter | Per-second particle budget; culls blood mist → ambient → weapon smoke → impacts, in that order | GPU + CPU |
| Decal Manager | Caps blood/impact/footstep decal counts and shortens decal lifetime on top of your game settings | GPU |
| Corpse/Ragdoll Control | Lower simultaneous-corpse cap + optional max corpse age for fast post-horde cleanup | CPU |
| Audio Event Limiter | Caps 3D positional one-shot sounds per second (music/UI/dialogue never touched) | CPU |
| Screen Effects | Per-category toggles: suppression blur, damage/blood-on-screen, psyker warp, corruption overlays, camera shake | GPU / comfort |
| Brightness Boost | Extra exposure for dark areas (visibility feature — saves no FPS, and says so) | — |
| Field of View | FOV multiplier beyond the stock slider range | preference |
| Lua GC Tuning | Garbage-collector step/pause tuning to trade a little average CPU for fewer hitches | CPU consistency |
| Diagnostics Overlay | FPS/frametime + live counters (particles culled, sounds dropped, corpses despawned…) with keybind and `/po_status` command | — |

## Installation

1. Install the [Darktide Mod Loader](https://www.nexusmods.com/warhammer40kdarktide/mods/19)
   and [DMF](https://www.nexusmods.com/warhammer40kdarktide/mods/8) per the
   [official guide](https://dmf-docs.darkti.de/#/installing-mods).
2. Copy the `PerformanceOverhaul` folder from this repo into `<game>/mods/`.
3. Add `PerformanceOverhaul` on its own line in `<game>/mods/mod_load_order.txt`.
4. In-game: Esc → Options → Mod Options → Performance Overhaul.

## Verifying it does something

Enable the Diagnostics Overlay (or type `/po_status` in chat). Set a limiter
aggressively, fight a horde in the Psykhanium, and watch its `culled`/`dropped` counter
climb while frame times steady. At default settings all counters stay at zero — that's
the point.

## Development

See [AGENT.md](AGENT.md) for the full specification: architecture, every hook target
(verified against the decompiled game source with file/line citations), DMF conventions,
guardrails, and the per-module verification loop.
