import 'package:flutter/material.dart';

import '../logic/category_tree.dart';

/// Ikonka znázorňující stav odškrtnutí kategorie.
///
/// - prázdná kategorie → tlumený prázdný kroužek
/// - nic odškrtnuto → prázdný kroužek
/// - částečně → napůl vyplněný kroužek
/// - vše odškrtnuto → vyplněné „fajfka" kolečko
class CategoryStateIcon extends StatelessWidget {
  final CategoryCheckState state;

  const CategoryStateIcon({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    switch (state) {
      case CategoryCheckState.empty:
        return Icon(Icons.radio_button_unchecked,
            color: scheme.outlineVariant, semanticLabel: 'prázdná kategorie');
      case CategoryCheckState.none:
        return Icon(Icons.radio_button_unchecked,
            color: scheme.outline, semanticLabel: 'nic odškrtnuto');
      case CategoryCheckState.partial:
        return Icon(Icons.contrast,
            color: scheme.primary, semanticLabel: 'částečně odškrtnuto');
      case CategoryCheckState.all:
        return Icon(Icons.check_circle,
            color: scheme.primary, semanticLabel: 'vše odškrtnuto');
    }
  }
}
