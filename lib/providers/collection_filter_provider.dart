import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SortBy {
  dateAddedDesc,
  dateAddedAsc,
  nameAsc,
  priceDesc,
  priceAsc,
  quantityDesc,
  rarityAsc,
}

extension SortByLabel on SortBy {
  String get label {
    switch (this) {
      case SortBy.dateAddedDesc:
        return 'Más recientes';
      case SortBy.dateAddedAsc:
        return 'Más antiguas';
      case SortBy.nameAsc:
        return 'Nombre (A–Z)';
      case SortBy.priceDesc:
        return 'Precio (mayor)';
      case SortBy.priceAsc:
        return 'Precio (menor)';
      case SortBy.quantityDesc:
        return 'Cantidad';
      case SortBy.rarityAsc:
        return 'Rareza';
    }
  }
}

enum PriceStatus { all, withPrice, withoutPrice }

extension PriceStatusLabel on PriceStatus {
  String get label {
    switch (this) {
      case PriceStatus.all:
        return 'Todas';
      case PriceStatus.withPrice:
        return 'Con precio';
      case PriceStatus.withoutPrice:
        return 'Sin precio';
    }
  }
}

class CollectionFilter {
  final SortBy sortBy;
  final PriceStatus priceStatus;
  final Set<String> expansions;
  final Set<String> rarities;

  const CollectionFilter({
    this.sortBy = SortBy.dateAddedDesc,
    this.priceStatus = PriceStatus.all,
    this.expansions = const <String>{},
    this.rarities = const <String>{},
  });

  bool get isActive =>
      priceStatus != PriceStatus.all ||
      expansions.isNotEmpty ||
      rarities.isNotEmpty ||
      sortBy != SortBy.dateAddedDesc;

  int get activeCount {
    var count = 0;
    if (priceStatus != PriceStatus.all) count++;
    if (expansions.isNotEmpty) count++;
    if (rarities.isNotEmpty) count++;
    return count;
  }

  CollectionFilter copyWith({
    SortBy? sortBy,
    PriceStatus? priceStatus,
    Set<String>? expansions,
    Set<String>? rarities,
  }) {
    return CollectionFilter(
      sortBy: sortBy ?? this.sortBy,
      priceStatus: priceStatus ?? this.priceStatus,
      expansions: expansions ?? this.expansions,
      rarities: rarities ?? this.rarities,
    );
  }
}

class CollectionFilterNotifier extends StateNotifier<CollectionFilter> {
  CollectionFilterNotifier() : super(const CollectionFilter());

  void setSortBy(SortBy v) => state = state.copyWith(sortBy: v);
  void setPriceStatus(PriceStatus v) => state = state.copyWith(priceStatus: v);

  void toggleExpansion(String name) {
    final next = Set<String>.from(state.expansions);
    if (!next.add(name)) next.remove(name);
    state = state.copyWith(expansions: next);
  }

  void toggleRarity(String name) {
    final next = Set<String>.from(state.rarities);
    if (!next.add(name)) next.remove(name);
    state = state.copyWith(rarities: next);
  }

  void clearAll() => state = const CollectionFilter();
}

final collectionFilterProvider =
    StateNotifierProvider<CollectionFilterNotifier, CollectionFilter>(
  (ref) => CollectionFilterNotifier(),
);
