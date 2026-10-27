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

### ADR 011: Signature 3D Bumpy Studs as Unified Visual Identity
- **Decision:** Enforce `Material = Enum.Material.Plastic` and `TopSurface = Enum.SurfaceType.Studs` across all visible horizontal and flat faces of terrain, walls, stalls, props, docks, and chests.
- **Why:** Delivers the chunky, tactile toy-like aesthetic benchmarked from *Steal an Egg*, establishing a cohesive visual signature across the entire game.

### ADR 012: Non-Breaking VisualMesh Injection for Tools & Loot
- **Decision:** Maintain existing root parts (`Handle`, `Blade`, `Tip`, `BarbCenter`, `Core`, `CoinPart`) as invisible collisionless anchors (`Transparency = 1`, `CanCollide = false`). Scale and weld new custom 3D Meshy meshes directly to the root part with `WeldConstraint`.
- **Why:** Guarantees 100% backward compatibility with Phase 1 combat, animations, server raycasts, and pickup listeners without modifying a single line of backend codebase.

### ADR 013: Server-Authoritative Loot Model ID Mapping
- **Decision:** Name template models in `ReplicatedStorage.LootModels` to match `LootConfig.Id` strings (`galleon_gold`, `glowing_kelp`, `small_chest`, etc.) rather than display names, while maintaining display name aliases.
- **Why:** `ServerScriptService.Core.LootServer` indexes templates via `lootData.Id`. Mismatched names previously caused the spawner to fall back to generating default blocky shapes on the fly.

### ADR 014: Solid Single-Color Zone PitWalls Over Dense Tiled Slicing
- **Decision:** Subdivide the 48 cylinder columns into 5 solid vertical zone tiers (240 parts total) colored with a distinct signature tone per zone, rather than thousands of dense checkerboard slices.
- **Why:** Slicing thousands of small wall tiles caused visual noise and depth-fog glare underwater. Single-color studded zone walls provide clean readability, eliminate seams, and maintain 60 FPS performance on mobile devices.

### ADR 015: Tool Class Exclusion in Display Showcases
- **Decision:** Never use the `Tool` class inside visual world exhibitions or showcase galleries. Cloned display weapons must use plain `Model`s containing `MeshPart`s with `CanTouch = false`.
- **Why:** Roblox's default character controller auto-equips unanchored or touched `Tool` instances. If the tool handle is anchored in a display, the player's arm welds to the anchored part, permanently freezing the character in place.

### ADR 016: True R6 Avatar Standardization
* **Context:** Initial animation testing encountered rig mismatches between R15 and R6.
* **Decision:** Formally standardized the game's Avatar Type to True R6 in project settings.
* **Why:** Classic R6 geometry provides responsive, lightweight movement that matches top-performing Roblox simulators (*Steal an Egg*, *Grow a Garden*) while eliminating multi-joint deformation lag in water.

### ADR 017: Native Tool.Grip Serialization
* **Context:** Imported tool models were oriented vertically, cutting through player shoulders.
* **Decision:** Used Roblox's native `Tool.Grip` CFrame property serialized directly on tool assets rather than runtime weld constraints or scripts.
* **Why:** `Tool.Grip` is natively supported by the Roblox engine, persists permanently via Argon sync, and incurs zero runtime script or physics overhead.

### ADR 018: True Ray-Line Ranged Hit Detection
* **Context:** Loose dot-product checks resulted in an auto-targeting cone that felt like an aimbot.
* **Decision:** Implemented perpendicular ray-line intersection math on the server verifying the spear path passes within the creature's physical body radius.
* **Why:** Rewards skill-based speargun aiming and prevents players from hitting targets outside their crosshair.

### ADR 019: Projectile Impale Sticking Effect
* **Context:** Ranged harpoon bolts previously vanished instantly on collision like laser beams.
* **Decision:** When connecting with a creature, the spear stops its velocity and welds directly to the creature's root part for 3.5 seconds before dissolving.
* **Why:** Dramatically enhances visual feedback, allowing players to see their spears embedded in swimming sea creatures.

### ADR 020: Natural Sinking Creature Death Sequences
* **Context:** Defeated sea creatures were disappearing instantly on reaching 0 HP.
* **Decision:** Implemented a 2.2-second belly-up roll, gentle sinking drift, and gradual transparency fade.
* **Why:** Replaces jarring object deletion with an authentic marine death animation while keeping performance lightweight.

### ADR 021: High-Volume Ambient Mastering (1.45–1.70)
* **Context:** Low-frequency underwater ambient audio was inaudible on mobile and laptop speakers.
* **Decision:** Mastered zone ambient target volumes between 1.45 and 1.70 in `SoundController.client.luau`.
* **Why:** Overcomes hardware speaker limitations while maintaining headroom for crisp, punchy combat and UI sound effects.