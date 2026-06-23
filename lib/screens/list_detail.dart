import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/category_tree.dart';
import '../logic/list_actions.dart';
import '../logic/quantity.dart';
import '../models/packing_category.dart';
import '../models/packing_item.dart';
import '../models/packing_list.dart';
import '../state/app_state.dart';
import '../strings.dart';
import '../widgets/category_icon.dart';
import 'list_edit.dart';

class ListDetailScreen extends StatelessWidget {
  final String listId;

  const ListDetailScreen({super.key, required this.listId});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final list = state.listById(listId);

    if (list == null) {
      return const Scaffold(body: Center(child: Text('Seznam nenalezen')));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(list.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.restart_alt),
            tooltip: S.reset,
            onPressed: () => _onReset(context, list),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: S.edit,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ListEditScreen(listId: listId),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _DaysStepper(list: list),
          _ProgressBar(list: list),
          const Divider(height: 1),
          Expanded(
            child: list.items.isEmpty && list.categories.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(S.emptyItems, textAlign: TextAlign.center),
                    ),
                  )
                : _ItemsTree(list: list),
          ),
        ],
      ),
    );
  }

  Future<void> _onReset(BuildContext context, PackingList list) async {
    final state = context.read<AppState>();
    final result = await showDialog<_ResetResult>(
      context: context,
      builder: (ctx) {
        int days = list.days;
        return StatefulBuilder(
          builder: (ctx, setLocal) => AlertDialog(
            title: const Text(S.resetConfirmTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(S.resetConfirmBody),
                const SizedBox(height: 16),
                const Text(S.resetChangeDays),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton.filledTonal(
                      onPressed: days > 1
                          ? () => setLocal(() => days--)
                          : null,
                      icon: const Icon(Icons.remove),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('$days',
                          style: Theme.of(ctx).textTheme.titleLarge),
                    ),
                    IconButton.filledTonal(
                      onPressed: () => setLocal(() => days++),
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(S.cancel),
              ),
              FilledButton(
                onPressed: () =>
                    Navigator.pop(ctx, _ResetResult(days: days)),
                child: const Text(S.reset),
              ),
            ],
          ),
        );
      },
    );
    if (result == null) return;
    final newDays = result.days == list.days ? null : result.days;
    await state.resetChecks(list.id, newDays: newDays);
  }
}

class _ResetResult {
  final int days;
  _ResetResult({required this.days});
}

class _DaysStepper extends StatelessWidget {
  final PackingList list;
  const _DaysStepper({required this.list});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text(S.days, style: Theme.of(context).textTheme.titleMedium),
          const Spacer(),
          IconButton.filledTonal(
            onPressed: list.days > 1
                ? () => state.setDays(list.id, list.days - 1)
                : null,
            icon: const Icon(Icons.remove),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('${list.days}',
                style: Theme.of(context).textTheme.titleLarge),
          ),
          IconButton.filledTonal(
            onPressed: () => state.setDays(list.id, list.days + 1),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final PackingList list;
  const _ProgressBar({required this.list});

  @override
  Widget build(BuildContext context) {
    final total = list.items.length;
    final done = list.packedCount;
    final value = total == 0 ? 0.0 : done / total;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(S.packed(done, total),
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(value: value, minHeight: 8),
          ),
        ],
      ),
    );
  }
}

/// Stromové zobrazení kategorií a položek (režim balení).
class _ItemsTree extends StatelessWidget {
  final PackingList list;
  const _ItemsTree({required this.list});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    _buildNodes(context, rows, parentId: null, depth: 0);
    return ListView(children: rows);
  }

  /// Položky odškrtnuté dolů, jinak zachované pořadí.
  List<PackingItem> _sortedItems(String? categoryId) {
    final items = itemsInCategory(list, categoryId);
    items.sort((a, b) {
      if (a.checked == b.checked) return 0;
      return a.checked ? 1 : -1;
    });
    return items;
  }

  void _buildNodes(
    BuildContext context,
    List<Widget> rows, {
    required String? parentId,
    required int depth,
  }) {
    // Nejprve podkategorie…
    for (final cat in childCategories(list, parentId)) {
      rows.add(_CategoryTile(list: list, category: cat, depth: depth));
      if (cat.expanded) {
        _buildNodes(context, rows, parentId: cat.id, depth: depth + 1);
      }
    }
    // …pak položky bez podkategorií (přímé položky této úrovně).
    for (final item in _sortedItems(parentId)) {
      rows.add(_ItemTile(list: list, item: item, depth: depth));
    }
  }
}

class _CategoryTile extends StatelessWidget {
  final PackingList list;
  final PackingCategory category;
  final int depth;
  const _CategoryTile({
    required this.list,
    required this.category,
    required this.depth,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final all = itemsInCategoryRecursive(list, category.id);
    final packed = all.where((i) => i.checked).length;
    final checkState = categoryCheckState(list, category.id);

    return Padding(
      padding: EdgeInsets.only(left: depth * 16.0),
      child: ListTile(
        onTap: () => state.toggleCategoryExpanded(list.id, category.id),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(category.expanded
                ? Icons.keyboard_arrow_down
                : Icons.keyboard_arrow_right),
            CategoryStateIcon(state: checkState),
          ],
        ),
        title: Text(category.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (all.isNotEmpty)
              Text('$packed/${all.length}',
                  style: Theme.of(context).textTheme.bodyMedium),
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: S.addItemToCategory,
              onPressed: () => _onAddItem(context),
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
    await state.addItem(list.id, item);
    // Ať je nová položka hned vidět.
    if (!category.expanded) {
      await state.toggleCategoryExpanded(list.id, category.id);
    }
  }
}

class _ItemTile extends StatelessWidget {
  final PackingList list;
  final PackingItem item;
  final int depth;
  const _ItemTile({required this.list, required this.item, required this.depth});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final qty = computeQuantity(item, list.days);
    final style = item.checked
        ? TextStyle(
            decoration: TextDecoration.lineThrough,
            color: Theme.of(context).disabledColor,
          )
        : null;

    return Padding(
      padding: EdgeInsets.only(left: depth * 16.0),
      child: CheckboxListTile(
        value: item.checked,
        onChanged: (v) => state.toggleItem(list.id, item.id, v ?? false),
        controlAffinity: ListTileControlAffinity.leading,
        title: Text(item.name, style: style),
        secondary: Text(S.pieces(qty),
            style: Theme.of(context).textTheme.titleMedium),
      ),
    );
  }
}
