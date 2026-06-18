import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/list_actions.dart';
import '../models/packing_list.dart';
import '../state/app_state.dart';
import '../strings.dart';
import '../widgets/dialogs.dart';
import 'list_detail.dart';

class ListsOverviewScreen extends StatelessWidget {
  const ListsOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final lists = state.lists;

    return Scaffold(
      appBar: AppBar(title: const Text(S.listsTitle)),
      body: lists.isEmpty
          ? const _EmptyState()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: lists.length,
              itemBuilder: (context, i) => _ListCard(list: lists[i]),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _onNew(context),
        icon: const Icon(Icons.add),
        label: const Text(S.newListTitle),
      ),
    );
  }

  Future<void> _onNew(BuildContext context) async {
    final choice = await showModalBottomSheet<_NewListChoice>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.note_add_outlined),
              title: const Text(S.newEmptyList),
              onTap: () => Navigator.pop(ctx, _NewListChoice.empty),
            ),
            ListTile(
              leading: const Icon(Icons.copy_all_outlined),
              title: const Text(S.copyExistingList),
              onTap: () => Navigator.pop(ctx, _NewListChoice.copy),
            ),
            ListTile(
              leading: const Icon(Icons.text_snippet_outlined),
              title: const Text(S.importFromText),
              onTap: () => Navigator.pop(ctx, _NewListChoice.import),
            ),
          ],
        ),
      ),
    );
    if (choice == null || !context.mounted) return;

    switch (choice) {
      case _NewListChoice.empty:
        await _createEmpty(context);
        break;
      case _NewListChoice.copy:
        await _createCopy(context);
        break;
      case _NewListChoice.import:
        await _createFromImport(context);
        break;
    }
  }

  Future<void> _createEmpty(BuildContext context) async {
    final name = await showTextInputDialog(
      context,
      title: S.newEmptyList,
      hint: S.listNameHint,
      confirmLabel: S.create,
    );
    if (name == null || !context.mounted) return;
    final list = newEmptyList(name);
    await context.read<AppState>().addList(list);
    if (context.mounted) _openDetail(context, list.id);
  }

  Future<void> _createCopy(BuildContext context) async {
    final state = context.read<AppState>();
    final lists = state.lists;
    if (lists.isEmpty) return;

    final source = await showDialog<PackingList>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text(S.chooseSourceList),
        children: [
          for (final l in lists)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, l),
              child: Text(l.name),
            ),
        ],
      ),
    );
    if (source == null || !context.mounted) return;

    final name = await showTextInputDialog(
      context,
      title: S.copyExistingList,
      hint: S.listNameHint,
      initialValue: '${source.name} (kopie)',
      confirmLabel: S.create,
    );
    if (name == null || !context.mounted) return;

    final copy = copyList(source, name);
    await state.addList(copy);
    if (context.mounted) _openDetail(context, copy.id);
  }

  Future<void> _createFromImport(BuildContext context) async {
    final name = await showTextInputDialog(
      context,
      title: S.importFromText,
      hint: S.listNameHint,
      confirmLabel: S.add,
    );
    if (name == null || !context.mounted) return;

    final text = await showImportDialog(context);
    if (text == null || !context.mounted) return;

    final list = listFromImport(name, text);
    if (list.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(S.importEmpty)),
      );
    }
    await context.read<AppState>().addList(list);
    if (context.mounted) _openDetail(context, list.id);
  }

  void _openDetail(BuildContext context, String listId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ListDetailScreen(listId: listId)),
    );
  }
}

enum _NewListChoice { empty, copy, import }

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.luggage_outlined,
              size: 72,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              S.emptyLists,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class _ListCard extends StatelessWidget {
  final PackingList list;

  const _ListCard({required this.list});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        title: Text(
          list.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(S.itemsCount(list.items.length)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ListDetailScreen(listId: list.id),
          ),
        ),
        onLongPress: () => _onLongPress(context),
      ),
    );
  }

  Future<void> _onLongPress(BuildContext context) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text(S.rename),
              onTap: () => Navigator.pop(ctx, 'rename'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text(S.delete),
              onTap: () => Navigator.pop(ctx, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (action == null || !context.mounted) return;

    final state = context.read<AppState>();
    if (action == 'rename') {
      final name = await showTextInputDialog(
        context,
        title: S.renameList,
        initialValue: list.name,
        confirmLabel: S.save,
      );
      if (name != null) await state.renameList(list.id, name);
    } else if (action == 'delete') {
      final ok = await showConfirmDialog(
        context,
        title: S.deleteListConfirm,
        confirmLabel: S.delete,
        destructive: true,
      );
      if (ok) await state.deleteList(list.id);
    }
  }
}
