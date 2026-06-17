import 'package:flutter_test/flutter_test.dart';

import 'package:balici_appka/logic/quantity.dart';
import 'package:balici_appka/models/packing_item.dart';
import 'package:balici_appka/models/quantity_mode.dart';

PackingItem _item(QuantityMode mode, int value) => PackingItem(
      id: 'test',
      name: 'Položka',
      mode: mode,
      value: value,
    );

void main() {
  group('computeQuantity – perDay (X kusů na den)', () {
    test('value * days pro běžný počet dní', () {
      expect(computeQuantity(_item(QuantityMode.perDay, 2), 5), 10);
    });

    test('1 den', () {
      expect(computeQuantity(_item(QuantityMode.perDay, 3), 1), 3);
    });

    test('minimálně 1, i když value by dalo 0 by se nestalo (value>=1)', () {
      expect(computeQuantity(_item(QuantityMode.perDay, 1), 1), 1);
    });
  });

  group('computeQuantity – perXDays (1 kus na X dní)', () {
    test('dělitelný počet dní', () {
      // 1 kus na 5 dní, 10 dní → 2 kusy
      expect(computeQuantity(_item(QuantityMode.perXDays, 5), 10), 2);
    });

    test('nedělitelný počet dní se zaokrouhluje nahoru', () {
      // 1 krém na 5 dní, jedu na 12 dní → 3 kusy
      expect(computeQuantity(_item(QuantityMode.perXDays, 5), 12), 3);
    });

    test('méně dní než interval → minimálně 1', () {
      // 1 kus na 7 dní, jedu na 3 dny → 1 kus
      expect(computeQuantity(_item(QuantityMode.perXDays, 7), 3), 1);
    });

    test('1 den', () {
      expect(computeQuantity(_item(QuantityMode.perXDays, 5), 1), 1);
    });

    test('přesně na hranici intervalu', () {
      // 1 kus na 3 dny, 3 dny → 1 kus
      expect(computeQuantity(_item(QuantityMode.perXDays, 3), 3), 1);
      // 4 dny → 2 kusy
      expect(computeQuantity(_item(QuantityMode.perXDays, 3), 4), 2);
    });
  });

  group('computeQuantity – fixed (X kusů celkem)', () {
    test('vrací value bez ohledu na počet dní', () {
      expect(computeQuantity(_item(QuantityMode.fixed, 4), 1), 4);
      expect(computeQuantity(_item(QuantityMode.fixed, 4), 10), 4);
    });

    test('minimálně 1 pro value 0 při days >= 1', () {
      expect(computeQuantity(_item(QuantityMode.fixed, 0), 5), 1);
    });
  });

  group('computeQuantity – hraniční počet dní', () {
    test('0 dní vrací 0', () {
      expect(computeQuantity(_item(QuantityMode.perDay, 2), 0), 0);
      expect(computeQuantity(_item(QuantityMode.perXDays, 5), 0), 0);
      expect(computeQuantity(_item(QuantityMode.fixed, 4), 0), 0);
    });
  });
}
