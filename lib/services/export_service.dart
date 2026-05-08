import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/card_model.dart';

enum ExportFormat { json, csv }

class ExportService {
  /// Writes the collection as a JSON file in temp dir and opens the share sheet.
  Future<void> exportJson(List<CardModel> cards) async {
    final payload = {
      'exportedAt': DateTime.now().toIso8601String(),
      'count': cards.length,
      'cards': cards.map(_toMap).toList(),
    };
    final json =
        const JsonEncoder.withIndent('  ').convert(payload);
    final file = await _writeToTemp(
      content: json,
      filename: _stampedFilename('coleccion-tcg', 'json'),
    );
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Mi colección de cartas',
    );
  }

  /// Writes the collection as a CSV file in temp dir and opens the share sheet.
  Future<void> exportCsv(List<CardModel> cards) async {
    final buffer = StringBuffer();
    const headers = [
      'id',
      'name',
      'quantity',
      'expansion',
      'rarity',
      'priceValue',
      'totalValue',
      'priceText',
      'dateAdded',
      'source',
      'cardApiId',
      'notes',
    ];
    buffer.writeln(headers.join(','));

    for (final c in cards) {
      final total = c.priceValue != null ? c.priceValue! * c.quantity : null;
      final row = [
        c.id,
        c.name,
        c.quantity,
        c.expansion ?? '',
        c.rarity ?? '',
        c.priceValue?.toString() ?? '',
        total?.toString() ?? '',
        c.price ?? '',
        c.dateAdded.toIso8601String(),
        c.source ?? '',
        c.cardApiId ?? '',
        c.notes ?? '',
      ].map(_csvEscape).join(',');
      buffer.writeln(row);
    }

    final file = await _writeToTemp(
      content: buffer.toString(),
      filename: _stampedFilename('coleccion-tcg', 'csv'),
    );
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Mi colección de cartas',
    );
  }

  Map<String, dynamic> _toMap(CardModel c) => {
        'id': c.id,
        'name': c.name,
        'quantity': c.quantity,
        'expansion': c.expansion,
        'rarity': c.rarity,
        'priceValue': c.priceValue,
        'priceText': c.price,
        'dateAdded': c.dateAdded.toIso8601String(),
        'imageUrl': c.imageUrl,
        'cardPageUrl': c.cardPageUrl,
        'cardApiId': c.cardApiId,
        'source': c.source,
        'notes': c.notes,
      };

  Future<File> _writeToTemp({
    required String content,
    required String filename,
  }) async {
    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, filename));
    await file.writeAsString(content);
    return file;
  }

  String _stampedFilename(String prefix, String ext) {
    final now = DateTime.now();
    final stamp =
        '${now.year}${_two(now.month)}${_two(now.day)}-${_two(now.hour)}${_two(now.minute)}';
    return '$prefix-$stamp.$ext';
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  String _csvEscape(Object value) {
    final s = value.toString();
    final needsQuoting =
        s.contains(',') || s.contains('"') || s.contains('\n');
    if (!needsQuoting) return s;
    final escaped = s.replaceAll('"', '""');
    return '"$escaped"';
  }
}
