// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'packing_list.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PackingListAdapter extends TypeAdapter<PackingList> {
  @override
  final int typeId = 2;

  @override
  PackingList read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PackingList(
      id: fields[0] as String,
      name: fields[1] as String,
      days: fields[2] as int,
      items: (fields[3] as List).cast<PackingItem>(),
      createdAt: fields[4] as DateTime,
      updatedAt: fields[5] as DateTime,
      categories: (fields[6] as List?)?.cast<PackingCategory>(),
    );
  }

  @override
  void write(BinaryWriter writer, PackingList obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.days)
      ..writeByte(3)
      ..write(obj.items)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.updatedAt)
      ..writeByte(6)
      ..write(obj.categories);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PackingListAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
