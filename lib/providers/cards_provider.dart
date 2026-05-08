import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/card_model.dart';
import '../services/database_service.dart';
import 'collection_filter_provider.dart';
import 'database_provider.dart';

class CardsNotifier extends StateNotifier<List<CardModel>> {
  final DatabaseService _databaseService;

  CardsNotifier(this._databaseService) : super([]) {
    _initialize();
  }

  Future<void> _initialize() async {
    await loadCards();
    // Best-effort: don't surface snapshot failures to the UI.
    try {
      await _databaseService.recordDailySnapshotIfNeeded(cards: state);
    } catch (_) {}
  }

  Future<void> loadCards() async {
    final cards = await _databaseService.getAllCards();
    state = cards;
  }

  Future<void> addCard({
    required String name,
    int quantity = 1,
    String? expansion,
    String? rarity,
    String? notes,
    String? image,
    String? price,
    double? priceValue,
    String? url,
    String? cardId,
    String? source,
    DateTime? dateAdded,
  }) async {
    final newCard = CardModel(
      id: const Uuid().v4(),
      name: name,
      dateAdded: dateAdded ?? DateTime.now(),
      quantity: quantity,
      expansion: expansion,
      rarity: rarity,
      notes: notes,
      image: image,
      price: price,
      priceValue: priceValue,
      url: url,
      cardId: cardId,
      source: source,
    );

    await _databaseService.addCard(newCard);
    await loadCards();
  }

  Future<void> updateCard(CardModel card) async {
    await _databaseService.updateCard(card);
    await loadCards();
  }

  Future<void> deleteCard(String id) async {
    await _databaseService.deleteCard(id);
    await loadCards();
  }

  /// Re-inserts a card preserving its original id. Used to undo a swipe-delete.
  Future<void> restoreCard(CardModel card) async {
    await _databaseService.addCard(card);
    await loadCards();
  }

  Future<void> incrementQuantity(String id) async {
    final card = _findInState(id);
    if (card != null) {
      await updateCard(card.copyWith(quantity: card.quantity + 1));
    }
  }

  Future<void> decrementQuantity(String id) async {
    final card = _findInState(id);
    if (card != null && card.quantity > 0) {
      await updateCard(card.copyWith(quantity: card.quantity - 1));
    }
  }

  CardModel? _findInState(String id) {
    for (final c in state) {
      if (c.id == id) return c;
    }
    return null;
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

/// All distinct expansion names present in the collection (sorted, no nulls/blanks).
final availableExpansionsProvider = Provider<List<String>>((ref) {
  final cards = ref.watch(cardsProvider);
  final set = <String>{};
  for (final c in cards) {
    final e = c.expansion?.trim();
    if (e != null && e.isNotEmpty) set.add(e);
  }
  final list = set.toList()..sort();
  return list;
});

/// All distinct rarity names present in the collection (sorted, no nulls/blanks).
final availableRaritiesProvider = Provider<List<String>>((ref) {
  final cards = ref.watch(cardsProvider);
  final set = <String>{};
  for (final c in cards) {
    final r = c.rarity?.trim();
    if (r != null && r.isNotEmpty) set.add(r);
  }
  final list = set.toList()..sort();
  return list;
});

final filteredCardsProvider = Provider<List<CardModel>>((ref) {
  final cards = ref.watch(cardsProvider);
  final query = ref.watch(searchQueryProvider);
  final filter = ref.watch(collectionFilterProvider);

  Iterable<CardModel> result = cards;

  switch (filter.priceStatus) {
    case PriceStatus.all:
      break;
    case PriceStatus.withPrice:
      result = result.where((c) => c.priceValue != null);
      break;
    case PriceStatus.withoutPrice:
      result = result.where((c) => c.priceValue == null);
      break;
  }

  if (filter.expansions.isNotEmpty) {
    result = result.where((c) =>
        c.expansion != null && filter.expansions.contains(c.expansion!.trim()));
  }

  if (filter.rarities.isNotEmpty) {
    result = result.where((c) =>
        c.rarity != null && filter.rarities.contains(c.rarity!.trim()));
  }

  if (query.isNotEmpty) {
    final lowerQuery = query.toLowerCase();
    result = result.where((card) =>
        card.name.toLowerCase().contains(lowerQuery) ||
        (card.expansion?.toLowerCase().contains(lowerQuery) ?? false));
  }

  final list = result.toList();
  _sortCards(list, filter.sortBy);
  return list;
});

void _sortCards(List<CardModel> list, SortBy sortBy) {
  int byPrice(CardModel a, CardModel b) {
    final av = a.priceValue;
    final bv = b.priceValue;
    if (av == null && bv == null) return 0;
    if (av == null) return 1; // nulls last
    if (bv == null) return -1;
    return av.compareTo(bv);
  }

  switch (sortBy) {
    case SortBy.dateAddedDesc:
      list.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
      break;
    case SortBy.dateAddedAsc:
      list.sort((a, b) => a.dateAdded.compareTo(b.dateAdded));
      break;
    case SortBy.nameAsc:
      list.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      break;
    case SortBy.priceDesc:
      list.sort((a, b) => byPrice(b, a));
      break;
    case SortBy.priceAsc:
      list.sort(byPrice);
      break;
    case SortBy.quantityDesc:
      list.sort((a, b) => b.quantity.compareTo(a.quantity));
      break;
    case SortBy.rarityAsc:
      list.sort((a, b) =>
          (a.rarity ?? '').toLowerCase().compareTo((b.rarity ?? '').toLowerCase()));
      break;
  }
}
