LazyG 0.8.10 TEST - independent saved positions

Fixed Setup.lua rotation frame using the same SavedVariables position key as HealthWidget.lua.
Rotation frame now uses SonahRotationSetupDB.rotationPosition. Health widget and traffic light keep existing SonahRotationSetupDB.position unchanged.
The rotation frame may return to its default position once after upgrading; move it with Shift + left drag to save a separate location.
Rotation sources, traffic light behavior, potion indicator and settings are unchanged.
Test in WoW Forever required; not a stable release.
