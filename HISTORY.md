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

---

## LP-0001 — 2026-11-20 15:42 (+07:00) — Введение обязательного подробного журнала изменений

**Статус:** документационное правило введено; тестирование Windows не проводилось.

**Период:** начало 2026-11-20 15:42 (+07:00); точное время завершения фиксируется коммитом GitHub.

**Запрос пользователя:** установить обязательное правило для каждого изменения записывать в `HISTORY.md` дату и время, название работы, причину и подробности реализации, затронутые части программы, результаты пользовательских тестов, найденные ошибки и способы предотвращения их повторения. Объяснить, почему ранние записи имеют другой формат.

**Цель и причина:** при переходе в новый чат сохранять полный контекст, включая неудачные решения, фактическую диагностику и проверенные результаты; предотвратить повторение ошибок из-за потери истории.

**Исходное состояние:** проверен `main`: единственный Markdown-файл `HISTORY.md` после консолидации десяти README. Историческая часть содержит записи версий 2.2–2.15 и консолидации, но не требует точного времени и унифицированных полей.

**Диагностика:** до 2026-11-20 15:42 (+07:00) записи велись в исторических README с разной полнотой. Это **особенность старого процесса документирования**, не ошибка программного кода. Не проставлять вымышленные исторические часы и не объявлять неподтверждённые причины установленными.

**План и решение:** в новом `PROJECT_CONTEXT.md` закрепить обязательный порядок чтения документов, единый журнал `HISTORY.md`, перечень полей, правила работы до и после теста, формат связки ошибок с работами и шаблон. Сохранить оригинальные архивные записи без переписывания.

**Затронутые файлы:** новый `PROJECT_CONTEXT.md`; дополнен `HISTORY.md`. Файлы `.cs`, `.xaml`, `.csproj`, иконки и другие ресурсы не изменялись.

**Как реализовано:** прочитаны текущая история и состав `main`; создан контекстный файл с обязательным стандартом и датой его введения; в историю добавлена эта работа как первая запись нового формата.

**Проверки:** актуальные файлы прочитаны через GitHub. Проверка целостности записи и наличия файлов после коммита — через GitHub. Сборка Windows: **НЕ ПРОВЕРЕНО**, поскольку код не изменялся.

**GitHub:** ветка `main`; ссылка на коммит определяется операцией публикации.

**Передача пользователю на тест:** проверка приложения не требуется; пользователь может проверить содержание документов GitHub.

**Обратная связь пользователя:** ожидается, если потребуется корректировка правил.

**Ошибки и предотвращение повторения:** не создавать параллельные журналы, не переписывать историю задним числом и не выдавать отсутствие тестов за успешный результат. Следующие работы должны фиксировать конкретную причину, затронутые файлы, диагностику, тесты и ссылки.

**Следующий шаг:** применять этот формат ко **всем** последующим изменениям LazyPix.

---

# Архив истории Lua-аддона LazyPix — версии 0.7.7–0.8.30

> Источник: оригинальные `LazyPix_Addon/README_*.txt` из GitHub. Перенос выполнен 2026-11-20; **тексты сохранены дословно**, включая историческое название LazyG, различия методов работы и предупреждения о непроверенных функциях. Даты создания каждой старой версии не известны, поэтому время задним числом не выдумывается. Для поиска конкретного изменения используйте номер версии ниже; начиная с 2026-11-20 15:42 +07:00 для новых работ обязателен журнал с точным временем в этом же файле.

## Реальное состояние аддона в репозитории на момент переноса

- Код расположен в `LazyPix_Addon/Setup.lua` и `LazyPix_Addon/HealthWidget.lua`; TOC: `LazyPix_Addon/LazyG.toc`; графические ресурсы: `Circle.tga`, `CircleGreen.tga`, `CircleOrange.tga`, `CircleRed.tga`.
- `LazyG.toc`: `Interface: 16001`, `Version: 0.8.30`, `OptionalDeps: Sonah, MaxDps, Hekili, JustAssistedCombat, RotationMaster`, `SavedVariablesPerCharacter: SonahRotationSetupDB`.
- В текущих исходниках ещё употребляются прежние технические имена `LazyG`, `/lazyg`, `SonahRotationSetupDB`. **Не переименовывать их автоматически**: это может повлиять на загрузку аддона, привычные команды и сохранённые настройки.
- Текущая версия **0.8.30 TEST**; её README отдельно заявляет отсутствие тестирования в WoW Forever. Ни одно описание ниже не является доказательством успешной проверки в клиенте.
- История демонстрирует эволюцию от Sonah-режима к пяти источникам, отдельному предпросмотру книги заклинаний, индикаторам здоровья/предметов, GCD, cooldown/range/cast и косметической рамке. Не смешивать эти алгоритмы с Windows-распознаванием RGB.

## Оригинальные записи аддона по версиям


### LazyPix_Addon/README_0.7.7.txt

LazyG 0.7.7
Shift + right-click the circular traffic light to toggle settings (outside combat).
Regular left click: green; regular right click: orange.
No other behavior changed from 0.7.6.


### LazyPix_Addon/README_0.7.8.txt

LazyG 0.7.8
- Combat movement: PLAYER_STARTED_MOVING / PLAYER_STOPPED_MOVING events, no secret GetUnitSpeed comparison.
- Secret health: native StatusBar dark overlay, proportional to health; NOT an exact 10% binary cutoff in combat.
- Outside combat with readable health: exact configured HP cutoff.
- Existing click, traffic modes and Shift+Right Click retained.
- If status bar cannot accept secret values, fallback remains grey.


### LazyPix_Addon/README_0.7.9.txt

LazyG 0.7.9: status now reports actual standing state used by the circle, event counter, safe speed and HP availability. Ensures health overlay is above icon. No guarantee of exact 10% cutoff with secret HP.


### LazyPix_Addon/README_0.8.0.txt

LazyG 0.8.0: HP threshold uses native Step ColorCurve and two icon layers. Gray base above threshold, bright color at/below threshold; secret HP is never compared in Lua. Traffic light unchanged from 0.7.9. If client lacks Step curves, icon stays gray and /lazyg status reports curve=unsupported.


### LazyPix_Addon/README_0.8.1.txt

LazyG 0.8.1: Health frame preview in Sonah setup mode.
When setup mode starts via minimap launcher, the health frame shows a bright red border and full-color selected consumable. Right click on the health frame cycles forward through healthstones and health potions in bags; left click cycles backward. The number in the bottom shows the selected entry. Preview ends with setup mode or on combat start. Normal HP threshold, traffic light and secure item clicks remain unchanged.


### LazyPix_Addon/README_0.8.2.txt

LazyG 0.8.2 TEST
Removed hard dependency on Sonah; Sonah is now an optional load-order dependency.
Standalone traffic light and health widget remain unchanged.
Sonah preview mode requires Sonah to be enabled.
MaxDps integration is NOT implemented yet; requires testing with exact Forever build files.

### LazyPix_Addon/README_0.8.3.txt

LazyG 0.8.3 TEST - MaxDPS mode

