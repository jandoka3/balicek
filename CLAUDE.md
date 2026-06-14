# Balíček – seznamy na balení s malým dítětem

Mobilní aplikace (Android + iOS) pro vytváření a používání seznamů věcí na balení.
Tento soubor je závazná specifikace a pravidla projektu. Vždy se jím řiď.

## Technologie

- **Flutter** (stable channel), jazyk Dart. Jeden kód pro Android i iOS.
- **Lokální úložiště: Hive** (balíček `hive` + `hive_flutter`). Žádný backend, žádné přihlašování, vše offline v telefonu.
- Stavový management: jednoduše `ChangeNotifier` + `provider`. Nepoužívej složitější řešení (bloc, riverpod), projekt je malý.
- Jazyk UI: **čeština**. Texty UI drž v jednom souboru `lib/strings.dart`, ať se dají později přeložit.

## Datový model

```dart
enum QuantityMode {
  perDay,      // potřeba X kusů na každý den  → množství = X * dny
  perXDays,    // potřeba 1 kus na každých X dní → množství = ceil(dny / X)
  fixed,       // potřeba přesně X kusů bez ohledu na délku → množství = X
}

class PackingItem {
  String id;            // uuid
  String name;          // např. "Tričko"
  QuantityMode mode;
  int value;            // význam podle mode: perDay = kusů/den, perXDays = počet dní na 1 kus, fixed = kusů celkem
  bool checked;         // odškrtnuto při balení
}

class PackingList {
  String id;            // uuid
  String name;          // např. "Rodinná dovolená"
  int days;             // aktuálně zvolený počet dní (default 3)
  List<PackingItem> items;
  DateTime createdAt;
  DateTime updatedAt;
}
```

### Výpočet množství (jediné místo v kódu!)

Funkce `int computeQuantity(PackingItem item, int days)` v `lib/logic/quantity.dart`:

- `perDay`: `value * days`
- `perXDays`: `(days / value).ceil()` (např. 1 krém na 5 dní, jedu na 12 dní → 3 kusy)
- `fixed`: `value`

Vždy minimálně 1, pokud `days >= 1`. Tato funkce MUSÍ mít unit testy na všechny tři režimy včetně hraničních případů (1 den, dělitelné/nedělitelné počty).

### Import seznamu (parser)

Funkce `List<String> parseImport(String input)` v `lib/logic/import_parser.dart`:

- Vstupní text se rozdělí podle **nových řádků** a zároveň podle **čárek** (obojí může být kombinované).
- Každá položka se ořízne o mezery, prázdné položky se zahodí, duplicity (case-insensitive) se zahodí.
- Z každého názvu vznikne `PackingItem` s výchozím režimem `fixed`, `value = 1`, `checked = false`.
- MUSÍ mít unit testy: jen řádky, jen čárky, mix, prázdné řádky, mezery, duplicity.

## Obrazovky

1. **Přehled seznamů** (úvodní)
   - Karty seznamů (název, počet položek). Klepnutí → detail.
   - FAB „+" → dialog: *Nový prázdný seznam* / *Kopie existujícího seznamu* (vybere se zdroj, zkopírují se položky, všechna zaškrtnutí se vynulují) / *Import z textu*.
   - Dlouhé podržení karty → přejmenovat / smazat (s potvrzením).

2. **Detail seznamu (režim balení)** – hlavní obrazovka
   - Nahoře volič počtu dní (stepper − / číslo / +). Změna dní okamžitě přepočítá množství u všech položek.
   - Seznam položek: checkbox, název, spočítané množství (např. „Tričko — 10 ks"). Položka = jeden řádek bez ohledu na množství (5 triček se odškrtává jako jedna položka).
   - Odškrtnuté položky se zobrazují přeškrtnuté a řadí se dolů.
   - Ukazatel průběhu „sbaleno 12/20".
   - Tlačítko **Reset** (ikona v AppBaru): odškrtne vše, zeptá se, zda změnit počet dní.
   - Tlačítko **Upravit** → režim editace.

3. **Editace seznamu**
   - Přidání položky: název + výběr jednoho ze tří režimů množství s lidsky čitelnými popisky:
     - „X kusů na den"
     - „1 kus na X dní"
     - „X kusů celkem (bez ohledu na dny)"
   - Úprava a mazání položek (swipe doleva = smazat), změna pořadí přetažením.
   - Import dalších položek z textu i do existujícího seznamu.

## Pravidla práce (pro Claude Code)

1. Před commitem vždy spusť `flutter analyze` a `flutter test` a oprav chyby.
2. Každá změna logiky (quantity, parser, kopírování seznamu, reset) = doplnit/upravit unit testy.
3. Dělej malé PR – jedna issue = jeden PR. Neřeš věci, které issue nezadává.
4. Neměň soubory v `.github/workflows/` pokud to issue výslovně nežádá.
5. Žádné nové závislosti bez zdůvodnění v popisu PR.
6. UI texty pouze přes `lib/strings.dart`.
7. Data ukládej do Hive okamžitě při každé změně (žádné tlačítko „uložit").

## Struktura projektu

```
lib/
  main.dart
  strings.dart
  models/        (PackingList, PackingItem, adaptery pro Hive)
  logic/         (quantity.dart, import_parser.dart, list_actions.dart)
  screens/       (lists_overview.dart, list_detail.dart, list_edit.dart)
  widgets/
test/
  logic/         (quantity_test.dart, import_parser_test.dart, ...)
```
