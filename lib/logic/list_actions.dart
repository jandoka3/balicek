import 'package:uuid/uuid.dart';

import '../models/packing_category.dart';
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

/// Vytvoří kopii seznamu: nové id, nový název, zkopírované položky i kategorie
/// (každá s novým id, zachovaná stromová struktura a zařazení položek),
/// všechna zaškrtnutí vynulovaná.
PackingList copyList(PackingList source, String newName) {
  final now = DateTime.now();

  // Mapa starých id kategorií na nová, ať se dají přepojit rodiče i položky.
  final idMap = <String, String>{
    for (final c in source.categories) c.id: _uuid.v4(),
  };

  final copiedCategories = source.categories
      .map((c) => PackingCategory(
            id: idMap[c.id]!,
            name: c.name,
            parentId: c.parentId == null ? null : idMap[c.parentId],
            expanded: c.expanded,
          ))
      .toList();

  final copiedItems = source.items
      .map((i) => PackingItem(
            id: _uuid.v4(),
            name: i.name,
            mode: i.mode,
            value: i.value,
            checked: false,
            categoryId: i.categoryId == null ? null : idMap[i.categoryId],
          ))
      .toList();

  return PackingList(
    id: _uuid.v4(),
    name: newName,
    days: source.days,
    items: copiedItems,
    categories: copiedCategories,
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

/// Vytvoří jednu novou položku, volitelně rovnou v kategorii [categoryId].
PackingItem newItem(
  String name,
  QuantityMode mode,
  int value, {
  String? categoryId,
}) {
  return PackingItem(
    id: _uuid.v4(),
    name: name,
    mode: mode,
    value: value < 1 ? 1 : value,
    checked: false,
    categoryId: categoryId,
  );
}

/// Vytvoří novou kategorii, volitelně jako podkategorii [parentId].
PackingCategory newCategory(String name, {String? parentId}) {
  return PackingCategory(
    id: _uuid.v4(),
    name: name,
    parentId: parentId,
  );
}

/// Smaže všechny položky, jejichž id je v [itemIds]. Mění [list] na místě.
void bulkDeleteItems(PackingList list, Set<String> itemIds) {
  list.items.removeWhere((i) => itemIds.contains(i.id));
}

/// Přeřadí všechny položky, jejichž id je v [itemIds], do kategorie
/// [categoryId] (`null` = bez kategorie). Mění [list] na místě.
void bulkMoveItemsToCategory(
  PackingList list,
  Set<String> itemIds,
  String? categoryId,
) {
  for (final i in list.items) {
    if (itemIds.contains(i.id)) i.categoryId = categoryId;
  }
}
