import '../models/packing_category.dart';
import '../models/packing_item.dart';
import '../models/packing_list.dart';

/// Stav odškrtnutí kategorie (počítá se rekurzivně přes všechny podkategorie).
enum CategoryCheckState {
  /// Kategorie (ani její podkategorie) neobsahuje žádné položky.
  empty,

  /// Žádná z položek není odškrtnutá.
  none,

  /// Část položek je odškrtnutá.
  partial,

  /// Všechny položky jsou odškrtnuté.
  all,
}

/// Najde kategorii podle [id], nebo `null`.
PackingCategory? categoryById(PackingList list, String? id) {
  if (id == null) return null;
  for (final c in list.categories) {
    if (c.id == id) return c;
  }
  return null;
}

/// Přímé podkategorie kategorie [parentId] (`null` = nejvyšší úroveň),
/// v pořadí, v jakém jsou v seznamu.
List<PackingCategory> childCategories(PackingList list, String? parentId) {
  return list.categories.where((c) => c.parentId == parentId).toList();
}

/// Přímé položky kategorie [categoryId] (`null` = bez kategorie),
/// v pořadí, v jakém jsou v seznamu.
List<PackingItem> itemsInCategory(PackingList list, String? categoryId) {
  return list.items.where((i) => i.categoryId == categoryId).toList();
}

/// Kategorie ve stromovém pořadí spolu s hloubkou zanoření (0 = nejvyšší).
/// Hodí se pro rozbalovací nabídky s odsazením podle úrovně.
List<({PackingCategory category, int depth})> flattenedCategories(
  PackingList list,
) {
  final result = <({PackingCategory category, int depth})>[];
  void walk(String? parentId, int depth) {
    for (final c in childCategories(list, parentId)) {
      result.add((category: c, depth: depth));
      walk(c.id, depth + 1);
    }
  }

  walk(null, 0);
  return result;
}

/// Id všech potomků kategorie [categoryId] (bez ní samotné).
List<String> descendantCategoryIds(PackingList list, String categoryId) {
  final result = <String>[];
  final queue = <String>[categoryId];
  // Ochrana proti případné poškozené (cyklické) struktuře.
  final visited = <String>{categoryId};
  while (queue.isNotEmpty) {
    final current = queue.removeLast();
    for (final c in list.categories) {
      if (c.parentId == current && visited.add(c.id)) {
        result.add(c.id);
        queue.add(c.id);
      }
    }
  }
  return result;
}

/// Všechny položky kategorie [categoryId] včetně položek ve všech
/// podkategoriích.
List<PackingItem> itemsInCategoryRecursive(PackingList list, String categoryId) {
  final ids = <String>{categoryId, ...descendantCategoryIds(list, categoryId)};
  return list.items.where((i) => ids.contains(i.categoryId)).toList();
}

/// Stav odškrtnutí kategorie [categoryId] napříč všemi jejími položkami
/// (rekurzivně přes podkategorie).
CategoryCheckState categoryCheckState(PackingList list, String categoryId) {
  final items = itemsInCategoryRecursive(list, categoryId);
  if (items.isEmpty) return CategoryCheckState.empty;
  final checked = items.where((i) => i.checked).length;
  if (checked == 0) return CategoryCheckState.none;
  if (checked == items.length) return CategoryCheckState.all;
  return CategoryCheckState.partial;
}

/// Vrátí `true`, pokud [nodeId] je [maybeAncestorId] nebo jeho potomek.
///
/// Postupuje od uzlu nahoru přes [PackingCategory.parentId]. Slouží k prevenci
/// cyklů – nesmíme z kategorie udělat potomka sebe sama.
bool isSelfOrDescendant(
  PackingList list,
  String maybeAncestorId,
  String? nodeId,
) {
  var current = nodeId;
  final visited = <String>{};
  while (current != null) {
    if (current == maybeAncestorId) return true;
    if (!visited.add(current)) break; // ochrana proti cyklu
    current = categoryById(list, current)?.parentId;
  }
  return false;
}

/// Lze nastavit kategorii [catId] rodiče [newParentId] (`null` = nejvyšší
/// úroveň)? Zakázané je nastavit sebe sama nebo některého ze svých potomků
/// (vzniklý by cyklus).
bool canSetCategoryParent(PackingList list, String catId, String? newParentId) {
  if (newParentId == null) return true;
  if (newParentId == catId) return false;
  if (categoryById(list, newParentId) == null) return false;
  return !isSelfOrDescendant(list, catId, newParentId);
}

/// Smaže kategorii [categoryId], všechny její podkategorie a jejich položky.
/// Mění [list] na místě.
void deleteCategoryWithItems(PackingList list, String categoryId) {
  final ids = <String>{categoryId, ...descendantCategoryIds(list, categoryId)};
  list.items.removeWhere((i) => ids.contains(i.categoryId));
  list.categories.removeWhere((c) => ids.contains(c.id));
}

/// Smaže pouze kategorii [categoryId]. Její přímé položky i přímé podkategorie
/// přesune o úroveň výš (k rodiči mazané kategorie). Mění [list] na místě.
void deleteCategoryKeepItems(PackingList list, String categoryId) {
  final category = categoryById(list, categoryId);
  if (category == null) return;
  final parentId = category.parentId;

  for (final i in list.items) {
    if (i.categoryId == categoryId) i.categoryId = parentId;
  }
  for (final c in list.categories) {
    if (c.parentId == categoryId) c.parentId = parentId;
  }
  list.categories.removeWhere((c) => c.id == categoryId);
}
