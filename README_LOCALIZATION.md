# LazyG 2.6 — multilingual UI (RU / EN)

Based on LazyG 2.4, without importing the RU spell database. The rotation recognition, pixel matching, profiles, and G Hub driver code are retained.

## What's included
- RU and EN buttons directly beside the LazyG title, with a ~36 px gap.
- Localized main window, class names, action tooltips, status, settings, prompts, and ability editor.
- New log messages are localized. Existing historical log lines are intentionally not rewritten.
- Language persists at `%APPDATA%\LazyG\language.txt`.
- Resource files `Localization/ru-RU.json` and `Localization/en-US.json` are embedded into the single-file EXE.
- Future locales can be added as a new embedded JSON resource using the same Russian source-text keys. `L.AvailableLanguages` discovers embedded language packs, `L.Set("fr-FR")` activates them. New buttons / language menu must be added for new locales.
- Spell names saved by the user and user-defined rotation names are not automatically translated. A bilingual Spell ID catalog is a separate future task.

## Build
`dotnet build LazyG.csproj -c Release`

## Publish
`dotnet publish LazyG.csproj -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true -p:DebugType=None -p:DebugSymbols=false`

The project was inspected and its XAML/JSON parsed, but **not compiled on Windows** in this environment. Please send the first build errors, if any, for correction.
