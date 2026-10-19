# Changelog

All notable changes to the Deep Tides project are documented in this file.

## [0.3.3] - 2026-10-20
### Fixed
- **Status Effect Speed Recovery:** Fixed Electric Eel stun (1.2s) and Giant Octopus ink slow (2.5s) in `CreatureServer` restoring hardcoded `16` speed; implemented `PlayerDataManager.GetDefaultWalkSpeed()` and `PlayerDataManager.ResetWalkSpeed()` to dynamically restore 100% of player Speed Fins and Prestige multipliers.
- **DataStore Userdata Crash:** Resolved `CantStoreValue: Cannot store in data store` error in `PlayerDataManager` by sanitizing loot items to primitive data types before saving, stripping `Color3` userdata.
- **UI Label Overlap:** Shortened Gear Shop modal text strings (`Tier X: Name` and `Current ➔ Next`) in `UIController` so labels fit cleanly without colliding with upgrade buttons.
- **Boss Bar Gating:** Restricted Leviathan boss bar visibility in `UIController` to Zone 5 (`Y <= -400 studs`), preventing the boss bar from displaying on the surface dock.
- **Prestige Button Boundary:** Grayed out and locked the Prestige Shrine action button at Rank X (`PrestigeLevel >= 10`).
- **Clean Overhead Badges:** Converted Prestige and PvP overhead displays into clean, frameless, text-only floating tags.

---

## [0.3.2] - 2026-10-20
### Added
- **AutoRevivePrompt:** Added pre-built `AutoRevivePrompt` in `StarterGui.MainHUD` matching the exact `380x72` geometry, fonts, and colors of `AutoOxygenPrompt`.
- **Anti-Dupe PvP Revive Race:** Added `HideRevivePrompt` RemoteEvent. When a dropped bag is stolen, the victim's revive prompt auto-closes to prevent item duplication.
- **PvE Death Loot Loss:** Submerged deaths in PvE mode now clear the player's loot bag, making Oxygen Tanks and Emergency Oxygen meaningful.

### Fixed
- Set `MainHUD.ResetOnSpawn = false` to prevent character respawns from destroying GUI references.
- Resolved line 134 `nil[zoneId]` indexing error in `LootServer` via `zoneLootMap`.

---

## [0.3.1] - 2026-10-20
### Added
- Connected `LootMagnetActive` attribute in `LootServer` to double pickup reach (up to 36 studs).
- Connected `GuaranteedRare` dev product in `LootServer` to upgrade drops to Rare+ with toast feedback.
- Implemented physical seabed loot bag drop on PvP defeat in `ServerInit`.

### Fixed
- Renamed `SellSever.server.luau` to `SellServer.server.luau`.
- Renamed `docs/CURRENT_TAST.md` to `docs/CURRENT_TASK.md`.

---

## [0.3.0] - 2026-10-20
### Added
- **Milestone 3 Endgame:** Added Zone 4 (The Abyss) and Zone 5 (The Cursed Deep).
- **The Leviathan Boss:** 1,500 HP world raid boss in Zone 5, with animated boss health bar and seabed Golden Treasure Vault (+5,000 Pearls).
- **Opt-in PvP Engine:** Dock station toggle, weapon damage, directional underwater Dodge Dash, and Suit Abilities (Speed Surge, Iron Skin, Thermal Barrier, Leviathan Aura).
- **Prestige System:** 50,000 Pearls reset requiring all Tier 5 gear, granting permanent +10% sell value and +5% speed per rank up to Rank X.
- **Monetisation Engine:** MarketplaceService validation, Game Passes, Dev Products, and 2-second automatic emergency prompts.

---

## [0.2.0] - 2026-10-18
### Added
- **Milestone 2 Expansion:** Zones 2 (Kelp Forest) & 3 (Shipwreck) with crushing depth pressure hazards.
- 5-Category / 5-Tier Gear Upgrade Shop with interactive dock ProximityPrompt.
- Wildlife AI: Jellyfish sting, Electric Eel stun, and Hammerhead Shark pursuit.
- Diving Tool weapon damage against creatures.

---

## [0.1.0] - 2026-10-16
### Added
- **Milestone 1 Core Loop:** Server-authoritative oxygen depletion loop and dock refill.
- Zone 1 Shallow Reef loot spawning and collection.
- Surface dock sell station with Pearl currency crediting.
- ProfileService session-locking persistence.
- MainHUD with Pearls counter, Bag counter, and Oxygen meter.