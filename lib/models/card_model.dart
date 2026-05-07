import 'package:hive/hive.dart';

part 'card_model.g.dart';

@HiveType(typeId: 0)
class CardModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  DateTime dateAdded;

  @HiveField(3)
  int quantity;

  @HiveField(4)
  String? expansion;

  @HiveField(5)
  String? rarity;

  @HiveField(6)
  String? notes;

  @HiveField(7)
  String? imageUrl;

  @HiveField(8)
  String? price;

  @HiveField(9)
  String? cardPageUrl;

  @HiveField(10)
  String? cardApiId;

  @HiveField(11)
  String? source;

  CardModel({
    required this.id,
    required this.name,
    required this.dateAdded,
    this.quantity = 1,
    this.expansion,
    this.rarity,
    this.notes,
    this.imageUrl,
    this.price,
    this.cardPageUrl,
    this.cardApiId,
    this.source,
  });

  CardModel copyWith({
    String? id,
    String? name,
    DateTime? dateAdded,
    int? quantity,
    String? expansion,
    String? rarity,
    String? notes,
    String? imageUrl,
    String? price,
    String? cardPageUrl,
    String? cardApiId,
    String? source,
  }) {
    return CardModel(
      id: id ?? this.id,
      name: name ?? this.name,
      dateAdded: dateAdded ?? this.dateAdded,
      quantity: quantity ?? this.quantity,
      expansion: expansion ?? this.expansion,
      rarity: rarity ?? this.rarity,
      notes: notes ?? this.notes,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      cardPageUrl: cardPageUrl ?? this.cardPageUrl,
      cardApiId: cardApiId ?? this.cardApiId,
      source: source ?? this.source,
    );
  }

  @override
  String toString() {
    return 'CardModel(id: $id, name: $name, quantity: $quantity, expansion: $expansion, rarity: $rarity)';
  }
}
