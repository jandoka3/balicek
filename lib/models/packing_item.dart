import 'package:hive/hive.dart';

import 'quantity_mode.dart';

part 'packing_item.g.dart';

/// Jedna položka seznamu na balení (např. „Tričko").
@HiveType(typeId: 1)
class PackingItem {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  QuantityMode mode;

  /// Význam podle [mode]:
  /// - [QuantityMode.perDay]: kusů na den
  /// - [QuantityMode.perXDays]: počet dní na 1 kus
  /// - [QuantityMode.fixed]: kusů celkem
  @HiveField(3)
  int value;

  /// Odškrtnuto při balení.
  @HiveField(4)
  bool checked;

  PackingItem({
    required this.id,
    required this.name,
    this.mode = QuantityMode.fixed,
    this.value = 1,
    this.checked = false,
  });

  PackingItem copyWith({
    String? id,
    String? name,
    QuantityMode? mode,
    int? value,
    bool? checked,
  }) {
    return PackingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      mode: mode ?? this.mode,
      value: value ?? this.value,
      checked: checked ?? this.checked,
    );
  }
}
