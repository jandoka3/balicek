import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/list_actions.dart';
import '../models/packing_item.dart';
import '../models/quantity_mode.dart';
import '../state/app_state.dart';
import '../strings.dart';
import '../widgets/dialogs.dart';

class ListEditScreen extends StatelessWidget {
  final String listId;

  const ListEditScreen({super.key, required this.listId});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final list = state.listById(listId);

    if (list == null) {
      return const Scaffold(body: Center(child: Text('Seznam nenalezen')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(S.editTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.text_snippet_outlined),
            tooltip: S.importTitle,
            onPressed: () => _onImport(context),
          ),
        ],
      ),
      body: list.items.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(S.emptyItems, textAlign: TextAlign.center),
              ),
            )
          : ReorderableListView.builder(
              itemCount: list.items.length,
              onReorderItem: (oldIndex, newIndex) =>
                  state.reorderItems(list.id, oldIndex, newIndex),
              itemBuilder: (context, i) {
                final item = list.items[i];
                return _EditItemTile(
                  key: ValueKey(item.id),
                  listId: listId,
                  item: item,
                  index: i,
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _onAddItem(context),
        icon: const Icon(Icons.add),
        label: const Text(S.addItem),
      ),
    );
  }

  Future<void> _onAddItem(BuildContext context) async {
    final result = await showItemEditor(context);
    if (result == null || !context.mounted) return;
    final item = newItem(result.name, result.mode, result.value);
    await context.read<AppState>().addItem(listId, item);
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

class _EditItemTile extends StatelessWidget {
  final String listId;
  final PackingItem item;
  final int index;

  const _EditItemTile({
    super.key,
    required this.listId,
    required this.item,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    return Dismissible(
      key: ValueKey('dismiss_${item.id}'),
      direction: DismissDirection.endToStart,
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
      child: ListTile(
        title: Text(item.name),
        subtitle: Text(_modeLabel(item)),
        trailing: ReorderableDragStartListener(
          index: index,
          child: const Icon(Icons.drag_handle),
        ),
        onTap: () => _onEdit(context),
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
    final result = await showItemEditor(context, existing: item);
    if (result == null || !context.mounted) return;
    final updated = item.copyWith(
      name: result.name,
      mode: result.mode,
      value: result.value,
    );
    await context.read<AppState>().updateItem(listId, updated);
  }
}

/// Výsledek editoru položky.
class ItemEditorResult {
  final String name;
  final QuantityMode mode;
  final int value;
  ItemEditorResult({
    required this.name,
    required this.mode,
    required this.value,
  });
}

/// Dialog pro přidání/úpravu položky (název + režim množství + hodnota).
Future<ItemEditorResult?> showItemEditor(
  BuildContext context, {
  PackingItem? existing,
}) {
  final nameController = TextEditingController(text: existing?.name ?? '');
  var mode = existing?.mode ?? QuantityMode.fixed;
  var value = existing?.value ?? 1;

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
                    ItemEditorResult(name: name, mode: mode, value: value),
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
