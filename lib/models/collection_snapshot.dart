class CollectionSnapshot {
  DateTime date;
  double totalValue;
  int uniqueCards;
  int totalCards;

  CollectionSnapshot({
    required this.date,
    required this.totalValue,
    required this.uniqueCards,
    required this.totalCards,
  });

  String get dayKey =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  factory CollectionSnapshot.fromJson(Map<String, dynamic> json) {
    return CollectionSnapshot(
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      totalValue: _parseDouble(json['totalValue']) ?? 0,
      uniqueCards: _parseInt(json['uniqueCards']) ?? 0,
      totalCards: _parseInt(json['totalCards']) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toUtc().toIso8601String(),
      'totalValue': totalValue,
      'uniqueCards': uniqueCards,
      'totalCards': totalCards,
    };
  }
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
