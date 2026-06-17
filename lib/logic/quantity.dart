import '../models/packing_item.dart';
import '../models/quantity_mode.dart';

/// Spočítá potřebné množství kusů položky [item] pro daný počet dní [days].
///
/// Toto je jediné místo v kódu, kde se množství počítá.
///
/// - [QuantityMode.perDay]: `value * days`
/// - [QuantityMode.perXDays]: `(days / value).ceil()`
/// - [QuantityMode.fixed]: `value`
///
/// Výsledek je vždy minimálně 1, pokud `days >= 1`. Pro `days < 1` vrací 0.
int computeQuantity(PackingItem item, int days) {
  if (days < 1) return 0;

  final int quantity;
  switch (item.mode) {
    case QuantityMode.perDay:
      quantity = item.value * days;
    case QuantityMode.perXDays:
      quantity = (days / item.value).ceil();
    case QuantityMode.fixed:
      quantity = item.value;
  }

  return quantity < 1 ? 1 : quantity;
}
