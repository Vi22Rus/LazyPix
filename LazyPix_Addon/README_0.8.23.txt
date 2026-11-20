LazyG 0.8.23 TEST — Player spellbook editor

- Editor spell list now comes from C_SpellBook (player bank) rather than Sonah, MaxDPS, or Hekili.
- Includes active learned spells from general/class/spec pages (including racial actives).
- Excludes passives, future spells, pet spells, profession pages, off-spec entries, and duplicate SpellIDs.
- The editor can now open with no rotation addon active.
- A saved editor index is shared across rotation sources; previous source-specific saved indices are left untouched.
- Live recommendations still use the existing Sonah, MaxDPS and Hekili adapters.
- Setup.lua is the only Lua file changed. HealthWidget.lua is unchanged.
- Learned active spells inside flyout groups are included when the flyout APIs are available.
- Requires in-game testing on WoW Forever.
