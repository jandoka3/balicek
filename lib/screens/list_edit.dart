import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/category_tree.dart';
import '../logic/list_actions.dart';
import '../models/packing_category.dart';
import '../models/packing_item.dart';
import '../models/packing_list.dart';
import '../models/quantity_mode.dart';
import '../state/app_state.dart';
import '../strings.dart';
import '../widgets/dialogs.dart';

class ListEditScreen extends StatefulWidget {
  final String listId;

  const ListEditScreen({super.key, required this.listId});

  @override
  State<ListEditScreen> createState() => _ListEditScreenState();
}

class _ListEditScreenState extends State<ListEditScreen> {
  final Set<String> _selectedIds = {};
  bool _selectionMode = false;

  String get listId => widget.listId;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final list = state.listById(listId);

    if (list == null) {
      return const Scaffold(body: Center(child: Text('Seznam nenalezen')));
    }

    final empty = list.items.isEmpty && list.categories.isEmpty;

    return Scaffold(
      appBar: AppBar(
        leading: _selectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                tooltip: S.selectionCancel,
                onPressed: _exitSelectionMode,
              )
            : null,
        title: Text(
          _selectionMode ? S.selectedCount(_selectedIds.length) : S.editTitle,
        ),
        actions: _selectionMode
            ? [
                IconButton(
                  icon: const Icon(Icons.drive_file_move_outline),
                  tooltip: S.moveToCategory,
                  onPressed: _selectedIds.isEmpty
                      ? null
                      : () => _onMoveSelected(context, list),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: S.delete,
                  onPressed: _selectedIds.isEmpty
                      ? null
                      : () => _onDeleteSelected(context),
                ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.checklist),
                  tooltip: S.selectItems,
                  onPressed: list.items.isEmpty ? null : _enterSelectionMode,
                ),
                IconButton(
                  icon: const Icon(Icons.create_new_folder_outlined),
                  tooltip: S.addCategory,
                  onPressed: () => _onAddCategory(context, parentId: null),
                ),
                IconButton(
                  icon: const Icon(Icons.text_snippet_outlined),
                  tooltip: S.importTitle,
                  onPressed: () => _onImport(context),
                ),
              ],
      ),
      body: empty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(S.emptyItems, textAlign: TextAlign.center),
              ),
            )
          : _EditTree(
              listId: listId,
              list: list,
              selectionMode: _selectionMode,
              selectedIds: _selectedIds,
              onToggleSelect: _toggleSelected,
              onLongPressItem: _selectAndEnterSelectionMode,
            ),
      floatingActionButton: _selectionMode
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _onAddItem(context, categoryId: null),
              icon: const Icon(Icons.add),
              label: const Text(S.addItem),
            ),
    );
  }

  void _enterSelectionMode() {
    setState(() => _selectionMode = true);
  }

  void _exitSelectionMode() {
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  void _selectAndEnterSelectionMode(String itemId) {
    setState(() {
      _selectionMode = true;
      _selectedIds.add(itemId);
    });
  }

  void _toggleSelected(String itemId) {
    setState(() {
      if (!_selectedIds.remove(itemId)) {
        _selectedIds.add(itemId);
      }
      if (_selectedIds.isEmpty) _selectionMode = false;
    });
  }

  Future<void> _onMoveSelected(BuildContext context, PackingList list) async {
    final state = context.read<AppState>();
    final categoryId = await showCategoryPickerDialog(context, list: list);
    if (categoryId == null || !context.mounted) return;
    await state.moveItemsToCategory(
      listId,
      Set.of(_selectedIds),
      categoryId.isEmpty ? null : categoryId,
    );
    if (!mounted) return;
    _exitSelectionMode();
  }

  Future<void> _onDeleteSelected(BuildContext context) async {
    final state = context.read<AppState>();
    final confirmed = await showConfirmDialog(
      context,
      title: S.deleteSelectedConfirm(_selectedIds.length),
      confirmLabel: S.delete,
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    await state.deleteItems(listId, Set.of(_selectedIds));
    if (!mounted) return;
    _exitSelectionMode();
  }

  Future<void> _onAddItem(
    BuildContext context, {
    required String? categoryId,
  }) async {
    final result = await showItemEditor(context);
    if (result == null || !context.mounted) return;
    final item =
        newItem(result.name, result.mode, result.value, categoryId: categoryId);
    await context.read<AppState>().addItem(listId, item);
  }

  Future<void> _onAddCategory(
    BuildContext context, {
    required String? parentId,
  }) async {
    final name = await showTextInputDialog(
      context,
      title: parentId == null ? S.newCategoryTitle : S.addSubcategory,
      hint: S.categoryNameHint,
      confirmLabel: S.create,
    );
    if (name == null || !context.mounted) return;
    await context
        .read<AppState>()
        .addCategory(listId, newCategory(name, parentId: parentId));
  }

  Future<void> _onImport(BuildContext context) async {
    final text = await showImportDialog(context);
    if (text == null || !context.mounted) return;
    final items = itemsFromImport(text);
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(S.importEmpty)),
      );
      return;
    }
    await context.read<AppState>().addItems(listId, items);
  }
}

