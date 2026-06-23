import 'package:hive/hive.dart';

part 'packing_category.g.dart';

/// Kategorie položek v seznamu na balení (např. „Oblečení").
///
/// Strom se reprezentuje plochým seznamem s odkazem na rodiče přes
/// [parentId]. `null` znamená kategorii na nejvyšší úrovni. Díky tomu, že
/// každý uzel má nejvýše jednoho rodiče, je struktura vždy stromová – stačí
/// hlídat, aby se kategorie nestala potomkem sebe sama.
@HiveType(typeId: 3)
class PackingCategory {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  /// Id nadřazené kategorie, nebo `null` pro nejvyšší úroveň.
  @HiveField(2)
  String? parentId;

  /// Zda je kategorie v UI rozbalená (ukládá se, ať to vydrží mezi spuštěními).
  @HiveField(3)
  bool expanded;

  PackingCategory({
    required this.id,
    required this.name,
    this.parentId,
    this.expanded = true,
  });

  PackingCategory copyWith({
    String? id,
    String? name,
    String? parentId,
    bool clearParent = false,
    bool? expanded,
  }) {
    return PackingCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: clearParent ? null : (parentId ?? this.parentId),
      expanded: expanded ?? this.expanded,
    );
  }
}
