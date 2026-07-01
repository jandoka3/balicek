import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../logic/category_tree.dart';
import '../logic/list_actions.dart';
import '../models/packing_category.dart';
import '../models/packing_item.dart';
import '../models/packing_list.dart';

/// Centrální stav aplikace nad Hive boxem.
///
/// Každá změna se okamžitě ukládá do Hive (žádné tlačítko „uložit").
class AppState extends ChangeNotifier {
  static const boxName = 'packing_lists';

  final Box<PackingList> _box;

  AppState(this._box);

  /// Seznamy seřazené od naposledy upravených.
  List<PackingList> get lists {
    final all = _box.values.toList();
    all.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return all;
  }

  PackingList? listById(String id) {
    for (final l in _box.values) {
      if (l.id == id) return l;
    }
    return null;
  }

  Future<void> addList(PackingList list) async {
    await _box.put(list.id, list);
    notifyListeners();
  }

  Future<void> deleteList(String id) async {
    await _box.delete(id);
    notifyListeners();
  }

  Future<void> renameList(String id, String newName) async {
    final list = listById(id);
    if (list == null) return;
    list.name = newName;
    await _save(list);
  }

  Future<void> setDays(String id, int days) async {
    final list = listById(id);
    if (list == null) return;
    list.days = days < 1 ? 1 : days;
    await _save(list);
  }

  Future<void> toggleItem(String listId, String itemId, bool checked) async {
    final list = listById(listId);
    if (list == null) return;
    for (final i in list.items) {
      if (i.id == itemId) {
        i.checked = checked;
        break;
      }
    }
    await _save(list);
  }

  Future<void> resetChecks(String id, {int? newDays}) async {
    final list = listById(id);
    if (list == null) return;
    for (final i in list.items) {
      i.checked = false;
    }
    if (newDays != null) list.days = newDays < 1 ? 1 : newDays;
    await _save(list);
  }

  Future<void> addItem(String listId, PackingItem item) async {
    final list = listById(listId);
    if (list == null) return;
    list.items.add(item);
    await _save(list);
  }

  Future<void> addItems(String listId, List<PackingItem> items) async {
    final list = listById(listId);
    if (list == null) return;
    list.items.addAll(items);
    await _save(list);
  }

  Future<void> updateItem(String listId, PackingItem updated) async {
    final list = listById(listId);
    if (list == null) return;
    final idx = list.items.indexWhere((i) => i.id == updated.id);
    if (idx == -1) return;
    list.items[idx] = updated;
    await _save(list);
  }

  Future<void> deleteItem(String listId, String itemId) async {
    final list = listById(listId);
    if (list == null) return;
    list.items.removeWhere((i) => i.id == itemId);
    await _save(list);
  }

  /// Přesune položku [itemId] do kategorie [targetCategoryId] a zařadí ji
  /// před položku [beforeItemId] (na konec, pokud je `null`). Používá se pro
  /// drag & drop – reorder i přesun mezi kategoriemi v jedné operaci.
  Future<void> moveItem(
    String listId,
    String itemId, {
    required String? targetCategoryId,
    String? beforeItemId,
  }) async {
    final list = listById(listId);
    if (list == null) return;
    moveItemInList(
      list,
      itemId,
      targetCategoryId: targetCategoryId,
      beforeItemId: beforeItemId,
    );
    await _save(list);
  }

  // --- Kategorie ---

  Future<void> addCategory(String listId, PackingCategory category) async {
    final list = listById(listId);
    if (list == null) return;
    list.categories.add(category);
    await _save(list);
  }

  Future<void> renameCategory(
    String listId,
    String categoryId,
    String newName,
  ) async {
    final list = listById(listId);
    if (list == null) return;
    final cat = categoryById(list, categoryId);
    if (cat == null) return;
    cat.name = newName;
    await _save(list);
  }

  /// Změní rodiče kategorie. Vrátí `false`, pokud by vznikl cyklus.
  Future<bool> setCategoryParent(
    String listId,
    String categoryId,
    String? newParentId,
  ) async {
    final list = listById(listId);
    if (list == null) return false;
    if (!canSetCategoryParent(list, categoryId, newParentId)) return false;
    final cat = categoryById(list, categoryId);
    if (cat == null) return false;
    cat.parentId = newParentId;
    await _save(list);
    return true;
  }

  Future<void> toggleCategoryExpanded(String listId, String categoryId) async {
    final list = listById(listId);
    if (list == null) return;
    final cat = categoryById(list, categoryId);
    if (cat == null) return;
    cat.expanded = !cat.expanded;
    await _save(list);
  }

  /// Smaže kategorii. Pokud [deleteItems] je `true`, smaže i položky a
  /// podkategorie; jinak je přesune o úroveň výš.
  Future<void> deleteCategory(
    String listId,
    String categoryId, {
    required bool deleteItems,
  }) async {
    final list = listById(listId);
    if (list == null) return;
    if (deleteItems) {
      deleteCategoryWithItems(list, categoryId);
    } else {
      deleteCategoryKeepItems(list, categoryId);
    }
    await _save(list);
  }

  Future<void> _save(PackingList list) async {
    list.updatedAt = DateTime.now();
    await _box.put(list.id, list);
    notifyListeners();
  }
}
