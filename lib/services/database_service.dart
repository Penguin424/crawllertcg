import 'package:hive_flutter/hive_flutter.dart';
import '../models/card_model.dart';

class DatabaseService {
  static const String _cardsBoxName = 'cards';
  Box<CardModel>? _cardsBox;

  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(CardModelAdapter());
    _cardsBox = await Hive.openBox<CardModel>(_cardsBoxName);
  }

  Box<CardModel> get cardsBox {
    if (_cardsBox == null || !_cardsBox!.isOpen) {
      throw Exception('Database not initialized. Call init() first.');
    }
    return _cardsBox!;
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
}
