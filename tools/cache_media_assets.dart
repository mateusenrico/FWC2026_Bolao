import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  final root = Directory.current;
  final cache = _MediaAssetCache(root);
  final result = await cache.run();

  stdout.writeln(
    'Media cache: ${result.downloaded} baixadas, '
    '${result.reused} existentes, ${result.failed} falhas.',
  );
  stdout.writeln('Manifesto atualizado em assets/media/media_manifest.json');
}

class _MediaAssetCache {
  final Directory root;
  final _sources = <String, _MediaSource>{};

  _MediaAssetCache(this.root);

  Future<_CacheResult> run() async {
    _collect();

    var downloaded = 0;
    var reused = 0;
    var failed = 0;

    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10)
      ..userAgent = 'fwc2026-bolao-media-cache/1.0';

    for (final source in _sources.values) {
      final file = File(_join(root.path, source.assetPath));
      await file.parent.create(recursive: true);

      if (await file.exists() && await file.length() > 0) {
        reused++;
        continue;
      }

      try {
        final request = await client.getUrl(Uri.parse(source.remoteUrl));
        final response = await request.close();
        if (response.statusCode < 200 || response.statusCode >= 300) {
          stderr.writeln('Falha ${response.statusCode}: ${source.remoteUrl}');
          failed++;
          continue;
        }

        await response.pipe(file.openWrite());
        downloaded++;
      } catch (error) {
        stderr.writeln('Falha ao baixar ${source.remoteUrl}: $error');
        failed++;
      }
    }

    client.close(force: true);
    await _writeManifest();

