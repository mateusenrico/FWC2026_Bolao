import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'package:fwc2026_bolao/core/functions/team_normalizer.dart';

const String _sportsDbApiKey = '123';
const String _sportsDbBaseUrl =
    'https://www.thesportsdb.com/api/v1/json/$_sportsDbApiKey';
const String _fixtureDownloadUrl =
    'https://fixturedownload.com/feed/json/fifa-world-cup-2026';

Future<void> main(List<String> args) async {
  final config = UpdateConfig.fromArgs(args);

  try {
    await TournamentDataUpdater(config).run();
  } catch (error, stackTrace) {
    stderr.writeln('Falha ao atualizar os dados: $error');
    stderr.writeln(stackTrace);
    exitCode = 1;
  }
}

class UpdateConfig {
  final String leagueId;
  final String season;
  final bool includeDayScan;
  final DateTime dayScanStart;
  final DateTime dayScanEnd;

  const UpdateConfig({
    required this.leagueId,
    required this.season,
    required this.includeDayScan,
    required this.dayScanStart,
    required this.dayScanEnd,
  });

  factory UpdateConfig.fromArgs(List<String> args) {
    final tournamentEnd = DateTime.utc(2026, 7, 19);
    final defaultEndCandidate = DateTime.now().toUtc().add(
      const Duration(days: 1),
    );
    final defaultEnd = defaultEndCandidate.isAfter(tournamentEnd)
        ? tournamentEnd
        : defaultEndCandidate;

    var leagueId = '4429';
    var season = '2026';
    var includeDayScan = true;
    var dayScanStart = DateTime.utc(2026, 6, 11);
    var dayScanEnd = defaultEnd;

    for (final arg in args) {
      if (arg.startsWith('--league-id=')) {
        leagueId = arg.substring('--league-id='.length).trim();
      } else if (arg.startsWith('--season=')) {
        season = arg.substring('--season='.length).trim();
      } else if (arg == '--no-day-scan') {
        includeDayScan = false;
      } else if (arg == '--include-day-scan') {
        includeDayScan = true;
      } else if (arg.startsWith('--from=')) {
        final parsed = DateTime.tryParse(
          arg.substring('--from='.length).trim(),
        );

        if (parsed != null) {
          dayScanStart = DateTime.utc(parsed.year, parsed.month, parsed.day);
        }
      } else if (arg.startsWith('--to=')) {
        final parsed = DateTime.tryParse(arg.substring('--to='.length).trim());

        if (parsed != null) {
          dayScanEnd = DateTime.utc(parsed.year, parsed.month, parsed.day);
        }
      }
    }

    return UpdateConfig(
      leagueId: leagueId,
      season: season,
      includeDayScan: includeDayScan,
      dayScanStart: dayScanStart,
      dayScanEnd: dayScanEnd,
    );
  }
}

class TournamentDataUpdater {
  final UpdateConfig config;

  TournamentDataUpdater(this.config);

  final Directory _dataDirectory = Directory('assets/data');

  File get _gamesFile => File('assets/data/jogos.json');

  File get _historyFile => File('assets/data/historico_partidas.json');

  File get _teamsFile => File('assets/data/times_participantes.json');

  File get _guessesFile => File('assets/data/palpites.json');

  File get _fixtureSeedFile => File('tools/data/world_cup_2026_fixtures.json');

  final List<ApiEndpointResult> _apiEndpointResults = [];
  final List<String> _warnings = [];

  Future<void> run() async {
    _assertRequiredFilesExist();

    final backupDirectory = await _backupDataFiles();

    stdout.writeln('Backup criado em: ${backupDirectory.path}');

    final fixtureRoot = await _readJsonObject(_fixtureSeedFile);
    final fixtures = _asMapList(fixtureRoot['fixtures']);
    final oldGames = await _readJsonList(_gamesFile);
    final oldHistory = await _readJsonList(_historyFile);
    final teams = await _readJsonList(_teamsFile);

    if (fixtures.length != 104) {
      throw StateError(
        'A fonte canônica deveria conter 104 partidas, '
        'mas contém ${fixtures.length}.',
      );
    }

    final stableIds = _buildStableIds(fixtures: fixtures, oldGames: oldGames);

    final oldGamesByMatchNumber = _mapOldGamesToMatchNumbers(
      fixtures: fixtures,
      oldGames: oldGames,
      stableIds: stableIds,
    );

    final sportsDbEvents = await _loadSportsDbEvents(
      existingHistory: oldHistory,
      fixtures: fixtures,
      oldGamesByMatchNumber: oldGamesByMatchNumber,
    );

    final sportsDbByMatchNumber = _mapSportsDbEventsToMatches(
      events: sportsDbEvents,
      fixtures: fixtures,
      oldGamesByMatchNumber: oldGamesByMatchNumber,
    );

    final fixtureDownloadByMatchNumber =
        await _fetchFixtureDownloadByMatchNumber();

    final games = _buildCanonicalGames(
      fixtures: fixtures,
      stableIds: stableIds,
      oldGamesByMatchNumber: oldGamesByMatchNumber,
      sportsDbByMatchNumber: sportsDbByMatchNumber,
      fixtureDownloadByMatchNumber: fixtureDownloadByMatchNumber,
      teams: teams,
    );

    final history = _buildCanonicalHistory(
      sportsDbEvents: sportsDbEvents,
      fixtures: fixtures,
      games: games,
      oldGamesByMatchNumber: oldGamesByMatchNumber,
    );

    _updateTeams(teams: teams, games: games);

    await _validate(games: games, history: history, teams: teams);

    await _writeJsonList(_gamesFile, games);
    await _writeJsonList(_historyFile, history);
    await _writeJsonList(_teamsFile, teams);

    _printSummary(
      games: games,
      history: history,
      sportsDbEvents: sportsDbEvents,
      sportsDbByMatchNumber: sportsDbByMatchNumber,
      fixtureDownloadByMatchNumber: fixtureDownloadByMatchNumber,
    );

    await _writeUpdateLog(
      games: games,
      history: history,
      sportsDbEvents: sportsDbEvents,
      sportsDbByMatchNumber: sportsDbByMatchNumber,
      fixtureDownloadByMatchNumber: fixtureDownloadByMatchNumber,
    );
  }

