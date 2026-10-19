# Known Issues & Technical Debt

### High Priority (Integration Hooks to Complete)
1. **Loot Magnet Dev Product Not Applied in Spawner:**
   - *Issue:* `MonetizationServer` sets attribute `LootMagnetActive = true` on the player character, but `LootServer.server.luau` maintains a fixed `MAX_COLLECT_DISTANCE = 18` and never checks the attribute.
   - *Fix:* Multiply `MAX_COLLECT_DISTANCE` and ProximityPrompt reach by 2 in `LootServer` when `char:GetAttribute("LootMagnetActive") == true`.

2. **Guaranteed Rare Dev Product Not Consumed:**
   - *Issue:* `MonetizationServer` sets `player:SetAttribute("GuaranteedRare", true)`, but loot items are rolled when the spawn node is populated rather than when the player interacts with it.
   - *Fix:* Re-roll or upgrade the item to Rare+ inside `LootServer` upon prompt trigger if the player has `GuaranteedRare` active, then clear the attribute.

3. **PvP Death Bag Drop & Revive Token Hook Missing:**
   - *Issue:* `ServerInit.server.luau` handles PvP weapon damage, but when a player dies in PvP, their inventory is not dropped onto the seafloor, and `LastDroppedLoot` is not saved. Consequently, `ReviveToken` has no dropped bag to restore.
   - *Fix:* Add a `Humanoid.Died` listener in `ServerInit` for PvP players: copy their bag to `LastDroppedLoot`, spawn a physical loot bag part in `Workspace.ActiveLoot`, and clear their inventory.

4. **Revive Token Client Auto-Prompt Missing:**
   - *Issue:* UX specification requires Revive Token to auto-prompt within 2 seconds of PvP death. `UIController.client.luau` currently only features `AutoOxygenPrompt`.
   - *Fix:* Create and tween `AutoRevivePrompt` in `UIController` when defeated in PvP.

---

### Low Priority / Cosmetic
5. **Script File Naming Typo:**
   - *Issue:* `src/ServerScriptService/Core/SellSever.server.luau` is spelled without the second 'r'.
   - *Fix:* Rename file to `SellServer.server.luau` in repository and filesystem.

6. **Documentation File Naming Typo:**
   - *Issue:* `docs/CURRENT_TAST.md` has a typo in the repo name.
   - *Fix:* Rename to `docs/CURRENT_TASK.md`.