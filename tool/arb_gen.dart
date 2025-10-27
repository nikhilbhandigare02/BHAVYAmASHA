import 'dart:convert';
import 'dart:io';

/// Configure which JSON files to extract translations from.
final List<String> sourceJsonFiles = [
  'assets/json/multilingual.json',
  'assets/json/asha-forms.json',
  'assets/json/national-program.json',
];

const String enArbPath = 'lib/l10n/app_en.arb';
const String hiArbPath = 'lib/l10n/app_hi.arb';

Future<void> main() async {
  final enMap = await _readArb(enArbPath);
  final hiMap = await _readArb(hiArbPath);

  final addedKeys = <String>[];

  for (final path in sourceJsonFiles) {
    final file = File(path);
    if (!await file.exists()) {
      stderr.writeln('Warning: $path not found. Skipping.');
      continue;
    }
    final text = await file.readAsString();
    dynamic data;
    try {
      data = jsonDecode(text);
    } catch (e) {
      stderr.writeln('Error: Failed to parse $path as JSON: $e');
      continue;
    }

    _walk(
      node: data,
      path: [],
      onLocalizedNode: (keyPath, map) {
        // map is a Map with at least en/hi
        final key = _makeKey(keyPath);
        final enVal = _asString(map['en']);
        final hiVal = _asString(map['hi']);
        if (enVal == null && hiVal == null) return;

        // Fallback to English if Hindi missing
        final enText = enVal ?? hiVal ?? '';
        final hiText = hiVal ?? enVal ?? '';

        enMap[key] = enText;
        hiMap[key] = hiText;
        addedKeys.add(key);
      },
    );
  }

  // Sort by key for stable diff
  final sortedEn = Map.fromEntries(enMap.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
  final sortedHi = Map.fromEntries(hiMap.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));

  await _writeArb(enArbPath, sortedEn);
  await _writeArb(hiArbPath, sortedHi);

  stdout.writeln('Done. Updated ${addedKeys.length} keys.');
}

Map<String, dynamic> _ensureArbMeta(Map<String, dynamic> arb, String locale) {
  arb['@@locale'] ??= locale;
  return arb;
}

Future<Map<String, dynamic>> _readArb(String path) async {
  final f = File(path);
  if (await f.exists()) {
    try {
      final raw = await f.readAsString();
      final map = jsonDecode(raw) as Map<String, dynamic>;
      // Strip any @-metadata items from previous runs except @@locale and @desc entries
      // We keep existing descriptions as-is, and we don't auto-generate descriptions.
      return Map<String, dynamic>.from(map);
    } catch (_) {
      // fallthrough to new map
    }
  }
  final locale = path.contains('_hi.') ? 'hi' : 'en';
  return _ensureArbMeta({
    '@@locale': locale,
  }, locale);
}

Future<void> _writeArb(String path, Map<String, dynamic> map) async {
  // Ensure @@locale is at top
  final ordered = <String, dynamic>{};
  if (map.containsKey('@@locale')) {
    ordered['@@locale'] = map['@@locale'];
  }
  map.forEach((k, v) {
    if (k == '@@locale') return;
    ordered[k] = v;
  });

  final encoder = const JsonEncoder.withIndent('  ');
  await File(path).writeAsString(encoder.convert(ordered) + '\n');
}

String? _asString(dynamic v) {
  if (v == null) return null;
  if (v is String) return v;
  return v.toString();
}

void _walk({
  required dynamic node,
  required List<String> path,
  required void Function(List<String> keyPath, Map<String, dynamic> map) onLocalizedNode,
}) {
  if (node is Map) {
    final map = Map<String, dynamic>.from(node as Map);

    final hasEn = map.containsKey('en') && (map['en'] is String || map['en'] != null);
    final hasHi = map.containsKey('hi') && (map['hi'] is String || map['hi'] != null);

    if (hasEn || hasHi) {
      // This map is a localized leaf (or contains localized text along with other keys like placeholder/messages)
      onLocalizedNode(path, map);
    }

    // Special handling for options arrays: generate keys for each option using its 'value' when available
    if (map['options'] is List) {
      final opts = map['options'] as List;
      for (var i = 0; i < opts.length; i++) {
        final item = opts[i];
        if (item is Map) {
          final valueId = item['value'];
          final seg = valueId is String ? valueId : 'option_${i + 1}';
          _walk(node: item, path: [...path, 'options', seg], onLocalizedNode: onLocalizedNode);
        } else {
          _walk(node: item, path: [...path, 'options', 'option_${i + 1}'], onLocalizedNode: onLocalizedNode);
        }
      }
    }

    // If there are gendered options as a map (e.g., { female: [], male: [] })
    if (map['options'] is Map) {
      final optMap = Map<String, dynamic>.from(map['options'] as Map);
      optMap.forEach((gender, list) {
        if (list is List) {
          for (var i = 0; i < list.length; i++) {
            final item = list[i];
            if (item is Map) {
              final valueId = item['value'];
              final seg = valueId is String ? valueId : 'option_${i + 1}';
              _walk(node: item, path: [...path, 'options', gender, seg], onLocalizedNode: onLocalizedNode);
            }
          }
        } else {
          _walk(node: list, path: [...path, 'options', gender], onLocalizedNode: onLocalizedNode);
        }
      });
    }

    // Walk standard keys
    for (final entry in map.entries) {
      final key = entry.key.toString();
      if (key == 'en' || key == 'hi' || key == 'value' || key == 'icon' || key == 'url') continue;
      if (key == 'options') continue; // already handled above
      _walk(node: entry.value, path: [...path, key], onLocalizedNode: onLocalizedNode);
    }
  } else if (node is List) {
    for (var i = 0; i < node.length; i++) {
      final item = node[i];
      // For generic lists without value identifiers, use index-based segment
      _walk(node: item, path: [...path, 'item_${i + 1}'], onLocalizedNode: onLocalizedNode);
    }
  }
}

String _makeKey(List<String> segments) {
  final sanitized = segments.map(_sanitizeSegment).where((s) => s.isNotEmpty).toList();
  return sanitized.join('_');
}

String _sanitizeSegment(String s) {
  // Convert camelCase/PascalCase to snake_case-ish then keep [a-z0-9_]
  final replacedDots = s.replaceAll('.', '_');
  final withUnderscore = replacedDots
      .replaceAllMapped(RegExp(r'([a-z0-9])([A-Z])'), (m) => '${m.group(1)}_${m.group(2)}')
      .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')
      .toLowerCase();
  return withUnderscore.replaceAll(RegExp(r'_+'), '_').replaceAll(RegExp(r'^_|_$'), '');
}
