# System Architecture

## Complete Project Hierarchy

```text
src/
├── ReplicatedStorage/
│   ├── Config/
│   │   ├── ZoneConfig.luau             -- 5 Zones, depth ranges, pressure damage, water colors
│   │   ├── LootConfig.luau             -- Weighted loot tables across 5 zones
│   │   ├── GearConfig.luau             -- 5 Gear categories x 5 Tiers with costs & attributes
│   │   └── MonetizationConfig.luau     -- GamePass & DevProduct definitions + Test Mode toggle
│   ├── Remotes/                        -- Managed dynamically by ServerInit
│   │   ├── OxygenUpdate (RemoteEvent)
│   │   ├── PlayerDataUpdate (RemoteEvent)
│   │   ├── SellResult (RemoteEvent)
│   │   ├── NotifyClient (RemoteEvent)
│   │   ├── RequestUpgrade (RemoteEvent)
│   │   ├── AttackRequest (RemoteEvent)
│   │   ├── AbilityRequest (RemoteEvent)
│   │   ├── TogglePvP (RemoteEvent)
│   │   ├── RequestPrestige (RemoteEvent)
│   │   ├── BossHealthUpdate (RemoteEvent)
│   │   └── TestBuyProduct (RemoteEvent)
│   ├── Tools/                          -- DivingTool_1 to DivingTool_5
│   ├── CreatureModels/                 -- Jellyfish, ElectricEel, HammerheadShark, GiantOctopus, TheLeviathan
│   └── LootModels/                     -- Optional custom models by loot Id
├── ServerScriptService/
│   ├── Core/
│   │   ├── PlayerDataManager.luau      -- ProfileService session locking, gear, prestige, passes
│   │   ├── ServerInit.server.luau      -- Network remotes, PvP combat & suit ability engine
│   │   ├── OxygenServer.server.luau    -- Heartbeat loop, drain, drown damage, pressure hazard
│   │   ├── SellSever.server.luau       -- Dock sell station, prestige/gamepass multipliers
│   │   ├── LootServer.server.luau      -- Procedural node spawner, proximity pickups, active tracking
│   │   ├── CreatureServer.server.luau  -- Ecosystem AI, attacks, Leviathan boss & vault
│   │   └── MonetizationServer.server.luau -- MarketplaceService receipt validation & test triggers
│   └── Libs/
│       └── ProfileService.luau         -- Production session-locking data library
├── StarterPlayer/
│   └── StarterPlayerScripts/
│       └── Controllers/
│           ├── UIController.client.luau   -- Main HUD, modals, dynamic scrolling, toasts, boss bar
│           ├── CombatClient.client.luau   -- Attack inputs, tool equip, underwater dodge dash, abilities
│           └── OxygenClient.client.luau   -- Oxygen update state cache
└── StarterGui/
    └── MainHUD/
        ├── PearlsPill / BagPill / PvPPill
        ├── OxygenContainer (Fill, Value)
        ├── CombatActionBar (Slot_Attack, Slot_Ability, Slot_Dodge)
        ├── BossBarContainer (Fill, HPText)
        ├── NotificationToast
        ├── AutoOxygenPrompt
        ├── GearShopModal (List, CloseButton)
        ├── PrestigeModal (PrestigeButton, CloseButton)
        ├── StoreModal (List, CloseButton)
        └── StoreButton

Workspace Required Structure
Workspace.ActiveLoot (Folder): Dynamically spawned active loot instances.
Workspace.ActiveCreatures (Folder): Dynamically active creature models.
Workspace.LootSpawns (Folder): BaseParts named SpawnNode* with attribute ZoneId (1 to 5).
Workspace.DockArea (Model/Folder):
SellShop / SellStation / SellPad with ProximityPrompt.
GearShop (Model with PrimaryPart and ProximityPrompt ShopPrompt).
PvPStation (Model with PrimaryPart and ProximityPrompt PvPPrompt).
PrestigeShrine (Model with PrimaryPart and ProximityPrompt PrestigePrompt).
Client-Server Network Flow
code
Text
[Client: CombatClient]  ──(AttackRequest)──────────> [Server: ServerInit]
                                                           │ (Validates distance, cooldown, PvP)
                                                           ▼
[Client: UIController]  <──(NotifyClient)─────────── [Server: ServerInit / CreatureServer]
[Client: MainHUD]       <──(BossHealthUpdate)─────── [Server: CreatureServer]
[Client: MainHUD]       <──(OxygenUpdate)─────────── [Server: OxygenServer (0.25s sync)]
[Client: MainHUD]       <──(PlayerDataUpdate)─────── [Server: PlayerDataManager]
[Client: UIController]  ──(RequestUpgrade)─────────> [Server: PlayerDataManager]
[Client: UIController]  ──(RequestPrestige)────────> [Server: PlayerDataManager]
[Client: UIController]  ──(TestBuyProduct)─────────> [Server: MonetizationServer]

Key Architectural Rules
Server Authority: All damage, loot addition, oxygen depletion, bag dropping, and pearl transactions run strictly on the server.
Data Persistence Safety: PlayerDataManager sanitizes all items before inserting them into profile.Data.LootBag so that Roblox userdata types (such as Color3) never enter ProfileService or DataStores.
Speed Authority: PlayerDataManager.GetDefaultWalkSpeed(player) is the single source of truth for walk/swim speed, dynamically computing Fins tiers and Prestige multipliers to prevent creature slows from corrupting player stats.
Anti-Dupe Safeguard: Dropped bags are a live race: using a Revive Token despawns the world bag, while another player looting the world bag dismisses the victim's revive prompt.

### Workspace Structure (Phase 2 Additions)
- `Workspace.ActiveLoot` (Folder): Dynamically spawned active loot instances.
- `Workspace.ActiveCreatures` (Folder): Dynamically active creature models.
- `Workspace.LootSpawns` (Folder): BaseParts named `SpawnNode_Z[1-3]_[1-6]` (18 nodes across Zones 1–3).
- `Workspace.DockArea` (Folder):
  - `SellShop` (Reskinned timber booth with Coral/Cream awning and sell prompt).
  - `GearShop` (Reskinned timber booth with Teal/Cream awning and upgrade prompt).
  - `PvPStation` (Custom 3D station, PrimaryPart = Mesh_0, PvPPrompt, TitleBoard).
  - `PrestigeShrine` (Custom 3D shrine, PrimaryPart = Mesh_0, PrestigePrompt, TitleBoard).
- `Workspace.Island` (Folder):
  - `GrassTiles`: 2-tone warm dimmed studded lawn tiles.
  - `BoundaryWalls`: 18-stud tall studded perimeter walls with anti-void caps.
  - `LagoonDocks`: 4 angled wooden boardwalk docks with support pilings and diving lanterns.
  - `SurfaceProps`: Studded palm groves, cargo stacks, bushes, lantern bollards.
  - `SandPatches`: 2-tone modular studded sand patches with template palette.
  - `PitWallTiles`: 240 solid 1-color studded wall sections spanning Zones 1 to 5 (Y = 2 to -600 studs).
- `Workspace.Zones` (Folder):
  - `Zone1_ShallowReef`: ReefProps & ExpandedProps (Corals, clam shrines, swim arches, anemones, tiki heads).
  - `Zone2_KelpForest`: KelpProps & ExpandedProps (65-stud kelp stalks, glowing bulbs, boulders, temple ruins, rowboat).
  - `Zone3_Shipwreck`: ShipwreckProps & ExpandedProps (Sunken Galleon, Captain's Cabin, mast, cannons, anchor, debris, cages).
  - `Zone4_TheAbyss`: AbyssProps & ExpandedProps (Smoker vents, crystals, ledges, kraken monoliths, shelf fungi).
  - `Zone5_TheCursedDeep`: CursedDeepProps & ExpandedProps (Leviathan ribcage tunnel, colossal horned skull, lava cascades, magma spires, chained talons, floor plate).
- `Workspace.Client_MilestoneA_Showcase` (Folder): Static client review exhibition gallery containing safe non-tool duplicates of all 3D assets.

### ReplicatedStorage Assets (Phase 2 Additions)
- `ReplicatedStorage.CreatureModels`: Custom 3D models for `Jellyfish`, `ElectricEel`, `HammerheadShark`, `GiantOctopus`, and `TheLeviathan`.
- `ReplicatedStorage.Tools`: `DivingTool_1` to `DivingTool_5` with custom 3D Meshy meshes scaled to hand size and welded to `Handle`.
- `ReplicatedStorage.LootModels`: 12 official collectible drops mapped to `LootConfig.Id` (`seashell`, `starfish`, `rusty_coin`, `small_chest`, `glowing_kelp`, `pearl_oyster`, `ancient_amphora`, `emerald_geode`, `galleon_gold`, `pirate_cutlass`, `ship_chronometer`, `cursed_skull_relic`) plus `BarnacledChest` and `FloatingPvPChest`.