LazyG 0.8.18 TEST — GCD border progress

Changes in Setup.lua only:
- Rotation icon rim is green when GCD is not active.
- When GCD has readable timestamps, the rim becomes dark and red fills its
  perimeter clockwise: top, right, bottom, left. Completion returns it to green.
- If WoW Forever protects GCD timing, a solid red border indicates active GCD;
  the existing native Blizzard cooldown frame remains responsible for exact timing.
  No fake progress or arithmetic on secret values is attempted.
- Red progress is outside the icon, avoiding extra overlays on RGB sampling area.
- In icon calibration mode, the rim is green and progress disabled.

Not changed: Sonah / MaxDPS / Hekili adapters, traffic light, healpot, minimap,
keyboard controls, frame sizing and position.

Testing in WoW Forever required. Lua parse check only; no live game test.
Previous archive 0.8.17 can be used for rollback.