- Sonah remains optional. LazyG traffic light and health potion widget work independently.
- /lazyg maxdps selects MaxDPS native MaxDpsSpellFrame as the rotation indicator.
- /lazyg on uses Sonah preview if available; when Sonah is absent and MaxDPS is loaded, it selects MaxDPS.
- /lazyg off leaves MaxDPS running; restores its spellFrame.enabled setting if LazyG changed it.
- No changes to MaxDps or MaxDps_Hunter are required.
- MaxDPS owns its frame visibility and its actual recommended spell; it will not display an icon if MaxDPS rotation is inactive.
- No in-game test performed. Test outside combat; then confirm abilities update in combat.


### LazyPix_Addon/README_0.8.4.txt

LazyG 0.8.4 TEST (unverified in game)
Automatic selection: Sonah if ready, otherwise MaxDPS. When both are ready, Sonah priority.
/lazyg source auto | sonah | maxdps ; /lazyg on/off.
Editor overlay exactly matches the native source icon (Sonah/MaxDPS). Left previous, right next.
MaxDPS preview pool comes from its currently registered action-bar spells, not its exact priority list.
No addon files modified outside LazyG. Healbot and traffic light unchanged.
In combat preview closes automatically. No spell casting.


### LazyPix_Addon/README_0.8.5.txt

LazyG 0.8.5 TEST

Single 52x52 LazyG rotation display. Sonah RECOMMENDATION, Hekili Primary passive subscription, MaxDPS 0.2s cached spell read. Preview cycles same frame, out of combat only. No changes to HealthWidget.lua or rotation addons.

Minimap LazyG: left start calibration; right stop. Preview: left previous, right next. Drag live LazyG frame by left mouse to move (out of combat).
Commands: /lazyg source auto|sonah|maxdps|hekili, /lazyg on, /lazyg off.
If multiple rotation addons are active, auto order: Sonah, MaxDPS, Hekili. Select manually with /lazyg source ... and reload/save preference.

Test with a single rotation addon enabled first, verify preview and real combat recommendations. Secret Values / protected combat rendering must be tested in WoW Forever. Restore prior 0.8.4 archive for rollback.


### LazyPix_Addon/README_0.8.6.txt

LazyG 0.8.6 TEST

Changes from 0.8.5:
- One startup notice (about 2 seconds after PLAYER_LOGIN) lists detected ready rotation engines and identifies which engine LazyG uses.
- If multiple engines are detected, shows a source command example and options.
- /lazyg help (and /lazyg without arguments) shows all existing commands.
- Existing source precedence and manual source preference remain unchanged.

No changes to HealthWidget.lua, MaxDPS, Sonah or Hekili. Other display logic unchanged.

Test with Sonah and MaxDPS together, with Sonah+Hekili, individually, and no rotation addons. Test /lazyg help and /lazyg source maxdps. In-game confirmation required. Roll back to 0.8.5 if necessary.


### LazyPix_Addon/README_0.8.7.txt

LazyG 0.8.7 TEST
Единый фрейм: Shift+ЛКМ — перетаскивание, Shift+ПКМ — настройки ширины/высоты (32–160 UI-единиц). Значения сохраняются для персонажа. В бою изменение положения и размера запрещено. Светофор, хилпот и адаптеры ротаций не изменены.


### LazyPix_Addon/README_0.8.8.txt

LazyG 0.8.8 TEST — idle-frame visibility fix

- Outside preview mode, the rotation frame is hidden when the selected engine has no recommended icon.
- The frame appears when a recommendation arrives.
- In preview/setup mode, the same frame is always shown with the selected spell.
- Exiting setup restores the live recommendation or hides the frame if none exists.
- Sonah, MaxDPS, Hekili adapters and HealthWidget.lua are unchanged.

TEST build: verify in WoW Forever, including combat and secret texture values.

### LazyPix_Addon/README_0.8.9.txt

LazyG 0.8.9 TEST — Hekili display synchronization fix

- Read the currently shown Hekili Primary/AOE first icon from its original UI, including overrides.
- Fallback to already published output when no visible Hekili icon is available.
- Listen for both Primary and AOE output changes.
- Refresh Hekili every 0.2 s from existing UI/output, without asking Hekili to calculate a rotation.
- Sonah, MaxDPS, Healbot and traffic light logic remain unchanged.

TEST in WoW Forever: verify displayed icons change in combat and when switching between Primary/AOE.


### LazyPix_Addon/README_0.8.10.txt

LazyG 0.8.10 TEST - independent saved positions

Fixed Setup.lua rotation frame using the same SavedVariables position key as HealthWidget.lua.
Rotation frame now uses SonahRotationSetupDB.rotationPosition. Health widget and traffic light keep existing SonahRotationSetupDB.position unchanged.
The rotation frame may return to its default position once after upgrading; move it with Shift + left drag to save a separate location.
Rotation sources, traffic light behavior, potion indicator and settings are unchanged.
Test in WoW Forever required; not a stable release.


### LazyPix_Addon/README_0.8.11.txt

LazyG 0.8.11 TEST — preview overlay fix

В режиме настройки больше не показывается декоративная золотистая рамка UI-ActionButton-Border поверх иконки ротации.
Иконка отображается без этой перекрывающей текстуры, чтобы выбирать RGB-пиксели.
Остальная функциональность сохранена из 0.8.10.

Проверить в WoW Forever: войти в режим настройки, перебрать иконки, убедиться в отсутствии наложения, выйти и проверить обычную ротацию.


### LazyPix_Addon/README_0.8.12.txt

LazyG 0.8.12 TEST — visual cooldown and range indicators

Based on LazyG 0.8.11 TEST.

- Recommended spell icon greys out for a readable global cooldown, independent spell cooldown, or out-of-range result.
- A bright short segment travels around the frame perimeter during a readable global cooldown.
- For secret GCD timings, the standard WoW cooldown edge is used where possible, without manipulating protected numbers in Lua.
- No effect is applied in icon-preview/editing mode; existing saved positions, sizes, source adapters, health widget and traffic light are retained.
- When the source does not supply a public numeric SpellID or combat API values are secret, spell-specific CD/range state may be unavailable. Unavailable range (nil) does not mean out of range.

IMPORTANT: Desaturation changes the actual onscreen RGB colors. Existing Windows LazyG ability-pixel samples may no longer match during GCD, cooldown, or out-of-range. Verify pixel detection before normal use.

Tests: Lua syntax verified with texlua. Gameplay behavior and Secret Values handling require testing in WoW Forever.


### LazyPix_Addon/README_0.8.13.txt

LazyG 0.8.13 TEST — minimap button positioning

- Minimap icon is anchored to the minimap rim (not a fixed top-left offset).
- Hold left mouse button and drag around the minimap rim to reposition.
- Short left/right clicks retain their original editor actions.
- Saved position: SonahRotationSetupDB.minimapAngle (separate from rotationPosition and position).
- Rotation frame, adapters, traffic light and health potion code unchanged.

Testing: drag icon, /reload, relog; check left/right click, and minimap position.
Game testing is required before marking the release stable.


### LazyPix_Addon/README_0.8.14.txt

LazyG 0.8.14 TEST
Fix: forward declare minimapAngle and PlaceMinimapButton so PLAYER_LOGIN correctly restores minimap placement and continues creating the rotation frame.
No changes to rotation adapters, HealthWidget, or GCD visuals.
Test in WoW Forever: frame in preview, live recommendations, minimap dragging, /reload persistence.

