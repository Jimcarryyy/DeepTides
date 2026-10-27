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

## [0.4.0] - 2026-10-23
### Phase 2: Milestone A (Commercial 3D Assets & Environment) - APPROVED ($198 AUD)
#### Added
- **Surface Hub Island Polish:**
  - Constructed 2-tone warm dimmed lawn using signature 3D bumpy studs (`Material.Plastic`, `TopSurface = Studs`).
  - Built 18-stud tall architectural wood perimeter walls with 360-degree studs and invisible anti-void safety caps.
  - Built 4 detailed wooden boardwalk lagoon docks with sloping timber planks, underwater support pilings, nautical rope bollards, and warm diving lanterns.
  - Populated island with studded palm tree groves, cargo crate/barrel stacks, shrub clusters, and lantern bollards.
  - Added modular 2-tone scatterable sand patches (`Workspace.Island.SandPatches`) with template models for easy in-Studio duplication.
- **Full PitWalls System (Zones 1–5):**
  - Sliced all 48 columns across the 600-stud dive shaft into solid 1-color-per-zone walls featuring signature 3D bumpy studs.
  - Zone progression palette: Sunlit Sand (Z1) ➔ Golden Olive (Z2) ➔ Bloodwood Rust (Z3) ➔ Abyssal Violet-Slate (Z4) ➔ Cursed Magma Sienna (Z5).
- **Underwater Environment Props (Zones 1–5):**
  - **Zone 1 (Shallow Reef):** 20 coral clusters, brain corals, staghorn antlers, table coral shelves, 2 giant clam shrines with glowing pearls, 2 swim-through arches, anemone gardens, and sunken carved tiki heads.
  - **Zone 2 (Kelp Forest):** 6x 65-stud towering kelp stalk landmarks, glowing lime bulbs, holdfast boulders, 3 ancient temple columns, a sunken rowboat caught in the canopy, and glowing barrel sponges.
  - **Zone 3 (Sunken Shipwreck):** Sunken Spanish Galleon hull at Y = -238, glowing Captain's Cabin, snapped 55-stud mast with crow's nest, cannons, anchor, mid-water debris, and 2 hanging gibbet cages with cursed skulls.
  - **Zone 4 (The Abyss):** Hydrothermal smoker vents, bioluminescent crystal clusters, trench ledges, 2 cyclopean kraken monoliths with glowing violet rune eyes, and tiered shelf fungi.
  - **Zone 5 (The Cursed Deep):** 42-stud Ancient Leviathan Ribcage Tunnel, Colossal Horned Skull (swimmable mouth), 3 vertical 160-stud lava cascades, magma spires, chained dragon talons, and solid seafloor plate at Y = -600.
- **World Containers:**
  - Built non-glitching Barnacled Treasure Chest and Floating PvP Loot Chest (zero Z-fighting, clearance offsets, layered crossing chains, welded).
- **Loot Models (12 Total across Zones 1–3):**
  - Integrated custom 3D Meshy meshes for all 12 collectible drops in `ReplicatedStorage.LootModels`.
  - Mapped models to exact `LootConfig.Id` keys: `seashell`, `starfish`, `rusty_coin`, `small_chest`, `glowing_kelp`, `pearl_oyster`, `ancient_amphora`, `emerald_geode`, `galleon_gold`, `pirate_cutlass`, `ship_chronometer`, `cursed_skull_relic`.
- **Diving Tools (Tiers 1–5):**
  - Upgraded all 5 tools in `ReplicatedStorage.Tools` with custom 3D Meshy meshes, scaled to hand size (2.8 to 5.8 studs), and welded to `Handle`.
- **Client Review Exhibition Gallery:**
  - Deployed `Workspace.Client_MilestoneA_Showcase` behind Spawn displaying all creatures, tools, loot, and chests with distance-gated 3D nameplates.
- **2D Studded UI Prototype:**
  - Built interactive prototype in `StarterGui.StuddedUI_Prototype` verifying 2D tiled studs (`rbxassetid://1347065099`), thick `UIStroke` borders, and responsive spring animations for Milestone B.

