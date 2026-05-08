// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'collection_snapshot.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CollectionSnapshotAdapter extends TypeAdapter<CollectionSnapshot> {
  @override
  final int typeId = 1;

  @override
  CollectionSnapshot read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CollectionSnapshot(
      date: fields[0] as DateTime,
      totalValue: fields[1] as double,
      uniqueCards: fields[2] as int,
      totalCards: fields[3] as int,
    );
  }

  @override
  void write(BinaryWriter writer, CollectionSnapshot obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.totalValue)
      ..writeByte(2)
      ..write(obj.uniqueCards)
      ..writeByte(3)
      ..write(obj.totalCards);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CollectionSnapshotAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
