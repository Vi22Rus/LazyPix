LazyG 0.8.25 TEST — JustAC integration

Added JustAC / JustAssistedCombat as a fourth rotation recommendation source.
The adapter reads the actual displayed first action from JustAC.spellIcons[1]
without invoking JustAC SpellQueue or recalculating rotations.

Selection: /lazyg source justac
Automatic selection: /lazyg source auto
Priority (when multiple addons are active): Sonah, MaxDPS, Hekili, JustAC.

JustAC support in this test uses its standard visible queue display.
If its main queue is hidden or using another display mode, LazyG hides its
recommendation; alternative nameplate-overlay-only display is not yet supported.
WAIT placeholders are ignored. Macro images can be shown without a SpellID.

The preview still reads active non-passive spells from the player spellbook.
HealthWidget.lua and the other adapters are unchanged.

Static source review only. Requires in-game validation on WoW Forever.
