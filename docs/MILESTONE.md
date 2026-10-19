# Milestones & Delivery Tracker

| Milestone | Deliverables | Timeline | Budget (AUD) | Codebase Status | Approval Status |
|---|---|---|---|---|---|
| **Milestone 1** | **Playable Core Demo:** Atoll Dock, Zone 1 Shallow Reef, Oxygen system, Bag collection, Dock sell station, Pearls UI, ProfileService save | Week 1 | $186 | **100% Complete** | Ready for Review |
| **Milestone 2** | **Expanded Gameplay:** Zones 2 & 3 (Kelp Forest, Shipwreck), 5-Tier Gear Upgrade Shop, Creature AI (Jellyfish, Eel, Shark), Tool combat | Weeks 2–3 | $217 | **100% Complete** | Ready for Review |
| **Milestone 3** | **Endgame & Monetisation:** Zones 4 & 5 (Abyss, Cursed Deep), World Boss (The Leviathan), Treasure Vault, Opt-in PvP system, Prestige system, Full Monetisation engine | Week 4 | $217 | **95% Complete** *(Awaiting final 4 integration hook patches)* | In Verification |

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

### Milestone 3 Acceptance (In Progress)
- [x] Zone 4 (Octopus) and Zone 5 (Leviathan Boss) fully functional with custom mechanics.
- [x] Leviathan boss features live health bar, coil swimming AI, and seabed Treasure Vault (+5,000 Pearls) on defeat.
- [x] Optional PvP toggle station at dock with overhead badges, suit abilities (Shields/Speed), and Dodge Dash.
- [x] Prestige Shrine functional (requires all Tier 5 gear + 50,000 Pearls; grants permanent +10% Pearl value and +5% speed per rank).
- [x] Monetization engine processes game passes and developer products in both Studio test mode and production.
- [ ] Connect the remaining 4 integration hooks (LootMagnet pickup reach, GuaranteedRare loot roll, PvP bag drop + ReviveToken prompt).