/// Stromové zobrazení pro editaci: kategorie i položky.
class _EditTree extends StatelessWidget {
  final String listId;
  final PackingList list;
  final bool selectionMode;
  final Set<String> selectedIds;
  final ValueChanged<String> onToggleSelect;
  final ValueChanged<String> onLongPressItem;

  const _EditTree({
    required this.listId,
    required this.list,
    required this.selectionMode,
    required this.selectedIds,
    required this.onToggleSelect,
    required this.onLongPressItem,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    _buildNodes(rows, parentId: null, depth: 0);
    return ListView(children: rows);
  }

  void _buildNodes(
    List<Widget> rows, {
    required String? parentId,
    required int depth,
  }) {
    for (final cat in childCategories(list, parentId)) {
      rows.add(_EditCategoryTile(
        key: ValueKey('cat_${cat.id}'),
        listId: listId,
        category: cat,
        depth: depth,
      ));
      if (cat.expanded) {
        _buildNodes(rows, parentId: cat.id, depth: depth + 1);
      }
    }
    for (final item in itemsInCategory(list, parentId)) {
      rows.add(_EditItemTile(
        key: ValueKey('item_${item.id}'),
        listId: listId,
        list: list,
        item: item,
        depth: depth,
        selectionMode: selectionMode,
        selected: selectedIds.contains(item.id),
        onToggleSelect: onToggleSelect,
        onLongPress: onLongPressItem,
      ));
    }
  }
}

class _EditCategoryTile extends StatelessWidget {
  final String listId;
  final PackingCategory category;
  final int depth;

