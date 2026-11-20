LazyG 0.8.22 TEST — Casting/Channeling dimming

- Recommended ability icon dims while the player casts a non-instant spell or channels.
- Uses player-only UNIT_SPELLCAST_START/STOP/FAILED/FAILED_QUIET/INTERRUPTED and CHANNEL_START/STOP events, no protected cast-time arithmetic.
- Existing 1.5-second cosmetic red GCD perimeter, regular CD and range checks unchanged.
- Setup/preview stays bright.
- HealthWidget.lua unchanged.
- Game test required: normal cast, interrupted cast, canceled cast, channeled spell, editor preview.
