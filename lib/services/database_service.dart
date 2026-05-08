import 'package:hive_flutter/hive_flutter.dart';
import '../models/card_model.dart';
import '../models/collection_snapshot.dart';
import 'price_service.dart';

class DatabaseService {
  static const String _cardsBoxName = 'cards';
  static const String _snapshotsBoxName = 'collection_snapshots';

  Box<CardModel>? _cardsBox;
  Box<CollectionSnapshot>? _snapshotsBox;

  Future<void> init() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(CardModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(CollectionSnapshotAdapter());
    }
    _cardsBox = await Hive.openBox<CardModel>(_cardsBoxName);
    _snapshotsBox =
        await Hive.openBox<CollectionSnapshot>(_snapshotsBoxName);
    await _migratePrices();
  }

  /// One-shot migration: for any card with `price` set as text but no
  /// numeric `priceValue`, parse the text and store the number.
  Future<void> _migratePrices() async {
    final box = _cardsBox!;
    for (final card in box.values) {
      if (card.priceValue != null) continue;
      final parsed = PriceService.parsePrice(card.price);
      if (parsed != null) {
        card.priceValue = parsed;
        await card.save();
      }
    }
  }

  Box<CardModel> get cardsBox {
    if (_cardsBox == null || !_cardsBox!.isOpen) {
      throw Exception('Database not initialized. Call init() first.');
    }
    return _cardsBox!;
  }

  Box<CollectionSnapshot> get snapshotsBox {
    if (_snapshotsBox == null || !_snapshotsBox!.isOpen) {
      throw Exception('Database not initialized. Call init() first.');
    }
    return _snapshotsBox!;
  }

  // CRUD Operations
  Future<void> addCard(CardModel card) async {
    await cardsBox.put(card.id, card);
  }

  Future<void> updateCard(CardModel card) async {
    await cardsBox.put(card.id, card);
  }

  Future<void> deleteCard(String id) async {
    await cardsBox.delete(id);
  }

  CardModel? getCard(String id) {
    return cardsBox.get(id);
  }

  List<CardModel> getAllCards() {
    return cardsBox.values.toList();
  }

  List<CardModel> searchCards(String query) {
    final lowerQuery = query.toLowerCase();
    return cardsBox.values
        .where((card) =>
            card.name.toLowerCase().contains(lowerQuery) ||
            (card.expansion?.toLowerCase().contains(lowerQuery) ?? false))
        .toList();
  }

  Stream<BoxEvent> watchCards() {
    return cardsBox.watch();
  }

  int get totalCards => cardsBox.length;

  Future<void> clearAllCards() async {
    await cardsBox.clear();
  }

  // Snapshot operations
  CollectionSnapshot? get latestSnapshot {
    final values = snapshotsBox.values.toList();
    if (values.isEmpty) return null;
    values.sort((a, b) => b.date.compareTo(a.date));
    return values.first;
  }

  /// Saves a snapshot for today if none exists yet for the current day.
  /// Idempotent: calling it multiple times the same day is a no-op.
  Future<void> recordDailySnapshotIfNeeded() async {
    final now = DateTime.now();
    final todayKey = _dayKey(now);
    final last = latestSnapshot;
    if (last != null && _dayKey(last.date) == todayKey) return;

    final cards = getAllCards();
    final snapshot = CollectionSnapshot(
      date: now,
      totalValue: PriceService.totalValue(cards),
      uniqueCards: cards.length,
      totalCards: cards.fold(0, (sum, c) => sum + c.quantity),
    );
    await snapshotsBox.put(todayKey, snapshot);
  }

  String _dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
