LazyG 0.8.28 TEST — MaxDPS/Hunter visual timing correction

- Auto Shot (75), Shoot (5019) and Auto Attack (6603) do not restart the decorative 1.5-second rim animation.
- Removed false cooldown dimming from isActive when start/duration are secret or unavailable; this cannot reliably distinguish the shared GCD from a longer ability cooldown.
- Verified standard, readable long cooldowns, range and cast/channel dimming logic is unchanged.
- Other adapters, spellbook preview, minimap, and HealthWidget.lua unchanged.

Test in-game: Hunter MaxDPS Auto Shot over 5+ seconds, cast an ability, confirm one completed rim cycle and icon undims after genuine cooldowns/casts; test a long ordinary cooldown and out-of-range grey state.
