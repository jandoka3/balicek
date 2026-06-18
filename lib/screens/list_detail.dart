import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/quantity.dart';
import '../models/packing_item.dart';
import '../models/packing_list.dart';
import '../state/app_state.dart';
import '../strings.dart';
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
            child: list.items.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(S.emptyItems, textAlign: TextAlign.center),
                    ),
                  )
                : _ItemsList(list: list),
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

class _ItemsList extends StatelessWidget {
  final PackingList list;
  const _ItemsList({required this.list});

  @override
  Widget build(BuildContext context) {
    // Odškrtnuté dolů, jinak zachované pořadí.
    final items = [...list.items];
    items.sort((a, b) {
      if (a.checked == b.checked) return 0;
      return a.checked ? 1 : -1;
    });

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, i) => _ItemTile(list: list, item: items[i]),
    );
  }
}

class _ItemTile extends StatelessWidget {
  final PackingList list;
  final PackingItem item;
  const _ItemTile({required this.list, required this.item});

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

    return CheckboxListTile(
      value: item.checked,
      onChanged: (v) => state.toggleItem(list.id, item.id, v ?? false),
      controlAffinity: ListTileControlAffinity.leading,
      title: Text(item.name, style: style),
      secondary: Text(S.pieces(qty),
          style: Theme.of(context).textTheme.titleMedium),
    );
  }
}
