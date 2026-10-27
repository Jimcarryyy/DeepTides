# Current Task: Phase 2 Milestone B — UI/UX, VFX & Audio Polish ($264 AUD)

## Active Step: Step 4 — Cross-Platform QA & Final Polish (~85% Milestone B Complete)
- [x] Baseline Lighting & Terrain diagnostics confirmed.
- [x] Client-side dynamic underwater lighting controller implemented (`UnderwaterVFXController.client.luau`).
- [x] Zone 1–5 atmosphere & fog lerp engine with high visibility tuning in Zones 3–5.
- [x] Character-bound swimming bubble trail (`BubblesParticle`) and water entry splash (`WaterSplash`).
- [x] Camera silt and colored ember particles removed per visual standard.
- [x] Complete Sound Design Polish:
  - [x] 5-Zone custom ElevenLabs ambient loops with boosted volume (1.45–1.70).
  - [x] Surface BGM isolation (zero audio leakage underwater).
  - [x] Continuous underwater drone and swimming bubbles.
  - [x] Plunge water splash sound (redundant resurface audio removed).
  - [x] 5 Unique 3D creature defeat sounds in `CreatureServer.server.luau`.
  - [x] `CreatureAttackImpact` and `PvPWeaponHit` spatial audio.
  - [x] `ZoneSwitcher` audio bound to depth transition toast notifications.
  - [x] Silenced toast audio on creature kill notifications.
- [x] Combat & Weapon System Overhaul:
  - [x] True R6 avatar standardization.
  - [x] Permanent `Tool.Grip` alignment across all 5 diving tools.
  - [x] Tier-based attack audio (`Knife&Axe`, `Spear&Trident`, `Harpoon`, `MonsterHitImpact`).
  - [x] 2-Hit melee combo cadence (`Slash1` ➔ `Slash2` ➔ 1.35s recovery).
  - [x] Harpoon 3D spear projectile, impale sticking effect, 85 studs/s hydrodynamic speed, and 1.25s reload cooldown.
  - [x] Automatic over-the-shoulder aim mode with `Alt` toggle, free natural swimming, and custom crosshair/lock/hitmarker UI.
  - [x] Server-side true ray-line line-of-sight validation (65 studs ranged / 16 studs melee).
  - [x] Natural 2.2s belly-up sinking creature death sequence.
- [ ] User final visual polish pass on UI screens (Gear Shop, Sell Stall, HUD).
- [ ] Mobile touch layout margins and thumbstick clearance verification.
- [ ] Console Gamepad navigation check.
- [ ] Package build for client review and Wise payout release ($264 AUD).

## Next Task: Phase 2 Milestone C — Live Monetization & Launch ($198 AUD)
- Live Robux Product IDs integration (Game Passes & Developer Products).
- Auto-prompt verification: Emergency Oxygen (< 15%) & Revive Token (PvP death).
- 50,000 Pearl Prestige system verification.
- 20–30 player server stress test and bug sweep.
- Handover and public launch preparation.