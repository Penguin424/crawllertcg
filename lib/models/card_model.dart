class CardModel {
  String id;
  String name;
  DateTime dateAdded;
  int quantity;
  String? expansion;
  String? rarity;
  String? notes;
  String? image;
  String? price;
  String? url;
  String? cardId;
  String? source;
  double? priceValue;

  CardModel({
    required this.id,
    required this.name,
    required this.dateAdded,
    this.quantity = 1,
    this.expansion,
    this.rarity,
    this.notes,
    this.image,
    this.price,
    this.url,
    this.cardId,
    this.source,
    this.priceValue,
  });

  factory CardModel.fromJson(Map<String, dynamic> json) {
    return CardModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      dateAdded: _parseDate(json['dateAdded']) ?? DateTime.now(),
      quantity: _parseInt(json['quantity']) ?? 1,
      expansion: json['expansion']?.toString(),
      rarity: json['rarity']?.toString(),
      notes: json['notes']?.toString(),
      image: json['image']?.toString(),
      price: json['price']?.toString(),
      url: json['url']?.toString(),
      cardId: json['cardId']?.toString(),
      source: json['source']?.toString(),
      priceValue: _parseDouble(json['priceValue']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dateAdded': dateAdded.toUtc().toIso8601String(),
      'quantity': quantity,
      'expansion': expansion,
      'rarity': rarity,
      'notes': notes,
      'image': image,
      'price': price,
      'url': url,
      'cardId': cardId,
      'source': source,
      'priceValue': priceValue,
    };
  }

  CardModel copyWith({
    String? id,
    String? name,
    DateTime? dateAdded,
    int? quantity,
    String? expansion,
    String? rarity,
    String? notes,
    String? image,
    String? price,
    String? url,
    String? cardId,
    String? source,
    double? priceValue,
    bool clearPriceValue = false,
  }) {
    return CardModel(
      id: id ?? this.id,
      name: name ?? this.name,
      dateAdded: dateAdded ?? this.dateAdded,
      quantity: quantity ?? this.quantity,
      expansion: expansion ?? this.expansion,
      rarity: rarity ?? this.rarity,
      notes: notes ?? this.notes,
      image: image ?? this.image,
      price: price ?? this.price,
      url: url ?? this.url,
      cardId: cardId ?? this.cardId,
      source: source ?? this.source,
      priceValue: clearPriceValue ? null : (priceValue ?? this.priceValue),
    );
  }

  @override
  String toString() {
    return 'CardModel(id: $id, name: $name, quantity: $quantity, expansion: $expansion, rarity: $rarity, priceValue: $priceValue)';
  }
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}

int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}
