# Changelog

## [Unreleased] - Initial Project Setup
- **Date:** 2026-10-16
- **Changes:**
  - Initialized documentation files (`PROJECT_CONTEXT.md`, `CURRENT_TASK.md`, `ARCHITECTURE.md`, `DECISIONS.md`, `KNOWN_ISSUES.md`, `MILESTONES.md`).
  - Outlined scope and execution plan for Milestone 1 demo.
- **Affected Files:** All context MD files.
- **Why:** Establish persistent workflow, technical roadmap, and architectural boundaries before writing code.

## [Unreleased] - Step 0 Completed
- **Date:** 2026-10-16
- **Changes:** Executed idempotent hierarchy setup script via Command Bar. Created `Config`, `Modules`, and `Remotes` (with `OxygenUpdate`, `PlayerDataUpdate`, `SellResult`) in ReplicatedStorage; `Core` and `Libs` in ServerScriptService; `Controllers` in StarterPlayerScripts; `Zones`, `LootSpawns`, and `DockArea` in Workspace.
- **Affected Files:** Roblox Studio hierarchy.
- **Why:** Establish consistent instance structure required by upcoming client/server modules.

## [0.1.0] - Milestone 1 Playable Demo Complete
- **Date:** 2026-10-16
- **Added:**
  - Full server-authoritative core gameplay loop: Dive -> Collect -> Surface -> Sell -> Save.
  - Low-poly atoll island hub with central ocean diving hole, seabed, and wooden dock.
  - ProfileService persistence saving player Pearls across game sessions.
  - Server-authoritative oxygen depletion (underwater) and rapid surface refill.
  - Zone 1 loot spawner with distinct low-poly models (Sea Shell, Starfish, Rusty Coin, Barnacled Chest).
  - Surface dock Sell Station pad with transactional sales and slide-in toast notifications.
  - StarterGui MainHUD featuring Pearls counter, Bag capacity tracker, and animated Oxygen gauge.
- **Fixed:**
  - Removed legacy TypeScript templates and infinite yield warnings.
  - Resolved event re-entrancy depth recursion in LootServer by isolating active loot into `Workspace.ActiveLoot`.
  - Shifted UI below modern Roblox Unibar to eliminate HUD overlap across devices.