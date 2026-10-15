---

### 5. `DECISIONS.md`
```markdown
# Architectural Decisions Log

### ADR 001: Data Persistence Library
- **Decision:** Use **ProfileService** over standard DataStore2 or manual DataStore.
- **Why:** ProfileService provides rock-solid session-locking out of the box, preventing item/pearl duplication bugs across servers. Essential for tradeable items and paid developer products later.

### ADR 002: Oxygen Drain Authoritativeness
- **Decision:** Server calculates water submergence and oxygen depletion tick; Client provides smooth visual lerp.
- **Why:** Prevents exploiters from disabling oxygen drain locally to stay underwater indefinitely.

### ADR 003: Milestone 1 Scope Isolation
- **Decision:** Exclude all Zone 2-5 assets, PvP mechanics, combat abilities, and prestige systems from Milestone 1 code.
- **Why:** Keeps the codebase clean for demo evaluation by client Lemar Bentley. Everything built for M1 must remain 100% reusable in M2/M3 without refactoring.