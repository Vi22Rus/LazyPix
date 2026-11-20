LazyG 0.8.9 TEST — Hekili display synchronization fix

- Read the currently shown Hekili Primary/AOE first icon from its original UI, including overrides.
- Fallback to already published output when no visible Hekili icon is available.
- Listen for both Primary and AOE output changes.
- Refresh Hekili every 0.2 s from existing UI/output, without asking Hekili to calculate a rotation.
- Sonah, MaxDPS, Healbot and traffic light logic remain unchanged.

TEST in WoW Forever: verify displayed icons change in combat and when switching between Primary/AOE.
