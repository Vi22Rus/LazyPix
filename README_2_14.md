# LazyG 2.14 — WoW Forever spell catalog and icons

- Replaced the previous built-in spell list with all 438 entries from `spell_icon_map.csv` (9 classes).
- Imported all 347 unique WEBP images from `icons.7z` and converted them to PNG resources for WPF. Every CSV row maps to an available icon.
- Ability names are kept exactly as supplied in CSV (English) for both UI language modes. The CSV contains no Russian translations; UI controls can still switch languages.
- Existing saved rotations are not deleted, but any abilities with names absent from the new catalog will display a fallback icon until reassigned.
- Healbot, hotkeys, traffic logic and localization UI were not modified.

Build: `dotnet run -c Release` from the project directory (Windows, .NET 10 SDK). This archive is source code; compilation on Windows is not verified here.
