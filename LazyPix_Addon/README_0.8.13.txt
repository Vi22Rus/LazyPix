LazyG 0.8.13 TEST — minimap button positioning

- Minimap icon is anchored to the minimap rim (not a fixed top-left offset).
- Hold left mouse button and drag around the minimap rim to reposition.
- Short left/right clicks retain their original editor actions.
- Saved position: SonahRotationSetupDB.minimapAngle (separate from rotationPosition and position).
- Rotation frame, adapters, traffic light and health potion code unchanged.

Testing: drag icon, /reload, relog; check left/right click, and minimap position.
Game testing is required before marking the release stable.
