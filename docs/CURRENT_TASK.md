---

### 3. `docs/CURRENT_TASK.md`

```markdown
# Current Task: Milestone 1–3 Complete & Client Review

## Goal
Milestones 1 to 3 are fully implemented, debugged, and verified in Roblox Studio. Prepare the demo for client review (Lemar Bentley), confirm milestone sign-off, and establish Contract 2 ($660 AUD) for the final art and polish phase.

---

## Completed Tasks (Milestones 1 to 3)
- [x] **Milestone 1:** Surface dock, Zone 1 Shallow Reef, Oxygen depletion loop, Loot collection, Dock sell station, ProfileService persistence, Main HUD.
- [x] **Milestone 2:** Zones 2 & 3 (Kelp Forest, Shipwreck), 5-Tier Gear Upgrade Shop, Creature AI (Jellyfish, Eel, Shark), Tool combat.
- [x] **Milestone 3:** Zones 4 & 5 (Abyss, Cursed Deep), World Boss (The Leviathan) + Golden Vault, Opt-in PvP system, Suit abilities, Underwater Dodge Dash, Prestige system (Rank X), Full Monetisation suite with 2s automatic prompts.
- [x] **Integration & Bug Fixes:**
  - Connected `LootMagnetActive` attribute for double pickup reach.
  - Connected `GuaranteedRare` drop upgrade and resolved loot pool indexing error.
  - Resolved DataStore serialization failure by sanitizing loot items to clean primitives.
  - Implemented physical seabed loot bag dropping upon PvP defeat.
  - Implemented anti-duplication safeguard for Revive Tokens (`HideRevivePrompt`).
  - Implemented PvE death loot loss so drowning and creature deaths have real stakes.
  - Created pre-built `AutoRevivePrompt` in `StarterGui.MainHUD` with uniform styling.
  - Set `MainHUD.ResetOnSpawn = false` to preserve HUD references across deaths.
  - Shortened Gear Shop modal labels to eliminate button overlap.
  - Gated the Leviathan boss bar to Zone 5 (`Y <= -400 studs`).
  - Added Prestige Rank X button lockout.
  - Converted overhead badges (`PVP` and `PRESTIGE X`) to clean, text-only floating tags.
  - Fixed Electric Eel and Giant Octopus status effects to cleanly restore gear speed via `PlayerDataManager.ResetWalkSpeed()`.

---

## Next Steps
1. **Client Review:** Lemar tests Milestone 3 and signs off on completion.
2. **Milestone 3 Payout:** Release of Milestone 3 payment ($186 AUD).
3. **Setup Contract 2 ($660 AUD):** Final commercial polish contract covering custom 3D models (dock, creatures, tools), UI/UX art overhaul, water VFX, lighting, and audio design.