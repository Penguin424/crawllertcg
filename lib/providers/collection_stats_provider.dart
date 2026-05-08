import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/card_model.dart';
import '../services/price_service.dart';
import 'cards_provider.dart';

class CollectionStats {
  final double totalValue;
  final int uniqueCards;
  final int totalCards;
  final int cardsWithoutPrice;
  final List<CardModel> topCards;
  final Map<String, double> byExpansion;
  final Map<String, double> byRarity;
  final CardModel? mostExpensive;

  const CollectionStats({
    required this.totalValue,
    required this.uniqueCards,
    required this.totalCards,
    required this.cardsWithoutPrice,
    required this.topCards,
    required this.byExpansion,
    required this.byRarity,
    required this.mostExpensive,
  });

  bool get isEmpty => uniqueCards == 0;
  bool get hasNoPricedCards => totalValue == 0 && uniqueCards > 0;

  String? get topExpansion {
    if (byExpansion.isEmpty) return null;
    final entries = byExpansion.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.first.key;
  }

  String? get topRarity {
    if (byRarity.isEmpty) return null;
    final entries = byRarity.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.first.key;
  }
}

final collectionStatsProvider = Provider<CollectionStats>((ref) {
  final cards = ref.watch(cardsProvider);

  CardModel? mostExpensive;
  for (final card in cards) {
    if (card.priceValue == null) continue;
    if (mostExpensive == null ||
        card.priceValue! > (mostExpensive.priceValue ?? 0)) {
      mostExpensive = card;
    }
  }

  return CollectionStats(
    totalValue: PriceService.totalValue(cards),
    uniqueCards: cards.length,
    totalCards: cards.fold(0, (sum, c) => sum + c.quantity),
    cardsWithoutPrice: PriceService.cardsWithoutPrice(cards),
    topCards: PriceService.topByValue(cards, limit: 5),
    byExpansion: PriceService.valueByExpansion(cards),
    byRarity: PriceService.valueByRarity(cards),
    mostExpensive: mostExpensive,
  );
});
