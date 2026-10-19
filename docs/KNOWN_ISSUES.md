# Known Issues & Technical Debt

### Active Technical Bugs
*(None. All gameplay bugs, DataStore errors, status effect speeds, UI overlaps, and network yields have been resolved.)*

---

### Pre-Launch Production Checklist (For Final Publishing)
1. **Live Robux Product IDs:**
   - In `MonetizationConfig.luau`, the game passes and developer products currently use placeholder IDs (`0`, `1`, `2`, etc.) with `TEST_MODE = true` for Studio testing.
   - Before publishing live for real Robux, create the products on the Roblox Creator Dashboard, paste the live numeric IDs into `MonetizationConfig.luau`, and set `TEST_MODE = false`.

2. **Art & Asset Polish Pass (Contract 2):**
   - The current 3D creature models, dock station parts, tools, and visual effects are functional placeholders and working samples.
   - These will be upgraded to commercial quality under the proposed $660 AUD polish contract.