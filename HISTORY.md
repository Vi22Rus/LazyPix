# LazyPix — единая история исходного проекта

> Архивный журнал. Собран 20 ноября 2026 года из **10 файлов README**, ранее находившихся в корне репозитория. Все оригинальные записи сохранены **дословно** с указанием исходного имени файла. Старое имя программы **LazyG** внутри исторических записей оставлено намеренно — именно так оно называлось во время соответствующих изменений.

## Как пользоваться этим файлом

Это история изменений старой Windows-программы, ныне **LazyPix**. Она описывает заявленные изменения, но **не подтверждает** успешную сборку или работоспособность конкретной функции. Исторические команды с `LazyG.csproj` и `LazyG.exe` не являются инструкцией к современной сборке; перед выполнением нужно проверить актуальное имя проекта и `.csproj`.

**Текущее состояние на момент консолидации:** в GitHub обнаружены исходники WPF, файлы C#, ресурсы и каталоги; изменения в них в рамках этой операции **не выполнялись**. Компиляция и запуск Windows-программы этой операцией **не проверялись**. Не путать LazyPix с отдельным репозиторием LazyG и его RGB-ядром.

## Содержание

| Версия / этап | Исходный документ | Основная тема |
| --- | --- | --- |
| 2.2 | README.md | Тёмная тема, редакторы, глобальные горячие клавиши |
| 2.3 | README_2_3.md | Девять иконок классов и интерфейс |
| 2.6 | README_LOCALIZATION.md | Локализация RU/EN |
| 2.7 | README_2_7.md | Флаги и двуязычный каталог |
| 2.8 | README_2_8.md | 438 английских названий |
| 2.9–2.10 | README_PALADIN_ICONS.md | Иконки паладина и EN-псевдонимы |
| 2.11 | README_2_11.md | 27 иконок специализаций |
| 2.12 | README_2_12_FIX.md | Исправление WPF Resource |
| 2.14 | README_2_14.md | 438 записей и 347 иконок |
| 2.15 | README_2_15.md | Двуязычный каталог и поиск |

## Оригинальные записи (без редактирования)

---

### Источник: `README.md`

# LazyG 2.2 — исправления по результатам проверки

Исходники WPF на .NET 10. В среде подготовки нет Windows/.NET SDK, поэтому компиляция и запуск не проверены. **Не заменяйте проверенный EXE до успешной сборки и проверки.**

## Изменения
- Поля ComboBox и подсказки приведены к тёмной теме.
- Все собственные окна подтверждения, уведомления и редакторы используют тёмную тему; окно переименования увеличено, чтобы кнопка помещалась.
- Подсказки кнопок сделаны контрастными.
- Панель классов выровнена влево.
- Режимы повтора обозначены крупными ⟳ и ①.
- Редактор способности: поиск по **неполному стартовому словарю** заклинаний по классу, возможность свободного ввода; Ctrl/Shift отдельными галочками; дополнительная задержка новой способности 200 мс.
- Добавлена регистрация **глобальных** горячих клавиш Windows (RegisterHotKey), включая F6 при активном окне игры, с настройкой комбинаций через кнопку «Горячие клавиши». Если комбинация занята другим приложением, будет предупреждение. В некоторых полноэкранных режимах/при запуске игры от администратора возможны ограничения.
- Основная логика распознавания и драйверная интеграция оставлены без изменений.

## Пока не реализовано
- Полный проверенный каталог всех заклинаний Forever и соответствующие игровые иконки: текущие подсказки охватывают лишь распространённые способности. Нельзя считать список полным.
- Новые графические ассеты для классов и способностей (требуется отдельная проверка лицензий и сопоставления имен).
- Проверка сборки на Windows.

## Сборка
В распакованной папке выполнить:
`dotnet build LazyG.csproj -c Release`

После успешной сборки:
`dotnet publish LazyG.csproj -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true -p:DebugType=None -p:DebugSymbols=false`

Перед тестированием сделайте резервную копию `%LOCALAPPDATA%\WoWForeverAssistant\profiles.json`.


---

### Источник: `README_2_3.md`

# LazyG 2.3 — исправления интерфейса и иконки классов

Основа: исходный архив LazyG 2.2 из чата. Встроены **ровно девять JPG, предоставленных пользователем**. Иконки встроены в WPF Resources и доступны без сети.

## Изменения
- Устранены старые неоднозначности компилятора `Brushes` / `PixelFormat`.
- Новый шаблон `ComboBox` и `ComboBoxItem` (тёмный фон в закрытом поле, в выпадающем списке, при наведении и выборе).
- Панель классов: одинаковые круглые иконки 46×46, фиксированная левая колонка, длинные названия с подсказкой.
- Расширены колонки и место под действия способностей; фиксированные кнопки 38×38.
- Панель запуска/паузы/стопа/теста/горячих клавиш переносится на следующую строку вместо обрезки.
- Окна создания/переименования/подтверждения увеличены; уведомления в основном окне заменены на стилизованные диалоги.
- Логика распознавания пикселей, G Hub и горячих клавиш не менялась.

## Проверка на Windows
1. `dotnet build LazyG.csproj -c Release`
2. `dotnet publish LazyG.csproj -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true -p:DebugType=None -p:DebugSymbols=false`
3. Проверить все 9 классов, выпадающий список специализаций (первая/вторая/третья позиции и наведение), кнопки при минимальном размере окна, попап переименования и Test Win.