  Future<void> _writeUpdateLog({
    required List<Map<String, dynamic>> games,
    required List<Map<String, dynamic>> history,
    required List<Map<String, dynamic>> sportsDbEvents,
    required Map<int, Map<String, dynamic>> sportsDbByMatchNumber,
    required Map<int, Map<String, dynamic>> fixtureDownloadByMatchNumber,
  }) async {
    final now = DateTime.now();
    final timestamp = _timestampForPath(now);
    final directory = Directory('logs/update_sportsdb');

    await directory.create(recursive: true);

    final gamesWithResult = games.where((game) {
      return game['temResultadoApi'] == true || game['temResultado'] == true;
    }).length;

    final historyWithResult = history.where((record) {
      return record['temResultado'] == true ||
          (_asInt(record['intHomeScore']) != null &&
              _asInt(record['intAwayScore']) != null);
    }).length;

    final log = {
      'timestampLocal': now.toIso8601String(),
      'timestampUtc': now.toUtc().toIso8601String(),
      'config': {
        'leagueId': config.leagueId,
        'season': config.season,
        'includeDayScan': config.includeDayScan,
        'dayScanStart': _dateOnly(config.dayScanStart),
        'dayScanEnd': _dateOnly(config.dayScanEnd),
      },
      'summary': {
        'games': games.length,
        'gamesWithResult': gamesWithResult,
        'history': history.length,
        'historyWithResult': historyWithResult,
        'sportsDbEvents': sportsDbEvents.length,
        'sportsDbMatchedByMatchNumber': sportsDbByMatchNumber.length,
        'fixtureDownloadEntries': fixtureDownloadByMatchNumber.length,
        'warnings': _warnings.length,
        'endpointCalls': _apiEndpointResults.length,
        'endpointCallsOk': _apiEndpointResults
            .where((result) => result.ok)
            .length,
        'endpointCallsFailed': _apiEndpointResults
            .where((result) => !result.ok)
            .length,
      },
      'endpointResults': _apiEndpointResults
          .map((result) => result.toJson())
          .toList(growable: false),
      'warnings': _warnings,
    };

    const encoder = JsonEncoder.withIndent('  ');
    final file = File('${directory.path}/$timestamp.json');

    await file.writeAsString('${encoder.convert(log)}\n');

    stdout.writeln('Log de atualização salvo em: ${file.path}');
  }

  String _endpointName(Uri uri) {
    final path = uri.pathSegments.isEmpty
        ? uri.toString()
        : uri.pathSegments.last;

    if (path.endsWith('.php')) {
      return path.replaceAll('.php', '');
    }

    return path;
  }

  void _assertRequiredFilesExist() {
    final requiredFiles = [
      _gamesFile,
      _historyFile,
      _teamsFile,
      _fixtureSeedFile,
    ];

    for (final file in requiredFiles) {
      if (!file.existsSync()) {
        throw StateError('Arquivo obrigatório não encontrado: ${file.path}');
      }
    }
  }

  Future<Directory> _backupDataFiles() async {
    final timestamp = _timestampForPath(DateTime.now());
    final backupDirectory = Directory('assets/data/backups/$timestamp');

    await backupDirectory.create(recursive: true);

    final files = _dataDirectory.listSync().whereType<File>().where(
      (file) => file.path.endsWith('.json'),
    );

    for (final file in files) {
      final fileName = file.uri.pathSegments.last;

      await file.copy('${backupDirectory.path}/$fileName');
    }

    return backupDirectory;
  }

  Future<Map<String, dynamic>> _readJsonObject(File file) async {
    final decoded = jsonDecode(await file.readAsString());

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }

