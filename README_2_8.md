# LazyG 2.8 — English catalog from supplied list

- Imported **438** distinct English names across all 9 classes from the user-provided WoW_Forever_Abilities(1).txt.
- Added **341** previously missing English entries; retained earlier RU catalog and curated pairs.
- Existing flag PNG buttons and RU/EN interface from 2.7 retained.
- English ability autocomplete uses English names; Russian autocomplete uses Russian names.
- English entries without reliably paired Russian equivalents are independent entries; no speculative translation or Spell ID assigned.
- Source does not distinguish passive talents, active talents or trainer abilities, and does not contain Spell IDs. Do not claim that it is a verified complete client extraction.
- Saved abilities are free text and do not automatically translate after switching UI language.
- No changes to G Hub driver or pixel detection.

## English source counts

- Воин: 43
- Паладин: 47
- Охотник: 48
- Разбойник: 34
- Жрец: 55
- Шаман: 49
- Маг: 58
- Чернокнижник: 48
- Друид: 56

## Build
`dotnet build LazyG.csproj -c Release`
