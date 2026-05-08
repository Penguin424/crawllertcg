import 'package:flutter_test/flutter_test.dart';
import 'package:tcgs/models/card_model.dart';
import 'package:tcgs/services/price_service.dart';

void main() {
  group('PriceService.parsePrice', () {
    test('returns null for null/empty/blank', () {
      expect(PriceService.parsePrice(null), isNull);
      expect(PriceService.parsePrice(''), isNull);
      expect(PriceService.parsePrice('   '), isNull);
    });

    test('returns null when no digits present', () {
      expect(PriceService.parsePrice('diez euros'), isNull);
      expect(PriceService.parsePrice('abc'), isNull);
    });

    test('parses simple integers', () {
      expect(PriceService.parsePrice('10'), 10.0);
      expect(PriceService.parsePrice(r'$10'), 10.0);
    });

    test('parses dot decimals', () {
      expect(PriceService.parsePrice(r'$10.50'), 10.5);
      expect(PriceService.parsePrice('€10.5'), 10.5);
    });

    test('parses comma decimals', () {
      expect(PriceService.parsePrice('10,50'), 10.5);
      expect(PriceService.parsePrice('10,50 EUR'), 10.5);
    });

    test('parses european thousands format (1.234,56)', () {
      expect(PriceService.parsePrice('1.234,56'), 1234.56);
    });

    test('parses english thousands format (1,234.56)', () {
      expect(PriceService.parsePrice('1,234.56'), 1234.56);
    });

    test('extracts first number when surrounded by text', () {
      expect(PriceService.parsePrice('precio: 10.50 USD aprox'), 10.5);
    });
  });

  group('PriceService aggregations', () {
    CardModel card({
      String name = 'X',
      double? priceValue,
      int quantity = 1,
      String? expansion,
      String? rarity,
    }) =>
        CardModel(
          id: name,
          name: name,
          dateAdded: DateTime(2024),
          quantity: quantity,
          priceValue: priceValue,
          expansion: expansion,
          rarity: rarity,
        );

    test('totalValue sums priceValue × quantity, ignoring nulls', () {
      final cards = [
        card(name: 'A', priceValue: 10, quantity: 2),
        card(name: 'B', priceValue: 5.5, quantity: 1),
        card(name: 'C', priceValue: null, quantity: 10),
      ];
      expect(PriceService.totalValue(cards), 25.5);
    });

    test('cardsWithoutPrice counts only nulls', () {
      final cards = [
        card(name: 'A', priceValue: 10),
        card(name: 'B', priceValue: null),
        card(name: 'C', priceValue: null),
      ];
      expect(PriceService.cardsWithoutPrice(cards), 2);
    });

    test('topByValue ranks by priceValue × quantity', () {
      final cards = [
        card(name: 'expensive-but-1x', priceValue: 100, quantity: 1),
        card(name: 'cheap-bulk', priceValue: 5, quantity: 40),
        card(name: 'mid', priceValue: 60, quantity: 2),
      ];
      final top = PriceService.topByValue(cards, limit: 3);
      expect(top.first.name, 'cheap-bulk'); // 200
      expect(top[1].name, 'mid'); // 120
      expect(top.last.name, 'expensive-but-1x'); // 100
    });

    test('valueByExpansion groups missing as "Sin expansión"', () {
      final cards = [
        card(name: 'A', priceValue: 10, expansion: 'Welcome to Rathe'),
        card(name: 'B', priceValue: 5, expansion: 'Welcome to Rathe'),
        card(name: 'C', priceValue: 7, expansion: null),
      ];
      final map = PriceService.valueByExpansion(cards);
      expect(map['Welcome to Rathe'], 15);
      expect(map['Sin expansión'], 7);
    });

    test('valueByRarity groups missing as "Sin rareza"', () {
      final cards = [
        card(name: 'A', priceValue: 10, rarity: 'Rare'),
        card(name: 'B', priceValue: 7, rarity: null),
      ];
      final map = PriceService.valueByRarity(cards);
      expect(map['Rare'], 10);
      expect(map['Sin rareza'], 7);
    });
  });

  group('PriceService.formatPrice', () {
    test('formats EUR with two decimals', () {
      final formatted = PriceService.formatPrice(1234.5);
      expect(formatted.contains('€'), isTrue);
      expect(formatted.contains('1'), isTrue);
    });

    test('formats USD with dollar symbol', () {
      final formatted = PriceService.formatPrice(10, currency: 'USD');
      expect(formatted.contains(r'$'), isTrue);
    });
  });
}
