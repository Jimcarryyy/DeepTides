# Deep Tides — Project Context

## Project Overview
- **Game:** Deep Tides (Ocean diving simulator with optional PvP)
- **Tagline:** "Dive deep. Find rare. Get home alive."
- **Platforms:** PC, Mobile, Console (Cross-platform controls active)
- **Client:** Lemar Bentley (Confidential)
- **Publishing Account:** DeepTidesDev
- **Initial Contract:** $620 AUD across 3 Milestones (M1: $186, M2: $217, M3: $217)
- **Visual References:** *Steal an Egg* (UI, creatures), *Catch and Tame* (environment), *Grow a Garden* (UI cleanliness).

---

## Core Gameplay Loop
1. **Dive:** Enter ocean waters from the Atoll Dock. Monitor oxygen level and dive depth.
2. **Discover:** Traverse through 5 distinct depth zones down to -600 studs.
3. **Collect:** Loot procedural drops into your Loot Bag (limited by bag capacity).
4. **Survive:** Dodge hostile wildlife (Jellyfish, Electric Eels, Sharks, Octopus, Leviathan) and hostile players in PvP mode.
5. **Sell & Bank:** Return to the surface DockArea to sell loot for Pearls.
6. **Upgrade & Prestige:** Purchase higher gear tiers at the Gear Shop or sacrifice maxed gear at the Prestige Shrine for permanent account buffs.

---

## Depth Zones (`ZoneConfig.luau`)
| Zone | Name | Depth Range (Studs) | Suit Req. | Hazard / Danger | Creature | Water Color |
|---|---|---|---|---|---|---|
| **1** | Shallow Reef | `0.5` to `-60` | Tier 1 | Low (0 crush dmg) | Jellyfish | `36, 175, 215` |
| **2** | Kelp Forest | `-60` to `-140` | Tier 2 | Medium (8 crush dmg/sec) | Electric Eel | `24, 140, 150` |
| **3** | Sunken Shipwreck | `-140` to `-240` | Tier 3 | High (18 crush dmg/sec) | Hammerhead Shark | `12, 65, 110` |
| **4** | The Abyss | `-240` to `-400` | Tier 4 | Very High (30 crush dmg/sec) | Giant Octopus | `8, 25, 60` |
| **5** | The Cursed Deep | `-400` to `-600` | Tier 5 | Extreme (50 crush dmg/sec) | The Leviathan (Boss) | `15, 8, 25` |

---

## Gear Catalog (`GearConfig.luau`)
Each category features 5 upgrade tiers:
- **Oxygen Tanks:**
  - T1: Rusty Tank (30s air, 0 ⚪)
  - T2: Standard Tank (60s air, 500 ⚪)
  - T3: Reinforced Tank (120s air, 1,500 ⚪)
  - T4: Abyssal Hyper-Tank (240s air, 4,000 ⚪)
  - T5: Leviathan Core Tank (480s air, 10,000 ⚪)
- **Loot Bags:**
  - T1: Pouch (5 slots, 0 ⚪)
  - T2: Canvas Duffle (10 slots, 300 ⚪)
  - T3: Explorer Hauler (20 slots, 1,000 ⚪)
  - T4: Abyssal Cargo Crate (35 slots, 2,500 ⚪)
  - T5: Vault of the Deep (50 slots, 6,000 ⚪)
- **Speed Fins:**
  - T1: Bare Feet (1.0x speed, 0 ⚪)
  - T2: Rubber Flippers (1.35x speed, 600 ⚪)
  - T3: Hydrofoil Blades (1.70x speed, 1,800 ⚪)
  - T4: Abyssal Jet-Fins (2.10x speed, 4,500 ⚪)
  - T5: Leviathan Gliders (2.50x speed, 9,000 ⚪)
- **Diving Suits:**
  - T1: Wetsuit (Safe to -60 studs, Perk: None, 0 ⚪)
  - T2: Kelp Diver Suit (Safe to -140 studs, Perk: Speed Surge +150% speed, 1,000 ⚪)
  - T3: Armored Abyss Suit (Safe to -240 studs, Perk: Iron Skin 60% Shield, 3,000 ⚪)
  - T4: Thermal Trench Suit (Safe to -400 studs, Perk: Thermal Barrier 70% Shield, 7,000 ⚪)
  - T5: Cursed Leviathan Suit (Safe to -600 studs, Perk: Leviathan Aura 80% Shield + 2x Speed, 15,000 ⚪)
- **Diving Tools:**
  - T1: Rusty Knife (15 dmg, 0.6s cd, 0 ⚪)
  - T2: Steel Spear (30 dmg, 0.75s cd, 400 ⚪)
  - T3: Titanium Harpoon (55 dmg, 0.9s cd, 1,200 ⚪)
  - T4: Obsidian War-Pick (90 dmg, 1.0s cd, 3,000 ⚪)
  - T5: Trident of the Deep (140 dmg, 1.1s cd, 7,500 ⚪)

---

## Prestige System (`PlayerDataManager.luau`)
- **Requirement:** All 5 gear items maxed to Tier 5 + 50,000 Pearls.
- **Max Rank:** 10 (Rank I to Rank X).
- **Reset:** All gear resets to Tier 1, bag is cleared.
- **Permanent Buffs:** +10% Pearl sell value per Prestige rank, +5% swim/walk speed per Prestige rank.
- **Cosmetic:** Overhead clean text tag displaying `PRESTIGE {Roman}`.

---

## Monetisation Suite (`MonetizationConfig.luau`)
- **Game Passes:**
  - `DeepDiver` (199 R$): Permanently doubles max oxygen capacity.
  - `TreasureHunter` (499 R$): +25% Pearl sell value bonus + 1 extra bag slot.
  - `LeviathanPass` (999 R$): Instant Zone 5 pressure immunity without Tier 5 suit prerequisite.
- **Developer Products:**
  - `StarterPack` (99 R$): 500 Pearls + 1 Uncommon drop + 1 Emergency Oxygen.
  - `EmergencyOxygen` (49 R$): Instantly refills oxygen tank to 100% mid-dive.
  - `ReviveToken` (99 R$): Recovers lost bag dropped during PvP defeat within 30-second window.
  - `LootMagnet` (49 R$): 2x collection reach for the current dive.
  - `RareDive` (149 R$): Guarantees Rare+ drop on next pickup.
- **UX Compliance:** Automatic pop-up for Emergency Oxygen triggers within 2s of critical oxygen (<= 8s). Automatic pop-up for Revive Token triggers within 2s of PvP defeat.
- **Studio Support:** `MonetizationConfig.TEST_MODE = true` allows in-Studio purchase testing without spending real Robux.


## Project Overview
- **Game:** Deep Tides (Ocean diving simulator with optional PvP)
- **Tagline:** "Dive deep. Find rare. Get home alive."
- **Platforms:** PC, Mobile, Console (Cross-platform controls active)
- **Client:** Lemar Bentley (Confidential)
- **Publishing Account:** DeepTidesDev
- **Phase 1 Contract:** $620 AUD across 3 Milestones (Completed & Approved)
- **Phase 2 Contract (Active):** $660 AUD across 3 Milestones (M-A: $198 [Approved], M-B: $264 [Active], M-C: $198 [Pending])
- **Visual References:** *Steal an Egg* (assets, creatures, proportions) & *Grow a Garden* (UI cleanliness, environment quality).
- **Strict Scope Exclusion:** Thumbnail artwork is 100% excluded.