LazyG 0.8.16 TEST — GCD border and Blizzard duration support

Based on 0.8.15. Changes confined to Setup.lua and TOC.
- Persistent gold hollow border and subtle outer glow around the rotation frame.
- For public GCD timing: gold moving segment along the exterior perimeter.
- For secret GCD timing: native Blizzard Cooldown with DurationObject.
  This native fallback is a radial cooldown, NOT a square perimeter snake.
- When editor is active no GCD graphics are drawn; icon is color-correct.
- Existing CD/range dimming, Sonah, MaxDPS, Hekili, HP and traffic light untouched.

Test in WoW Forever especially combat/Secret Values and RGB recognition.
