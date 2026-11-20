LazyG 0.8.8 TEST — idle-frame visibility fix

- Outside preview mode, the rotation frame is hidden when the selected engine has no recommended icon.
- The frame appears when a recommendation arrives.
- In preview/setup mode, the same frame is always shown with the selected spell.
- Exiting setup restores the live recommendation or hides the frame if none exists.
- Sonah, MaxDPS, Hekili adapters and HealthWidget.lua are unchanged.

TEST build: verify in WoW Forever, including combat and secret texture values.
