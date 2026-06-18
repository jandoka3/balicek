import 'package:flutter/material.dart';

import '../strings.dart';

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
