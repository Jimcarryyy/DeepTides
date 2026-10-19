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