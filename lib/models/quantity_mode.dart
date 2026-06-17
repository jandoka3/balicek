import 'package:hive/hive.dart';

part 'quantity_mode.g.dart';

/// Režim, podle kterého se počítá množství položky v závislosti na počtu dní.
@HiveType(typeId: 0)
enum QuantityMode {
  /// Potřeba X kusů na každý den → množství = value * dny.
  @HiveField(0)
  perDay,

  /// Potřeba 1 kus na každých X dní → množství = ceil(dny / value).
  @HiveField(1)
  perXDays,

  /// Potřeba přesně X kusů bez ohledu na délku → množství = value.
  @HiveField(2)
  fixed,
}