### LazyPix_Addon/README_0.8.15.txt

LazyG 0.8.15 TEST — ordinary cooldown detection

Fixed: if C_Spell.GetSpellCooldown returns protected startTime/duration, use its non-secret isActive flag to dim the recommended spell while cooldown is active. Existing public-time GCD/normal-CD distinction stays unchanged.

When times are protected, isActive can also represent GCD; the frame is dimmed but the source of cooldown cannot be distinguished by this fallback.

No changes to adapters, minimap, frame settings, HealthWidget, or existing GCD border indicator.

Test in WoW Forever: ordinary cooldown (especially while in combat), GCD, editor icon brightness, hiding frame without recommendation, and Lua errors.


### LazyPix_Addon/README_0.8.16.txt

LazyG 0.8.16 TEST — GCD border and Blizzard duration support

Based on 0.8.15. Changes confined to Setup.lua and TOC.
- Persistent gold hollow border and subtle outer glow around the rotation frame.
- For public GCD timing: gold moving segment along the exterior perimeter.
- For secret GCD timing: native Blizzard Cooldown with DurationObject.
  This native fallback is a radial cooldown, NOT a square perimeter snake.
- When editor is active no GCD graphics are drawn; icon is color-correct.
- Existing CD/range dimming, Sonah, MaxDPS, Hekili, HP and traffic light untouched.

Test in WoW Forever especially combat/Secret Values and RGB recognition.


### LazyPix_Addon/README_0.8.17.txt

LazyG 0.8.17 TEST — GCD display correction

Based on 0.8.16, modifies only Setup.lua and TOC.
- Blizzard Cooldown from GetSpellCooldownDuration(61304) is the primary GCD animation.
- Listens to SPELL_UPDATE_COOLDOWN; avoids resetting the animation every 0.1 seconds.
- Perimeter segment remains available only if GCD timing is not secret.
- No GCD animation in icon setup mode.
- Original border and all rotation adapters, traffic light and healbot unchanged.

In WoW Forever test GCD during combat, out of combat, after /reload,
then check that no Blizzard Lua error appears and RGB sampling remains usable.


### LazyPix_Addon/README_0.8.18.txt

LazyG 0.8.18 TEST — GCD border progress

Changes in Setup.lua only:
- Rotation icon rim is green when GCD is not active.
- When GCD has readable timestamps, the rim becomes dark and red fills its
  perimeter clockwise: top, right, bottom, left. Completion returns it to green.
- If WoW Forever protects GCD timing, a solid red border indicates active GCD;
  the existing native Blizzard cooldown frame remains responsible for exact timing.
  No fake progress or arithmetic on secret values is attempted.
- Red progress is outside the icon, avoiding extra overlays on RGB sampling area.
- In icon calibration mode, the rim is green and progress disabled.

Not changed: Sonah / MaxDPS / Hekili adapters, traffic light, healpot, minimap,
keyboard controls, frame sizing and position.

Testing in WoW Forever required. Lua parse check only; no live game test.
Previous archive 0.8.17 can be used for rollback.


### LazyPix_Addon/README_0.8.19.txt

LazyG 0.8.19 TEST — GCD red rim progress detection fix

Исправлено: красное заполнение рамки теперь запускается по реальным
доступным startTime/duration GCD 61304 независимо от isActive.
При защищённом времени используется только индикатор активности
и штатный Cooldown Blizzard (если доступны).

Остальные функции, адаптеры, светофор и хилпот не изменены.

Проверка в игре: при активной рекомендации применить способность
с GCD; увидеть заполнение рамки красным и возврат к зелёному.
Тестировать вне боя и в бою, с /reload.


### LazyPix_Addon/README_0.8.20.txt

LazyG 0.8.20 TEST — Healbot cooldown detection

Исправлена проверка готовности Health Potion/Healthstone в HealthWidget.lua:
сначала C_Spell.GetItemCooldown(id).isActive (NeverSecret), затем резервная
проверка числовых времён C_Container.GetItemCooldown.
Если оба способа недоступны, предмет остаётся серым во избежание
ложной индикации доступности.

/lazyg status показывает ID предмета, видимость HP, готовность и API-источник
проверки кулдауна. Светофор, аддоны ротаций и GCD не изменены.

Проверить в WoW Forever при здоровье выше и ниже порога, когда предмет
готов и когда находится на кулдауне; затем /lazyg status.

### LazyPix_Addon/README_0.8.21.txt

LazyG 0.8.21 TEST — cosmetic GCD frame progress

- GCD frame visual uses a fixed 1.5-second timer, started by UNIT_SPELLCAST_SUCCEEDED for the player.
- Red border fills clockwise; returns to green after 1.5 seconds.
- Removed GCD 61304 polling, duration objects, and Blizzard cooldown overlay.
- This is a visual approximation, not an accurate GCD measure. Off-GCD casts may also trigger it.
- Existing ordinary cooldown, range, adapters, and health widget unchanged.
- In editor mode GCD animation is disabled.


### LazyPix_Addon/README_0.8.22.txt

LazyG 0.8.22 TEST — Casting/Channeling dimming

- Recommended ability icon dims while the player casts a non-instant spell or channels.
- Uses player-only UNIT_SPELLCAST_START/STOP/FAILED/FAILED_QUIET/INTERRUPTED and CHANNEL_START/STOP events, no protected cast-time arithmetic.
- Existing 1.5-second cosmetic red GCD perimeter, regular CD and range checks unchanged.
- Setup/preview stays bright.
- HealthWidget.lua unchanged.
- Game test required: normal cast, interrupted cast, canceled cast, channeled spell, editor preview.


### LazyPix_Addon/README_0.8.23.txt

LazyG 0.8.23 TEST — Player spellbook editor

- Editor spell list now comes from C_SpellBook (player bank) rather than Sonah, MaxDPS, or Hekili.
- Includes active learned spells from general/class/spec pages (including racial actives).
- Excludes passives, future spells, pet spells, profession pages, off-spec entries, and duplicate SpellIDs.
- The editor can now open with no rotation addon active.
- A saved editor index is shared across rotation sources; previous source-specific saved indices are left untouched.
- Live recommendations still use the existing Sonah, MaxDPS and Hekili adapters.
- Setup.lua is the only Lua file changed. HealthWidget.lua is unchanged.
- Learned active spells inside flyout groups are included when the flyout APIs are available.
- Requires in-game testing on WoW Forever.


### LazyPix_Addon/README_0.8.24.txt

LazyG 0.8.24 TEST — Sonah recommendation synchronization

- Sonah is now included in the existing 0.2-second refresh of the current live recommendation, as MaxDPS and Hekili already were.
- This reads Sonah.Engine:Current() only; it does not recalculate or change Sonah rotations.
- Existing RECOMMENDATION listener remains unchanged.
- Fix targets a stale icon in LazyG after changing a Sonah profile without /reload.
- HealthWidget.lua, spellbook preview, visuals, minimap and other adapters were not modified.
- Requires in-game verification.


### LazyPix_Addon/README_0.8.25.txt

LazyG 0.8.25 TEST — JustAC integration

