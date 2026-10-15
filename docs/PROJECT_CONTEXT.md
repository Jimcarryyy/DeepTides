# Deep Tides — Project Context

## Overview
- **Game:** Deep Tides (Ocean diving simulator with optional PvP)
- **Tagline:** "Dive deep. Find rare. Get home alive."
- **Platforms:** PC, Mobile, Console
- **Account:** DeepTidesDev
- **Client:** Lemar Bentley (Confidential)
- **Timeline:** 4 Weeks
- **Budget:** $620 AUD (Split across 3 milestones)
- **Reference Games:** Steal an Egg (UI/creatures), Catch and Tame (map/feel), Grow a Garden (UI polish)

## Core Loop
Dive -> Discover -> Collect (fill loot bag before oxygen runs out) -> Survive (creatures & players on ascent) -> Sell at surface dock for Pearls -> Upgrade gear -> Go deeper.

## Zones
| Zone | Name | Loot | Danger | Creature |
|---|---|---|---|---|
| 1 | Shallow Reef | Common | Low | Jellyfish (slow, weak sting) |
| 2 | Kelp Forest | Uncommon | Medium | Electric Eel (fast, brief stun) |
| 3 | Sunken Shipwreck | Rare | High | Hammerhead Shark (aggressive, high damage) |
| 4 | The Abyss | Epic | Very High | Giant Octopus (grabs, slows movement) |
| 5 | The Cursed Deep | Legendary | Extreme | The Leviathan (weekly server-wide boss) |

## PvP System (Optional)
- Opt-in toggle before diving.
- Intercept players on the ascent to steal loot bags.
- Defeat = lose loot; surface safely = keep loot.
- Combat: Attack, Special Ability (suit-specific), Dodge (directional dash).

## Economy & Gear
- **Currency:** Pearls
- **Loot Types:** Chests (Common), Artefacts (Shipwrecks), Creature Drops, Legendary Relics (Tradeable, Zone 4-5).
- **Gear Categories:**
  - Oxygen Tank (500 - 5,000 Pearls)
  - Diving Suit (1,000 - 10,000 Pearls)
  - Loot Bag (300 - 3,000 Pearls)
  - Diving Tool (400 - 4,000 Pearls)
  - Speed Fins (600 - 6,000 Pearls)
- **Prestige:** Available at 50,000 total Pearls. Resets gear for permanent buffs/cosmetics (up to 10 prestiges, unlocks nameplate badge).

## Monetisation (MarketplaceService)
- **Game Passes:**
  - Deep Diver (199 R$): 2x oxygen capacity
  - Treasure Hunter (499 R$): +25% Pearl value, +1 loot bag slot
  - Leviathan Pass (999 R$): Instant Zone 5 access, animated suit, rare loot shop
- **Developer Products:**
  - Starter Pack (99 R$): 500 Pearls + 1 Uncommon drop + 1 Emergency Oxygen (1x popup after dive 1)
  - Emergency Oxygen (49 R$): Full oxygen refill mid-dive
  - Revive Token (99 R$): Recover PvP lost loot (30s window)
  - Loot Magnet (49 R$): 2x pickup radius + wall vision for 1 dive
  - Rare Dive (149 R$): Guaranteed Rare+ drop on next dive
- **UX Rule:** Emergency Oxygen & Revive Token MUST auto-prompt within 2 seconds of trigger (critical oxygen / PvP death).

## Technical Requirements
- Server-authoritative logic (loot, oxygen, damage, PvP, sales).
- ProfileService for player data and persistence.
- PathfindingService for creature AI.
- Cross-platform input (UserInputService / ContextActionService).
- Target capacity: 20-30 concurrent players per server.