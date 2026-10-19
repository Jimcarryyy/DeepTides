# Architectural Decisions Log (ADR)

### ADR 001: ProfileService for Data Persistence
- **Decision:** Use ProfileService with session locking over basic DataStore2 or standard GlobalDataStore.
- **Why:** Session locking prevents currency duplication, race conditions on sudden disconnects, and item loss during server transitions. Crucial for handling real Robux transactions and tradeable relics.

### ADR 002: Server-Authoritative Oxygen & Pressure Hazard
- **Decision:** Calculate oxygen drain, drowning ticks, and depth pressure hazards strictly on the server Heartbeat loop in `OxygenServer`. Replicate via throttled RemoteEvent (`0.25s` interval).
- **Why:** Completely mitigates client-side memory-editing exploits (e.g. infinite oxygen or depth god-mode).

### ADR 003: Procedural Lightweight Creature AI
- **Decision:** Implement wildlife AI (Jellyfish, Eels, Sharks, Octopus, Leviathan) using mathematical vector interpolation, trigonometric oscillation, and distance checks inside a central Heartbeat loop rather than standard Roblox Humanoids or PathfindingService.
- **Why:** Standard Roblox Humanoids in water produce massive physics overhead and erratic swimming replication. Procedural CFrame updates for 10-15 aquatic creatures maintain stable 60 FPS server performance with 20-30 CCU.

### ADR 004: Centralized Remote Management in ServerInit
- **Decision:** Auto-initialize all required `RemoteEvent` instances in `ServerInit.server.luau` upon server start if missing.
- **Why:** Eliminates manual Studio hierarchy setup errors, guarantees client scripts never throw infinite yield warnings on `WaitForChild("Remotes")`, and simplifies Argon deployment.

### ADR 005: 5-Tier Linear Economy & 50,000 Pearl Prestige Loop
- **Decision:** Require all 5 gear categories to reach Tier 5 before allowing Prestige at the cost of 50,000 Pearls.
- **Why:** Prevents players from rushing Prestige by upgrading only the cheapest gear. Creates a sustained, balanced endgame grind.

### ADR 006: Dual-Mode Monetisation Architecture
- **Decision:** Implement standard `MarketplaceService.ProcessReceipt` alongside a `MonetizationConfig.TEST_MODE` flag and `TestBuyProduct` remote.
- **Why:** Allows full end-to-end testing of developer products and game passes in local Studio sessions without publishing the experience or spending real Robux.