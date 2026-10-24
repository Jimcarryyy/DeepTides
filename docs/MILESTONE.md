# Milestones & Delivery Tracker

## Phase 1: Gameplay Foundation ($620 AUD) — COMPLETED
| Milestone | Deliverables | Budget (AUD) | Codebase Status | Approval Status |
|---|---|---|---|---|
| **Milestone 1** | **Playable Core Demo:** Atoll Dock, Zone 1 Shallow Reef, Oxygen system, Bag collection, Dock sell station, Pearls UI, ProfileService save | $186 | **100% Complete** | **Approved** |
| **Milestone 2** | **Expanded Gameplay:** Zones 2 & 3 (Kelp Forest, Shipwreck), 5-Tier Gear Upgrade Shop, Creature AI (Jellyfish, Eel, Shark), Tool combat | $217 | **100% Complete** | **Approved** |
| **Milestone 3** | **Endgame & Monetisation:** Zones 4 & 5 (Abyss, Cursed Deep), World Boss (The Leviathan), Treasure Vault, Opt-in PvP system, Prestige system, Full Monetisation engine | $217 | **100% Complete** | **Approved** |

---

## Phase 2: Commercial Polish & Launch ($660 AUD) — ACTIVE
| Milestone | Deliverables | Budget (AUD) | Target / Trigger | Status |
|---|---|---|---|---|
| **Milestone A** | **Custom 3D Models & Main Props:** All creatures, 5 tools, 12 loot items, surface hub, 4 docks, 5-zone props, chests, pitwalls | **$198** | Client approval of custom 3D assets | **APPROVED** (Paid via Wise) |
| **Milestone B** | **UI/UX, VFX & Audio Polish:** Full UI redesign across all screens, zone-based water VFX & lighting, complete sound design | **$264** | Client approval of UI, VFX, and audio | **ACTIVE (In Progress)** |
| **Milestone C** | **Live Robux & Launch Readiness:** Production product IDs, receipt validation, 2s auto-prompts, mobile/console QA, public release | **$198** | Full game polished and launch-ready | **PENDING** |

---

## Milestone Acceptance Criteria

### Phase 2 Milestone A Acceptance (VERIFIED & APPROVED)
- [x] Custom 3D models for all 5 creatures integrated in `ReplicatedStorage.CreatureModels`.
- [x] Surface Hub complete: 2-tone studded grass, 18-stud timber walls, 4 lagoon boardwalk docks, reskinned shops, custom 3D Prestige Shrine, custom 3D PvP Station, surface props & sand patches.
- [x] PitWalls across all 5 zones (Y = 2 to -600 studs) upgraded with solid zone colors and 3D bumpy studs.
- [x] Unique environment props active in all 5 depth zones (Corals, Giant Kelp, Sunken Galleon, Smoker Vents, Leviathan Ribcage & Horned Skull).
- [x] Both world chests (Barnacled Treasure Chest and Floating PvP Loot Chest) rebuilt with zero Z-fighting.
- [x] All 12 collectible loot models integrated in `ReplicatedStorage.LootModels` and verified on spawn nodes.
- [x] All 5 diving tools upgraded with custom 3D Meshy meshes in `ReplicatedStorage.Tools`, hand-scaled, and welded.
- [x] Client review exhibition gallery (`Workspace.Client_MilestoneA_Showcase`) reviewed and approved by Lemar Bentley.

### Phase 2 Milestone B Acceptance Criteria (CURRENT FOCUS)
- [x] Complete UI/UX redesign across all screens matching *Grow a Garden* clean style (rounded corners, smooth spring animations, clean typography).
- [x] 2D Studded UI style implemented for HUD pills, Oxygen meter, Action Bar, and Shop/Prestige/Store modals.
- [x] Custom 2D icons created and integrated for all 5 gear categories in the Gear Shop modal.
- [ ] Responsive UI layout tested on PC, Mobile, Tablet, and Console gamepad navigation.
- [ ] Underwater lighting and water color transitions tuned per zone (Shallow Reef cyan ➔ Kelp emerald ➔ Shipwreck navy ➔ Abyss violet ➔ Cursed Deep magma).
- [ ] Environmental particle VFX active (bubble trails, silt drift, volcanic embers, eel sparks, pressure vignette).
- [ ] Complete sound design polish (zone-based BGM, muffled underwater audio, collection chimes, cash register SFX, creature audio, UI clicks).

### Phase 2 Milestone C Acceptance Criteria (UPCOMING)
- [ ] Live numeric Robux Game Pass IDs (Deep Diver 199, Treasure Hunter 499, Leviathan Pass 999) and Dev Product IDs integrated in `MonetizationConfig.luau` with `TEST_MODE = false`.
- [ ] Server receipt validation active with MarketplaceService.
- [ ] 2-second automatic popup triggers verified for Emergency Oxygen (critical O2) and Revive Token (PvP defeat).
- [ ] Performance audit: solid 60 FPS verified with 20–30 CCU on PC, Mobile, and Console.
- [ ] Full bug sweep, memory audit, clean code handover to client.