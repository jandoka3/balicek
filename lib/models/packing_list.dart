import 'package:hive/hive.dart';

import 'packing_item.dart';

part 'packing_list.g.dart';

/// Seznam věcí na balení (např. „Rodinná dovolená").
@HiveType(typeId: 2)
class PackingList {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  /// Aktuálně zvolený počet dní (default 3).
  @HiveField(2)
  int days;

  @HiveField(3)
  List<PackingItem> items;

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  DateTime updatedAt;

  PackingList({
    required this.id,
    required this.name,
    this.days = 3,
    List<PackingItem>? items,
    required this.createdAt,
    required this.updatedAt,
  }) : items = items ?? <PackingItem>[];
}
