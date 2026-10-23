# Known Issues & Technical Debt

### Active Technical Bugs
*(None. All gameplay bugs, DataStore errors, status effect speeds, UI overlaps, tool welds, and prompt hooks have been resolved.)*

---

### Resolved in Phase 2 Milestone A
- [x] **Prestige & PvP Station Prompts:** Resolved `nil.PrimaryPart` error in `ServerInit` and `UIController`; prompts now connect seamlessly to custom 3D station models.
- [x] **Loot Spawner Model Fallbacks:** Resolved fallback to default blocks by aligning template names to `LootConfig.Id` keys across all 18 spawn nodes.
- [x] **Showcase Weapon Freezing:** Eliminated player character lockup on weapon display by using `Model` classes with `CanTouch = false` instead of anchored `Tool`s.
- [x] **Chests Z-Fighting:** Resolved texture flickering on Barnacled Chest and Floating PvP Chest by staggering geometry with 0.1–0.2 stud clearance offsets and physically layered chains.
- [x] **Lighting & Sun Glare:** Eliminated blinding white glare by tuning `Lighting.Brightness = 1.8`, `ExposureCompensation = -0.2`, `Bloom.Threshold = 1.25`, and clamping all workspace `PointLight`s to 0.7 max brightness.

---

### Phase 2 Production Checklist (Milestones B & C)
1. **Full UI/UX Redesign (Milestone B):**
   - Replace placeholder rectangular frames with 2D studded, rounded panels matching *Grow a Garden* cleanliness.
   - Design custom 2D icons for all 5 gear categories in the Gear Shop modal.
2. **Underwater VFX & Audio Polish (Milestone B):**
   - Implement zone-based fog/water color shifts, particle systems (bubbles, silt, embers), and complete audio soundscape.
3. **Live Robux Product IDs (Milestone C):**
   - In `MonetizationConfig.luau`, replace placeholder IDs with live numeric IDs from the Creator Dashboard and set `TEST_MODE = false`.