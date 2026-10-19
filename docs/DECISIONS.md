# Architectural Decisions Log (ADR)

### ADR 001: ProfileService for Data Persistence
- **Decision:** Use ProfileService with session locking over basic DataStore2 or standard GlobalDataStore.
- **Why:** Session locking prevents currency duplication, race conditions on sudden disconnects, and item loss during server transitions.

### ADR 002: Server-Authoritative Oxygen & Depth Pressure
- **Decision:** Calculate oxygen drain, drowning ticks, and depth pressure hazards strictly on the server Heartbeat loop in `OxygenServer`. Replicate via throttled RemoteEvent (`0.25s` interval).
- **Why:** Mitigates client-side memory-editing exploits (e.g. infinite oxygen or depth god-mode).

### ADR 003: Procedural Lightweight Creature AI
- **Decision:** Implement wildlife AI (Jellyfish, Eels, Sharks, Octopus, Leviathan) using mathematical vector interpolation, trigonometric oscillation, and distance checks inside a central Heartbeat loop rather than standard Roblox Humanoids or PathfindingService.
- **Why:** Standard Roblox Humanoids in water produce massive physics overhead and erratic swimming replication. Procedural CFrame updates maintain stable 60 FPS server performance with 20-30 CCU.

### ADR 004: Centralized Remote Management in ServerInit
- **Decision:** Auto-initialize all required `RemoteEvent` instances in `ServerInit.server.luau` upon server start if missing.
- **Why:** Eliminates manual Studio hierarchy setup errors, guarantees client scripts never throw infinite yield warnings, and simplifies Argon deployment.

### ADR 005: 5-Tier Linear Economy & 50,000 Pearl Prestige Loop
- **Decision:** Require all 5 gear categories to reach Tier 5 before allowing Prestige at the cost of 50,000 Pearls.
- **Why:** Prevents players from rushing Prestige by upgrading only the cheapest gear. Creates a sustained, balanced endgame grind.

### ADR 006: Dual-Mode Monetisation Architecture
- **Decision:** Implement standard `MarketplaceService.ProcessReceipt` alongside a `MonetizationConfig.TEST_MODE` flag and `TestBuyProduct` remote.
- **Why:** Allows full end-to-end testing of developer products and game passes in local Studio sessions without publishing the experience or spending real Robux.

### ADR 007: Anti-Dupe PvP Loot Dropping & 30-Second Revive Race
- **Decision:** When a PvP player dies, their dropped bag is a live race: using a Revive Token immediately despawns the world bag, while another player looting the bag clears the victim's backup and dismisses their revive prompt via `HideRevivePrompt`.
- **Why:** Completely eliminates item duplication while adhering to the client's 30-second recovery window.

### ADR 008: DataStore Userdata Sanitization
- **Decision:** Sanitize all loot items in `PlayerDataManager.AddToBag()` into clean primitive types (`Id`, `Name`, `BaseValue`, `Rarity`) and strip `Color3` objects.
- **Why:** Roblox DataStores cannot serialize Roblox DataTypes (like `Color3`, `Vector3`, or `CFrame`). Sanitization ensures ProfileService auto-saves succeed without UTF-8 serialization errors.

### ADR 009: Centralized Player Speed Authority
- **Decision:** Expose `PlayerDataManager.GetDefaultWalkSpeed()` and `PlayerDataManager.ResetWalkSpeed()` to handle speed restorations after status effects (Electric Eel stun, Giant Octopus slow) and suit abilities.
- **Why:** Prevents status effect recovery timers from hardcoding default 16 walkspeed and wiping out Speed Fins and Prestige multipliers.

### ADR 010: Pre-Built GUI in StarterGui Over Runtime Instantiation
- **Decision:** Construct and style UI frames (such as `AutoRevivePrompt`) inside `StarterGui.MainHUD` first, keeping `UIController` strictly for event wiring and tween animations. Set `MainHUD.ResetOnSpawn = false`.
- **Why:** Preserves uniform visual polish, prevents runtime GUI reference breakage upon character death, and allows rapid in-Studio inspection.