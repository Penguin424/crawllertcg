import 'package:dio/dio.dart';
import '../utils/http_client.dart';

class FleshAndBloodCard {
  final String name;
  final String? image;
  final String? price;
  final String? rarity;
  final String? cardId;
  final String? expansion;
  final String? source;
  final String? url;

  const FleshAndBloodCard({
    required this.name,
    this.image,
    this.price,
    this.rarity,
    this.cardId,
    this.expansion,
    this.source,
    this.url,
  });

  factory FleshAndBloodCard.fromJson(Map<String, dynamic> json) {
    return FleshAndBloodCard(
      name: json['name']?.toString() ?? '',
      image: json['image']?.toString(),
      price: json['price']?.toString(),
      rarity: json['rarity']?.toString(),
      cardId: json['cardid']?.toString() ?? json['cardId']?.toString(),
      expansion: json['expansion']?.toString(),
      source: json['source']?.toString(),
      url: json['url']?.toString(),
    );
  }
}

class FleshAndBloodService {
  static const _searchPath = '/scraper/flesh-and-blood/search';

  Future<List<FleshAndBloodCard>> searchCards(String name) async {
    try {
      final response = await HttpClient.instance.get<dynamic>(
        _searchPath,
        queryParameters: {'name': name},
      );

      final data = response.data;

      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(FleshAndBloodCard.fromJson)
            .toList();
      }

      if (data is Map<String, dynamic>) {
        final list = data['cards'] ?? data['results'] ?? data['data'] ?? [];
        if (list is List) {
          return list
              .whereType<Map<String, dynamic>>()
              .map(FleshAndBloodCard.fromJson)
              .toList();
        }
      }

      return [];
    } on DioException catch (e) {
      throw Exception('Error al buscar carta: ${e.message}');
    }
  }
}
