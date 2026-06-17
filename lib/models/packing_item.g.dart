// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'packing_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PackingItemAdapter extends TypeAdapter<PackingItem> {
  @override
  final int typeId = 1;

  @override
  PackingItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PackingItem(
      id: fields[0] as String,
      name: fields[1] as String,
      mode: fields[2] as QuantityMode,
      value: fields[3] as int,
      checked: fields[4] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, PackingItem obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.mode)
      ..writeByte(3)
      ..write(obj.value)
      ..writeByte(4)
      ..write(obj.checked);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PackingItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