Added JustAC / JustAssistedCombat as a fourth rotation recommendation source.
The adapter reads the actual displayed first action from JustAC.spellIcons[1]
without invoking JustAC SpellQueue or recalculating rotations.

Selection: /lazyg source justac
Automatic selection: /lazyg source auto
Priority (when multiple addons are active): Sonah, MaxDPS, Hekili, JustAC.

JustAC support in this test uses its standard visible queue display.
If its main queue is hidden or using another display mode, LazyG hides its
recommendation; alternative nameplate-overlay-only display is not yet supported.
WAIT placeholders are ignored. Macro images can be shown without a SpellID.

The preview still reads active non-passive spells from the player spellbook.
HealthWidget.lua and the other adapters are unchanged.

Static source review only. Requires in-game validation on WoW Forever.


### LazyPix_Addon/README_0.8.26.txt

LazyG 0.8.26 TEST — RotationMaster adapter

Added RotationMaster 2.1.1 as a fifth passive recommendation source.
The adapter reads the first live recommendation from
RotationMaster.nextWindow.icons[1], without evaluating its rotation.
Requires Rotation Master's "Preview Spells" display to be enabled.
Sample/empty recommendations are ignored. Item icons are forwarded, but
item IDs are not treated as spell IDs for cooldown or range checks.
Some gated overlay effects in RotationMaster may render separately from
its base texture and are not replicated by this adapter.

Commands: /lazyg source rotationmaster ; /lazyg source auto ; /lazyg help
Automatic priority: Sonah > MaxDPS > Hekili > JustAC > RotationMaster.

Editor still reads the player's spellbook; HealthWidget.lua unchanged.
Static source verification only. Test in WoW Forever before approving.

### LazyPix_Addon/README_0.8.27.txt

LazyG 0.8.27 TEST — один ранг способности в режиме настройки

В режиме настройки чтение книги заклинаний группирует известные активные
способности по локализованному названию и показывает только один ранг.
При наличии subName выбирается ранг с наибольшим номером; если номер не
определяется — используется последняя подходящая запись книги.
Рекомендуемый ранг определяется исключительно при построении списка.
Все источники рекомендаций, светофор, хилпот и GCD не изменены.

Проверить: /lazyg on, перелистывание способностей, отсутствие повторов
рангов (например, Укус змеи). В самой игре пока не проверено.


### LazyPix_Addon/README_0.8.28.txt

LazyG 0.8.28 TEST — MaxDPS/Hunter visual timing correction

- Auto Shot (75), Shoot (5019) and Auto Attack (6603) do not restart the decorative 1.5-second rim animation.
- Removed false cooldown dimming from isActive when start/duration are secret or unavailable; this cannot reliably distinguish the shared GCD from a longer ability cooldown.
- Verified standard, readable long cooldowns, range and cast/channel dimming logic is unchanged.
- Other adapters, spellbook preview, minimap, and HealthWidget.lua unchanged.

Test in-game: Hunter MaxDPS Auto Shot over 5+ seconds, cast an ability, confirm one completed rim cycle and icon undims after genuine cooldowns/casts; test a long ordinary cooldown and out-of-range grey state.


### LazyPix_Addon/README_0.8.29.txt

LazyG 0.8.29 TEST

Косметическая рамка отделена от логики доступности способностей.
Красная рамка запускается от успешного применения заклинания персонажем на 1,5 секунды, Auto Shot/Shoot/Auto Attack исключены для предотвращения постоянного перезапуска.
Она не влияет на затемнение, ротации, CD, range и каст.
Таймер не сбрасывается при исчезновении рекомендации; при скрытом фрейме или предпросмотре эффекты не отображаются.
Проверить отдельно в WoW Forever.


### LazyPix_Addon/README_0.8.30.txt

LazyG 0.8.30 TEST — независимое затемнение GCD

Исправлено: после успешного применения способности игроком иконка
затемняется на ориентировочные 1,5 секунды (кроме Auto Shot, Shoot, Auto Attack).

Это отдельный таймер gcdDimUntil, не связанный с косметической
анимацией рамки cosmeticStart. Рамка не влияет на затемнение,
а затемнение не управляет рамкой.

Условия обычного CD, дальности, каста и channeling не изменены.
Важно: таймер приблизительный и не определяет реальный GCD по API.
Изменения только Setup.lua, LazyG.toc и этот README.
Версия не тестировалась в WoW Forever.

## Итоги чтения исходников и архивной истории аддона — 2026-11-20 16:19 (+07:00)

**Охват:** 34 README, версии `0.7.7–0.8.30`; актуальные `LazyG.toc`, `Setup.lua`, `HealthWidget.lua`. Все 34 исходных README перенесены выше **дословно**, в исходном хронологическом порядке. Их исторические даты/часы не установлены.

**Эволюция функций:**
- `0.7.7–0.8.1`: светофор, управление режимами, обход защищённых значений движения/здоровья, условие HP через WoW ColorCurve, предпросмотр лечебных предметов.
- `0.8.2–0.8.6`: снята жёсткая зависимость от Sonah, интегрированы MaxDPS и Hekili; единый фрейм и автоматический приоритет; добавлены команды выбора источников и сообщение о готовых источниках.
- `0.8.7–0.8.14`: перетаскивание/размер фрейма, отсутствие пустой иконки без рекомендации, синхронизация Hekili, разделение ключей сохранения координат, устранение накладывающейся на RGB предпросмотр рамки, визуальная индикация CD/range/GCD, перемещение кнопки миникарты и исправление порядка объявления переменных.
- `0.8.15–0.8.22`: несколько итераций обработки обычных CD, Secret Values и GCD; затем переход к косметической рамке фиксированной длительности; доработка готовности лечебных предметов и затемнения во время каста/channeling.
- `0.8.23–0.8.26`: настройка через изученные активные способности из книги заклинаний, синхронизация Sonah, адаптеры JustAC и RotationMaster (всего пять источников).
- `0.8.27–0.8.30`: удаление дублей рангов при предпросмотре; предотвращение непрерывного перезапуска рамки Auto Shot/Shoot/Auto Attack; исправление ложного затемнения CD; независимая косметическая рамка и приблизительное затемнение GCD.

**Ошибки, которые нельзя повторять:** общий ключ положения фрейма ротации и HealthWidget приводил к конфликту; таймер косметической рамки не должен управлять фактической доступностью спелла; `isActive` при защищённых значениях может отражать общий GCD, а не долгий CD; затемнение меняет RGB-пиксели, которые распознаёт Windows-программа; при защищённых HP/GCD нельзя делать числовые сравнения; после релога положение миникарты зависит от корректного порядка объявления функции.

**Статусы:** большинство последних README прямо помечены `TEST`, для `0.8.30` указано «не тестировалась в WoW Forever». Парсинг Lua и исторические проверки в отдельных записях **не равны игровому тесту**. Сборка Windows в этой работе не выполнялась.

**Обсуждённое, но не реализованное данным изменением требование:** при нескольких загруженных основных ротационных аддонах предупреждать о конфликте, не учитывать классовые модули отдельно, не выбирать источник автоматически. В текущем Lua всё ещё присутствуют `/lazyg source ...` и приоритет автоматического выбора. Менять это только отдельной задачей.

---

