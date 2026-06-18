import 'dart:convert';

import 'package:flutter/foundation.dart' show FlutterError;
import 'package:flutter/services.dart' show rootBundle;

class LocalMediaManifestService {
  const LocalMediaManifestService._();

  static const assetPath = 'assets/media/media_manifest.json';

  static Future<Map<String, String>> carregar() async {
    try {
      final raw = await rootBundle.loadString(assetPath);
      final decoded = jsonDecode(raw);

      if (decoded is Map<String, dynamic>) {
        return _fromMap(decoded);
      }

      return const {};
    } on FlutterError {
      return const {};
    } on FormatException {
      return const {};
    }
  }

  static Map<String, String> _fromMap(Map<String, dynamic> json) {
    final items = json['items'];
    if (items is List) {
      final result = <String, String>{};
      for (final item in items) {
        if (item is! Map) {
          continue;
        }

        final remoteUrl = item['remoteUrl']?.toString().trim();
        final assetPath = item['assetPath']?.toString().trim();
        if (remoteUrl == null ||
            remoteUrl.isEmpty ||
            assetPath == null ||
            assetPath.isEmpty) {
          continue;
        }

        result[remoteUrl] = assetPath;
      }

      return Map.unmodifiable(result);
    }

    return Map.unmodifiable({
      for (final entry in json.entries)
        if (entry.value is String &&
            entry.key.trim().isNotEmpty &&
            entry.value.toString().trim().isNotEmpty)
          entry.key: entry.value.toString().trim(),
    });
  }
}