    return _CacheResult(downloaded: downloaded, reused: reused, failed: failed);
  }

  void _collect() {
    for (final item in _readJsonList('assets/data/times_sportsdb.json')) {
      final label = _string(item['nomeBolao']) ?? _string(item['nomeApi']);
      _add(item['badgeUrl'], 'team_badges', label);
      _add(item['logoUrl'], 'team_badges', label);
      _add(item['bannerUrl'], 'team_images', label);
      _add(item['fanartUrl'], 'team_images', label);
      _add(item['equipamentoUrl'], 'team_images', label);
      _collectRawImages(item['raw'], 'team_images', label);
    }

    for (final item in _readJsonList('assets/data/historico_partidas.json')) {
      final label = _string(item['strEvent']) ?? 'jogo-${item['matchNumber']}';
      _add(
        item['strHomeTeamBadge'],
        'team_badges',
        _string(item['strHomeTeam']),
      );
      _add(
        item['strAwayTeamBadge'],
        'team_badges',
        _string(item['strAwayTeam']),
      );
      _add(item['strThumb'], 'match_images', label);
      _add(item['strPoster'], 'match_images', label);
      _add(item['strFanart'], 'match_images', label);
      _add(item['strBanner'], 'match_images', label);
      _collectRawImages(item, 'match_images', label);
    }

    for (final item in _readJsonList('assets/data/venues_sportsdb.json')) {
      final label = _string(item['nome']);
      _add(item['thumbUrl'], 'venue_images', label);
      _add(item['fanartUrl'], 'venue_images', label);
      _collectRawImages(item['raw'], 'venue_images', label);
    }

    final league = _readJsonObject('assets/data/liga_sportsdb.json');
    if (league.isNotEmpty) {
      final label = _string(league['nome']) ?? 'fifa-world-cup';
      _add(league['badgeUrl'], 'league_images', label);
      _add(league['logoUrl'], 'league_images', label);
      _add(league['posterUrl'], 'league_images', label);
      _add(league['bannerUrl'], 'league_images', label);
      _add(league['fanartUrl'], 'league_images', label);
      _collectRawImages(league['raw'], 'league_images', label);
    }
  }

  void _collectRawImages(dynamic value, String category, String? label) {
    if (value is! Map) {
      return;
    }

    for (final entry in value.entries) {
      final key = entry.key.toString().toLowerCase();
      if (!_looksLikeImageField(key)) {
        continue;
      }

      _add(entry.value, category, label);
    }
  }

  bool _looksLikeImageField(String key) {
    return key.contains('badge') ||
        key.contains('logo') ||
        key.contains('banner') ||
        key.contains('fanart') ||
        key.contains('thumb') ||
        key.contains('poster') ||
        key.contains('jersey') ||
        key.contains('cutout') ||
        key.contains('render') ||
        key.contains('image');
  }

  void _add(dynamic value, String category, String? label) {
    final remoteUrl = _string(value);
    if (remoteUrl == null || !_isImageUrl(remoteUrl)) {
      return;
    }

    _sources.putIfAbsent(remoteUrl, () {
      final extension = _extensionFor(remoteUrl);
      final slug = _slug(label ?? category);
      final hash = _fnv1a(remoteUrl).toRadixString(16).padLeft(8, '0');
      final filename = '${slug}_$hash.$extension';
      return _MediaSource(
        remoteUrl: remoteUrl,
        category: category,
        assetPath: 'assets/media/$category/$filename',
      );
    });
  }

  bool _isImageUrl(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https')) {
      return false;
    }

    return RegExp(
      r'\.(png|jpg|jpeg|webp)(?:$|\?)',
      caseSensitive: false,
    ).hasMatch(uri.path);
  }

  String _extensionFor(String value) {
    final match = RegExp(
      r'\.(png|jpg|jpeg|webp)(?:$|\?)',
      caseSensitive: false,
    ).firstMatch(Uri.parse(value).path);

    final ext = match?.group(1)?.toLowerCase();
    return ext == 'jpeg' ? 'jpg' : (ext ?? 'jpg');
  }

  Future<void> _writeManifest() async {
    final manifestFile = File(
      _join(root.path, 'assets/media/media_manifest.json'),
    );
    final items = _sources.values.toList()
      ..sort((a, b) => a.assetPath.compareTo(b.assetPath));

    const encoder = JsonEncoder.withIndent('  ');
    await manifestFile.writeAsString(
      '${encoder.convert({
        'generatedAt': DateTime.now().toUtc().toIso8601String(),
        'items': [
          for (final item in items) {'remoteUrl': item.remoteUrl, 'assetPath': item.assetPath, 'category': item.category},
        ],
      })}\n',
    );
  }

  List<Map<String, dynamic>> _readJsonList(String path) {
    final file = File(_join(root.path, path));
    if (!file.existsSync()) {
      return const [];
    }

    final decoded = jsonDecode(file.readAsStringSync());
    if (decoded is! List) {
      return const [];
    }

    return [
      for (final item in decoded)
        if (item is Map) Map<String, dynamic>.from(item),
    ];
  }

  Map<String, dynamic> _readJsonObject(String path) {
    final file = File(_join(root.path, path));
    if (!file.existsSync()) {
      return const {};
    }

    final decoded = jsonDecode(file.readAsStringSync());
    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }

    return const {};
  }
}

class _MediaSource {
  final String remoteUrl;
  final String category;
  final String assetPath;

  const _MediaSource({
    required this.remoteUrl,
    required this.category,
    required this.assetPath,
  });
}

class _CacheResult {
  final int downloaded;
  final int reused;
  final int failed;

  const _CacheResult({
    required this.downloaded,
    required this.reused,
    required this.failed,
  });
}

String? _string(dynamic value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

String _slug(String value) {
  final normalized = value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');

  if (normalized.isEmpty) {
    return 'media';
  }

  return normalized.length > 48 ? normalized.substring(0, 48) : normalized;
}

int _fnv1a(String value) {
  var hash = 0x811c9dc5;
  for (final byte in utf8.encode(value)) {
    hash ^= byte;
    hash = (hash * 0x01000193) & 0xffffffff;
  }

  return hash;
}

String _join(String a, String b) {
  if (a.endsWith(Platform.pathSeparator)) {
    return '$a$b';
  }

  return '$a${Platform.pathSeparator}$b';
}
