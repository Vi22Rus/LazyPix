LazyG 0.8.21 TEST — cosmetic GCD frame progress

- GCD frame visual uses a fixed 1.5-second timer, started by UNIT_SPELLCAST_SUCCEEDED for the player.
- Red border fills clockwise; returns to green after 1.5 seconds.
- Removed GCD 61304 polling, duration objects, and Blizzard cooldown overlay.
- This is a visual approximation, not an accurate GCD measure. Off-GCD casts may also trigger it.
- Existing ordinary cooldown, range, adapters, and health widget unchanged.
- In editor mode GCD animation is disabled.