    throw FormatException('${file.path} deveria conter um objeto JSON.');
  }

  Future<List<Map<String, dynamic>>> _readJsonList(File file) async {
    final decoded = jsonDecode(await file.readAsString());

    if (decoded is! List) {
      throw FormatException('${file.path} deveria conter uma lista JSON.');
    }

    return _asMapList(decoded);
  }

  Future<void> _writeJsonList(
    File file,
    List<Map<String, dynamic>> data,
  ) async {
    const encoder = JsonEncoder.withIndent('  ');

    await file.writeAsString('${encoder.convert(data)}\n');
  }

  List<Map<String, dynamic>> _asMapList(dynamic value) {
    if (value is! List) {
      return const [];
    }

    return value.map((item) {
      if (item is Map<String, dynamic>) {
        return Map<String, dynamic>.from(item);
      }

      if (item is Map) {
        return Map<String, dynamic>.from(item);
      }

      throw FormatException(
        'Esperado objeto JSON, recebido: '
        '${item.runtimeType}.',
      );
    }).toList();
  }

  Map<int, String> _buildStableIds({
    required List<Map<String, dynamic>> fixtures,
    required List<Map<String, dynamic>> oldGames,
  }) {
    final result = <int, String>{};
    final usedIds = <String>{};

    final canonicalOldGames = oldGames.where(
      (game) => !_isApiGeneratedGame(game),
    );

    for (final game in canonicalOldGames) {
      final matchNumber = _asInt(game['matchNumber']);
      final gameId = game['jogoId']?.toString();

      if (matchNumber != null &&
          matchNumber >= 1 &&
          matchNumber <= 104 &&
          gameId != null &&
          gameId.isNotEmpty &&
          usedIds.add(gameId)) {
        result[matchNumber] = gameId;
      }
    }

    final groupFixtureByPair = <String, Map<String, dynamic>>{};

    for (final fixture in fixtures) {
      if (fixture['stage'] == 'group-stage') {
        groupFixtureByPair[_pairKey(
              fixture['homeTeam']?.toString() ?? '',
              fixture['awayTeam']?.toString() ?? '',
            )] =
            fixture;
      }
    }

    for (final game in canonicalOldGames) {
      final gameId = game['jogoId']?.toString();

      if (gameId == null ||
          gameId.isEmpty ||
          usedIds.contains(gameId) ||
          game['faseTipo'] != 'fase_de_grupos') {
        continue;
      }

      final fixture =
          groupFixtureByPair[_pairKey(
            game['mandantePrevisto']?.toString() ?? '',
            game['visitantePrevisto']?.toString() ?? '',
          )];

      final matchNumber = _asInt(fixture?['matchNumber']);

      if (matchNumber != null && !result.containsKey(matchNumber)) {
        result[matchNumber] = gameId;
        usedIds.add(gameId);
      }
    }

    final availableKnockoutFixtures = fixtures
        .where(
          (fixture) =>
              fixture['stage'] != 'group-stage' &&
              !result.containsKey(_asInt(fixture['matchNumber'])),
        )
        .toList();

    for (final game in canonicalOldGames) {
      final gameId = game['jogoId']?.toString();

      if (gameId == null ||
          gameId.isEmpty ||
          usedIds.contains(gameId) ||
          game['faseTipo'] != 'mata_mata') {
        continue;
      }

      final gameTime = _parseUtc(game['dataUtc']?.toString());

      if (gameTime == null || availableKnockoutFixtures.isEmpty) {
        continue;
      }

      Map<String, dynamic>? bestFixture;
      var bestDifference = 1 << 62;

      for (final fixture in availableKnockoutFixtures) {
        final fixtureTime = _parseUtc(fixture['kickoffUtc']?.toString());

        if (fixtureTime == null) {
          continue;
        }

        final difference = gameTime.difference(fixtureTime).inSeconds.abs();

        if (difference < bestDifference) {
          bestDifference = difference;
          bestFixture = fixture;
        }
      }

      final matchNumber = _asInt(bestFixture?['matchNumber']);

      if (matchNumber != null && !result.containsKey(matchNumber)) {
        result[matchNumber] = gameId;
        usedIds.add(gameId);
        availableKnockoutFixtures.remove(bestFixture);
      }
    }

    for (var matchNumber = 1; matchNumber <= 104; matchNumber++) {
      result.putIfAbsent(
        matchNumber,
        () => 'wc2026_m${matchNumber.toString().padLeft(3, '0')}',
      );
    }

    return result;
  }

  Map<int, Map<String, dynamic>> _mapOldGamesToMatchNumbers({
    required List<Map<String, dynamic>> fixtures,
    required List<Map<String, dynamic>> oldGames,
    required Map<int, String> stableIds,
  }) {
    final oldById = <String, Map<String, dynamic>>{
      for (final game in oldGames)
        if (game['jogoId'] != null) game['jogoId'].toString(): game,
    };

    return {
      for (final entry in stableIds.entries)
        if (oldById[entry.value] != null) entry.key: oldById[entry.value]!,
    };
  }

  Future<List<Map<String, dynamic>>> _loadSportsDbEvents({
    required List<Map<String, dynamic>> existingHistory,
    required List<Map<String, dynamic>> fixtures,
    required Map<int, Map<String, dynamic>> oldGamesByMatchNumber,
  }) async {
    final byId = <String, Map<String, dynamic>>{};

    for (final record in existingHistory) {
      final idEvent = record['idEvent']?.toString();

      if (idEvent != null && idEvent.isNotEmpty) {
        byId[idEvent] = Map<String, dynamic>.from(record);
      }
    }

    final fetchedEvents = await _fetchSportsDbEvents();

    for (final event in fetchedEvents) {
      final idEvent = event['idEvent']?.toString();

      if (idEvent != null && idEvent.isNotEmpty) {
        byId[idEvent] = event;
      }
    }

    return byId.values.toList();
  }

  Future<List<Map<String, dynamic>>> _fetchSportsDbEvents() async {
    final allEvents = <Map<String, dynamic>>[];

    final coreUris = [
      Uri.parse(
        '$_sportsDbBaseUrl/eventsseason.php'
        '?id=${config.leagueId}&s=${config.season}',
      ),
      Uri.parse(
        '$_sportsDbBaseUrl/eventsnextleague.php'
        '?id=${config.leagueId}',
      ),
      Uri.parse(
        '$_sportsDbBaseUrl/eventspastleague.php'
        '?id=${config.leagueId}',
      ),
    ];

    for (final uri in coreUris) {
      allEvents.addAll(await _fetchSportsDbEventsFromUri(uri));
    }

    if (config.includeDayScan) {
      var current = config.dayScanStart;
      final last = config.dayScanEnd;

      while (!current.isAfter(last)) {
        final uri = Uri.parse(
          '$_sportsDbBaseUrl/eventsday.php'
          '?d=${_dateOnly(current)}&s=Soccer',
        );

        allEvents.addAll(await _fetchSportsDbEventsFromUri(uri));

        current = current.add(const Duration(days: 1));
      }
    }

    final byId = <String, Map<String, dynamic>>{};

    for (final event in allEvents) {
      final idEvent = event['idEvent']?.toString();

      if (idEvent != null && idEvent.isNotEmpty) {
        byId[idEvent] = event;
      }
    }

    return byId.values.toList();
  }

  Future<List<Map<String, dynamic>>> _fetchSportsDbEventsFromUri(
    Uri uri,
  ) async {
    stdout.writeln('GET $uri');

    final stopwatch = Stopwatch()..start();

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 25));

      stopwatch.stop();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = 'SportsDB respondeu ${response.statusCode} para $uri.';
        stderr.writeln('Aviso: $message');
        _warnings.add(message);
        _apiEndpointResults.add(
          ApiEndpointResult(
            name: _endpointName(uri),
            uri: uri.toString(),
            ok: false,
            statusCode: response.statusCode,
            eventCount: 0,
            durationMs: stopwatch.elapsedMilliseconds,
            error: message,
          ),
        );
        return const [];
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! Map) {
        final message = 'Resposta SportsDB não era objeto JSON em $uri.';
        stderr.writeln('Aviso: $message');
        _warnings.add(message);
        _apiEndpointResults.add(
          ApiEndpointResult(
            name: _endpointName(uri),
            uri: uri.toString(),
            ok: false,
            statusCode: response.statusCode,
            eventCount: 0,
            durationMs: stopwatch.elapsedMilliseconds,
            error: message,
          ),
        );
        return const [];
      }

      final rawEvents = decoded['events'];

      if (rawEvents == null) {
        _apiEndpointResults.add(
          ApiEndpointResult(
            name: _endpointName(uri),
            uri: uri.toString(),
            ok: true,
            statusCode: response.statusCode,
            eventCount: 0,
            durationMs: stopwatch.elapsedMilliseconds,
          ),
        );
        return const [];
      }

      if (rawEvents is! List) {
        final message = 'Campo events da SportsDB não era lista em $uri.';
        stderr.writeln('Aviso: $message');
        _warnings.add(message);
        _apiEndpointResults.add(
          ApiEndpointResult(
            name: _endpointName(uri),
            uri: uri.toString(),
            ok: false,
            statusCode: response.statusCode,
            eventCount: 0,
            durationMs: stopwatch.elapsedMilliseconds,
            error: message,
          ),
        );
        return const [];
      }

      final events = <Map<String, dynamic>>[];
      var malformedItems = 0;

      for (final item in rawEvents) {
        try {
          Map<String, dynamic>? event;

          if (item is Map<String, dynamic>) {
            event = Map<String, dynamic>.from(item);
          } else if (item is Map) {
            event = Map<String, dynamic>.from(item);
          }

          if (event == null) {
            malformedItems++;
            continue;
          }

          if (event['idLeague']?.toString() == config.leagueId &&
              event['strSeason']?.toString() == config.season) {
            events.add(event);
          }
        } catch (_) {
          malformedItems++;
        }
      }

      if (malformedItems > 0) {
        final message =
            'SportsDB retornou $malformedItems item(ns) malformado(s) em $uri.';
        stderr.writeln('Aviso: $message');
        _warnings.add(message);
      }

      _apiEndpointResults.add(
        ApiEndpointResult(
          name: _endpointName(uri),
          uri: uri.toString(),
          ok: true,
          statusCode: response.statusCode,
          eventCount: events.length,
          durationMs: stopwatch.elapsedMilliseconds,
          warning: malformedItems > 0
              ? '$malformedItems item(ns) malformado(s) ignorado(s).'
              : null,
        ),
      );

      return events;
    } catch (error) {
      stopwatch.stop();

      final message = 'não foi possível consultar $uri: $error';
      stderr.writeln('Aviso: $message');
      _warnings.add(message);
      _apiEndpointResults.add(
        ApiEndpointResult(
          name: _endpointName(uri),
          uri: uri.toString(),
          ok: false,
          eventCount: 0,
          durationMs: stopwatch.elapsedMilliseconds,
          error: message,
        ),
      );
      return const [];
    }
  }

  Future<Map<int, Map<String, dynamic>>>
  _fetchFixtureDownloadByMatchNumber() async {
    stdout.writeln('GET $_fixtureDownloadUrl');

    final uri = Uri.parse(_fixtureDownloadUrl);
    final stopwatch = Stopwatch()..start();

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 25));

      stopwatch.stop();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = 'FixtureDownload respondeu ${response.statusCode}.';
        stderr.writeln('Aviso: $message');
        _warnings.add(message);
        _apiEndpointResults.add(
          ApiEndpointResult(
            name: 'fixturedownload',
            uri: uri.toString(),
            ok: false,
            statusCode: response.statusCode,
            eventCount: 0,
            durationMs: stopwatch.elapsedMilliseconds,
            error: message,
          ),
        );
        return const {};
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! List) {
        final message = 'FixtureDownload não retornou lista JSON.';
        stderr.writeln('Aviso: $message');
        _warnings.add(message);
        _apiEndpointResults.add(
          ApiEndpointResult(
            name: 'fixturedownload',
            uri: uri.toString(),
            ok: false,
            statusCode: response.statusCode,
            eventCount: 0,
            durationMs: stopwatch.elapsedMilliseconds,
            error: message,
          ),
        );
        return const {};
      }

      final result = <int, Map<String, dynamic>>{};
      var malformedItems = 0;

      for (final item in decoded) {
        try {
          Map<String, dynamic>? record;

          if (item is Map<String, dynamic>) {
            record = Map<String, dynamic>.from(item);
          } else if (item is Map) {
            record = Map<String, dynamic>.from(item);
          }

          if (record == null) {
            malformedItems++;
            continue;
          }

          final matchNumber = _asInt(record['MatchNumber']);

          if (matchNumber != null) {
            result[matchNumber] = record;
          }
        } catch (_) {
          malformedItems++;
        }
      }

      if (malformedItems > 0) {
        final message =
            'FixtureDownload retornou $malformedItems item(ns) malformado(s).';
        stderr.writeln('Aviso: $message');
        _warnings.add(message);
      }

      _apiEndpointResults.add(
        ApiEndpointResult(
          name: 'fixturedownload',
          uri: uri.toString(),
          ok: true,
          statusCode: response.statusCode,
          eventCount: result.length,
          durationMs: stopwatch.elapsedMilliseconds,
          warning: malformedItems > 0
              ? '$malformedItems item(ns) malformado(s) ignorado(s).'
              : null,
        ),
      );

      return result;
    } catch (error) {
      stopwatch.stop();

      final message = 'não foi possível consultar FixtureDownload: $error';
      stderr.writeln('Aviso: $message');
      _warnings.add(message);
      _apiEndpointResults.add(
        ApiEndpointResult(
          name: 'fixturedownload',
          uri: uri.toString(),
          ok: false,
          eventCount: 0,
          durationMs: stopwatch.elapsedMilliseconds,
          error: message,
        ),
      );
      return const {};
    }
  }

  Map<int, Map<String, dynamic>> _mapSportsDbEventsToMatches({
    required List<Map<String, dynamic>> events,
    required List<Map<String, dynamic>> fixtures,
    required Map<int, Map<String, dynamic>> oldGamesByMatchNumber,
  }) {
    final matchByExistingEventId = <String, int>{};

    for (final entry in oldGamesByMatchNumber.entries) {
      final idEvent = entry.value['idEventAtual']?.toString();

      if (idEvent != null && idEvent.isNotEmpty) {
        matchByExistingEventId[idEvent] = entry.key;
      }
    }

    final groupFixtureByPair = <String, Map<String, dynamic>>{};

    for (final fixture in fixtures) {
      if (fixture['stage'] == 'group-stage') {
        groupFixtureByPair[_pairKey(
              fixture['homeTeam']?.toString() ?? '',
              fixture['awayTeam']?.toString() ?? '',
            )] =
            fixture;
      }
    }

    final result = <int, Map<String, dynamic>>{};

    for (final event in events) {
      final idEvent = event['idEvent']?.toString();

      int? matchNumber;

      if (idEvent != null) {
        matchNumber = matchByExistingEventId[idEvent];
      }

      if (matchNumber == null) {
        final fixture =
            groupFixtureByPair[_pairKey(
              event['strHomeTeam']?.toString() ?? '',
              event['strAwayTeam']?.toString() ?? '',
            )];

        matchNumber = _asInt(fixture?['matchNumber']);
      }

      matchNumber ??= _nearestFixtureMatchNumber(
        event: event,
        fixtures: fixtures,
      );

      if (matchNumber == null) {
        stderr.writeln(
          'Aviso: evento SportsDB sem partida canônica: '
          '${event['strHomeTeam']} x '
          '${event['strAwayTeam']} '
          '(idEvent=${event['idEvent']}).',
        );
        continue;
      }

      final previous = result[matchNumber];

      if (previous == null ||
          _sportsDbEventPriority(event) >= _sportsDbEventPriority(previous)) {
        result[matchNumber] = event;
      }
    }

    return result;
  }

  int? _nearestFixtureMatchNumber({
    required Map<String, dynamic> event,
    required List<Map<String, dynamic>> fixtures,
  }) {
    final eventTime = _parseSportsDbUtc(event['strTimestamp']?.toString());

    if (eventTime == null) {
      return null;
    }

    Map<String, dynamic>? bestFixture;
    var bestDifference = 1 << 62;

    for (final fixture in fixtures) {
      final fixtureTime = _parseUtc(fixture['kickoffUtc']?.toString());

      if (fixtureTime == null) {
        continue;
      }

      final difference = eventTime.difference(fixtureTime).inSeconds.abs();

      if (difference < bestDifference) {
        bestDifference = difference;
        bestFixture = fixture;
      }
    }

    if (bestDifference > const Duration(hours: 36).inSeconds) {
      return null;
    }

    return _asInt(bestFixture?['matchNumber']);
  }

  int _sportsDbEventPriority(Map<String, dynamic> event) {
    var priority = 0;

    if (_hasScore(event)) {
      priority += 10;
    }

    if (_sportsDbIsFinal(event)) {
      priority += 100;
    }

    return priority;
  }

  List<Map<String, dynamic>> _buildCanonicalGames({
    required List<Map<String, dynamic>> fixtures,
    required Map<int, String> stableIds,
    required Map<int, Map<String, dynamic>> oldGamesByMatchNumber,
    required Map<int, Map<String, dynamic>> sportsDbByMatchNumber,
    required Map<int, Map<String, dynamic>> fixtureDownloadByMatchNumber,
    required List<Map<String, dynamic>> teams,
  }) {
    final chronologicalFixtures = [...fixtures]
      ..sort((a, b) {
        final timeA = _parseUtc(a['kickoffUtc']?.toString());
        final timeB = _parseUtc(b['kickoffUtc']?.toString());

        final comparison = timeA!.compareTo(timeB!);

        if (comparison != 0) {
          return comparison;
        }

        return _asInt(a['matchNumber'])!.compareTo(_asInt(b['matchNumber'])!);
      });

    final chronologicalOrder = <int, int>{};

    for (var index = 0; index < chronologicalFixtures.length; index++) {
      chronologicalOrder[_asInt(chronologicalFixtures[index]['matchNumber'])!] =
          index + 1;
    }

    final groupRoundByMatchNumber = _buildGroupRounds(fixtures);

    final teamByKey = <String, Map<String, dynamic>>{
      for (final team in teams)
        TeamNormalizer.key(team['nome']?.toString() ?? ''): team,
    };

    final result = <Map<String, dynamic>>[];

    for (final fixture in fixtures) {
      final matchNumber = _asInt(fixture['matchNumber'])!;
      final stage = fixture['stage']?.toString() ?? '';
      final group = _nullableString(fixture['group']);
      final kickoffUtc = _parseUtc(fixture['kickoffUtc']?.toString())!;

      final oldGame = oldGamesByMatchNumber[matchNumber];
      final sportsDb = sportsDbByMatchNumber[matchNumber];
      final fixtureDownload = fixtureDownloadByMatchNumber[matchNumber];

      final resultData = _chooseResult(
        oldGame: oldGame,
        sportsDb: sportsDb,
        fixtureDownload: fixtureDownload,
        kickoffUtc: kickoffUtc,
      );

      final mandanteReference = _buildParticipantReference(
        fixture['homeTeam']?.toString() ?? '',
        stableIds: stableIds,
        teamByKey: teamByKey,
      );
      final visitanteReference = _buildParticipantReference(
        fixture['awayTeam']?.toString() ?? '',
        stableIds: stableIds,
        teamByKey: teamByKey,
      );

      final status = _canonicalStatus(
        kickoffUtc: kickoffUtc,
        sportsDb: sportsDb,
        resultFinal: resultData.resultFinal,
      );

      result.add({
        'jogoId': stableIds[matchNumber],
        'matchNumber': matchNumber,
        'ordem': chronologicalOrder[matchNumber],
        'fase': stage == 'group-stage' ? 'Grupo $group' : _stageLabel(stage),
        'faseCodigo': stage,
        'faseTipo': stage == 'group-stage' ? 'fase_de_grupos' : 'mata_mata',
        'grupo': group,
        'rodada': stage == 'group-stage'
            ? groupRoundByMatchNumber[matchNumber]
            : null,
        'roundNumber': _roundNumber(
          stage,
          groupRoundByMatchNumber[matchNumber],
        ),
        'dataTorneio': fixture['date']?.toString() ?? '',
        'dataUtc': _formatUtc(kickoffUtc),
        'dataLocal': _formatBrasilia(kickoffUtc),
        'horaLocal': _formatTime(kickoffUtc.subtract(const Duration(hours: 3))),
        'estadio': fixture['stadium']?.toString() ?? '',
        'cidadeSede': fixture['hostCity']?.toString() ?? '',
        'matchUrl': fixture['matchUrl']?.toString() ?? '',
        'fonteFixture': 'thestatsapi',
        'mandantePrevisto': mandanteReference['descricao'],
        'visitantePrevisto': visitanteReference['descricao'],
        'mandanteReferencia': mandanteReference,
        'visitanteReferencia': visitanteReference,
        'idEventAtual':
            sportsDb?['idEvent']?.toString() ??
            oldGame?['idEventAtual']?.toString(),
        'statusJogo': status,
        'golsMandante': resultData.homeScore,
        'golsVisitante': resultData.awayScore,
        'vencedor': _winner(resultData.homeScore, resultData.awayScore),
        'temHistoricoApi': sportsDb != null,
        'temResultadoApi': sportsDb != null && _hasScore(sportsDb),
        'temResultado': resultData.hasScore,
        'resultadoFinal': resultData.resultFinal,
        'fonteResultado': resultData.source,
      });
    }

    result.sort((a, b) => _asInt(a['ordem'])!.compareTo(_asInt(b['ordem'])!));

    return result;
  }

  Map<int, int> _buildGroupRounds(List<Map<String, dynamic>> fixtures) {
    final byGroup = <String, List<Map<String, dynamic>>>{};

    for (final fixture in fixtures) {
      final group = _nullableString(fixture['group']);

      if (fixture['stage'] == 'group-stage' && group != null) {
        byGroup.putIfAbsent(group, () => []).add(fixture);
      }
    }

    final result = <int, int>{};

    for (final groupFixtures in byGroup.values) {
      groupFixtures.sort((a, b) {
        return _parseUtc(
          a['kickoffUtc']?.toString(),
        )!.compareTo(_parseUtc(b['kickoffUtc']?.toString())!);
      });

      for (var index = 0; index < groupFixtures.length; index++) {
        result[_asInt(groupFixtures[index]['matchNumber'])!] = (index ~/ 2) + 1;
      }
    }

    return result;
  }

  Map<String, dynamic> _buildParticipantReference(
    String source, {
    required Map<int, String> stableIds,
    required Map<String, Map<String, dynamic>> teamByKey,
  }) {
    final teamKey = TeamNormalizer.key(source);
    final team = teamByKey[teamKey];

    if (team != null) {
      return {
        'tipo': 'time',
        'descricao': team['nome'],
        'timeId': team['timeId'],
        'timeKey': teamKey,
        'nomeFonte': source,
      };
    }

    var match = RegExp(
      r'^Group ([A-L]) winners$',
      caseSensitive: false,
    ).firstMatch(source);

    if (match != null) {
      final group = match.group(1)!.toUpperCase();

      return {
        'tipo': 'posicao_grupo',
        'descricao': '1º do Grupo $group',
        'grupo': group,
        'posicao': 1,
      };
    }

    match = RegExp(
      r'^Group ([A-L]) runners-up$',
      caseSensitive: false,
    ).firstMatch(source);

    if (match != null) {
      final group = match.group(1)!.toUpperCase();

      return {
        'tipo': 'posicao_grupo',
        'descricao': '2º do Grupo $group',
        'grupo': group,
        'posicao': 2,
      };
    }

    match = RegExp(
      r'^Group ([A-L](?:/[A-L])+) third place$',
      caseSensitive: false,
    ).firstMatch(source);

    if (match != null) {
      final groups = match.group(1)!.toUpperCase().split('/');

      return {
        'tipo': 'melhor_terceiro',
        'descricao': '3º de ${groups.join('/')}',
        'posicao': 3,
        'gruposElegiveis': groups,
      };
    }

    match = RegExp(
      r'^Winner Match (\d+)$',
      caseSensitive: false,
    ).firstMatch(source);

    if (match != null) {
      final matchNumber = int.parse(match.group(1)!);

      return {
        'tipo': 'vencedor_jogo',
        'descricao': 'Vencedor do jogo $matchNumber',
        'matchNumberReferencia': matchNumber,
        'jogoIdReferencia': stableIds[matchNumber],
      };
    }

    match = RegExp(
      r'^Loser Match (\d+)$',
      caseSensitive: false,
    ).firstMatch(source);

    if (match != null) {
      final matchNumber = int.parse(match.group(1)!);

      return {
        'tipo': 'perdedor_jogo',
        'descricao': 'Perdedor do jogo $matchNumber',
        'matchNumberReferencia': matchNumber,
        'jogoIdReferencia': stableIds[matchNumber],
      };
    }

    return {'tipo': 'texto', 'descricao': source, 'nomeFonte': source};
  }

  _ResultData _chooseResult({
    required Map<String, dynamic>? oldGame,
    required Map<String, dynamic>? sportsDb,
    required Map<String, dynamic>? fixtureDownload,
    required DateTime kickoffUtc,
  }) {
    if (sportsDb != null && _sportsDbIsFinal(sportsDb)) {
      return _ResultData(
        homeScore: _asInt(sportsDb['intHomeScore']),
        awayScore: _asInt(sportsDb['intAwayScore']),
        resultFinal: true,
        source: 'sportsdb',
      );
    }

    final fixtureHomeScore = _asInt(fixtureDownload?['HomeTeamScore']);
    final fixtureAwayScore = _asInt(fixtureDownload?['AwayTeamScore']);

    if (fixtureHomeScore != null && fixtureAwayScore != null) {
      final winner = fixtureDownload?['Winner']?.toString().trim();

      final oldEnough =
          DateTime.now().toUtc().difference(kickoffUtc).inMinutes > 180;

      return _ResultData(
        homeScore: fixtureHomeScore,
        awayScore: fixtureAwayScore,
        resultFinal: (winner != null && winner.isNotEmpty) || oldEnough,
        source: 'fixturedownload',
      );
    }

    final oldHomeScore = _asInt(oldGame?['golsMandante']);
    final oldAwayScore = _asInt(oldGame?['golsVisitante']);
    final oldFinal = oldGame?['resultadoFinal'] == true;

    if (oldHomeScore != null && oldAwayScore != null && oldFinal) {
      return _ResultData(
        homeScore: oldHomeScore,
        awayScore: oldAwayScore,
        resultFinal: true,
        source: oldGame?['fonteResultado']?.toString() ?? 'base_anterior',
      );
    }

    if (sportsDb != null && _hasScore(sportsDb)) {
      return _ResultData(
        homeScore: _asInt(sportsDb['intHomeScore']),
        awayScore: _asInt(sportsDb['intAwayScore']),
        resultFinal: false,
        source: 'sportsdb',
      );
    }

    if (oldHomeScore != null && oldAwayScore != null) {
      return _ResultData(
        homeScore: oldHomeScore,
        awayScore: oldAwayScore,
        resultFinal: oldFinal,
        source: oldGame?['fonteResultado']?.toString() ?? 'base_anterior',
      );
    }

    return const _ResultData(
      homeScore: null,
      awayScore: null,
      resultFinal: false,
      source: null,
    );
  }

  List<Map<String, dynamic>> _buildCanonicalHistory({
    required List<Map<String, dynamic>> sportsDbEvents,
    required List<Map<String, dynamic>> fixtures,
    required List<Map<String, dynamic>> games,
    required Map<int, Map<String, dynamic>> oldGamesByMatchNumber,
  }) {
    final eventByMatchNumber = _mapSportsDbEventsToMatches(
      events: sportsDbEvents,
      fixtures: fixtures,
      oldGamesByMatchNumber: oldGamesByMatchNumber,
    );

    final gameByMatchNumber = <int, Map<String, dynamic>>{
      for (final game in games) _asInt(game['matchNumber'])!: game,
    };

    final result = <Map<String, dynamic>>[];

    for (final entry in eventByMatchNumber.entries) {
      final matchNumber = entry.key;
      final event = entry.value;
      final game = gameByMatchNumber[matchNumber]!;

      result.add({
        ...event,
        'historicoId': 'sportsdb_${event['idEvent']}',
        'fonteDados': 'sportsdb',
        'matchNumber': matchNumber,
        'jogoId': game['jogoId'],
        'eventTimeGMT': game['dataUtc'],
        'fase': game['fase'],
        'faseCodigo': game['faseCodigo'],
        'faseTipo': game['faseTipo'],
        'grupo': game['grupo'],
        'rodada': game['rodada'],
        'roundNumber': game['roundNumber'],
        'statusJogoCanonico': game['statusJogo'],
        'ordemBolao': game['ordem'],
        'mandantePrevisto': game['mandantePrevisto'],
        'visitantePrevisto': game['visitantePrevisto'],
        'temResultado': _hasScore(event),
        'resultadoFinal': _sportsDbIsFinal(event),
      });
    }

    result.sort((a, b) {
      return _asInt(a['matchNumber'])!.compareTo(_asInt(b['matchNumber'])!);
    });

    return result;
  }

  void _updateTeams({
    required List<Map<String, dynamic>> teams,
    required List<Map<String, dynamic>> games,
  }) {
    final teamByKey = <String, Map<String, dynamic>>{
      for (final team in teams)
        TeamNormalizer.key(team['nome']?.toString() ?? ''): team,
    };

    for (final team in teams) {
      team['jogosIds'] = <String>[];
      team['rankingGrupo'] = null;
      team['rankingGrupoProvisorio'] = true;
      team['estatisticasGrupo'] = {
        'pontos': 0,
        'jogos': 0,
        'vitorias': 0,
        'empates': 0,
        'derrotas': 0,
        'golsPro': 0,
        'golsContra': 0,
        'saldoGols': 0,
        'fairPlayPontos': null,
        'cartoesAmarelos': null,
        'cartoesVermelhos': null,
        'cartoesVermelhosIndiretos': null,
        'cartoesAmareloVermelho': null,
        'observacaoDesempate':
            'Classificação provisória sem dados de fair play.',
      };
    }

    for (final game in games) {
      if (game['faseTipo'] != 'fase_de_grupos') {
        continue;
      }

      final homeReference = _asStringMap(game['mandanteReferencia']);
      final awayReference = _asStringMap(game['visitanteReferencia']);

      final homeKey = homeReference['timeKey']?.toString();
      final awayKey = awayReference['timeKey']?.toString();

      final homeTeam = homeKey == null ? null : teamByKey[homeKey];
      final awayTeam = awayKey == null ? null : teamByKey[awayKey];

      if (homeTeam == null || awayTeam == null) {
        continue;
      }

      (homeTeam['jogosIds'] as List).add(game['jogoId']);
      (awayTeam['jogosIds'] as List).add(game['jogoId']);

      if (game['resultadoFinal'] != true) {
        continue;
      }

      final homeScore = _asInt(game['golsMandante']);
      final awayScore = _asInt(game['golsVisitante']);

      if (homeScore == null || awayScore == null) {
        continue;
      }

      _applyGroupResult(
        team: homeTeam,
        goalsFor: homeScore,
        goalsAgainst: awayScore,
      );
      _applyGroupResult(
        team: awayTeam,
        goalsFor: awayScore,
        goalsAgainst: homeScore,
      );
    }

    final teamsByGroup = <String, List<Map<String, dynamic>>>{};

    for (final team in teams) {
      final group = team['grupo']?.toString() ?? '';

      teamsByGroup.putIfAbsent(group, () => []).add(team);
    }

    for (final groupTeams in teamsByGroup.values) {
      groupTeams.sort((a, b) {
        final statsA = _asStringMap(a['estatisticasGrupo']);
        final statsB = _asStringMap(b['estatisticasGrupo']);

        final points = (_asInt(statsB['pontos']) ?? 0).compareTo(
          _asInt(statsA['pontos']) ?? 0,
        );

        if (points != 0) {
          return points;
        }

        final goalDifference = (_asInt(statsB['saldoGols']) ?? 0).compareTo(
          _asInt(statsA['saldoGols']) ?? 0,
        );

        if (goalDifference != 0) {
          return goalDifference;
        }

        final goalsFor = (_asInt(statsB['golsPro']) ?? 0).compareTo(
          _asInt(statsA['golsPro']) ?? 0,
        );

        if (goalsFor != 0) {
          return goalsFor;
        }

        return (a['nome']?.toString() ?? '').compareTo(
          b['nome']?.toString() ?? '',
        );
      });

      for (var index = 0; index < groupTeams.length; index++) {
        groupTeams[index]['rankingGrupo'] = index + 1;
      }
    }

    teams.sort((a, b) {
      final groupComparison = (a['grupo']?.toString() ?? '').compareTo(
        b['grupo']?.toString() ?? '',
      );

      if (groupComparison != 0) {
        return groupComparison;
      }

      return (_asInt(a['rankingGrupo']) ?? 999).compareTo(
        _asInt(b['rankingGrupo']) ?? 999,
      );
    });
  }

  void _applyGroupResult({
    required Map<String, dynamic> team,
    required int goalsFor,
    required int goalsAgainst,
  }) {
    final stats = _asStringMap(team['estatisticasGrupo']);

    stats['jogos'] = (_asInt(stats['jogos']) ?? 0) + 1;
    stats['golsPro'] = (_asInt(stats['golsPro']) ?? 0) + goalsFor;
    stats['golsContra'] = (_asInt(stats['golsContra']) ?? 0) + goalsAgainst;
    stats['saldoGols'] =
        (_asInt(stats['golsPro']) ?? 0) - (_asInt(stats['golsContra']) ?? 0);

    if (goalsFor > goalsAgainst) {
      stats['vitorias'] = (_asInt(stats['vitorias']) ?? 0) + 1;
      stats['pontos'] = (_asInt(stats['pontos']) ?? 0) + 3;
    } else if (goalsFor == goalsAgainst) {
      stats['empates'] = (_asInt(stats['empates']) ?? 0) + 1;
      stats['pontos'] = (_asInt(stats['pontos']) ?? 0) + 1;
    } else {
      stats['derrotas'] = (_asInt(stats['derrotas']) ?? 0) + 1;
    }

    team['estatisticasGrupo'] = stats;
  }

  Future<void> _validate({
    required List<Map<String, dynamic>> games,
    required List<Map<String, dynamic>> history,
    required List<Map<String, dynamic>> teams,
  }) async {
    if (games.length != 104) {
      throw StateError('jogos.json deveria terminar com 104 partidas.');
    }

    final gameIds = games
        .map((game) => game['jogoId']?.toString())
        .whereType<String>()
        .toSet();
    final matchNumbers = games
        .map((game) => _asInt(game['matchNumber']))
        .whereType<int>()
        .toSet();

    if (gameIds.length != 104 || matchNumbers.length != 104) {
      throw StateError('Há jogoId ou matchNumber duplicado.');
    }

    for (var matchNumber = 1; matchNumber <= 104; matchNumber++) {
      if (!matchNumbers.contains(matchNumber)) {
        throw StateError('matchNumber ausente: $matchNumber.');
      }
    }

    final invalidHistory = history.where(
      (record) => !gameIds.contains(record['jogoId']?.toString()),
    );

    if (invalidHistory.isNotEmpty) {
      throw StateError(
        '${invalidHistory.length} registros históricos '
        'apontam para jogos inexistentes.',
      );
    }

    if (_guessesFile.existsSync()) {
      final guesses = await _readJsonList(_guessesFile);
      final invalidGuesses = guesses.where(
        (guess) => !gameIds.contains(guess['jogoId']?.toString()),
      );

      if (invalidGuesses.isNotEmpty) {
        throw StateError(
          '${invalidGuesses.length} palpites apontam '
          'para jogos inexistentes.',
        );
      }
    }

    if (teams.length != 48) {
      throw StateError(
        'times_participantes.json deveria conter '
        '48 seleções.',
      );
    }

    final teamsWithWrongGameCount = teams.where(
      (team) =>
          team['jogosIds'] is! List || (team['jogosIds'] as List).length != 3,
    );

    if (teamsWithWrongGameCount.isNotEmpty) {
      throw StateError(
        '${teamsWithWrongGameCount.length} seleções '
        'não possuem exatamente 3 jogos de grupo.',
      );
    }
  }

  void _printSummary({
    required List<Map<String, dynamic>> games,
    required List<Map<String, dynamic>> history,
    required List<Map<String, dynamic>> sportsDbEvents,
    required Map<int, Map<String, dynamic>> sportsDbByMatchNumber,
    required Map<int, Map<String, dynamic>> fixtureDownloadByMatchNumber,
  }) {
    final finalResults = games.where((game) => game['resultadoFinal'] == true);
    final fixtureFallbackResults = games.where(
      (game) => game['fonteResultado'] == 'fixturedownload',
    );

    stdout.writeln('');
    stdout.writeln('Atualização concluída.');
    stdout.writeln('- Jogos canônicos: ${games.length}');
    stdout.writeln('- Registros SportsDB preservados: ${history.length}');
    stdout.writeln(
      '- Eventos SportsDB disponíveis: '
      '${sportsDbEvents.length}',
    );
    stdout.writeln(
      '- Eventos SportsDB mapeados: '
      '${sportsDbByMatchNumber.length}',
    );
    stdout.writeln(
      '- Partidas FixtureDownload disponíveis: '
      '${fixtureDownloadByMatchNumber.length}',
    );
    stdout.writeln(
      '- Resultados finais consolidados: '
      '${finalResults.length}',
    );
    stdout.writeln(
      '- Resultados usando fallback FixtureDownload: '
      '${fixtureFallbackResults.length}',
    );

    final withoutResult = games.where(
      (game) =>
          game['statusJogo'] == 'encerrado' && game['resultadoFinal'] != true,
    );

    if (withoutResult.isNotEmpty) {
      stdout.writeln('Partidas encerradas ainda sem resultado final:');

      for (final game in withoutResult) {
        stdout.writeln(
          '- Jogo ${game['matchNumber']}: '
          '${game['mandantePrevisto']} x '
          '${game['visitantePrevisto']}',
        );
      }
    }
  }

  String _canonicalStatus({
    required DateTime kickoffUtc,
    required Map<String, dynamic>? sportsDb,
    required bool resultFinal,
  }) {
    if (resultFinal) {
      return 'encerrado';
    }

    final sportsStatus = sportsDb?['strStatus']?.toString().toUpperCase();

    if ({'LIVE', '1H', '2H', 'HT'}.contains(sportsStatus)) {
      return 'em_andamento';
    }

    final difference = DateTime.now().toUtc().difference(kickoffUtc).inMinutes;

    if (difference < 0) {
      return 'agendado';
    }

    if (difference <= 180) {
      return 'em_andamento';
    }

    return 'encerrado';
  }

  bool _sportsDbIsFinal(Map<String, dynamic> event) {
    final status = event['strStatus']?.toString().toUpperCase();

    return _hasScore(event) &&
        {'FT', 'AET', 'PEN', 'FINISHED'}.contains(status);
  }

  bool _hasScore(Map<String, dynamic> event) {
    return _asInt(event['intHomeScore']) != null &&
        _asInt(event['intAwayScore']) != null;
  }

  bool _isApiGeneratedGame(Map<String, dynamic> game) {
    final gameId = game['jogoId']?.toString() ?? '';

    return game['origem'] == 'api' || gameId.startsWith('gapi');
  }

  String _pairKey(String first, String second) {
    final values = [TeamNormalizer.key(first), TeamNormalizer.key(second)]
      ..sort();

    return '${values[0]}|${values[1]}';
  }

  String _stageLabel(String stage) {
    switch (stage) {
      case 'round-of-32':
        return 'Fase de 32';
      case 'round-of-16':
        return 'Oitavas de final';
      case 'quarter-finals':
        return 'Quartas de final';
      case 'semi-finals':
        return 'Semifinal';
      case 'third-place':
        return 'Disputa de 3º lugar';
      case 'final':
        return 'Final';
      default:
        return stage;
    }
  }

  int _roundNumber(String stage, int? groupRound) {
    switch (stage) {
      case 'group-stage':
        return groupRound ?? 0;
      case 'round-of-32':
        return 4;
      case 'round-of-16':
        return 5;
      case 'quarter-finals':
        return 6;
      case 'semi-finals':
        return 7;
      case 'third-place':
      case 'final':
        return 8;
      default:
        return 0;
    }
  }

  String? _winner(int? homeScore, int? awayScore) {
    if (homeScore == null || awayScore == null) {
      return null;
    }

    if (homeScore > awayScore) {
      return 'mandante';
    }

    if (awayScore > homeScore) {
      return 'visitante';
    }

    return 'empate';
  }

  DateTime? _parseUtc(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    return DateTime.tryParse(value)?.toUtc();
  }

  DateTime? _parseSportsDbUtc(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final text = value.trim();
    final hasOffset =
        text.endsWith('Z') || RegExp(r'[+-]\d{2}:\d{2}$').hasMatch(text);
    final normalized = hasOffset ? text : '${text}Z';

    return DateTime.tryParse(normalized)?.toUtc();
  }

  String _formatUtc(DateTime value) {
    return value
        .toUtc()
        .toIso8601String()
        .split('.')
        .first
        .replaceFirst(RegExp(r'$'), 'Z');
  }

  String _formatBrasilia(DateTime utc) {
    final local = utc.toUtc().subtract(const Duration(hours: 3));

    return '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}T'
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}:'
        '${local.second.toString().padLeft(2, '0')}-03:00';
  }

  String _formatTime(DateTime value) {
    return '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';
  }

  String _dateOnly(DateTime value) {
    return '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }

  String _timestampForPath(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    final second = value.second.toString().padLeft(2, '0');

    return '$year$month${day}_$hour$minute$second';
  }

  int? _asInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value.toString());
  }

  String? _nullableString(dynamic value) {
    if (value == null) {
      return null;
    }

    final text = value.toString().trim();

    return text.isEmpty ? null : text;
  }

  Map<String, dynamic> _asStringMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return <String, dynamic>{};
  }
}

class ApiEndpointResult {
  final String name;
  final String uri;
  final bool ok;
  final int? statusCode;
  final int eventCount;
  final int durationMs;
  final String? error;
  final String? warning;

  const ApiEndpointResult({
    required this.name,
    required this.uri,
    required this.ok,
    this.statusCode,
    required this.eventCount,
    required this.durationMs,
    this.error,
    this.warning,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'uri': uri,
      'ok': ok,
      'statusCode': statusCode,
      'eventCount': eventCount,
      'durationMs': durationMs,
      'error': error,
      'warning': warning,
    };
  }
}

class _ResultData {
  final int? homeScore;
  final int? awayScore;
  final bool resultFinal;
  final String? source;

  const _ResultData({
    required this.homeScore,
    required this.awayScore,
    required this.resultFinal,
    required this.source,
  });

  bool get hasScore {
    return homeScore != null && awayScore != null;
  }
}
