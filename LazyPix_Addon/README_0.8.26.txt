LazyG 0.8.26 TEST — RotationMaster adapter

Added RotationMaster 2.1.1 as a fifth passive recommendation source.
The adapter reads the first live recommendation from
RotationMaster.nextWindow.icons[1], without evaluating its rotation.
Requires Rotation Master's "Preview Spells" display to be enabled.
Sample/empty recommendations are ignored. Item icons are forwarded, but
item IDs are not treated as spell IDs for cooldown or range checks.
Some gated overlay effects in RotationMaster may render separately from
its base texture and are not replicated by this adapter.

Commands: /lazyg source rotationmaster ; /lazyg source auto ; /lazyg help
Automatic priority: Sonah > MaxDPS > Hekili > JustAC > RotationMaster.

Editor still reads the player's spellbook; HealthWidget.lua unchanged.
Static source verification only. Test in WoW Forever before approving.
