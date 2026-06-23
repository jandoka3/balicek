import 'package:balici_appka/logic/category_tree.dart';
import 'package:balici_appka/models/packing_category.dart';
import 'package:balici_appka/models/packing_item.dart';
import 'package:balici_appka/models/packing_list.dart';
import 'package:balici_appka/models/quantity_mode.dart';
import 'package:flutter_test/flutter_test.dart';

PackingItem item(String id, String? categoryId, {bool checked = false}) =>
    PackingItem(
      id: id,
      name: id,
      mode: QuantityMode.fixed,
      value: 1,
      checked: checked,
      categoryId: categoryId,
    );

PackingCategory cat(String id, {String? parentId}) =>
    PackingCategory(id: id, name: id, parentId: parentId);

PackingList buildList({
  List<PackingCategory> categories = const [],
  List<PackingItem> items = const [],
}) {
  final now = DateTime(2026, 1, 1);
  return PackingList(
    id: 'list',
    name: 'Test',
    createdAt: now,
    updatedAt: now,
    categories: [...categories],
    items: [...items],
  );
}

void main() {
  group('childCategories / itemsInCategory', () {
    final list = buildList(
      categories: [cat('a'), cat('b', parentId: 'a'), cat('c')],
      items: [item('i1', 'a'), item('i2', 'b'), item('i3', null)],
    );

    test('vrátí přímé podkategorie', () {
      expect(childCategories(list, null).map((c) => c.id), ['a', 'c']);
      expect(childCategories(list, 'a').map((c) => c.id), ['b']);
      expect(childCategories(list, 'b'), isEmpty);
    });

    test('vrátí přímé položky kategorie (null = bez kategorie)', () {
      expect(itemsInCategory(list, 'a').map((i) => i.id), ['i1']);
      expect(itemsInCategory(list, 'b').map((i) => i.id), ['i2']);
      expect(itemsInCategory(list, null).map((i) => i.id), ['i3']);
    });
  });

  group('descendantCategoryIds', () {
    test('vrátí všechny potomky napříč úrovněmi', () {
      final list = buildList(categories: [
        cat('a'),
        cat('b', parentId: 'a'),
        cat('c', parentId: 'b'),
        cat('d', parentId: 'a'),
        cat('e'), // jiný strom
      ]);
      expect(descendantCategoryIds(list, 'a').toSet(), {'b', 'c', 'd'});
      expect(descendantCategoryIds(list, 'b').toSet(), {'c'});
      expect(descendantCategoryIds(list, 'e'), isEmpty);
    });
  });

  group('itemsInCategoryRecursive', () {
    test('zahrne položky z podkategorií', () {
      final list = buildList(
        categories: [cat('a'), cat('b', parentId: 'a')],
        items: [item('i1', 'a'), item('i2', 'b'), item('i3', null)],
      );
      expect(
        itemsInCategoryRecursive(list, 'a').map((i) => i.id).toSet(),
        {'i1', 'i2'},
      );
    });
  });

  group('categoryCheckState', () {
    test('prázdná kategorie bez položek', () {
      final list = buildList(categories: [cat('a')]);
      expect(categoryCheckState(list, 'a'), CategoryCheckState.empty);
    });

    test('nic odškrtnuto', () {
      final list = buildList(
        categories: [cat('a')],
        items: [item('i1', 'a'), item('i2', 'a')],
      );
      expect(categoryCheckState(list, 'a'), CategoryCheckState.none);
    });

    test('částečně odškrtnuto', () {
      final list = buildList(
        categories: [cat('a')],
        items: [item('i1', 'a', checked: true), item('i2', 'a')],
      );
      expect(categoryCheckState(list, 'a'), CategoryCheckState.partial);
    });

    test('vše odškrtnuto', () {
      final list = buildList(
        categories: [cat('a')],
        items: [item('i1', 'a', checked: true), item('i2', 'a', checked: true)],
      );
      expect(categoryCheckState(list, 'a'), CategoryCheckState.all);
    });

    test('počítá rekurzivně přes podkategorie', () {
      final list = buildList(
        categories: [cat('a'), cat('b', parentId: 'a')],
        items: [item('i1', 'a', checked: true), item('i2', 'b')],
      );
      // jedna v 'a' odškrtnutá, jedna v 'b' ne → částečně
      expect(categoryCheckState(list, 'a'), CategoryCheckState.partial);
      expect(categoryCheckState(list, 'b'), CategoryCheckState.none);
    });
  });

  group('cykly – isSelfOrDescendant / canSetCategoryParent', () {
    final list = buildList(categories: [
      cat('a'),
      cat('b', parentId: 'a'),
      cat('c', parentId: 'b'),
      cat('x'),
    ]);

    test('isSelfOrDescendant', () {
      expect(isSelfOrDescendant(list, 'a', 'a'), isTrue);
      expect(isSelfOrDescendant(list, 'a', 'c'), isTrue);
      expect(isSelfOrDescendant(list, 'b', 'c'), isTrue);
      expect(isSelfOrDescendant(list, 'c', 'a'), isFalse);
      expect(isSelfOrDescendant(list, 'a', 'x'), isFalse);
    });

    test('nelze nastavit rodiče na sebe sama', () {
      expect(canSetCategoryParent(list, 'a', 'a'), isFalse);
    });

    test('nelze nastavit rodiče na vlastního potomka', () {
      expect(canSetCategoryParent(list, 'a', 'c'), isFalse);
      expect(canSetCategoryParent(list, 'a', 'b'), isFalse);
    });

    test('lze nastavit platného rodiče i nejvyšší úroveň', () {
      expect(canSetCategoryParent(list, 'c', 'x'), isTrue);
      expect(canSetCategoryParent(list, 'b', null), isTrue);
    });

    test('neexistující rodič není povolen', () {
      expect(canSetCategoryParent(list, 'a', 'neexistuje'), isFalse);
    });
  });

  group('deleteCategoryWithItems', () {
    test('smaže kategorii, podkategorie i jejich položky', () {
      final list = buildList(
        categories: [cat('a'), cat('b', parentId: 'a'), cat('c')],
        items: [
          item('i1', 'a'),
          item('i2', 'b'),
          item('i3', 'c'),
          item('i4', null),
        ],
      );
      deleteCategoryWithItems(list, 'a');
      expect(list.categories.map((c) => c.id).toSet(), {'c'});
      expect(list.items.map((i) => i.id).toSet(), {'i3', 'i4'});
    });
  });

  group('deleteCategoryKeepItems', () {
    test('přesune položky a podkategorie o úroveň výš', () {
      final list = buildList(
        categories: [cat('a'), cat('b', parentId: 'a'), cat('c', parentId: 'b')],
        items: [item('i1', 'b'), item('i2', 'c')],
      );
      // smažeme prostřední 'b' → jeho položka i podkategorie 'c' jdou pod 'a'
      deleteCategoryKeepItems(list, 'b');
      expect(list.categories.map((c) => c.id).toSet(), {'a', 'c'});
      expect(categoryById(list, 'c')!.parentId, 'a');
      expect(list.items.firstWhere((i) => i.id == 'i1').categoryId, 'a');
      // i2 zůstává v 'c'
      expect(list.items.firstWhere((i) => i.id == 'i2').categoryId, 'c');
    });

    test('mazání kategorie nejvyšší úrovně přesune položky mimo kategorii', () {
      final list = buildList(
        categories: [cat('a'), cat('b', parentId: 'a')],
        items: [item('i1', 'a')],
      );
      deleteCategoryKeepItems(list, 'a');
      expect(list.categories.map((c) => c.id).toSet(), {'b'});
      expect(categoryById(list, 'b')!.parentId, isNull);
      expect(list.items.first.categoryId, isNull);
    });
  });

  group('flattenedCategories', () {
    test('vrátí kategorie ve stromovém pořadí s hloubkou', () {
      final list = buildList(categories: [
        cat('a'),
        cat('b', parentId: 'a'),
        cat('c', parentId: 'b'),
        cat('d'),
      ]);
      final flat = flattenedCategories(list);
      expect(flat.map((e) => e.category.id), ['a', 'b', 'c', 'd']);
      expect(flat.map((e) => e.depth), [0, 1, 2, 0]);
    });
  });
}
