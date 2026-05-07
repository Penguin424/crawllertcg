import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/card_model.dart';
import '../providers/cards_provider.dart';

class CardListItem extends ConsumerWidget {
  final CardModel card;
  final VoidCallback onTap;

  const CardListItem({
    super.key,
    required this.card,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: Text(
            card.name.isNotEmpty ? card.name[0].toUpperCase() : '?',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          card.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (card.expansion != null)
              Text(
                card.expansion!,
                style: TextStyle(color: Colors.grey[600]),
              ),
            Row(
              children: [
                Icon(Icons.inventory_2, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Cantidad: ${card.quantity}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                if (card.rarity != null) ...[
                  const SizedBox(width: 12),
                  Icon(Icons.star, size: 16, color: Colors.amber[700]),
                  const SizedBox(width: 4),
                  Text(
                    card.rarity!,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: card.quantity > 0
                  ? () {
                      ref
                          .read(cardsProvider.notifier)
                          .decrementQuantity(card.id);
                    }
                  : null,
              tooltip: 'Disminuir cantidad',
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () {
                ref.read(cardsProvider.notifier).incrementQuantity(card.id);
              },
              tooltip: 'Aumentar cantidad',
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
