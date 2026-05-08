import 'package:hive/hive.dart';

part 'collection_snapshot.g.dart';

@HiveType(typeId: 1)
class CollectionSnapshot extends HiveObject {
  @HiveField(0)
  DateTime date;

  @HiveField(1)
  double totalValue;

  @HiveField(2)
  int uniqueCards;

  @HiveField(3)
  int totalCards;

  CollectionSnapshot({
    required this.date,
    required this.totalValue,
    required this.uniqueCards,
    required this.totalCards,
  });

  String get dayKey =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
