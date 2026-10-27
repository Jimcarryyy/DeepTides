# Known Issues & QA Tracker

## Active Bugs
*None. 0 active bugs in current build.*

## Resolved in Milestone B
- [x] **Infinite Slash Loop:** Fixed animation asset loop flags by forcing `track.Looped = false` on attack tracks.
- [x] **Tool Unequipped Click Blocking:** Resolved `gameProcessed` blocking mouse clicks by hooking `Tool.Activated` directly.
- [x] **Underwater Velocity Damping:** Replaced instant velocity impulses with short `LinearVelocity` constraints to overcome Terrain Water drag during dashes.
- [x] **Surface BGM Leakage:** Silenced and paused surface music underwater, restoring smoothly on resurfacing.
- [x] **Resurface Sound Doubling:** Removed redundant custom resurface splash audio to prevent clashing with native Roblox character sounds.
- [x] **Missing Harpoon Range:** Updated `CreatureServer.server.luau` to allow 65-stud ranged validation for Tier 3 Harpoon.
- [x] **Harpoon Snapping & Auto-Aim:** Replaced rigid body-locking with smooth 0.35s camera glide, 0.22s hydrodynamic swivel, and free natural swimming.
- [x] **Aimbot Cone Feel:** Replaced 140-degree angle checks with true line-of-sight ray intersection.
- [x] **Instant Creature Despawn:** Replaced instant deletion with a 2.2s belly-up sinking fade-out sequence.
- [x] **Redundant Kill Toast Chime:** Silenced toast notification audio on creature defeat toasts to prevent clashing with 3D death cries.

## Production QA Checklist for Milestone C
- [ ] Live Robux Product IDs integration (Game Passes & Developer Products).
- [ ] Emergency Oxygen prompt popup timing (< 2 seconds at < 15% oxygen).
- [ ] Revive Token prompt popup timing (< 2 seconds after PvP death, 30s expiry).
- [ ] 50,000 Pearl Prestige system verification across Ranks 1–10.
- [ ] Mobile touch layout margins and thumbstick clearance.
- [ ] Console Gamepad navigation across shop and sell modals.
- [ ] Server stress test (20–30 players diving and looting simultaneously).