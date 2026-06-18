import 'package:uuid/uuid.dart';

import '../models/packing_item.dart';
import '../models/packing_list.dart';
import '../models/quantity_mode.dart';
import 'import_parser.dart';

const _uuid = Uuid();

/// Vytvoří nové prázdné položky z textu importu (režim fixed, value 1).
List<PackingItem> itemsFromImport(String input) {
  return parseImport(input)
      .map((name) => PackingItem(
            id: _uuid.v4(),
            name: name,
            mode: QuantityMode.fixed,
            value: 1,
            checked: false,
          ))
      .toList();
}

/// Vytvoří kopii seznamu: nové id, nový název, zkopírované položky
/// (každá s novým id), všechna zaškrtnutí vynulovaná.
PackingList copyList(PackingList source, String newName) {
  final now = DateTime.now();
  final copiedItems = source.items
      .map((i) => PackingItem(
            id: _uuid.v4(),
            name: i.name,
            mode: i.mode,
            value: i.value,
            checked: false,
          ))
      .toList();

  return PackingList(
    id: _uuid.v4(),
    name: newName,
    days: source.days,
    items: copiedItems,
    createdAt: now,
    updatedAt: now,
  );
}

/// Vytvoří nový prázdný seznam.
PackingList newEmptyList(String name) {
  final now = DateTime.now();
  return PackingList(
    id: _uuid.v4(),
    name: name,
    items: [],
    createdAt: now,
    updatedAt: now,
  );
}

/// Vytvoří nový seznam z importovaného textu.
PackingList listFromImport(String name, String input) {
  final now = DateTime.now();
  return PackingList(
    id: _uuid.v4(),
    name: name,
    items: itemsFromImport(input),
    createdAt: now,
    updatedAt: now,
  );
}

/// Vytvoří jednu novou položku.
PackingItem newItem(String name, QuantityMode mode, int value) {
  return PackingItem(
    id: _uuid.v4(),
    name: name,
    mode: mode,
    value: value < 1 ? 1 : value,
    checked: false,
  );
}
