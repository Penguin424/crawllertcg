import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/card_model.dart';
import '../providers/cards_provider.dart';
import '../providers/collection_filter_provider.dart';
import '../providers/collection_stats_provider.dart';
import '../services/price_service.dart';
import 'card_detail_screen.dart';
import 'home_screen.dart';

class SummaryScreen extends ConsumerWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(collectionStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumen'),
      ),
      body: stats.isEmpty
          ? const _EmptyState()
          : RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(cardsProvider);
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _HeroValueCard(stats: stats),
                  if (stats.cardsWithoutPrice > 0) ...[
                    const SizedBox(height: 16),
                    _MissingPricesBanner(
                      count: stats.cardsWithoutPrice,
                      onTap: () => _goToCollectionWithoutPriceFilter(ref),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _SecondaryMetricsGrid(stats: stats),
                  const SizedBox(height: 24),
                  if (stats.topCards.isNotEmpty) ...[
                    _SectionHeader('Top cartas más valiosas'),
                    const SizedBox(height: 8),
                    _TopCardsList(cards: stats.topCards),
                    const SizedBox(height: 24),
                  ],
                  if (stats.byExpansion.isNotEmpty) ...[
                    _SectionHeader('Valor por expansión'),
                    const SizedBox(height: 8),
                    _BreakdownBars(
                      data: stats.byExpansion,
                      total: stats.totalValue,
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (stats.byRarity.isNotEmpty) ...[
                    _SectionHeader('Valor por rareza'),
                    const SizedBox(height: 8),
                    _BreakdownChips(data: stats.byRarity),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
    );
  }

  void _goToCollectionWithoutPriceFilter(WidgetRef ref) {
    ref
        .read(collectionFilterProvider.notifier)
        .setPriceStatus(PriceStatus.withoutPrice);
    ref.read(searchQueryProvider.notifier).state = '';
    ref.read(selectedIndexProvider.notifier).state = 1; // Almacén tab
  }
}

class _EmptyState extends ConsumerWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.dashboard_outlined,
                size: 100, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Aún no tienes cartas',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Empieza escaneando o añadiendo cartas para ver aquí el valor de tu colección.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: const Text('Escanear primera carta'),
              onPressed: () =>
                  ref.read(selectedIndexProvider.notifier).state = 2,
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroValueCard extends StatelessWidget {
  final CollectionStats stats;

  const _HeroValueCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final valueText = stats.totalValue == 0
        ? '— —'
        : PriceService.formatPrice(stats.totalValue);

    return Card(
      elevation: 4,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.85),
              theme.colorScheme.primary,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Valor de tu colección',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              valueText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 38,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _heroChip(
                    icon: Icons.style,
                    label: '${stats.uniqueCards} únicas'),
                const SizedBox(width: 8),
                _heroChip(
                    icon: Icons.collections,
                    label: '${stats.totalCards} totales'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _MissingPricesBanner extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _MissingPricesBanner({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.amber.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.amber[800]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$count carta${count == 1 ? '' : 's'} sin precio. Añádelo para que aparezca${count == 1 ? '' : 'n'} en el total.',
                  style: TextStyle(color: Colors.amber[900], fontSize: 13),
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.amber[800]),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecondaryMetricsGrid extends StatelessWidget {
  final CollectionStats stats;

  const _SecondaryMetricsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final mostExpensive = stats.mostExpensive;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.6,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _MetricTile(
          icon: Icons.local_fire_department,
          label: 'Carta más cara',
          value: mostExpensive != null
              ? PriceService.formatPrice(mostExpensive.priceValue!)
              : '—',
          subtitle: mostExpensive?.name,
        ),
        _MetricTile(
          icon: Icons.collections_bookmark,
          label: 'Expansión top',
          value: stats.topExpansion ?? '—',
          subtitle: stats.topExpansion != null
              ? PriceService.formatPrice(stats.byExpansion[stats.topExpansion]!)
              : null,
        ),
        _MetricTile(
          icon: Icons.star,
          label: 'Rareza top',
          value: stats.topRarity ?? '—',
          subtitle: stats.topRarity != null
              ? PriceService.formatPrice(stats.byRarity[stats.topRarity]!)
              : null,
        ),
        _MetricTile(
          icon: Icons.help_outline,
          label: 'Sin precio',
          value: '${stats.cardsWithoutPrice}',
          subtitle: stats.cardsWithoutPrice == 0
              ? 'Todo cubierto'
              : 'cartas a completar',
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? subtitle;

  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon,
                    size: 16, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 6),
                Text(label,
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey[600])),
              ],
            ),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }
}

class _TopCardsList extends StatelessWidget {
  final List<CardModel> cards;
  const _TopCardsList({required this.cards});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            ListTile(
              leading: CircleAvatar(
                backgroundColor:
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                child: Text(
                  '${i + 1}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              title: Text(cards[i].name,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                '${PriceService.formatPrice(cards[i].priceValue!)} × ${cards[i].quantity}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              trailing: Text(
                PriceService.formatPrice(
                    cards[i].priceValue! * cards[i].quantity),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CardDetailScreen(card: cards[i]),
                  ),
                );
              },
            ),
            if (i < cards.length - 1)
              const Divider(height: 1, indent: 72),
          ],
        ],
      ),
    );
  }
}

class _BreakdownBars extends StatelessWidget {
  final Map<String, double> data;
  final double total;

  const _BreakdownBars({required this.data, required this.total});

  @override
  Widget build(BuildContext context) {
    final entries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxValue = entries.first.value;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (final entry in entries.take(8)) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.key,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        Text(
                          PriceService.formatPrice(entry.value),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: maxValue == 0 ? 0 : entry.value / maxValue,
                        minHeight: 6,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation(
                            Theme.of(context).colorScheme.primary),
                      ),
                    ),
                    if (total > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          '${(entry.value / total * 100).toStringAsFixed(1)}% del total',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey[600]),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BreakdownChips extends StatelessWidget {
  final Map<String, double> data;

  const _BreakdownChips({required this.data});

  @override
  Widget build(BuildContext context) {
    final entries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final entry in entries)
          Chip(
            label: Text(
              '${entry.key} · ${PriceService.formatPrice(entry.value)}',
              style: const TextStyle(fontSize: 12),
            ),
          ),
      ],
    );
  }
}
