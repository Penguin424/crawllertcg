import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/cards_provider.dart';
import '../services/flesh_and_blood_service.dart';
import '../services/price_service.dart';
import 'add_card_screen.dart';
import 'card_detail_screen.dart';

class CardSearchResultsScreen extends ConsumerWidget {
  final List<FleshAndBloodCard> results;
  final String imagePath;
  final String searchQuery;

  const CardSearchResultsScreen({
    super.key,
    required this.results,
    required this.imagePath,
    required this.searchQuery,
  });

  Future<void> _saveCard(
    BuildContext context,
    WidgetRef ref,
    FleshAndBloodCard card,
  ) async {
    final quantity = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _QuantitySheet(card: card, initialQuantity: 1),
    );

    if (quantity == null || !context.mounted) return;

    await ref.read(cardsProvider.notifier).addCard(
          name: card.name,
          quantity: quantity,
          expansion: card.expansion,
          rarity: card.rarity,
          image: card.image,
          price: card.price,
          priceValue: PriceService.parsePrice(card.price),
          url: card.url,
          cardId: card.cardId,
          source: card.source,
          dateAdded: DateTime.now(),
        );

    if (!context.mounted) return;

    final savedCard = ref.read(cardsProvider).last;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Carta añadida a la colección'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => CardDetailScreen(card: savedCard)),
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultados de búsqueda'),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.withValues(alpha: 0.1),
            child: Row(
              children: [
                Icon(Icons.search, color: Colors.blue[700]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${results.length} resultado(s) para "$searchQuery"',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: results.length,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemBuilder: (context, index) {
                final card = results[index];
                return _SearchResultCard(
                  card: card,
                  onSave: () => _saveCard(context, ref, card),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddCardScreen(
                      initialName: searchQuery,
                      imagePath: imagePath,
                    ),
                  ),
                ),
                icon: const Icon(Icons.edit),
                label: const Text('Ingresar manualmente'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  final FleshAndBloodCard card;
  final VoidCallback onSave;

  const _SearchResultCard({required this.card, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: card.image != null
                  ? Image.network(
                      card.image!,
                      width: 80,
                      height: 112,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imagePlaceholder(),
                    )
                  : _imagePlaceholder(),
            ),
            const SizedBox(width: 12),
            // Datos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre + botón
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          card.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: onSave,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Añadir'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Precio
                  if (card.price != null)
                    Row(
                      children: [
                        Icon(Icons.attach_money,
                            size: 16, color: Colors.green[700]),
                        Text(
                          card.price!,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 4),
                  // Rareza y Expansion
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (card.rarity != null)
                        _Chip(
                          icon: Icons.star_outline,
                          label: card.rarity!,
                          color: Colors.purple,
                        ),
                      if (card.expansion != null)
                        _Chip(
                          icon: Icons.collections_bookmark_outlined,
                          label: card.expansion!,
                          color: Colors.teal,
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Card ID
                  if (card.cardId != null)
                    Row(
                      children: [
                        Icon(Icons.tag, size: 13, color: Colors.grey[500]),
                        const SizedBox(width: 3),
                        Text(
                          card.cardId!,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  // Source
                  if (card.source != null)
                    Row(
                      children: [
                        Icon(Icons.public, size: 13, color: Colors.grey[500]),
                        const SizedBox(width: 3),
                        Text(
                          card.source!,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  // URL
                  if (card.url != null)
                    InkWell(
                      onTap: () async {
                        final uri = Uri.tryParse(card.url!);
                        if (uri != null && await canLaunchUrl(uri)) {
                          await launchUrl(uri,
                              mode: LaunchMode.externalApplication);
                        }
                      },
                      child: Row(
                        children: [
                          Icon(Icons.open_in_new,
                              size: 13, color: Colors.blue[600]),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              card.url!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[600],
                                decoration: TextDecoration.underline,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 80,
      height: 112,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.image_not_supported, color: Colors.grey[400]),
    );
  }
}

class _QuantitySheet extends StatefulWidget {
  final FleshAndBloodCard card;
  final int initialQuantity;

  const _QuantitySheet({required this.card, required this.initialQuantity});

  @override
  State<_QuantitySheet> createState() => _QuantitySheetState();
}

class _QuantitySheetState extends State<_QuantitySheet> {
  late int _quantity;

  @override
  void initState() {
    super.initState();
    _quantity = widget.initialQuantity;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.card.name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (widget.card.rarity != null) ...[
            const SizedBox(height: 4),
            Text(
              widget.card.rarity!,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
          const SizedBox(height: 24),
          const Text(
            'Cantidad a añadir',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.outlined(
                icon: const Icon(Icons.remove),
                onPressed:
                    _quantity > 1 ? () => setState(() => _quantity--) : null,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  '$_quantity',
                  style: const TextStyle(
                      fontSize: 32, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton.outlined(
                icon: const Icon(Icons.add),
                onPressed:
                    _quantity < 99 ? () => setState(() => _quantity++) : null,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, _quantity),
                  child: const Text('Confirmar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Chip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
                fontSize: 12, color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
