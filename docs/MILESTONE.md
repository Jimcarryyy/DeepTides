# Milestones & Delivery Tracker

| Milestone | Deliverables | Timeline | Budget (AUD) | Codebase Status | Approval Status |
|---|---|---|---|---|---|
| **Milestone 1** | **Playable Core Demo:** Atoll Dock, Zone 1 Shallow Reef, Oxygen system, Bag collection, Dock sell station, Pearls UI, ProfileService save | Week 1 | $186 | **100% Complete** | **Approved** |
| **Milestone 2** | **Expanded Gameplay:** Zones 2 & 3 (Kelp Forest, Shipwreck), 5-Tier Gear Upgrade Shop, Creature AI (Jellyfish, Eel, Shark), Tool combat | Weeks 2–3 | $217 | **100% Complete** | **Approved** |
| **Milestone 3** | **Endgame & Monetisation:** Zones 4 & 5 (Abyss, Cursed Deep), World Boss (The Leviathan), Treasure Vault, Opt-in PvP system, Prestige system, Full Monetisation engine | Week 4 | $217 | **100% Complete** | **Ready for Review / Payment** |

---

## Future Phase: Contract 2 ($660 AUD)
- **Goal:** Commercial art, UI/UX polish, custom 3D models, rich VFX/lighting, and launch preparation.
- **Scope:**
  - High-polish custom 3D models for creatures, tools, and dock props (replacing functional placeholders).
  - Clean, styled UI/UX matching visual references (*Steal an Egg*, *Grow a Garden*).
  - Rich underwater ambiance, water particle VFX, sound design, and audio soundscape.
  - Full cross-platform optimization and production launch setup.

---

## Milestone Verification Criteria

### Milestone 1 Acceptance (Verified Working)
- [x] Player spawns at surface dock, dives into water, experiences accurate oxygen depletion.
- [x] Loot items spawn dynamically in Zone 1 and can be picked up to bag limit.
- [x] Surface dock sell station empties bag, credits Pearls, and displays toast notification.
- [x] ProfileService reliably saves Pearl balance across sessions.

### Milestone 2 Acceptance (Verified Working)
- [x] Zones 2 and 3 feature unique depth ranges, water color changes, and crushing pressure hazard for inadequate suits.
- [x] Gear Shop modal opens from dock station and allows upgrading all 5 gear types across 5 tiers with Pearls.
- [x] Wildlife AI (Jellyfish sting, Eel electrical stun, Shark pursuit) damages players submerged in respective zones.
- [x] Diving Tool attacks deal tier-based damage to creatures with visual hit flashes.

### Milestone 3 Acceptance (Verified Working)
- [x] Zone 4 (Octopus) and Zone 5 (Leviathan Boss) fully functional with custom mechanics.
- [x] Leviathan boss features live health bar (gated to Zone 5), coil swimming AI, and seabed Treasure Vault (+5,000 Pearls) on defeat.
- [x] Optional PvP toggle station at dock with clean text badges, suit abilities (Shields/Speed), and Dodge Dash.
- [x] Dropped loot bag spawning on PvP defeat with anti-duplication Revive Token race condition protection.
- [x] PvE deaths to drowning or wildlife empty loot bags to preserve survival stakes.
- [x] Prestige Shrine functional (requires all Tier 5 gear + 50,000 Pearls; grants permanent +10% Pearl value and +5% speed per rank up to Rank X, with Rank X button lockout).
- [x] Monetization engine processes game passes and developer products in both Studio test mode and production, adhering to the 2-second automatic prompt rule.
- [x] Creature status effects (Eel stun, Octopus ink slow) dynamically restore 100% of player Speed Fins and Prestige multipliers upon expiry.