## LP-0002 — 2026-11-20 16:19 (+07:00) — Объединение истории Lua-аддона и единого контекста двух компонентов

**Компонент:** Windows + Addon (только документация, исходный код не изменён).
**Версии компонентов:** Windows — без изменений; Addon `0.8.30 TEST` — без изменений.
**Статус:** документация обновлена; поведение приложения и аддона не проверялось.
**Время:** начало 2026-11-20 16:00 (+07:00), запись оформлена 2026-11-20 16:19 (+07:00); время завершения определяется коммитом GitHub.
**Запрос пользователя:** прочитать добавленную папку аддона и все её README; объединить историю; зафиксировать совместную разработку Windows-программы и Lua-аддона в одном чате/репозитории, ввести общий подробный журнал изменений для обоих.
**Причина и цель:** до этой работы контекст охватывал преимущественно Windows-часть, отдельные старые README аддона дробили историю между файлами и чатами; это повышало риск повторения ошибок и потери решений.
**Проверено до изменения:** GitHub `main`, `LazyPix_Addon/LazyG.toc`, части `Setup.lua` и `HealthWidget.lua`, 34 README с версий `0.7.7–0.8.30`, `PROJECT_CONTEXT.md` и `HISTORY.md`.
**Решение:** добавить в `HISTORY.md` оригинальные тексты всех старых README и обзор технических решений, в `PROJECT_CONTEXT.md` закрепить два компонента, обязательную маркировку `Windows`/`Addon`/`Windows + Addon` и единый журнал. После сверки полного переноса удалить только дублирующие README из `LazyPix_Addon/`.
**Затронутые файлы:** `HISTORY.md`, `PROJECT_CONTEXT.md`; удалены исключительно `LazyPix_Addon/README_*.txt` (34 файла). **Не тронуты:** `.toc`, `.lua`, `.tga`, C#, XAML, .csproj, каталоги и изображения.
**Диагностика:** фактическая версия TOC `0.8.30`, исторические наименования `LazyG` не равны текущему имени репозитория; эти идентификаторы оставлены для совместимости. Исторические README указывают несколько важных регрессий в визуальных индикаторах и сохранениях.
**Проверка:** до коммита подтверждено наличие всех 34 исходных текстов в `HISTORY.md`; после коммита требуется сверить дерево GitHub. Запуск WoW и компиляция Windows: **НЕ ПРОВЕРЕНО** (код не изменён).
**GitHub:** `main`; точная ссылка на коммит доступна в истории GitHub.
**Передача на тест:** не требуется для правки документации; пользовательские игровые тесты `0.8.30` отсутствуют в доступном README.
**Обратная связь пользователя:** ожидается.
**Как не повторить ошибки:** всегда сверять две части системы и реальные версии; не считать косметическое отображение реальным GCD и не путать статус в README с проверкой; протоколировать точные файлы, причину, тест и пользовательский фидбэк.
**Следующий шаг:** проверить совместимость текущих исходников обеих частей в игре на соответствующих клиентах по будущему запросу; не менять архитектуру без разрешения.


---

## LP-0003 — 2026-11-20 16:27–16:29 (+07:00) — Полное переименование Windows и Lua в LazyPix

**Компонент:** Windows + Addon.
**Статус:** DEV, готово к проверке сборки/игровому тесту.
**Запрос пользователя:** заменить во всём актуальном исходном коде Windows-программы и Lua-аддона все упоминания старого названия LazyG на LazyPix, включая названия проекта, ресурсов, интерфейса, команд и аддона.
**Причина:** единое название двух компонентов и отсутствие старого бренда в исполняемом коде.
**Исходная проверка:** GitHub `main`, исходные файлы .cs/.xaml/.csproj/.json/.lua/.toc, имена изображений и история проекта. Перед работой: Windows `LazyG.csproj` (AssemblyName LazyG); Lua `LazyPix_Addon/LazyG.toc`, Version 0.8.30 TEST; 2 Lua-модуля.
**Диагностика и связанные риски:** в Windows старое имя встречалось в заголовках, локализации, настройке языка и путях значка; в Lua — в slash-команде, именованных фреймах, глобальной таблице связи с HealthWidget, путях текстур и TOC. Простая замена без согласования имени папки WoW и TOC могла бы оставить аддон незагружаемым/без иконок.
**Техническое решение и затронутые файлы:**
- `LazyG.csproj` → `LazyPix.csproj`, `AssemblyName=LazyPix`; `Assets/LazyG.ico` и `Assets/LazyG.png` → `Assets/LazyPix.ico` / `Assets/LazyPix.png` без изменения бинарного изображения; пути обновлены в XAML и .csproj.
- Заголовки и сообщения: `MainWindow.xaml`, `MainWindow.xaml.cs`, `EditorDialogs.cs`, `GlobalHotkeys.cs`, `Localization.cs`, `Localization/en-US.json`, `Localization/ru-RU.json`.
- `LazyPix_Addon/Setup.lua`, `LazyPix_Addon/HealthWidget.lua`: надписи, имена глобальных объектов фреймов, API-связка `LazyPixHealthWidget`, slash-команда `/lazypix`, текстуры из папки `LazyPix_Addon`.
- `LazyPix_Addon/LazyG.toc` → `LazyPix_Addon/LazyPix_Addon.toc` (в WoW имя TOC должно совпадать с именем каталога), заголовок LazyPix; версия 0.8.30 сохранена.
- `PROJECT_CONTEXT.md` актуализирован; исторические исходные записи `HISTORY.md` **не переписаны задним числом**.
**Совместимость:** переменная сохранений WoW `SonahRotationSetupDB`, имена C# пространств `WoWForeverAssistant`, пути профилей Windows `%LOCALAPPDATA%\WoWForeverAssistant` и JSON-ключи сериализации сохранены: они не содержат старый бренд и изменение их могло бы нарушить совместимость. Язык Windows теперь сохраняется в `%APPDATA%\LazyPix\language.txt`: прежний выбор языка из старого каталога автоматически не переносится; по умолчанию RU, язык можно выбрать снова.
**Проверки:** сверка текстовых вхождений и целостности GitHub-дерева после коммита. Windows dotnet publish и игровой тест Lua **НЕ ПРОВЕРЕНЫ** на момент записи. Следует проверять загрузку TOC, текстуры, команду `/lazypix`, фрейм рекомендаций, HealthWidget, переменные профиля и публикацию одного EXE. Не объявлять релиз.
**Ошибка, которую нельзя повторять:** не переименовывать только TOC без каталога или пути текстур; не менять SavedVariables `SonahRotationSetupDB` без миграции; не утверждать, что успешная текстовая замена означает успешную сборку/игровую работу.
**Обратная связь пользователя:** ожидается.
**Следующее действие:** проверка Windows Actions и игровая проверка Lua; исправления фиксировать в новом ID с диагностикой и ссылкой на этот пункт.


