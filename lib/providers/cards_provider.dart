import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/card_model.dart';
import '../services/database_service.dart';
import 'database_provider.dart';

class CardsNotifier extends StateNotifier<List<CardModel>> {
  final DatabaseService _databaseService;

  CardsNotifier(this._databaseService) : super([]) {
    loadCards();
  }

  void loadCards() {
    state = _databaseService.getAllCards();
  }

  Future<void> addCard({
    required String name,
    int quantity = 1,
    String? expansion,
    String? rarity,
    String? notes,
    String? imageUrl,
    String? price,
    String? cardPageUrl,
    String? cardApiId,
    String? source,
  }) async {
    final newCard = CardModel(
      id: const Uuid().v4(),
      name: name,
      dateAdded: DateTime.now(),
      quantity: quantity,
      expansion: expansion,
      rarity: rarity,
      notes: notes,
      imageUrl: imageUrl,
      price: price,
      cardPageUrl: cardPageUrl,
      cardApiId: cardApiId,
      source: source,
    );

    await _databaseService.addCard(newCard);
    loadCards();
  }

  Future<void> updateCard(CardModel card) async {
    await _databaseService.updateCard(card);
    loadCards();
  }

  Future<void> deleteCard(String id) async {
    await _databaseService.deleteCard(id);
    loadCards();
  }

  Future<void> incrementQuantity(String id) async {
    final card = _databaseService.getCard(id);
    if (card != null) {
      await updateCard(card.copyWith(quantity: card.quantity + 1));
    }
  }

  Future<void> decrementQuantity(String id) async {
    final card = _databaseService.getCard(id);
    if (card != null && card.quantity > 0) {
      await updateCard(card.copyWith(quantity: card.quantity - 1));
    }
  }

  List<CardModel> searchCards(String query) {
    return _databaseService.searchCards(query);
  }

  int get totalCards => state.length;

  int get totalCardCount => state.fold(0, (sum, card) => sum + card.quantity);
}

final cardsProvider = StateNotifierProvider<CardsNotifier, List<CardModel>>((ref) {
  final databaseService = ref.watch(databaseServiceProvider);
  return CardsNotifier(databaseService);
});

final totalCardsCountProvider = Provider<int>((ref) {
  final cards = ref.watch(cardsProvider);
  return cards.fold(0, (sum, card) => sum + card.quantity);
});

final searchQueryProvider = StateProvider<String>((ref) => '');

final filteredCardsProvider = Provider<List<CardModel>>((ref) {
  final cards = ref.watch(cardsProvider);
  final query = ref.watch(searchQueryProvider);

  if (query.isEmpty) return cards;

  final lowerQuery = query.toLowerCase();
  return cards
      .where((card) =>
          card.name.toLowerCase().contains(lowerQuery) ||
          (card.expansion?.toLowerCase().contains(lowerQuery) ?? false))
      .toList();
});