#### Fixed
- **Prestige Shrine & PvP Station Prompts:** Fixed fatal `nil.PrimaryPart` error in `ServerInit` and `UIController` by assigning `PrimaryPart = Mesh_0`, setting `RequiresLineOfSight = false`, and normalizing model names.
- **Loot Server Fallback Blocks:** Fixed spawner falling back to procedural default blocks by matching `ReplicatedStorage.LootModels` names to `LootConfig.Id` strings.
- **Showcase Player Freezing Bug:** Eliminated player character lockup on weapon display by removing `Tool` classes from the exhibition and using visual `Model`s only with `CanTouch = false`.
- **Lighting & Glare Audit:** Reduced blinding glare by lowering `Lighting.Brightness = 1.8`, setting `ExposureCompensation = -0.2`, raising `Bloom.Threshold = 1.25`, and globally clamping all workspace `PointLight`s to 0.7 max brightness.

## [0.5.0] - 2026-10-25
### Added
- Phase 2 Milestone B UI/UX Overhaul implementation.
- *Steal an Egg* / *Grow a Garden* modular visual standard across all screens (`GearShopModal`, `PrestigeModal`, `StoreModal`, and prompts).
- Chunky 68px/76px circular studs on outer frames and headers, with zero `UICorner` (crisp 90° arcade block layout).
- Dual outlines (Outer black comic stroke + inner silver-gray bevel highlight) across all major modals, cards, icon boxes, and buttons.
- Parallel chameleon glass reflection rays behind card content, featuring center-convergence hover effects.
- Integration of 36 custom asset IDs across HUD currency pills, tier-1 to 5 gear icons, and store gamepasses/dev products.
- 1-time purchase locking and visual `PURCHASED` badges for the 3 Game Passes and the Starter Pack.

---

## [0.5.2] - 2026-10-27
### Added
- **5-Zone Dynamic Sound Engine:** Integrated custom ElevenLabs ambient loops for Zones 1–5 in `SoundController.client.luau` with boosted volumes (1.45–1.70), gapless looping, and 2-second cross-fading.
- **Surface Audio Isolation:** Complete muting and pausing of surface BGM when submerged, restoring cleanly on surfacing.
- **Creature 3D Defeat Audio:** Added unique 3D spatial defeat sounds for Jellyfish, Electric Eel, Hammerhead Shark, Giant Octopus, and The Leviathan in `CreatureServer.server.luau`.
- **Damage Audio System:** Wired `DamageSFX.CreatureAttackImpact` for monster strikes and `DamageSFX.PvPWeaponHit` for player combat in `ServerInit.server.luau`.
- **Zone Switcher Sound:** Integrated `ZoneSwitcher` audio into `UIController.client.luau` triggering alongside depth toast notifications.
- **Harpoon Ranged Combat Pipeline:**
  - 3D `HarpoonBullet` model projectile flight (85 studs/s) with cavitation bubble wake.
  - Creature impale effect: harpoon spears weld and stick into the target's body for 3.5s before dissolving.
  - Custom UI crosshairs: `Aim reticle` (98984117406248), dynamic red `Target lock` (94965985205021), and damage `Hit marker` (85125072168334).
  - Automatic aim activation underwater with manual `Alt` lock/unlock toggle.
  - Over-the-shoulder camera offset (`Vector3.new(2.6, 0.5, -0.8)`) with smooth 0.35s glide and free natural swimming.
  - Smooth 0.22s hydrodynamic swivel and subtle camera recoil on fire.
  - Server-side true ray-line hit detection up to 65 studs in `CreatureServer.server.luau`.
- **2-Hit Melee Combo System:** Slashes alternate smoothly (`Slash1` ➔ 0.42s ➔ `Slash2`), followed by an enforced 1.35s recovery cooldown.
- **Natural Creature Death Sequence:** Replaced instant deletion with a 2.2s belly-up sinking/floating fade-out animation.

### Changed
- **Underwater Visibility:** Boosted brightness and extended `FogEnd` in Zones 3–5 (Shipwreck: 125 studs, Abyss: 95 studs, Magma: 85 studs).
- **VFX Cleanliness:** Removed colored camera silt/embers from `UnderwaterVFXController.client.luau` and removed dodge wake particles.
- **Rig Standardization:** Standardized project Avatar Type to True R6.
- **Tool Grip Pipeline:** Replaced temporary constraints with permanent native `Tool.Grip` serialization.
- **UI Toast Polish:** Silenced redundant cash register sound on creature kill toast notifications while preserving visual popups.