**Ограничение:** в текущей Linux-среде отсутствует Windows/.NET SDK, поэтому компиляция и запуск WPF не проверены. XML-файлы проверены на корректность структуры. Не заменяйте рабочий EXE до успешной проверки.


---

### Источник: `README_LOCALIZATION.md`

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


---

### Источник: `README_2_7.md`

# LazyG 2.7 — флаги и каталог способностей RU/EN

- В кнопках RU/EN вместо emoji и буквенных кодов флагов используются встроенные PNG (российский и британский).
- Встроенный `Data/spells_ru_en.json`: русский список из предоставленного TXT и частично сопоставленные английские названия.
- Автоподсказки в редакторе способностей используют язык интерфейса при открытии редактора.
- Английский TXT является индексом источников, а не полным каталогом: поэтому английские подсказки пока неполные. Неизвестные переводы намеренно не выдумываются.
- Выбранное название сохраняется как пользовательский текст, при смене языка уже сохранённая способность автоматически не переименовывается.
- Драйвер, сканирование пикселей и горячие клавиши не изменены.

## Сборка
`dotnet build LazyG.csproj -c Release`

## Публикация
`dotnet publish LazyG.csproj -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true -p:DebugType=None -p:DebugSymbols=false`


---

### Источник: `README_2_8.md`

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


---

### Источник: `README_PALADIN_ICONS.md`

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


---

### Источник: `README_2_11.md`

# LazyG 2.11 — иконки специализаций (27)

Основа: исходники LazyG 2.10 с иконками паладина на RU/EN.

Из пользовательского архива BUIKD.7z взяты все 27 BMP. Они преобразованы в PNG и встроены в приложение.

Для каждого из 9 классов сопоставлены 3 специализации. Значок определяется **классом и сохранённым полем Specialization**, а не пользовательским названием ротации. Например: Маг → Frost → `spell_frost_frostbolt02.png`, даже если пользователь назвал ротацию «Frost Fire».

Значки отображаются:
- в раскрывающемся списке выбора специализации при создании ротации;
- в списке сохранённых ротаций слева;
- рядом с заголовком выбранной ротации в центральной области.

Привязка не зависит от языка интерфейса. Существующие профили используют сохранённую специализацию, иконки у них тоже должны появиться. Данные профилей не изменяются.

Сборка на Windows из корня проекта:
`dotnet publish -c Release -r win-x64 --self-contained true /p:PublishSingleFile=true`

EXE: `bin\Release\net10.0-windows\win-x64\publish\LazyG.exe`

Сборка и запуск в Windows не проверены: в среде отсутствует .NET SDK.


---

### Источник: `README_2_12_FIX.md`

LazyG 2.12: исправлено включение 27 иконок специализаций в WPF Resource при сборке. Иконки привязаны к классу и Specialization, а не к пользовательскому имени. Сборка: dotnet publish -c Release -r win-x64 --self-contained true /p:PublishSingleFile=true. На Windows сборка не проверена.


---

### Источник: `README_2_14.md`

# LazyG 2.14 — WoW Forever spell catalog and icons

- Replaced the previous built-in spell list with all 438 entries from `spell_icon_map.csv` (9 classes).
- Imported all 347 unique WEBP images from `icons.7z` and converted them to PNG resources for WPF. Every CSV row maps to an available icon.
- Ability names are kept exactly as supplied in CSV (English) for both UI language modes. The CSV contains no Russian translations; UI controls can still switch languages.
- Existing saved rotations are not deleted, but any abilities with names absent from the new catalog will display a fallback icon until reassigned.
- Healbot, hotkeys, traffic logic and localization UI were not modified.

Build: `dotnet run -c Release` from the project directory (Windows, .NET 10 SDK). This archive is source code; compilation on Windows is not verified here.


---

### Источник: `README_2_15.md`

# LazyG 2.15 — двуязычный каталог способностей

- 438 записей из пользовательского `spell_icon_map.csv` сопоставлены с русскими вариантами названий; SpellID и иконки не изменены.
- При выборе RU в подсказках и списке ротации показываются русские названия, при EN — английские.
- Поиск подсказок работает по русским и английским названиям.
- В профилях сохраняется исходное английское название, чтобы переключение языка не нарушало связи с иконками.
- Исправлено включение ресурсов PNG всех классов в WPF-проекте.

**Ограничение:** перевод выполнен вручную; русские названия уникальных способностей WoW Forever и отдельных заклинаний могут отличаться от официальной локализации клиента. Для точного соответствия требуется русскоязычная база Forever со SpellID. Существующие произвольные названия сохраняются без перевода.

Сборка: `dotnet run -c Release` из папки с `LazyG.csproj` (Windows, .NET 10 SDK).

---

## Журнал консолидации — 2026-11-20

**Запрос пользователя:** собрать историю README в один файл и удалить лишние README, не затрагивая системные файлы приложения.

**Решение:** все десять README перенесены в этот документ дословно и в хронологическом порядке версий; исходные десять README удаляются из корня. История доступна также через Git-историю коммита.

**Проверка:** содержимое десяти файлов прочитано через GitHub; новая запись содержит каждый исходный текст. **Изменения исходников C#, XAML, изображений и конфигурации сборки не производились.**

**Сборка/тест пользователя:** не проводились. **Следующий шаг:** отдельно проверить актуальный проект и настроить DEV-сборку по прямому запросу пользователя.
