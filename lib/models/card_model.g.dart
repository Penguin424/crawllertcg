// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'card_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CardModelAdapter extends TypeAdapter<CardModel> {
  @override
  final int typeId = 0;

  @override
  CardModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CardModel(
      id: fields[0] as String,
      name: fields[1] as String,
      dateAdded: fields[2] as DateTime,
      quantity: fields[3] as int,
      expansion: fields[4] as String?,
      rarity: fields[5] as String?,
      notes: fields[6] as String?,
      imageUrl: fields[7] as String?,
      price: fields[8] as String?,
      cardPageUrl: fields[9] as String?,
      cardApiId: fields[10] as String?,
      source: fields[11] as String?,
      priceValue: fields[12] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, CardModel obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.dateAdded)
      ..writeByte(3)
      ..write(obj.quantity)
      ..writeByte(4)
      ..write(obj.expansion)
      ..writeByte(5)
      ..write(obj.rarity)
      ..writeByte(6)
      ..write(obj.notes)
      ..writeByte(7)
      ..write(obj.imageUrl)
      ..writeByte(8)
      ..write(obj.price)
      ..writeByte(9)
      ..write(obj.cardPageUrl)
      ..writeByte(10)
      ..write(obj.cardApiId)
      ..writeByte(11)
      ..write(obj.source)
      ..writeByte(12)
      ..write(obj.priceValue);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CardModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
