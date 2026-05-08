import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/cards_provider.dart';
import '../services/price_service.dart';

class AddCardScreen extends ConsumerStatefulWidget {
  final String? initialName;
  final String? imagePath;
  final String? initialExpansion;
  final String? initialRarity;
  final String? initialPrice;
  final String? initialUrl;

  const AddCardScreen({
    super.key,
    this.initialName,
    this.imagePath,
    this.initialExpansion,
    this.initialRarity,
    this.initialPrice,
    this.initialUrl,
  });

  @override
  ConsumerState<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends ConsumerState<AddCardScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _expansionController;
  late TextEditingController _rarityController;
  late TextEditingController _priceController;
  late TextEditingController _urlController;
  late TextEditingController _notesController;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _expansionController =
        TextEditingController(text: widget.initialExpansion ?? '');
    _rarityController =
        TextEditingController(text: widget.initialRarity ?? '');
    _priceController = TextEditingController(text: widget.initialPrice ?? '');
    _urlController =
        TextEditingController(text: widget.initialUrl ?? '');
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _expansionController.dispose();
    _rarityController.dispose();
    _priceController.dispose();
    _urlController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveCard() async {
    if (_formKey.currentState!.validate()) {
      try {
        final priceText = _priceController.text.trim();
        final priceValue = PriceService.parsePrice(priceText);
        await ref.read(cardsProvider.notifier).addCard(
              name: _nameController.text.trim(),
              quantity: _quantity,
              expansion: _expansionController.text.trim().isEmpty
                  ? null
                  : _expansionController.text.trim(),
              rarity: _rarityController.text.trim().isEmpty
                  ? null
                  : _rarityController.text.trim(),
              price: priceText.isEmpty ? null : priceText,
              priceValue: priceValue,
              url: _urlController.text.trim().isEmpty
                  ? null
                  : _urlController.text.trim(),
              notes: _notesController.text.trim().isEmpty
                  ? null
                  : _notesController.text.trim(),
              image: widget.imagePath,
              dateAdded: DateTime.now(),
            );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Carta añadida exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al guardar carta: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Añadir Carta'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveCard,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Nombre
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.style),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El nombre es obligatorio';
                }
                return null;
              },
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),

            // Expansion y Rareza
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _expansionController,
                    decoration: const InputDecoration(
                      labelText: 'Expansión',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.collections_bookmark),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _rarityController,
                    decoration: const InputDecoration(
                      labelText: 'Rareza',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.star),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Precio
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Precio',
                hintText: 'Ej. 12.50',
                helperText: 'Solo números. Se usará para sumar el valor de tu colección.',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return null;
                if (PriceService.parsePrice(value) == null) {
                  return 'Introduce un número válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // URL de la carta
            TextFormField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'URL de la carta',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),

            // Cantidad
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cantidad: $_quantity',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: _quantity > 1
                              ? () => setState(() => _quantity--)
                              : null,
                        ),
                        Expanded(
                          child: Slider(
                            value: _quantity.toDouble(),
                            min: 1,
                            max: 100,
                            divisions: 99,
                            label: _quantity.toString(),
                            onChanged: (value) =>
                                setState(() => _quantity = value.toInt()),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: _quantity < 100
                              ? () => setState(() => _quantity++)
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Notas
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notas',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: _saveCard,
              icon: const Icon(Icons.save),
              label: const Text('Guardar Carta'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
