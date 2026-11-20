LazyG 0.8.24 TEST — Sonah recommendation synchronization

- Sonah is now included in the existing 0.2-second refresh of the current live recommendation, as MaxDPS and Hekili already were.
- This reads Sonah.Engine:Current() only; it does not recalculate or change Sonah rotations.
- Existing RECOMMENDATION listener remains unchanged.
- Fix targets a stale icon in LazyG after changing a Sonah profile without /reload.
- HealthWidget.lua, spellbook preview, visuals, minimap and other adapters were not modified.
- Requires in-game verification.
