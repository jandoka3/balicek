// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quantity_mode.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class QuantityModeAdapter extends TypeAdapter<QuantityMode> {
  @override
  final int typeId = 0;

  @override
  QuantityMode read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return QuantityMode.perDay;
      case 1:
        return QuantityMode.perXDays;
      case 2:
        return QuantityMode.fixed;
      default:
        return QuantityMode.perDay;
    }
  }

  @override
  void write(BinaryWriter writer, QuantityMode obj) {
    switch (obj) {
      case QuantityMode.perDay:
        writer.writeByte(0);
      case QuantityMode.perXDays:
        writer.writeByte(1);
      case QuantityMode.fixed:
        writer.writeByte(2);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuantityModeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
