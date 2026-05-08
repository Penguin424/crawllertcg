import 'package:intl/intl.dart';
import '../models/card_model.dart';

class PriceService {
  static final RegExp _numberPattern = RegExp(r'(\d{1,3}(?:[.,]\d{3})+|\d+)(?:[.,](\d{1,2}))?');

  /// Extracts the first decimal value from a free-form price string.
  /// Handles formats like "$10.50", "10,50 EUR", "€10.5", "1.234,56", "1,234.56".
  /// Returns null if no number can be parsed.
  static double? parsePrice(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;

    final match = _numberPattern.firstMatch(raw);
    if (match == null) return null;

    var integerPart = match.group(1)!;
    final decimalPart = match.group(2);

    final hasThousandsSeparator =
        integerPart.contains('.') || integerPart.contains(',');
    if (hasThousandsSeparator) {
      integerPart = integerPart.replaceAll(RegExp(r'[.,]'), '');
    }

    final normalized =
        decimalPart != null ? '$integerPart.$decimalPart' : integerPart;
    return double.tryParse(normalized);
  }

  /// Formats a numeric value as a currency string. Default: USD with en_US locale.
  static String formatPrice(double value, {String currency = 'USD'}) {
    final symbol = _currencySymbol(currency);
    final formatter = NumberFormat.currency(
      locale: 'en_US',
      symbol: symbol,
      decimalDigits: 2,
    );
    return formatter.format(value);
  }

  static String _currencySymbol(String code) {
    switch (code.toUpperCase()) {
      case 'EUR':
        return '€';
      case 'USD':
        return r'$';
      case 'GBP':
        return '£';
      default:
        return code.toUpperCase();
    }
  }

  /// Sum of (priceValue × quantity) across all cards. Cards without price are ignored.
  static double totalValue(List<CardModel> cards) {
    var total = 0.0;
    for (final card in cards) {
      final price = card.priceValue;
      if (price != null) total += price * card.quantity;
    }
    return total;
  }

  /// Count of cards in collection that don't have a numeric price set.
  static int cardsWithoutPrice(List<CardModel> cards) {
    return cards.where((c) => c.priceValue == null).length;
  }

  /// Map of expansion → total value contributed by cards in that expansion.
  static Map<String, double> valueByExpansion(List<CardModel> cards) {
    final map = <String, double>{};
    for (final card in cards) {
      final price = card.priceValue;
      if (price == null) continue;
      final key = card.expansion?.trim().isNotEmpty == true
          ? card.expansion!.trim()
          : 'Sin expansión';
      map[key] = (map[key] ?? 0) + price * card.quantity;
    }
    return map;
  }

  /// Map of rarity → total value contributed by cards with that rarity.
  static Map<String, double> valueByRarity(List<CardModel> cards) {
    final map = <String, double>{};
    for (final card in cards) {
      final price = card.priceValue;
      if (price == null) continue;
      final key = card.rarity?.trim().isNotEmpty == true
          ? card.rarity!.trim()
          : 'Sin rareza';
      map[key] = (map[key] ?? 0) + price * card.quantity;
    }
    return map;
  }

  /// Top N cards sorted by total value (priceValue × quantity), descending.
  static List<CardModel> topByValue(List<CardModel> cards, {int limit = 10}) {
    final priced = cards.where((c) => c.priceValue != null).toList();
    priced.sort((a, b) {
      final av = a.priceValue! * a.quantity;
      final bv = b.priceValue! * b.quantity;
      return bv.compareTo(av);
    });
    return priced.take(limit).toList();
  }
}
