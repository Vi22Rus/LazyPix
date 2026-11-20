LazyG 0.8.17 TEST — GCD display correction

Based on 0.8.16, modifies only Setup.lua and TOC.
- Blizzard Cooldown from GetSpellCooldownDuration(61304) is the primary GCD animation.
- Listens to SPELL_UPDATE_COOLDOWN; avoids resetting the animation every 0.1 seconds.
- Perimeter segment remains available only if GCD timing is not secret.
- No GCD animation in icon setup mode.
- Original border and all rotation adapters, traffic light and healbot unchanged.

In WoW Forever test GCD during combat, out of combat, after /reload,
then check that no Blizzard Lua error appears and RGB sampling remains usable.
