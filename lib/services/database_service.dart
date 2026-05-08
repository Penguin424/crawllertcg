import 'package:dio/dio.dart';
import '../models/card_model.dart';
import '../models/collection_snapshot.dart';
import '../utils/http_client.dart';
import 'price_service.dart';

/// REST-backed data service. Replaces the previous Hive implementation.
/// All endpoints follow the contract described in `schema_tcgs_api.md`.
class DatabaseService {
  static const _cardsPath = '/cards';
  static const _snapshotsPath = '/collection-snapshots';

  final HttpClient _http;

  DatabaseService({HttpClient? client}) : _http = client ?? HttpClient.instance;

  // ---- Cards ----

  Future<List<CardModel>> getAllCards() async {
    final res = await _http.get<dynamic>(_cardsPath);
    return _decodeCardList(res.data);
  }

  Future<CardModel?> getCard(String id) async {
    try {
      final res = await _http.get<dynamic>('$_cardsPath/$id');
      final data = res.data;
      if (data is Map<String, dynamic>) {
        return CardModel.fromJson(data);
      }
      if (data is Map) {
        return CardModel.fromJson(Map<String, dynamic>.from(data));
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<CardModel> addCard(CardModel card) async {
    try {
      final res = await _http.post<dynamic>(_cardsPath, data: card.toJson());
      return _decodeCard(res.data) ?? card;
    } catch (e) {
      print('Error adding card: $e');
      rethrow;
    }
  }

  Future<CardModel> updateCard(CardModel card) async {
    final res = await _http.put<dynamic>(
      '$_cardsPath/${card.id}',
      data: card.toJson(),
    );
    return _decodeCard(res.data) ?? card;
  }

  Future<void> deleteCard(String id) async {
    await _http.delete<dynamic>('$_cardsPath/$id');
  }

  // ---- Snapshots ----

  Future<List<CollectionSnapshot>> getAllSnapshots() async {
    final res = await _http.get<dynamic>(_snapshotsPath);
    return _decodeSnapshotList(res.data);
  }

  Future<CollectionSnapshot?> getLatestSnapshot() async {
    final list = await getAllSnapshots();
    if (list.isEmpty) return null;
    list.sort((a, b) => b.date.compareTo(a.date));
    return list.first;
  }

  Future<CollectionSnapshot?> getSnapshotForDate(DateTime date) async {
    try {
      final res = await _http.get<dynamic>('$_snapshotsPath/${_dayKey(date)}');
      final data = res.data;
      if (data is Map<String, dynamic>) {
        return CollectionSnapshot.fromJson(data);
      }
      if (data is Map) {
        return CollectionSnapshot.fromJson(Map<String, dynamic>.from(data));
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  /// Posts a snapshot for today if none exists yet for the current day.
  /// Idempotent: calling it multiple times the same day is a no-op.
  Future<void> recordDailySnapshotIfNeeded({List<CardModel>? cards}) async {
    final now = DateTime.now();
    final existing = await getSnapshotForDate(now);
    if (existing != null) return;

    final source = cards ?? await getAllCards();
    final snapshot = CollectionSnapshot(
      date: now,
      totalValue: PriceService.totalValue(source),
      uniqueCards: source.length,
      totalCards: source.fold(0, (sum, c) => sum + c.quantity),
    );
    await _http.post<dynamic>(_snapshotsPath, data: snapshot.toJson());
  }

  // ---- Helpers ----

  static String _dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static List<CardModel> _decodeCardList(dynamic data) {
    final list = _extractList(data, ['cards', 'data', 'results']);
    return list
        .whereType<Map>()
        .map((m) => CardModel.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  static CardModel? _decodeCard(dynamic data) {
    if (data is Map<String, dynamic>) return CardModel.fromJson(data);
    if (data is Map) return CardModel.fromJson(Map<String, dynamic>.from(data));
    if (data is Map && data['card'] is Map) {
      return CardModel.fromJson(Map<String, dynamic>.from(data['card'] as Map));
    }
    return null;
  }

  static List<CollectionSnapshot> _decodeSnapshotList(dynamic data) {
    final list = _extractList(data, ['snapshots', 'data', 'results']);
    return list
        .whereType<Map>()
        .map((m) => CollectionSnapshot.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  static List<dynamic> _extractList(dynamic data, List<String> wrapperKeys) {
    if (data is List) return data;
    if (data is Map) {
      for (final key in wrapperKeys) {
        final inner = data[key];
        if (inner is List) return inner;
      }
    }
    return const [];
  }
}
