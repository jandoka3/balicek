import 'package:balici_appka/logic/list_actions.dart';
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
