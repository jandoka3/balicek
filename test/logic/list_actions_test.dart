import 'package:balici_appka/logic/list_actions.dart';
import 'package:balici_appka/models/packing_category.dart';
import 'package:balici_appka/models/packing_item.dart';
import 'package:balici_appka/models/packing_list.dart';
import 'package:balici_appka/models/quantity_mode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('copyList', () {
    final now = DateTime(2026, 1, 1);
    PackingList source() => PackingList(
          id: 'src',
          name: 'Dovolená',
          days: 7,
          createdAt: now,
          updatedAt: now,
          items: [
            PackingItem(
                id: 'a',
                name: 'Tričko',
                mode: QuantityMode.perDay,
                value: 1,
                checked: true),
            PackingItem(
                id: 'b',
                name: 'Krém',
                mode: QuantityMode.perXDays,
                value: 5,
                checked: true),
          ],
        );

    test('zkopíruje všechny položky včetně režimů a hodnot', () {
      final copy = copyList(source(), 'Nová dovolená');
      expect(copy.items.length, 2);
      expect(copy.items[0].name, 'Tričko');
      expect(copy.items[0].mode, QuantityMode.perDay);
      expect(copy.items[0].value, 1);
      expect(copy.items[1].mode, QuantityMode.perXDays);
      expect(copy.items[1].value, 5);
      expect(copy.days, 7);
    });

    test('vynuluje všechna zaškrtnutí', () {
      final copy = copyList(source(), 'Nová');
      expect(copy.items.every((i) => !i.checked), isTrue);
    });

    test('nový seznam má nové id a zadaný název', () {
      final copy = copyList(source(), 'Jméno');
      expect(copy.id, isNot('src'));
      expect(copy.name, 'Jméno');
    });

    test('položky mají nová id (neodkazují na originál)', () {
      final copy = copyList(source(), 'X');
      expect(copy.items[0].id, isNot('a'));
      expect(copy.items[1].id, isNot('b'));
    });

    test('změna kopie neovlivní originál', () {
      final src = source();
      final copy = copyList(src, 'X');
      copy.items.removeAt(0);
      expect(src.items.length, 2); // originál nezměněn
    });
  });

  group('copyList s kategoriemi', () {
    final now = DateTime(2026, 1, 1);
    PackingList source() => PackingList(
          id: 'src',
          name: 'Dovolená',
          days: 5,
          createdAt: now,
          updatedAt: now,
          categories: [
            PackingCategory(id: 'c1', name: 'Oblečení'),
            PackingCategory(id: 'c2', name: 'Spodní', parentId: 'c1'),
          ],
          items: [
            PackingItem(
                id: 'a',
                name: 'Tričko',
                mode: QuantityMode.fixed,
                value: 1,
                checked: true,
                categoryId: 'c1'),
            PackingItem(
                id: 'b',
                name: 'Ponožky',
                mode: QuantityMode.fixed,
                value: 1,
                checked: false,
                categoryId: 'c2'),
            PackingItem(
                id: 'c',
                name: 'Mapa',
                mode: QuantityMode.fixed,
                value: 1,
                checked: false,
                categoryId: null),
          ],
        );

    test('zkopíruje kategorie s novými id', () {
      final copy = copyList(source(), 'Nová');
      expect(copy.categories.length, 2);
      expect(copy.categories.map((c) => c.id), isNot(contains('c1')));
      expect(copy.categories.map((c) => c.id), isNot(contains('c2')));
      expect(copy.categories.map((c) => c.name).toSet(),
          {'Oblečení', 'Spodní'});
    });

    test('zachová stromovou strukturu (přepojí parentId)', () {
      final copy = copyList(source(), 'Nová');
      final top = copy.categories.firstWhere((c) => c.name == 'Oblečení');
      final sub = copy.categories.firstWhere((c) => c.name == 'Spodní');
      expect(top.parentId, isNull);
      expect(sub.parentId, top.id);
    });

    test('položky odkazují na nové kategorie (přepojí categoryId)', () {
      final copy = copyList(source(), 'Nová');
      final top = copy.categories.firstWhere((c) => c.name == 'Oblečení');
      final sub = copy.categories.firstWhere((c) => c.name == 'Spodní');
      final tricko = copy.items.firstWhere((i) => i.name == 'Tričko');
      final ponozky = copy.items.firstWhere((i) => i.name == 'Ponožky');
      final mapa = copy.items.firstWhere((i) => i.name == 'Mapa');
      expect(tricko.categoryId, top.id);
      expect(ponozky.categoryId, sub.id);
      expect(mapa.categoryId, isNull);
    });

    test('zaškrtnutí se vynulují i u položek v kategoriích', () {
      final copy = copyList(source(), 'Nová');
      expect(copy.items.every((i) => !i.checked), isTrue);
    });
  });

  group('newCategory', () {
    test('vytvoří kategorii s id a názvem, default nejvyšší úroveň', () {
      final c = newCategory('Hygiena');
      expect(c.name, 'Hygiena');
      expect(c.id, isNotEmpty);
      expect(c.parentId, isNull);
      expect(c.expanded, isTrue);
    });

    test('umí vytvořit podkategorii', () {
      final c = newCategory('Spodní', parentId: 'c1');
      expect(c.parentId, 'c1');
    });
  });

  group('newItem s kategorií', () {
    test('umí položku rovnou zařadit do kategorie', () {
      final i = newItem('Tričko', QuantityMode.fixed, 2, categoryId: 'c1');
      expect(i.categoryId, 'c1');
      expect(i.value, 2);
    });

    test('bez kategorie má categoryId null', () {
      final i = newItem('Tričko', QuantityMode.fixed, 1);
      expect(i.categoryId, isNull);
    });
  });

  group('itemsFromImport', () {
    test('vytvoří položky v režimu fixed s hodnotou 1', () {
      final items = itemsFromImport('Tričko, Kalhoty');
      expect(items.length, 2);
      expect(items.every((i) => i.mode == QuantityMode.fixed), isTrue);
      expect(items.every((i) => i.value == 1), isTrue);
      expect(items.every((i) => !i.checked), isTrue);
    });
  });

  group('listFromImport', () {
    test('vytvoří seznam s položkami z textu', () {
      final list = listFromImport('Léto', 'Tričko\nKraťasy');
      expect(list.name, 'Léto');
      expect(list.items.length, 2);
    });
  });
}
