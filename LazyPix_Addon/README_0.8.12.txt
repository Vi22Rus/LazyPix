LazyG 0.8.12 TEST — visual cooldown and range indicators

Based on LazyG 0.8.11 TEST.

- Recommended spell icon greys out for a readable global cooldown, independent spell cooldown, or out-of-range result.
- A bright short segment travels around the frame perimeter during a readable global cooldown.
- For secret GCD timings, the standard WoW cooldown edge is used where possible, without manipulating protected numbers in Lua.
- No effect is applied in icon-preview/editing mode; existing saved positions, sizes, source adapters, health widget and traffic light are retained.
- When the source does not supply a public numeric SpellID or combat API values are secret, spell-specific CD/range state may be unavailable. Unavailable range (nil) does not mean out of range.

IMPORTANT: Desaturation changes the actual onscreen RGB colors. Existing Windows LazyG ability-pixel samples may no longer match during GCD, cooldown, or out-of-range. Verify pixel detection before normal use.

Tests: Lua syntax verified with texlua. Gameplay behavior and Secret Values handling require testing in WoW Forever.