**Дополнение LP-0003 — 2026-11-20 16:32 (+07:00), результаты GitHub Actions:** коммит переименования [2afec9293174ec4e1b057433380eab185f2bcd51](https://github.com/Vi22Rus/LazyPix/commit/2afec9293174ec4e1b057433380eab185f2bcd51). Windows-сборка [Actions #44711416326](https://github.com/Vi22Rus/LazyPix/actions/runs/44711416326) завершилась **success**. Шаги `dotnet publish` для `LazyPix.csproj` и `upload-artifact` завершились **success**. Артефакт `LazyPix-Windows-DEV`, ID `14617128624` (архив примерно 75,4 МБ). Проверена корректность имён файлов и отсутствие `LazyG` в актуальных текстовых исходниках программы и аддона. **НЕ ПРОВЕРЕНО:** запуск Windows EXE пользователем, загрузка WoW аддона, сохранение настроек и реальное распознавание RGB; статус версии остаётся DEV.


## LP-0004 — 2026-11-23 (точное время не зафиксировано) — индекс CHANGELOG и проектный AGENTS на согласовании
**Компонент:** Windows + Addon (только документация).
**Версии:** Windows без изменения; Lua 0.8.30 TEST без изменения.
**Статус:** CHANGELOG.md создан в main; AGENTS.md подготовлен только локально для просмотра пользователя, в GitHub НЕ опубликован.
**Запрос:** изучить репозиторий и подготовить инструкции AGENTS.md, не публикуя их без просмотра; создать CHANGELOG.md.
**Причина и решение:** существующий PROJECT_CONTEXT.md запрещал параллельные журналы. Новый CHANGELOG.md оформлен только кратким индексом, с явной ссылкой на HISTORY.md как единственный подробный источник истины; архив истории не переписывался.
**Проверены файлы:** PROJECT_CONTEXT.md, HISTORY.md, LazyPix.csproj, LazyPix_Addon/LazyPix_Addon.toc, Setup.lua, HealthWidget.lua и структура .github/workflows.
**Изменения:** новый CHANGELOG.md; эта запись HISTORY.md. Ни один файл исходного кода, Lua, ресурсов, workflow не изменён.
**GitHub:** [создание CHANGELOG.md](https://github.com/Vi22Rus/LazyPix/commit/062cda48ecd54a49f09eb5a1ea70ca01dd438a7d); коммит настоящей записи фиксируется отдельно. Ветка main.
**Проверки:** GitHub подтвердил создание CHANGELOG.md; проверки сборки Windows и загрузки в WoW НЕ ТРЕБУЮТСЯ для docs-only, НЕ ПРОВОДИЛИСЬ.
**Обратная связь:** ожидается согласование AGENTS.md пользователем.
**Следующий шаг:** по разрешению пользователя опубликовать отредактированный AGENTS.md; текущий черновик в GitHub отсутствует.


## LP-0005 — 2026-11-23 (время не зафиксировано) — полное документирование каждого нового коммита
**Компонент:** Windows + Addon (документационные правила).
**Версии:** Windows без изменения; Lua 0.8.30 TEST без изменения.
**Статус:** DOCS ONLY; код и workflow не менялись.
**Запрос пользователя:** отныне полностью отражать все коммиты в CHANGELOG.md: что сделано, где сделано и зачем сделано.
**Причина:** краткий индекс не фиксировал отдельные изменения и их технические причины, что мешало восстановлению истории разработки.
**Решение и файлы:** CHANGELOG.md — правило и запись с 2026-11-23; PROJECT_CONTEXT.md — согласование исключения из прежнего запрета на параллельный CHANGELOG; HISTORY.md — эта подробная запись. AGENTS.md отредактирован только в локальном черновике и в GitHub не опубликован.
**Проверки:** содержание документов проверено; игровой тест и dotnet publish НЕ ПРОВЕРЕНЫ (docs-only). Исходная ветка main; точный SHA итогового коммита доступен через историю GitHub.
**Обратная связь:** ожидается утверждение черновика AGENTS.md.
**Следующая задача:** применять правило для каждого следующего коммита независимо от ветки и версии.


## LP-0006 — 2026-11-23 — публикация согласованного AGENTS.md
**Компонент:** Windows + Addon, документация; версии кода без изменения, Addon 0.8.30 TEST.
**Статус:** DOCS-ONLY. **Запрос:** пользователь утвердил AGENTS.md и разрешил публикацию в main.
**Что/где/зачем:** новый корневой AGENTS.md с правилами по актуальным источникам, git-веткам, совместимости, 5 адаптерам исходного 0.8.30, GCD/рамке, проверкам Windows и Lua; детализация коммита в CHANGELOG.md. Нужен единый стандарт для всех следующих чатов.
**Проверки:** GitHub commit и наличие файла; CI и игровой тест НЕ ПРОВЕРЕНЫ (нет изменений кода).
**Откат:** возврат к родительскому main commit. **Следующий шаг:** экспериментальную разработку вести только в отдельной ветке.


## LP-0007 — 2026-11-23 — isolated Auto Connect branch, removal of old rotation adapters
**Компонент:** Lua Addon; версия 0.8.30 TEST (main) → 0.8.31-dev (experiment).
**Запрос:** создать отдельную ветку аддона для Auto Connect, удалить все пять адаптеров без изменений main.
**Зачем:** независимое экспериментальное основание для нового механизма обнаружения, подключения и fallback-адаптеров; исключить использование старой жёсткой интеграции.
**Изменения:** LazyPix_Addon/Setup.lua — удалены Sonah/MaxDPS/Hekili/JustAC/RotationMaster и относящиеся к ним обнаружение, подписки, команды выбора и опрос; при отсутствии провайдера live-иконка скрывается. LazyPix_Addon/LazyPix_Addon.toc — удалены OptionalDeps пяти источников, версия 0.8.31-dev. HealthWidget.lua и Windows-программа без изменений.
**Что сохранено:** фрейм, предпросмотр из spellbook, позиционирование, настройки, миникарта, GCD и косметика, светофор и хилбот.
**Результат:** исходники подготовлены в experimental/addon-auto-connect; Auto Connect ещё НЕ РЕАЛИЗОВАН, боевые рекомендации в этой ветке пока отсутствуют.
**Проверки:** статическая проверка ссылок/структуры; игровой тест и проверка Lua runtime НЕ ПРОВЕРЕНЫ. MAIN и 0.8.30 TEST — точка отката.
**Следующий шаг:** отдельная реализация универсального контракта подключения и discovery со строгими ограничениями WoW API.


## LP-0008 — 2026-11-23 — исправлена склейка обработчика slash-команды в Auto Connect experiment
**Компонент:** Addon 0.8.31-dev, только экспериментальная ветка.
**Причина:** после автоматического удаления блоков адаптеров в Setup.lua появилась некорректная строка SLASH_LAZYPIX1end), из-за которой Lua не загрузится.
**Исправление:** LazyPix_Addon/Setup.lua — удалить ошибочный фрагмент, оставить единственное присваивание SLASH_LAZYPIX1 и существующий SlashCmdList.LAZYPIX.
**Проверка:** статическая проверка структуры и отсутствия adapter references; реальный lua interpreter/игровой тест НЕ ПРОВЕРЕНЫ.
**Предыдущий коммит:** 3047ac7c7e595c7793681eb8b3bf249e1ffd5b59. **Откат:** main 0.8.30 TEST. **Следующий шаг:** тест загрузки аддона в игре до начала реализации Auto Connect.

## LP-0009 — 2026-11-23 — Auto Connect: discovery, provider contract and generic adapter
**Компонент/версия:** Addon 0.8.31-dev → 0.8.32-dev, только experimental/addon-auto-connect. Windows без изменений.
**Запрос:** реализовать три согласованных уровня подключения без восстановления пяти исходных жёстких адаптеров.
**Исходное состояние:** ветка после LP-0008, нет источников рекомендаций; сохранены собственный фрейм, миникарта, предпросмотр, HealthWidget.
**Реализация:** новый AutoConnect.lua с регистрацией провайдера, обнаружением загруженных аддонов и TOC X-LazyPix-Provider, универсальным адаптером по опубликованному пути; Setup.lua считывает рекомендацию через Auto.Read, обрабатывает ADDON_LOADED, PLAYER_LOGIN и OnUpdate, предоставляет /lazypix sources и /lazypix source <id>. TOC грузит новый модуль перед Setup. AUTOCONNECT.md документирует интерфейс; tests/autoconnect_test.lua задаёт mock-сценарий.
**Безопасность и границы:** API `secret values` при проверке числа SpellID; protected текстуру не сравнивать. Никакого вызова чужих вычислителей ротаций и поиска произвольных текстур. Сторонним аддонам без публичного результата требуется внешний мост. При двух провайдерах выбор по priority и id. Сохранён HealthWidget.lua и SavedVariables.
**Проверки:** статические проверки структуры; тест написан, но Lua интерпретатор и WoW Forever не запускались. Пользовательское тестирование ОЖИДАЕТСЯ. 
**Риски:** совместимость C_AddOns/TOC API WoW Forever, фактические публикуемые источниками значения, секретные текстуры; при несовместимости источник отсутствует, а иконка скрыта.
**Rollback:** предыдущий коммит d96f8d5d167556222b6c9ebeebaff1e1cea5c1c7; стабильная точка старой линейки — main 0.8.30 TEST.
**Следующий шаг:** запустить Lua 5.1 тест, проверить /reload, /lazypix sources, подключить один конкретный живой источник в отдельном минимальном мосте.


## LP-0010 — 2026-11-23 — Lua 5.1 CI и совместимость имён источников
**Компонент:** Lua Addon 0.8.32-dev, experiment-only.
**Проблема:** slash-команда нижнего регистра могла не выбрать провайдер с именем TestRot. Отсутствовал CI для Lua Auto Connect.
**Изменения:** Auto.SetPreferred сравнивает зарегистрированные имена без учёта регистра и отказывает при неоднозначном совпадении; Lua mock test проверяет ввод в нижнем регистре; AUTOCONNECT.md уточняет поведение; отдельный GitHub Actions workflow проверяет luac5.1 и запускает Lua mock.
**Зачем:** надёжная диагностика до WoW Forever.
**Проверки:** CI ожидает запуска после commit, игровой тест и полная совместимость WoW API НЕ ПРОВЕРЕНЫ.
**Предыдущий коммит:** ef02e5c98fe7b28850d88ce33cac7637048a332f.
**Откат:** main 0.8.30 TEST, для экспериментальных тестов — предыдущий SHA.
**Следующий шаг:** проверить результаты Actions и живое подключение совместимого источника.


## LP-0011 — 2026-11-23 — зафиксирован фактический PASS GitHub Actions Auto Connect
**Компонент:** Lua Addon 0.8.32-dev, experimental/addon-auto-connect, документация.
**Событие:** workflow https://github.com/Vi22Rus/LazyPix/actions/runs/45097646800 завершился SUCCESS для исходного SHA f8df11d6c98675115892f1e51f63022c872180a6.
**Проверки:** все файлы AutoConnect.lua, Setup.lua, HealthWidget.lua и mock-тест проверены luac5.1; mock autoconnect_test.lua исполнен под Lua 5.1 (PASS). Наличие шага CI не доказывает корректную работу WoW protected/secret API.
**Файлы:** CHANGELOG.md, HISTORY.md (docs-only). Цель — сохранить фактическое подтверждение CI с отчётливой оговоркой о границах.
**Результат:** GitHub Actions PASS; WoW Forever — НЕ ПРОВЕРЕНО; Windows — не затронут.
**Откат:** f8df11d6c98675115892f1e51f63022c872180a6. **Следующая задача:** проверить реального совместимого провайдера в WoW, с /lazypix sources и тестом смены target/rotation recommendation.

## LP-0012 — 2026-11-23 — P01–P05 anonymous protocol discovery
**Компонент:** Lua Addon 0.8.32-dev → 0.8.33-dev, experimental/addon-auto-connect, Windows без изменений.
**Запрос пользователя:** сохранить пять алгоритмов чтения сторонних готовых ротационных рекомендаций без названий продуктов в исполняемом модуле; подтвердить протокол несколькими независимыми признаками. Новые аддоны в дальнейшем добавлять как новые протоколы.
**Тест пользователя и причина:** 0.8.32-dev в WoW Forever обнаружил 8 загруженных аддонов, зарегистрировал 0 совместимых источников. При неизвестном стороннем аддоне это соответствует ограничению прежнего механизма. Прямой автоматический универсальный доступ к рекомендациям любого аддона невозможен без доступного интерфейса.
**Источники:** актуальные Setup.lua из main, AutoConnect.lua экспериментальной ветки, Sonah.zip, Hekili_Forever.zip и JustAC.zip. Исходники 3.3.5 не использованы для функций WoW Forever.
**Решение:** ProtocolDiscovery.lua с пятью анонимными стратегиями и независимыми структурными доказательствами; обнаружение по экспортированным таблицам и AceAddon, блокировка ambiguous и source changed; не вызывать чужой ротационный evaluator; считывать только готовый результат. Старые RegisterProvider и RegisterAdapter сохраняются, как и фрейм/предпросмотр/мини-карта/светофор/GCD.
**Изменённые файлы:** LazyPix_Addon/ProtocolDiscovery.lua (новый модуль), AutoConnect.lua (вызов Scanner), Setup.lua (slash диагностика), LazyPix_Addon.toc, AUTOCONNECT.md, tests/autoconnect_test.lua, CHANGELOG.md, HISTORY.md. HealthWidget.lua, Windows и main не затронуты.
**Проверки:** Lua mock test и luac через CI должны быть проверены после push. В игре P01–P05 НЕ ПРОВЕРЕНЫ, взаимодействие с секретными полями/защитой WoW и с RGB Windows НЕ ПРОВЕРЕНО. Приоритет: тест /reload, /lazypix protocols, /lazypix sources, появление рекомендации, смена цели, режим настройки и UI.
**Статус:** DEV, передача пользователю на тест после CI. **Rollback:** 548d01dc386a7d4a1830e6bb003e522f8b372195; main отдельно сохраняет 0.8.30 TEST.
**Следующий шаг:** выполнить тест в WoW Forever, исправлять только подтверждённые отказы; затем подключать новые источники как новые структурные протоколы.

## LP-0013 — 2026-11-23 — отдельная Lua 5.1 CI-проверка ProtocolDiscovery.lua
**Причина:** новый модуль создан в LP-0012, а workflow до этого не включал его в самостоятельную проверку `luac5.1 -p`.
**Файлы:** .github/workflows/lazypix-addon-autoconnect-dev.yml, CHANGELOG.md, HISTORY.md.
**Изменение:** добавлена строка проверки ProtocolDiscovery.lua в существующий job до исполнения mock-теста.
**Проверки:** GitHub Actions после push; фактический результат вне этого commit. Игровые интеграции не проверены.
**Ветка:** experimental/addon-auto-connect, addon 0.8.33-dev; код Lua и Windows не изменён.
**Rollback:** c425c075af864b575a1aed6edca8d35258ef6653.

## LP-0014 — 2026-11-23 — зафиксирован успех CI 0.8.33-dev
**Компонент:** Lua Addon, documentation-only, версия остаётся 0.8.33-dev.
**Событие:** GitHub Actions #45099960062 для c0942c1732ecd340d8502dafbd3b489859b62dca завершился SUCCESS: luac5.1 -p AutoConnect, ProtocolDiscovery, Setup, HealthWidget, test; затем lua5.1 autoconnect_test.lua PASS. Предыдущий #45099908592 для c425c075af864b575a1aed6edca8d35258ef6653 тоже SUCCESS.
**Причина/изменения:** зафиксировать достоверный результат в CHANGELOG.md и HISTORY.md, не приписывая Lua CI полноценный игровой тест. Исходники и CI workflow не менялись.
**Границы:** интеграция с настоящими источниками WoW Forever, secret values и Windows RGB НЕ ПРОВЕРЕНА.
**Ветка и откат:** experimental/addon-auto-connect; откат на c0942c1732ecd340d8502dafbd3b489859b62dca; main без изменений.
**Дальше:** пользовательский /reload, /lazypix protocols, /lazypix sources и сравнение иконки в бою с источником.

## LP-0015 — 2026-11-23 — 0.8.34-dev: диагностика и исправление обнаружения P01–P05
**Компонент:** Lua Addon 0.8.33-dev → 0.8.34-dev, experimental/addon-auto-connect; Windows без изменений.
**Запрос:** пользователь обнаружил отказ подключения к работающему ротационному источнику и статус not-found для всех пяти протоколов. Попросил исправить и максимально подробно объяснить причину в CHANGELOG.md.
**Проверенные источники:** GitHub ProtocolDiscovery.lua, AutoConnect.lua, Setup.lua, tests/autoconnect_test.lua на экспериментальной ветке; исходники из приложенного Sonah.zip — Core/Init.lua (Listen), Core/Organisms/Engine.lua (Current), Core/Organisms/Registry.lua (ActiveSpec); старый Setup.lua из main. В референсе P01 действительно есть 3 структурных поля. Прямая причина отказа именно в клиенте пользователя пока не доказана.
**Диагностика:** обнаружен объективный дефект в enumerate(): неупорядоченный pairs(_G) останавливался после 12000 записей, мог пропустить источник; field() отсеивал userdata фреймы. Один глобальный список без подробных счётчиков не позволял локализовать отказ. Для устранения ложных выводов диагностика теперь показывает 3–4 признака по лучшему одному объекту, а также суммарные количества. Совпадения полей у разных объектов не суммируются в готовый протокол.
**Решение и файлы:** ProtocolDiscovery.lua — полный обход, userdata field, диагностические probes/report/Diagnostics; Setup.lua — slash /lazypix protocol debug; tests/autoconnect_test.lua — mock P01+счётчики; toc — 0.8.34-dev; AUTOCONNECT.md — описание. HealthWidget.lua и Windows не изменены.
**Риски:** полный обход _G может затрачивать CPU, особенно при /lazypix protocol debug; доступность отдельных структур зависит от экспорта и фактической загрузки; UI-иконки могут появляться только позже. Protected/secret значения не вычисляются или сравниваются; выводимые debug показатели не содержат имён сторонних продуктов.
**Проверки:** GitHub Actions Lua 5.1 запланирован по push; реальный тест в игре 0.8.34-dev НЕ ПРОВЕРЕН. Тест 0.8.33-dev с P01 — FAIL со слов пользователя. Откат: 0bf9045794502c341bc3f82e3f190862d44634aa. main без изменений.
**Следующий шаг:** /reload, /lazypix protocols, /lazypix protocol debug, /lazypix sources. По P01 исследовать реальную цепочку отсутствующего признака и уже затем коррекцию, если не заработает.

## LP-0016 — 2026-11-23 — зафиксирован PASS CI для P01–P05 0.8.34-dev
**Причина:** завершился запуск тестов LP-0015, необходимо записать реальный результат для отслеживания регрессий.
**Изменение:** только CHANGELOG.md и HISTORY.md. Код, версия Lua-аддона и Windows не изменены.
**Проверено:** https://github.com/Vi22Rus/LazyPix/actions/runs/45100816270 — SUCCESS для eb31e97082cad6c1135df902480439b67717ce90; luac5.1 -p для всего Lua ядра, включая ProtocolDiscovery.lua, и integration mock PASS с регрессией P01.
**Не проверено:** WoW Forever реальное подключение, стабильность frame/secret API, RGB Windows. Предыдущий пользовательский результат 0.8.33-dev — все not-found — остаётся фактическим.
**Ветка:** experimental/addon-auto-connect; 0.8.34-dev; откат eb31e97082cad6c1135df902480439b67717ce90.
**Дальше:** пользовательский тест /lazypix protocols и /lazypix protocol debug.

## LP-0017 — 2026-11-23 — устранение регулярных зависаний Auto Connect
**Компонент/версия:** Addon 0.8.34-dev → 0.8.35-dev, experimental/addon-auto-connect, Windows и main неизменны.
**Сообщение пользователя:** P01 registered со всеми 4 признаками YES, остальные P02–P05 not-found; ~92% CPU у модификаций, сильные фризы, WoW Lua timeout 2026-11-23 09:36:47 (+07:00), stack [CAMERAORSELECTORMOVE]. Это подтверждает живое обнаружение P01, но не подтверждает успешную передачу рекомендации.
**Кодовая первопричина ресурсоёмкости:** Auto.Tick в каждом кадре, каждые 2 с Auto.Scan→Protocol.Scan с полным обходом _G и диагностическими переборами для каждой стратегии; стоимость выросла после удаления лимита 12000 в LP-0015. Оценка доли CPU требует отдельного профилирования.
**Решение:** Auto.Tick только проверяет флаг pending нового ADDON_LOADED; сканирование по событию с двухсекундной задержкой, не периодическое. Подробный report только по ручной команде protocol debug; protocols читает состояния из памяти. Переключение стратегии и существующее считывание 0.2 с оставлены.
**Изменены:** AutoConnect.lua, ProtocolDiscovery.lua, Setup.lua, LazyPix_Addon.toc, tests/autoconnect_test.lua, AUTOCONNECT.md, CHANGELOG.md, HISTORY.md. HealthWidget.lua и Windows не менялись.
**Проверки:** добавлен Lua 5.1 mock на отсутствие повторного idle scan, CI по push ожидается; реальный WoW-тест 0.8.35-dev НЕ ПРОВЕРЕН. Приоритет: загрузка без фриза, отсутствие фризов в течение нескольких минут, /lazypix protocols, рекомендация P01.
**Rollback:** 797609222569e0a6ee9486cd82307f3d6f40a9aa только для Git-отката, не для игрового использования из-за фризов.
