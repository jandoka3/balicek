import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

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

  /// [newIndex] je už upravený index cílové pozice (z onReorderItem).
  Future<void> reorderItems(String listId, int oldIndex, int newIndex) async {
    final list = listById(listId);
    if (list == null) return;
    final item = list.items.removeAt(oldIndex);
    list.items.insert(newIndex, item);
    await _save(list);
  }

  Future<void> _save(PackingList list) async {
    list.updatedAt = DateTime.now();
    await _box.put(list.id, list);
    notifyListeners();
  }
}
