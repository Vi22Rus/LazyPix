LazyG 0.8.15 TEST — ordinary cooldown detection

Fixed: if C_Spell.GetSpellCooldown returns protected startTime/duration, use its non-secret isActive flag to dim the recommended spell while cooldown is active. Existing public-time GCD/normal-CD distinction stays unchanged.

When times are protected, isActive can also represent GCD; the frame is dimmed but the source of cooldown cannot be distinguished by this fallback.

No changes to adapters, minimap, frame settings, HealthWidget, or existing GCD border indicator.

Test in WoW Forever: ordinary cooldown (especially while in combat), GCD, editor icon brightness, hiding frame without recommendation, and Lua errors.
