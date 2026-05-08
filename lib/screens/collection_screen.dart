import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/card_model.dart';
import '../providers/cards_provider.dart';
import '../providers/collection_filter_provider.dart';
import '../providers/collection_stats_provider.dart';
import '../services/export_service.dart';
import '../services/price_service.dart';
import '../widgets/card_list_item.dart';
import 'card_detail_screen.dart';

class CollectionScreen extends ConsumerStatefulWidget {
  const CollectionScreen({super.key});

  @override
  ConsumerState<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends ConsumerState<CollectionScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete(CardModel card) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar carta'),
        content: Text('¿Eliminar "${card.name}" de tu colección?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(cardsProvider.notifier).deleteCard(card.id);
    messenger.showSnackBar(
      SnackBar(
        content: Text('Carta eliminada: ${card.name}'),
        action: SnackBarAction(
          label: 'Deshacer',
          onPressed: () =>
              ref.read(cardsProvider.notifier).restoreCard(card),
        ),
      ),
    );
  }

  Future<void> _openFilters() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _FilterSheet(),
    );
  }

  Future<void> _exportCollection(ExportFormat format) async {
    final cards = ref.read(cardsProvider);
    if (cards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tu colección está vacía.')),
      );
      return;
    }
    try {
      final service = ExportService();
      switch (format) {
        case ExportFormat.json:
          await service.exportJson(cards);
          break;
        case ExportFormat.csv:
          await service.exportCsv(cards);
          break;
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al exportar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredCards = ref.watch(filteredCardsProvider);
    final stats = ref.watch(collectionStatsProvider);
    final filter = ref.watch(collectionFilterProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Colección'),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                tooltip: 'Filtros y orden',
                icon: const Icon(Icons.tune),
                onPressed: _openFilters,
              ),
              if (filter.isActive)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          PopupMenuButton<ExportFormat>(
            tooltip: 'Exportar',
            icon: const Icon(Icons.ios_share),
            onSelected: _exportCollection,
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: ExportFormat.csv,
                child: Row(children: [
                  Icon(Icons.table_chart_outlined, size: 18),
                  SizedBox(width: 8),
                  Text('Exportar CSV'),
                ]),
              ),
              PopupMenuItem(
                value: ExportFormat.json,
                child: Row(children: [
                  Icon(Icons.data_object, size: 18),
                  SizedBox(width: 8),
                  Text('Exportar JSON'),
                ]),
              ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar cartas...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(searchQueryProvider.notifier).state = '';
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: theme.colorScheme.surface,
              ),
              onChanged: (value) {
                ref.read(searchQueryProvider.notifier).state = value;
              },
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          _StatsHeader(stats: stats),
          if (filter.isActive) const _ActiveFiltersBar(),
          Expanded(
            child: filteredCards.isEmpty
                ? _CollectionEmptyState(
                    hasSearchQuery: _searchController.text.isNotEmpty,
                    filterActive: filter.isActive,
                  )
                : ListView.builder(
                    itemCount: filteredCards.length,
                    itemBuilder: (context, index) {
                      final card = filteredCards[index];
                      return Dismissible(
                        key: ValueKey('card-${card.id}'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          color: Colors.red,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (_) async {
                          await _confirmDelete(card);
                          return false; // We handle the delete ourselves
                        },
                        child: CardListItem(
                          card: card,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    CardDetailScreen(card: card),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _StatsHeader extends StatelessWidget {
  final CollectionStats stats;

  const _StatsHeader({required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mostExpensive = stats.mostExpensive;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      color: theme.colorScheme.primary.withValues(alpha: 0.08),
      child: Row(
        children: [
          Expanded(
            child: _StatTile(
              icon: Icons.style,
              label: 'Únicas',
              value: '${stats.uniqueCards}',
            ),
          ),
          Expanded(
            child: _StatTile(
              icon: Icons.collections,
              label: 'Totales',
              value: '${stats.totalCards}',
            ),
          ),
          Expanded(
            child: _StatTile(
              icon: Icons.attach_money,
              label: 'Valor',
              value: stats.totalValue == 0
                  ? '—'
                  : PriceService.formatPrice(stats.totalValue),
            ),
          ),
          Expanded(
            child: _StatTile(
              icon: Icons.local_fire_department,
              label: 'Más cara',
              value: mostExpensive != null
                  ? PriceService.formatPrice(mostExpensive.priceValue!)
                  : '—',
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            maxLines: 1,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
      ],
    );
  }
}

class _ActiveFiltersBar extends ConsumerWidget {
  const _ActiveFiltersBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(collectionFilterProvider);
    final notifier = ref.read(collectionFilterProvider.notifier);

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: [
          if (filter.sortBy != SortBy.dateAddedDesc)
            _FilterChipPill(
              label: filter.sortBy.label,
              icon: Icons.sort,
              onRemove: () => notifier.setSortBy(SortBy.dateAddedDesc),
            ),
          if (filter.priceStatus != PriceStatus.all)
            _FilterChipPill(
              label: filter.priceStatus.label,
              icon: Icons.attach_money,
              onRemove: () => notifier.setPriceStatus(PriceStatus.all),
            ),
          for (final exp in filter.expansions)
            _FilterChipPill(
              label: exp,
              icon: Icons.collections_bookmark,
              onRemove: () => notifier.toggleExpansion(exp),
            ),
          for (final r in filter.rarities)
            _FilterChipPill(
              label: r,
              icon: Icons.star,
              onRemove: () => notifier.toggleRarity(r),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: TextButton.icon(
              onPressed: notifier.clearAll,
              icon: const Icon(Icons.clear_all, size: 16),
              label: const Text('Limpiar'),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChipPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onRemove;

  const _FilterChipPill({
    required this.label,
    required this.icon,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InputChip(
        avatar: Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        onDeleted: onRemove,
        deleteIcon: const Icon(Icons.close, size: 16),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

class _CollectionEmptyState extends StatelessWidget {
  final bool hasSearchQuery;
  final bool filterActive;

  const _CollectionEmptyState({
    required this.hasSearchQuery,
    required this.filterActive,
  });

  @override
  Widget build(BuildContext context) {
    String title;
    String hint;
    if (hasSearchQuery) {
      title = 'No se encontraron cartas';
      hint = 'Prueba con otro nombre o expansión.';
    } else if (filterActive) {
      title = 'Ningún resultado con estos filtros';
      hint = 'Ajusta o limpia los filtros para ver más cartas.';
    } else {
      title = 'No hay cartas en tu colección';
      hint = 'Usa el escáner o añade una carta manualmente.';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 100, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(hint,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _FilterSheet extends ConsumerWidget {
  const _FilterSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(collectionFilterProvider);
    final notifier = ref.read(collectionFilterProvider.notifier);
    final expansions = ref.watch(availableExpansionsProvider);
    final rarities = ref.watch(availableRaritiesProvider);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      builder: (_, scrollCtrl) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text(
                    'Filtros y orden',
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  if (filter.isActive)
                    TextButton(
                      onPressed: notifier.clearAll,
                      child: const Text('Restablecer'),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  children: [
                    const _SectionTitle('Ordenar por'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        for (final sort in SortBy.values)
                          ChoiceChip(
                            label: Text(sort.label),
                            selected: filter.sortBy == sort,
                            onSelected: (_) => notifier.setSortBy(sort),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const _SectionTitle('Estado de precio'),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final s in PriceStatus.values)
                          ChoiceChip(
                            label: Text(s.label),
                            selected: filter.priceStatus == s,
                            onSelected: (_) => notifier.setPriceStatus(s),
                          ),
                      ],
                    ),
                    if (expansions.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _SectionTitle(
                        'Expansión'
                        '${filter.expansions.isNotEmpty ? ' · ${filter.expansions.length}' : ''}',
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          for (final e in expansions)
                            FilterChip(
                              label: Text(e),
                              selected: filter.expansions.contains(e),
                              onSelected: (_) => notifier.toggleExpansion(e),
                            ),
                        ],
                      ),
                    ],
                    if (rarities.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _SectionTitle(
                        'Rareza'
                        '${filter.rarities.isNotEmpty ? ' · ${filter.rarities.length}' : ''}',
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          for (final r in rarities)
                            FilterChip(
                              label: Text(r),
                              selected: filter.rarities.contains(r),
                              onSelected: (_) => notifier.toggleRarity(r),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Aplicar'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style:
            const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }
}
