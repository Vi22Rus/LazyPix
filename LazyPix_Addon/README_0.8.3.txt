LazyG 0.8.3 TEST - MaxDPS mode

- Sonah remains optional. LazyG traffic light and health potion widget work independently.
- /lazyg maxdps selects MaxDPS native MaxDpsSpellFrame as the rotation indicator.
- /lazyg on uses Sonah preview if available; when Sonah is absent and MaxDPS is loaded, it selects MaxDPS.
- /lazyg off leaves MaxDPS running; restores its spellFrame.enabled setting if LazyG changed it.
- No changes to MaxDps or MaxDps_Hunter are required.
- MaxDPS owns its frame visibility and its actual recommended spell; it will not display an icon if MaxDPS rotation is inactive.
- No in-game test performed. Test outside combat; then confirm abilities update in combat.
