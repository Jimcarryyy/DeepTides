# Current Task: Milestone 1 Setup & Core Demo Loop

## Goal
Establish project foundation and deliver a playable Milestone 1 demo: Surface dock, Zone 1 (Shallow Reef), functional oxygen drain/refill, collectible loot, loot bag inventory, dock selling station, basic HUD (Pearls + Oxygen), and data persistence.

## Task Breakdown
- [ ] **Step 0: Workspace & Folder Structure**
  - [ ] Set up project directory tree for Argon sync.
  - [ ] Run initial setup script in Command Bar to establish folders in ReplicatedStorage, ServerScriptService, StarterGui.
- [ ] **Step 1: Core Data Framework**
  - [ ] Integrate ProfileService.
  - [ ] Create `PlayerDataManager` (handles Pearls, Gear Levels, Bag contents).
- [ ] **Step 2: Configuration Modules**
  - [ ] Create `LootConfig` (Zone 1 items, values, weights).
  - [ ] Create `GearConfig` (Base tank capacity, base bag size).
  - [ ] Create `ZoneConfig` (Zone 1 depth boundary).
- [ ] **Step 3: Oxygen System**
  - [ ] Server-side oxygen manager (drains when submerged below water line, refills at surface/dock).
  - [ ] Oxygen replication to client.
- [ ] **Step 4: Loot Spawning & Collection**
  - [ ] Zone 1 loot spawner (server-authoritative item placement using CollectionService).
  - [ ] Proximity / touch collection logic checking bag capacity.
- [ ] **Step 5: Surface Dock & Sell Station**
  - [ ] Dock sell zone (ProximityPrompt or Touched event).
  - [ ] Transaction logic: clears bag, credits Pearls via `PlayerDataManager`.
- [ ] **Step 6: Demo UI (Clean & Polished)**
  - [ ] Oxygen gauge / bar (StarterGui).
  - [ ] Pearls balance & Loot bag capacity counter (StarterGui).
  - [ ] Sell summary notification.
- [ ] **Step 7: Environment & Assistant Prompts**
  - [ ] Generate basic dock model + Zone 1 reef props via Studio Assistant.
  - [ ] Lighting & underwater atmosphere settings (WaterColor, Fog/Atmosphere).

## Blockers
- Awaiting initial approval to begin Step 0.

## Definition of Done (Milestone 1 Demo)
1. Player spawns at dock, displays 0 Pearls and full Oxygen.
2. Player jumps into water; oxygen drains steadily.
3. Player swims down to Zone 1, interacts with loot items until bag is full.
4. Player surfaces at dock; oxygen refills.
5. Player steps onto sell area; loot bag empties, Pearls update on UI and save to ProfileService.