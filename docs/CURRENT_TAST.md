---

### 3. `docs/CURRENT_TASK.md`

*(Note: Replace `docs/CURRENT_TAST.md` with this file to fix the repo file name typo)*

```markdown
# Current Task: Milestone 1–3 Integration Verification & Bug Fixes

## Goal
Verify all features implemented across Milestones 1 to 3 in Roblox Studio, patch discovered logic gaps in the codebase, and finalize the complete game loop for client sign-off.

---

## Codebase Status: Milestones 1–3 Implemented
- [x] **Milestone 1:** Core loop, Zone 1 Shallow Reef, Oxygen system, Loot Bag collection, Dock selling, ProfileService persistence, Main HUD.
- [x] **Milestone 2:** Zones 2 & 3 (Kelp Forest, Shipwreck), 5-Tier Gear Upgrade Shop, Creature AI (Jellyfish, Eel, Shark), Tool combat.
- [x] **Milestone 3:** Zones 4 & 5 (Abyss, Cursed Deep), World Boss (The Leviathan), Treasure Vault, Opt-in PvP system with suit abilities and dodge dash, Prestige system (10 ranks), Full Monetisation suite with auto-prompts.

---

## Active Tasks / Fixes Required (Based on Code Audit)
- [ ] **Fix 1: Hook Loot Magnet Dev Product in `LootServer.server.luau`**
  - Check `char:GetAttribute("LootMagnetActive")` to double `MAX_COLLECT_DISTANCE` and ProximityPrompt distance.
- [ ] **Fix 2: Hook Guaranteed Rare Drop in `LootServer.server.luau`**
  - Read `player:GetAttribute("GuaranteedRare")` during collection and override rolled item rarity if active.
- [ ] **Fix 3: Complete PvP Loot Bag Drop & Revive Token Hook**
  - In `ServerInit.server.luau`, detect when a PvP player is killed by another player underwater.
  - Drop their loot bag into `Workspace.ActiveLoot`, store `LastDroppedLoot` attribute for the 30s Revive Token window.
- [ ] **Fix 4: Add Auto-Prompt for Revive Token to `UIController.client.luau`**
  - Show 2-second automatic purchase modal upon PvP defeat.
- [ ] **Fix 5: File Rename Cleanup**
  - Rename `src/ServerScriptService/Core/SellSever.server.luau` to `SellServer.server.luau`.
  - Delete obsolete `docs/CURRENT_TAST.md` in favor of `docs/CURRENT_TASK.md`.
- [ ] **Fix 6: End-to-End Studio Smoke Test**
  - Test all 5 zones, boss fight, prestige reset, and purchase simulation in Studio.

---

## What "Done" Looks Like
All 3 milestones fully playable without console warnings or dead attributes, verified in Studio, and ready for client delivery and payout.