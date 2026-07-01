import 'package:flutter/material.dart';

import '../logic/category_tree.dart';
import '../models/packing_list.dart';
import '../strings.dart';

/// Speciální hodnota volby „Bez kategorie" v [showCategoryPickerDialog],
/// aby šla odlišit od `null` (=zrušeno) vráceného při zavření dialogu.
const _noCategoryValue = '';

/// Dialog s jedním textovým polem. Vrátí zadaný text, nebo null při zrušení.
Future<String?> showTextInputDialog(
  BuildContext context, {
  required String title,
  String? hint,
  String initialValue = '',
  String confirmLabel = S.ok,
}) {
  final controller = TextEditingController(text: initialValue);
  return showDialog<String>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(hintText: hint),
          onSubmitted: (_) => _submit(ctx, controller),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(S.cancel),
          ),
          FilledButton(
            onPressed: () => _submit(ctx, controller),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
}

void _submit(BuildContext ctx, TextEditingController controller) {
  final value = controller.text.trim();
  if (value.isEmpty) return;
  Navigator.pop(ctx, value);
}

/// Dialog pro import položek z textu. Vrátí zadaný text, nebo null při zrušení.
Future<String?> showImportDialog(BuildContext context) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: const Text(S.importTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 4,
          maxLines: 10,
          keyboardType: TextInputType.multiline,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: S.importHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(S.cancel),
          ),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isEmpty) return;
              Navigator.pop(ctx, text);
            },
            child: const Text(S.add),
          ),
        ],
      );
    },
  );
}

/// Dialog pro výběr kategorie v seznamu [list] (např. pro hromadný přesun
/// položek). Vrátí id vybrané kategorie, prázdný řetězec pro „bez kategorie",
/// nebo `null`, pokud uživatel dialog zavřel bez potvrzení.
Future<String?> showCategoryPickerDialog(
  BuildContext context, {
  required PackingList list,
  String? initialCategoryId,
}) {
  final categories = flattenedCategories(list);
  var selected = initialCategoryId ?? _noCategoryValue;

  return showDialog<String>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setLocal) {
          return AlertDialog(
            title: const Text(S.chooseCategory),
            content: DropdownButton<String>(
              isExpanded: true,
              value: selected,
              items: [
                const DropdownMenuItem<String>(
                  value: _noCategoryValue,
                  child: Text(S.noCategory),
                ),
                for (final e in categories)
                  DropdownMenuItem<String>(
                    value: e.category.id,
                    child: Text(
                      '${'   ' * e.depth}${e.category.name}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (v) => setLocal(() => selected = v!),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(S.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, selected),
                child: const Text(S.save),
              ),
            ],
          );
        },
      );
    },
  );
}

/// Potvrzovací dialog (ano/ne). Vrátí true při potvrzení.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  String confirmLabel = S.ok,
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: Text(title),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(S.cancel),
          ),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: Theme.of(ctx).colorScheme.error,
                  )
                : null,
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
  return result ?? false;
}
