# LazyG 2.9 — иконки паладина

Основа: LazyG 2.8 RU/EN Complete Source.

Добавлены 46 PNG из предоставленного PALADIN.7z (BMP 64×64).
47 русских названий способностей связаны с изображениями из списка пользователя; две способности используют один и тот же файл.

Иконки отображаются:
- в основном списке способностей паладина вместо ✦;
- в выпадающих подсказках при вводе названия способности.

При ручном вводе названия, отсутствующего в таблице, остаётся символ ✦. Иконки других классов пока не изменены.
Имена способности должны совпадать с русским каталогом; в английском режиме сопоставление по EN-названию пока не предусмотрено.

Сборка на Windows с .NET 10 SDK:
dotnet publish -c Release -r win-x64 --self-contained true /p:PublishSingleFile=true

Итоговый EXE: bin\Release\net10.0-windows\win-x64\publish\LazyG.exe

В текущей среде нет Windows/.NET SDK; сборка и запуск не проверены.

## 2.10: EN icons fix

- English names are resolved through the embedded RU/EN spell catalog to the canonical Russian spell name.
- The same PNG is used for RU and EN in both the ability list and the add-ability suggestions.
- No invented translations: an EN name missing from the bilingual catalog cannot be matched automatically.
- Existing rotations with either language name use the same icon when the pair is present.

## 2.10 bilingual mappings
Added 30 EN aliases for RU abilities with icons. English names are linked to the same PNG through the catalog. Some labels are provisional and should be verified against WoW Forever.
