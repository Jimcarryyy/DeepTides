# Changelog

All notable changes to the Deep Tides project are documented in this file.

## [0.3.0] - 2026-10-20 (Milestone 1–3 Full Codebase Delivery)
### Added
- **Zone 4 & 5 Expansion:** Added "The Abyss" (-240 to -400 studs) and "The Cursed Deep" (-400 to -600 studs) with extreme pressure hazards and custom water tinting.
- **The Leviathan World Raid Boss:** 1,500 HP raid boss in Zone 5 with animated boss health bar, undulation AI, and seafloor golden Treasure Vault rewarding +5,000 Pearls on defeat.
- **Hostile Ecosystem AI:** Giant Octopus (ink cloud blind / -50% speed), Hammerhead Shark (fast pursuit), Electric Eel (electric stun), and ambient Jellyfish.
- **Opt-in PvP Engine:** Surface dock PvP station toggle, overhead billboard indicators, directional underwater Dodge Dash (Space/Shift/ButtonB), and weapon swing combat.
- **Suit Special Abilities:**
  - Tier 2: Speed Surge (+150% swim speed for 4s).
  - Tier 3: Iron Skin (-60% damage reduction for 6s).
  - Tier 4: Thermal Barrier (-70% damage reduction for 7s).
  - Tier 5: Leviathan Aura (-80% shield + 2x speed for 8s).
- **Prestige System:** Unlocked at all Tier 5 gear + 50,000 Pearls. Resets gear for +10% Pearl value and +5% speed per rank up to Rank X with overhead prestige crests.
- **Monetisation Engine:**
  - MarketplaceService `ProcessReceipt` and `PromptGamePassPurchaseFinished`.
  - Game passes: Deep Diver (2x oxygen), Treasure Hunter (+25% sell value, +1 slot), Leviathan Pass (Zone 5 pressure immunity).
  - Dev Products: Starter Pack, Emergency Oxygen, Revive Token, Loot Magnet, Rare Dive.
  - Studio Test Mode toggle (`MonetizationConfig.TEST_MODE`) via `TestBuyProduct` remote.
  - Hard UX 2-second auto-prompt on critical oxygen (<= 8s).
- **Dynamic Scrolling Frames:** Automatic `CanvasSize` binding based on `UIListLayout.AbsoluteContentSize` in `UIController`.

### Fixed
- Stabilized tool equipping logic to eliminate unhandled tool state replication.
- Added dynamic pressure hazard calculations preventing depth exploits.

---

## [0.2.0] - 2026-10-18 (Milestone 2 Expansion)
### Added
- 5-Tier Gear Upgrade Shop (`GearShopModal`) supporting Oxygen Tanks, Loot Bags, Speed Fins, Diving Suits, and Diving Tools.
- Surface dock Gear Shop station with interactive ProximityPrompt.
- Underwater combat damage calculation against wildlife using equipped Diving Tools.
- Zone 2 & Zone 3 loot items (Glowing Kelp Bulb, Giant Pearl Oyster, Galleon Gold Ingot, Captain's Cutlass, etc.).

---

## [0.1.0] - 2026-10-16 (Milestone 1 Core Loop)
### Added
- Initial server-authoritative oxygen depletion loop and surface dock refill.
- Zone 1 Shallow Reef loot spawning (Sea Shell, Starfish, Rusty Coin, Barnacled Chest).
- ProfileService session-locking persistence for Pearls and gear data.
- Surface dock sell station with Pearl awards and notification toast alerts.
- Basic MainHUD with Pearls counter, Bag counter, and Oxygen meter.