  const _EditCategoryTile({
    super.key,
    required this.listId,
    required this.category,
    required this.depth,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    return Padding(
      padding: EdgeInsets.only(left: depth * 16.0),
      child: ListTile(
        onTap: () => state.toggleCategoryExpanded(listId, category.id),
        leading: Icon(category.expanded
            ? Icons.keyboard_arrow_down
            : Icons.keyboard_arrow_right),
        title: Row(
          children: [
            const Icon(Icons.folder_outlined, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(category.name,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: S.addItemToCategory,
              onPressed: () => _onAddItem(context),
            ),
            PopupMenuButton<String>(
              onSelected: (v) => _onMenu(context, v),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'subcat', child: Text(S.addSubcategory)),
                PopupMenuItem(value: 'rename', child: Text(S.rename)),
                PopupMenuItem(value: 'delete', child: Text(S.delete)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onAddItem(BuildContext context) async {
    final state = context.read<AppState>();
    final result = await showItemEditor(context);
    if (result == null || !context.mounted) return;
    final item =
        newItem(result.name, result.mode, result.value, categoryId: category.id);
    await state.addItem(listId, item);
    if (!category.expanded) {
      await state.toggleCategoryExpanded(listId, category.id);
    }
  }

  Future<void> _onMenu(BuildContext context, String action) async {
    final state = context.read<AppState>();
    switch (action) {
      case 'subcat':
        final name = await showTextInputDialog(
          context,
          title: S.addSubcategory,
          hint: S.categoryNameHint,
          confirmLabel: S.create,
        );
        if (name == null || !context.mounted) return;
        await state.addCategory(
            listId, newCategory(name, parentId: category.id));
        break;
      case 'rename':
        final name = await showTextInputDialog(
          context,
          title: S.renameCategory,
          initialValue: category.name,
          confirmLabel: S.save,
        );
        if (name == null) return;
        await state.renameCategory(listId, category.id, name);
        break;
      case 'delete':
        await _onDelete(context);
        break;
    }
  }

  Future<void> _onDelete(BuildContext context) async {
    final state = context.read<AppState>();
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(S.deleteCategoryTitle),
        content: const Text(S.deleteCategoryBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(S.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'moveup'),
            child: const Text(S.deleteCategoryMoveUp),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, 'delete'),
            child: const Text(S.deleteCategoryAndItems),
          ),
        ],
      ),
    );
    if (choice == null) return;
    await state.deleteCategory(
      listId,
      category.id,
      deleteItems: choice == 'delete',
    );
  }
}

class _EditItemTile extends StatelessWidget {
  final String listId;
  final PackingList list;
  final PackingItem item;
  final int depth;
  final bool selectionMode;
  final bool selected;
  final ValueChanged<String> onToggleSelect;
  final ValueChanged<String> onLongPress;

  const _EditItemTile({
    super.key,
    required this.listId,
    required this.list,
    required this.item,
    required this.depth,
    required this.selectionMode,
    required this.selected,
    required this.onToggleSelect,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    return Dismissible(
      key: ValueKey('dismiss_${item.id}'),
      direction:
          selectionMode ? DismissDirection.none : DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        color: Theme.of(context).colorScheme.error,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) => showConfirmDialog(
        context,
        title: S.deleteItemConfirm,
        confirmLabel: S.delete,
        destructive: true,
      ),
      onDismissed: (_) => state.deleteItem(listId, item.id),
      child: Padding(
        padding: EdgeInsets.only(left: depth * 16.0),
        child: ListTile(
          leading: selectionMode
              ? Checkbox(
                  value: selected,
                  onChanged: (_) => onToggleSelect(item.id),
                )
              : null,
          title: Text(item.name),
          subtitle: Text(_modeLabel(item)),
          onTap: () =>
              selectionMode ? onToggleSelect(item.id) : _onEdit(context),
          onLongPress: () => onLongPress(item.id),
        ),
      ),
    );
  }

  String _modeLabel(PackingItem item) {
    switch (item.mode) {
      case QuantityMode.perDay:
        return '${item.value} ks na den';
      case QuantityMode.perXDays:
        return '1 ks na ${item.value} dní';
      case QuantityMode.fixed:
        return '${item.value} ks celkem';
    }
  }

  Future<void> _onEdit(BuildContext context) async {
    final result = await showItemEditor(
      context,
      existing: item,
      list: list,
    );
    if (result == null || !context.mounted) return;
    final updated = item.copyWith(
      name: result.name,
      mode: result.mode,
      value: result.value,
    );
    updated.categoryId = result.categoryId;
    await context.read<AppState>().updateItem(listId, updated);
  }
}

/// Výsledek editoru položky.
class ItemEditorResult {
  final String name;
  final QuantityMode mode;
  final int value;
  final String? categoryId;
  ItemEditorResult({
    required this.name,
    required this.mode,
    required this.value,
    this.categoryId,
  });
}

/// Dialog pro přidání/úpravu položky (název + režim množství + hodnota).
///
/// Pokud je předán [list], zobrazí se i výběr kategorie (jinak se kategorie
/// zachová z [existing], případně zůstane prázdná).
Future<ItemEditorResult?> showItemEditor(
  BuildContext context, {
  PackingItem? existing,
  PackingList? list,
}) {
  final nameController = TextEditingController(text: existing?.name ?? '');
  var mode = existing?.mode ?? QuantityMode.fixed;
  var value = existing?.value ?? 1;
  String? categoryId = existing?.categoryId;

  final categories = list == null
      ? <({PackingCategory category, int depth})>[]
      : flattenedCategories(list);

  return showDialog<ItemEditorResult>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setLocal) {
          return AlertDialog(
            title: Text(existing == null ? S.addItem : S.edit),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: S.itemName,
                      hintText: S.itemNameHint,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(S.quantityMode,
                      style: Theme.of(ctx).textTheme.labelLarge),
                  RadioGroup<QuantityMode>(
                    groupValue: mode,
                    onChanged: (m) => setLocal(() => mode = m!),
                    child: const Column(
                      children: [
                        RadioListTile<QuantityMode>(
                          value: QuantityMode.perDay,
                          title: Text(S.modePerDay),
                          contentPadding: EdgeInsets.zero,
                        ),
                        RadioListTile<QuantityMode>(
                          value: QuantityMode.perXDays,
                          title: Text(S.modePerXDays),
                          contentPadding: EdgeInsets.zero,
                        ),
                        RadioListTile<QuantityMode>(
                          value: QuantityMode.fixed,
                          title: Text(S.modeFixed),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(S.value,
                          style: Theme.of(ctx).textTheme.titleMedium),
                      const Spacer(),
                      IconButton.filledTonal(
                        onPressed:
                            value > 1 ? () => setLocal(() => value--) : null,
                        icon: const Icon(Icons.remove),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('$value',
                            style: Theme.of(ctx).textTheme.titleLarge),
                      ),
                      IconButton.filledTonal(
                        onPressed: () => setLocal(() => value++),
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  if (list != null) ...[
                    const SizedBox(height: 16),
                    Text(S.category,
                        style: Theme.of(ctx).textTheme.labelLarge),
                    const SizedBox(height: 4),
                    DropdownButton<String?>(
                      isExpanded: true,
                      value: categoryId,
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text(S.noCategory),
                        ),
                        for (final e in categories)
                          DropdownMenuItem<String?>(
                            value: e.category.id,
                            child: Text(
                              '${'   ' * e.depth}${e.category.name}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (v) => setLocal(() => categoryId = v),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(S.cancel),
              ),
              FilledButton(
                onPressed: () {
                  final name = nameController.text.trim();
                  if (name.isEmpty) return;
                  Navigator.pop(
                    ctx,
                    ItemEditorResult(
                      name: name,
                      mode: mode,
                      value: value,
                      categoryId: categoryId,
                    ),
                  );
                },
                child: const Text(S.save),
              ),
            ],
          );
        },
      );
    },
  );
}
