import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/card_model.dart';
import '../providers/cards_provider.dart';
import '../services/price_service.dart';

class CardDetailScreen extends ConsumerWidget {
  final CardModel card;

  const CardDetailScreen({super.key, required this.card});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updatedCard = ref
        .watch(cardsProvider)
        .firstWhere((c) => c.id == card.id, orElse: () => card);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles de la Carta'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Confirmar eliminación'),
                  content: Text(
                      '¿Estás seguro de eliminar "${updatedCard.name}"?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Eliminar',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );

              if (confirm == true && context.mounted) {
                await ref
                    .read(cardsProvider.notifier)
                    .deleteCard(updatedCard.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Carta eliminada'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con imagen
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              child: Column(
                children: [
                  if (updatedCard.imageUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        updatedCard.imageUrl!,
                        height: 220,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.style,
                          size: 80,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    )
                  else
                    Icon(Icons.style,
                        size: 80, color: Theme.of(context).primaryColor),
                  const SizedBox(height: 16),
                  Text(
                    updatedCard.name,
                    style: const TextStyle(
                        fontSize: 26, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  _PriceRow(card: updatedCard),
                ],
              ),
            ),

            // Cantidad
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton.filled(
                        icon: const Icon(Icons.remove),
                        onPressed: updatedCard.quantity > 0
                            ? () => ref
                                .read(cardsProvider.notifier)
                                .decrementQuantity(updatedCard.id)
                            : null,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            const Text('Cantidad',
                                style: TextStyle(
                                    fontSize: 14, color: Colors.grey)),
                            Text(
                              '${updatedCard.quantity}',
                              style: const TextStyle(
                                  fontSize: 36, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      IconButton.filled(
                        icon: const Icon(Icons.add),
                        onPressed: () => ref
                            .read(cardsProvider.notifier)
                            .incrementQuantity(updatedCard.id),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Información
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Información',
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (updatedCard.rarity != null)
                    _DetailRow(
                      icon: Icons.star,
                      label: 'Rareza',
                      value: updatedCard.rarity!,
                    ),
                  if (updatedCard.expansion != null)
                    _DetailRow(
                      icon: Icons.collections_bookmark,
                      label: 'Expansión',
                      value: updatedCard.expansion!,
                    ),
                  if (updatedCard.cardApiId != null)
                    _DetailRow(
                      icon: Icons.tag,
                      label: 'Card ID',
                      value: updatedCard.cardApiId!,
                    ),
                  if (updatedCard.source != null)
                    _DetailRow(
                      icon: Icons.public,
                      label: 'Fuente',
                      value: updatedCard.source!,
                    ),
                  _DetailRow(
                    icon: Icons.calendar_today,
                    label: 'Fecha de adición',
                    value: DateFormat('dd/MM/yyyy').format(updatedCard.dateAdded),
                  ),
                  if (updatedCard.cardPageUrl != null)
                    _UrlRow(url: updatedCard.cardPageUrl!),
                  if (updatedCard.notes != null &&
                      updatedCard.notes!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text('Notas',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(updatedCard.notes!),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600]),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                Text(value,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends ConsumerWidget {
  final CardModel card;

  const _PriceRow({required this.card});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final hasPrice = card.priceValue != null;
    final display = hasPrice
        ? PriceService.formatPrice(card.priceValue!)
        : 'Añadir precio';

    return InkWell(
      onTap: () => _editPrice(context, ref),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasPrice ? Icons.euro : Icons.add_circle_outline,
              size: 22,
              color: hasPrice ? Colors.green[700] : theme.colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              display,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color:
                    hasPrice ? Colors.green[700] : theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.edit_outlined,
                size: 16, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  Future<void> _editPrice(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(
      text: card.priceValue?.toString().replaceAll('.', ',') ?? '',
    );
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<double?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar precio'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              hintText: 'Ej. 12,50',
              prefixIcon: Icon(Icons.euro),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return null;
              if (PriceService.parsePrice(value) == null) {
                return 'Introduce un número válido';
              }
              return null;
            },
          ),
        ),
        actions: [
          if (card.priceValue != null)
            TextButton(
              onPressed: () => Navigator.pop(ctx, double.nan),
              child: const Text('Quitar precio',
                  style: TextStyle(color: Colors.red)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                final raw = controller.text.trim();
                if (raw.isEmpty) {
                  Navigator.pop(ctx, double.nan);
                } else {
                  Navigator.pop(ctx, PriceService.parsePrice(raw));
                }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (result == null) return; // Cancelled

    final isClear = result.isNaN;
    final updated = card.copyWith(
      priceValue: isClear ? null : result,
      price: isClear ? null : PriceService.formatPrice(result),
      clearPriceValue: isClear,
    );
    await ref.read(cardsProvider.notifier).updateCard(updated);
  }
}

class _UrlRow extends StatelessWidget {
  final String url;

  const _UrlRow({required this.url});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.link, color: Colors.grey[600]),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Página de la carta',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                InkWell(
                  onTap: () async {
                    final uri = Uri.tryParse(url);
                    if (uri != null && await canLaunchUrl(uri)) {
                      await launchUrl(uri,
                          mode: LaunchMode.externalApplication);
                    }
                  },
                  child: Text(
                    url,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue[600],
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
