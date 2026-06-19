import 'dart:convert';

import 'package:http/http.dart' as http;

class SportsDbApiService {
  static const String apiKey = '123';
  static const String baseUrl =
      'https://www.thesportsdb.com/api/v1/json/$apiKey';

  final String leagueId;
  final String season;
  final Duration timeout;

  const SportsDbApiService({
    this.leagueId = '4429',
    this.season = '2026',
    this.timeout = const Duration(seconds: 20),
  });

  Future<SportsDbApiResult> fetchRefreshResult({
    Iterable<String> eventIds = const [],
  }) async {
    final requests = buildRefreshRequests(eventIds: eventIds);

    final endpointResults = await Future.wait(requests.map(_fetchEndpointSafe));

    final byId = <String, SportsDbEvent>{};

    for (final result in endpointResults) {
      for (final event in result.events) {
        if (event.idLeague == leagueId && event.idEvent.isNotEmpty) {
          byId[event.idEvent] = _preferEvent(byId[event.idEvent], event);
        }
      }
    }

    return SportsDbApiResult(
      events: byId.values.toList(growable: false),
      endpoints: endpointResults,
    );
  }

  SportsDbEvent _preferEvent(SportsDbEvent? current, SportsDbEvent incoming) {
    if (current == null) {
      return incoming;
    }

    if (incoming.temPlacar && !current.temPlacar) {
      return incoming;
    }

    if (current.temPlacar && !incoming.temPlacar) {
      return current;
    }

    if (incoming.temPlacar && current.temPlacar) {
      final incomingTotal = incoming.intHomeScore! + incoming.intAwayScore!;
      final currentTotal = current.intHomeScore! + current.intAwayScore!;

      if (incomingTotal != currentTotal) {
        return incomingTotal > currentTotal ? incoming : current;
      }

      if (incoming.isFinal && !current.isFinal) {
        return incoming;
      }

      if (current.isFinal && !incoming.isFinal) {
        return current;
      }
    }

    if (incoming.isFinal && !current.isFinal) {
      return incoming;
    }

    if (current.isFinal && !incoming.isFinal) {
      return current;
    }

    final incomingStatusRank = _statusRank(incoming.statusCanonico);
    final currentStatusRank = _statusRank(current.statusCanonico);
    if (incomingStatusRank > currentStatusRank) {
      return incoming;
    }

    if (currentStatusRank > incomingStatusRank) {
      return current;
    }

    return incoming;
  }

  int _statusRank(String status) {
    return switch (status) {
      'encerrado' => 3,
      'em_andamento' => 2,
      'adiado' => 1,
      'agendado' => 1,
      _ => 0,
    };
  }

  List<SportsDbEndpointRequest> buildRefreshRequests({
    DateTime? nowUtc,
    Iterable<String> eventIds = const [],
  }) {
    final currentUtc = (nowUtc ?? DateTime.now().toUtc()).toUtc();

    final requests = <SportsDbEndpointRequest>[
      SportsDbEndpointRequest(
        name: 'eventsseason',
        uri: Uri.parse('$baseUrl/eventsseason.php?id=$leagueId&s=$season'),
      ),
      SportsDbEndpointRequest(
        name: 'eventsnextleague',
        uri: Uri.parse('$baseUrl/eventsnextleague.php?id=$leagueId'),
      ),
      SportsDbEndpointRequest(
        name: 'eventspastleague',
        uri: Uri.parse('$baseUrl/eventspastleague.php?id=$leagueId'),
      ),
    ];

    for (var offset = -3; offset <= 1; offset++) {
      final date = currentUtc.add(Duration(days: offset));
      final dateText = _dateOnly(date);

      requests.add(
        SportsDbEndpointRequest(
          name: 'eventsday:$dateText',
          uri: Uri.parse('$baseUrl/eventsday.php?d=$dateText&s=Soccer'),
        ),
      );
    }

    final uniqueEventIds = <String>{};
    for (final eventId in eventIds) {
      final normalized = eventId.trim();
      if (normalized.isNotEmpty) {
        uniqueEventIds.add(normalized);
      }
    }

    for (final eventId in uniqueEventIds) {
      requests.add(
        SportsDbEndpointRequest(
          name: 'lookupevent:$eventId',
          uri: Uri.parse('$baseUrl/lookupevent.php?id=$eventId'),
        ),
      );
    }

    return requests;
  }

  Future<List<SportsDbEvent>> fetchRefreshEvents() async {
    final result = await fetchRefreshResult();
    return result.events;
  }

  Future<List<SportsDbEvent>> fetchAllCoreEvents() {
    return fetchRefreshEvents();
  }

  Future<SportsDbEventDetailsResult> fetchEventDetails(String eventId) async {
    final requests = buildEventDetailRequests(eventId);
    final endpointResults = await Future.wait(
      requests.map(_fetchDetailEndpointSafe),
    );

    final timelines = <SportsDbTimelineItem>[];
    final lineups = <SportsDbLineupItem>[];
    final results = <SportsDbPlayerResult>[];
    final stats = <SportsDbEventStat>[];

    for (final endpoint in endpointResults) {
      switch (endpoint.kind) {
        case SportsDbDetailKind.timeline:
          timelines.addAll(endpoint.rows.map(SportsDbTimelineItem.fromJson));
        case SportsDbDetailKind.lineup:
          lineups.addAll(endpoint.rows.map(SportsDbLineupItem.fromJson));
        case SportsDbDetailKind.results:
          results.addAll(endpoint.rows.map(SportsDbPlayerResult.fromJson));
        case SportsDbDetailKind.stats:
          stats.addAll(endpoint.rows.map(SportsDbEventStat.fromJson));
      }
    }

    timelines.sort((a, b) => a.minuteValue.compareTo(b.minuteValue));

    return SportsDbEventDetailsResult(
      eventId: eventId,
      timeline: timelines,
      lineup: lineups,
      results: results,
      stats: stats,
      endpoints: endpointResults,
    );
  }

  List<SportsDbDetailEndpointRequest> buildEventDetailRequests(String eventId) {
    final normalized = eventId.trim();
    if (normalized.isEmpty) {
      return const [];
    }

    return [
      SportsDbDetailEndpointRequest(
        name: 'lookuptimeline:$normalized',
        kind: SportsDbDetailKind.timeline,
        keys: const ['timeline', 'eventtimeline'],
        uri: Uri.parse('$baseUrl/lookuptimeline.php?id=$normalized'),
      ),
      SportsDbDetailEndpointRequest(
        name: 'lookuplineup:$normalized',
        kind: SportsDbDetailKind.lineup,
        keys: const ['lineup', 'eventlineup'],
        uri: Uri.parse('$baseUrl/lookuplineup.php?id=$normalized'),
      ),
      SportsDbDetailEndpointRequest(
        name: 'eventresults:$normalized',
        kind: SportsDbDetailKind.results,
        keys: const ['results', 'eventresults'],
        uri: Uri.parse('$baseUrl/eventresults.php?id=$normalized'),
      ),
      SportsDbDetailEndpointRequest(
        name: 'lookupeventstats:$normalized',
        kind: SportsDbDetailKind.stats,
        keys: const ['eventstats', 'stats'],
        uri: Uri.parse('$baseUrl/lookupeventstats.php?id=$normalized'),
      ),
    ];
  }

  Future<SportsDbEndpointResult> _fetchEndpointSafe(
    SportsDbEndpointRequest request,
  ) async {
    final stopwatch = Stopwatch()..start();

    try {
      final response = await http.get(request.uri).timeout(timeout);
      stopwatch.stop();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return SportsDbEndpointResult(
          name: request.name,
          uri: request.uri.toString(),
          ok: false,
          statusCode: response.statusCode,
          events: const [],
          durationMs: stopwatch.elapsedMilliseconds,
          error: 'HTTP ${response.statusCode} ao consultar ${request.uri}',
        );
      }

      final parsed = _parseEvents(
        body: response.body,
        endpointName: request.name,
        uri: request.uri,
      );

      return SportsDbEndpointResult(
        name: request.name,
        uri: request.uri.toString(),
        ok: parsed.ok,
        statusCode: response.statusCode,
        events: parsed.events,
        durationMs: stopwatch.elapsedMilliseconds,
        error: parsed.error,
        warning: parsed.warning,
      );
    } catch (error) {
      stopwatch.stop();

      return SportsDbEndpointResult(
        name: request.name,
        uri: request.uri.toString(),
        ok: false,
        events: const [],
        durationMs: stopwatch.elapsedMilliseconds,
        error: error.toString(),
      );
    }
  }

  Future<SportsDbDetailEndpointResult> _fetchDetailEndpointSafe(
    SportsDbDetailEndpointRequest request,
  ) async {
    final stopwatch = Stopwatch()..start();

    try {
      final response = await http.get(request.uri).timeout(timeout);
      stopwatch.stop();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return SportsDbDetailEndpointResult(
          name: request.name,
          kind: request.kind,
          uri: request.uri.toString(),
          ok: false,
          statusCode: response.statusCode,
          rows: const [],
          durationMs: stopwatch.elapsedMilliseconds,
          error: 'HTTP ${response.statusCode} ao consultar ${request.uri}',
        );
      }

      final parsed = _parseRows(
        body: response.body,
        endpointName: request.name,
        uri: request.uri,
        keys: request.keys,
      );

      return SportsDbDetailEndpointResult(
        name: request.name,
        kind: request.kind,
        uri: request.uri.toString(),
        ok: parsed.ok,
        statusCode: response.statusCode,
        rows: parsed.rows,
        durationMs: stopwatch.elapsedMilliseconds,
        error: parsed.error,
        warning: parsed.warning,
      );
    } catch (error) {
      stopwatch.stop();

      return SportsDbDetailEndpointResult(
        name: request.name,
        kind: request.kind,
        uri: request.uri.toString(),
        ok: false,
        rows: const [],
        durationMs: stopwatch.elapsedMilliseconds,
        error: error.toString(),
      );
    }
  }

  _ParsedEvents _parseEvents({
    required String body,
    required String endpointName,
    required Uri uri,
  }) {
    try {
      final decoded = jsonDecode(body);

      if (decoded is! Map) {
        return _ParsedEvents(
          ok: false,
          events: const [],
          error: 'Resposta de $endpointName não era objeto JSON.',
        );
      }

      final rawEvents = decoded['events'];

      if (rawEvents == null) {
        return const _ParsedEvents(ok: true, events: []);
      }

      if (rawEvents is! List) {
        return _ParsedEvents(
          ok: false,
          events: const [],
          error: 'Campo events de $endpointName não era uma lista JSON.',
        );
      }

      final events = <SportsDbEvent>[];
      var malformedItems = 0;

      for (final item in rawEvents) {
        try {
          if (item is Map<String, dynamic>) {
            events.add(SportsDbEvent.fromJson(item));
          } else if (item is Map) {
            events.add(SportsDbEvent.fromJson(Map<String, dynamic>.from(item)));
          } else {
            malformedItems++;
          }
        } catch (_) {
          malformedItems++;
        }
      }

      return _ParsedEvents(
        ok: true,
        events: events,
        warning: malformedItems > 0
            ? '$malformedItems item(ns) malformado(s) ignorado(s) em $uri.'
            : null,
      );
    } catch (error) {
      return _ParsedEvents(
        ok: false,
        events: const [],
        error: 'Erro ao decodificar JSON de $endpointName: $error',
      );
    }
  }

  _ParsedRows _parseRows({
    required String body,
    required String endpointName,
    required Uri uri,
    required List<String> keys,
  }) {
    try {
      final decoded = jsonDecode(body);

      if (decoded is! Map) {
        return _ParsedRows(
          ok: false,
          rows: const [],
          error: 'Resposta de $endpointName não era objeto JSON.',
        );
      }

      Object? rawRows;
      for (final key in keys) {
        if (decoded.containsKey(key)) {
          rawRows = decoded[key];
          break;
        }
      }

      rawRows ??= decoded.values.whereType<List>().firstOrNull;

      if (rawRows == null) {
        return const _ParsedRows(ok: true, rows: []);
      }

      if (rawRows is! List) {
        return _ParsedRows(
          ok: false,
          rows: const [],
          error: 'Campo de dados de $endpointName não era uma lista JSON.',
        );
      }

      final rows = <Map<String, dynamic>>[];
      var malformedItems = 0;

      for (final item in rawRows) {
        if (item is Map<String, dynamic>) {
          rows.add(item);
        } else if (item is Map) {
          rows.add(Map<String, dynamic>.from(item));
        } else {
          malformedItems++;
        }
      }

      return _ParsedRows(
        ok: true,
        rows: rows,
        warning: malformedItems > 0
            ? '$malformedItems item(ns) malformado(s) ignorado(s) em $uri.'
            : null,
      );
    } catch (error) {
      return _ParsedRows(
        ok: false,
        rows: const [],
        error: 'Erro ao decodificar JSON de $endpointName: $error',
      );
    }
  }

  static String _dateOnly(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }
}

class SportsDbApiResult {
  final List<SportsDbEvent> events;
  final List<SportsDbEndpointResult> endpoints;

  const SportsDbApiResult({required this.events, required this.endpoints});

  bool get hasAnySuccessfulEndpoint {
    return endpoints.any((endpoint) => endpoint.ok);
  }

  bool get hasAnyFailedEndpoint {
    return endpoints.any((endpoint) => !endpoint.ok);
  }

  int get successfulEndpointCount {
    return endpoints.where((endpoint) => endpoint.ok).length;
  }

  int get failedEndpointCount {
    return endpoints.where((endpoint) => !endpoint.ok).length;
  }

  String get summaryText {
    final warnings = endpoints
        .where((endpoint) => endpoint.error != null || endpoint.warning != null)
        .length;

    return 'SportsDB: ${events.length} eventos, '
        '$successfulEndpointCount endpoint(s) OK, '
        '$failedEndpointCount falha(s), '
        '$warnings aviso(s).';
  }
}

class SportsDbEndpointRequest {
  final String name;
  final Uri uri;

  const SportsDbEndpointRequest({required this.name, required this.uri});
}

class SportsDbEndpointResult {
  final String name;
  final String uri;
  final bool ok;
  final int? statusCode;
  final List<SportsDbEvent> events;
  final int durationMs;
  final String? error;
  final String? warning;

  const SportsDbEndpointResult({
    required this.name,
    required this.uri,
    required this.ok,
    this.statusCode,
    required this.events,
    required this.durationMs,
    this.error,
    this.warning,
  });

  int get eventCount => events.length;
}

enum SportsDbDetailKind { timeline, lineup, results, stats }

class SportsDbDetailEndpointRequest {
  final String name;
  final SportsDbDetailKind kind;
  final Uri uri;
  final List<String> keys;

  const SportsDbDetailEndpointRequest({
    required this.name,
    required this.kind,
    required this.uri,
    required this.keys,
  });
}

class SportsDbDetailEndpointResult {
  final String name;
  final SportsDbDetailKind kind;
  final String uri;
  final bool ok;
  final int? statusCode;
  final List<Map<String, dynamic>> rows;
  final int durationMs;
  final String? error;
  final String? warning;

  const SportsDbDetailEndpointResult({
    required this.name,
    required this.kind,
    required this.uri,
    required this.ok,
    this.statusCode,
    required this.rows,
    required this.durationMs,
    this.error,
    this.warning,
  });

  int get rowCount => rows.length;
}

class SportsDbEventDetailsResult {
  final String eventId;
  final List<SportsDbTimelineItem> timeline;
  final List<SportsDbLineupItem> lineup;
  final List<SportsDbPlayerResult> results;
  final List<SportsDbEventStat> stats;
  final List<SportsDbDetailEndpointResult> endpoints;

  const SportsDbEventDetailsResult({
    required this.eventId,
    required this.timeline,
    required this.lineup,
    required this.results,
    required this.stats,
    required this.endpoints,
  });

  bool get hasAnySuccessfulEndpoint {
    return endpoints.any((endpoint) => endpoint.ok);
  }

  bool get hasAnyData {
    return timeline.isNotEmpty ||
        lineup.isNotEmpty ||
        results.isNotEmpty ||
        stats.isNotEmpty;
  }

  bool get hasAnyFailedEndpoint {
    return endpoints.any((endpoint) => !endpoint.ok);
  }
}

class SportsDbTimelineItem {
  final String? minute;
  final String? type;
  final String? team;
  final String? player;
  final String? detail;
  final Map<String, dynamic> raw;

  const SportsDbTimelineItem({
    required this.minute,
    required this.type,
    required this.team,
    required this.player,
    required this.detail,
    required this.raw,
  });

  factory SportsDbTimelineItem.fromJson(Map<String, dynamic> json) {
    return SportsDbTimelineItem(
      minute: _firstString(json, const [
        'intTime',
        'intMinute',
        'strTime',
        'strMinute',
      ]),
      type: _firstString(json, const [
        'strTimeline',
        'strTimelineDetail',
        'strType',
        'strEvent',
      ]),
      team: _firstString(json, const ['strTeam', 'strHome', 'strAway']),
      player: _firstString(json, const [
        'strPlayer',
        'strPlayer1',
        'strEventPlayer',
      ]),
      detail: _firstString(json, const [
        'strTimelineDetail',
        'strDetail',
        'strAssist',
        'strComment',
      ]),
      raw: Map<String, dynamic>.from(json),
    );
  }

  int get minuteValue {
    final text = minute;
    if (text == null) {
      return 999;
    }

    return int.tryParse(RegExp(r'\d+').firstMatch(text)?.group(0) ?? '') ?? 999;
  }

  bool get isGoal {
    return _containsAny(type, const ['goal', 'gol']);
  }

  bool get isYellowCard {
    return _containsAny(type, const ['yellow', 'amarelo']);
  }

  bool get isRedCard {
    return _containsAny(type, const ['red card', 'vermelho']);
  }

  bool get isCard => isYellowCard || isRedCard;

  bool get isCancelled {
    return _containsAny(type, const [
          'cancelled',
          'disallowed',
          'var',
          'anulado',
        ]) ||
        _containsAny(detail, const [
          'cancelled',
          'disallowed',
          'var',
          'anulado',
        ]);
  }

  bool get isNotable => isGoal || isCard || isCancelled;

  String get displayType {
    if (isCancelled) {
      return isGoal ? 'Gol anulado' : 'Revisão/Anulado';
    }

    if (isGoal) {
      return 'Gol';
    }

    if (isYellowCard) {
      return 'Cartão amarelo';
    }

    if (isRedCard) {
      return 'Cartão vermelho';
    }

    return type ?? 'Evento';
  }
}

class SportsDbLineupItem {
  final String? team;
  final String? player;
  final String? position;
  final String? number;
  final String? substitute;
  final Map<String, dynamic> raw;

  const SportsDbLineupItem({
    required this.team,
    required this.player,
    required this.position,
    required this.number,
    required this.substitute,
    required this.raw,
  });

  factory SportsDbLineupItem.fromJson(Map<String, dynamic> json) {
    return SportsDbLineupItem(
      team: _firstString(json, const ['strTeam', 'strHome', 'strAway']),
      player: _firstString(json, const ['strPlayer', 'strPlayerName']),
      position: _firstString(json, const ['strPosition', 'strRole']),
      number: _firstString(json, const ['intSquadNumber', 'strNumber']),
      substitute: _firstString(json, const ['strSubstitute', 'strLineup']),
      raw: Map<String, dynamic>.from(json),
    );
  }

  bool get isSubstitute {
    final value = substitute?.toLowerCase().trim();
    return value == 'yes' ||
        value == 'true' ||
        value == 'substitute' ||
        value == 'bench';
  }
}

class SportsDbPlayerResult {
  final String? team;
  final String? player;
  final String? position;
  final String? rating;
  final Map<String, dynamic> raw;

  const SportsDbPlayerResult({
    required this.team,
    required this.player,
    required this.position,
    required this.rating,
    required this.raw,
  });

  factory SportsDbPlayerResult.fromJson(Map<String, dynamic> json) {
    return SportsDbPlayerResult(
      team: _firstString(json, const ['strTeam', 'strHome', 'strAway']),
      player: _firstString(json, const ['strPlayer', 'strPlayerName']),
      position: _firstString(json, const ['strPosition']),
      rating: _firstString(json, const ['strRating', 'intRating']),
      raw: Map<String, dynamic>.from(json),
    );
  }
}

class SportsDbEventStat {
  final String? name;
  final String? home;
  final String? away;
  final Map<String, dynamic> raw;

  const SportsDbEventStat({
    required this.name,
    required this.home,
    required this.away,
    required this.raw,
  });

  factory SportsDbEventStat.fromJson(Map<String, dynamic> json) {
    return SportsDbEventStat(
      name: _firstString(json, const ['strStat', 'strStatistic']),
      home: _firstString(json, const ['intHome', 'strHome']),
      away: _firstString(json, const ['intAway', 'strAway']),
      raw: Map<String, dynamic>.from(json),
    );
  }
}

class _ParsedEvents {
  final bool ok;
  final List<SportsDbEvent> events;
  final String? error;
  final String? warning;

  const _ParsedEvents({
    required this.ok,
    required this.events,
    this.error,
    this.warning,
  });
}

class _ParsedRows {
  final bool ok;
  final List<Map<String, dynamic>> rows;
  final String? error;
  final String? warning;

  const _ParsedRows({
    required this.ok,
    required this.rows,
    this.error,
    this.warning,
  });
}

String? _firstString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value == null) {
      continue;
    }

    final text = value.toString().trim();
    if (text.isNotEmpty) {
      return text;
    }
  }

  return null;
}

bool _containsAny(String? value, List<String> needles) {
  final text = value?.toLowerCase();
  if (text == null) {
    return false;
  }

  return needles.any((needle) => text.contains(needle));
}

class SportsDbEvent {
  static const Duration maxLiveDuration = Duration(minutes: 145);

  final String idEvent;
  final String? idLeague;

  final String? strEvent;
  final String? strHomeTeam;
  final String? strAwayTeam;
  final String? idHomeTeam;
  final String? idAwayTeam;

  final int? intHomeScore;
  final int? intAwayScore;

  final String? dateEvent;
  final String? dateEventLocal;
  final String? strTime;
  final String? strTimeLocal;
  final DateTime? strTimestampUtc;

  final String? strVenue;
  final String? strCity;
  final String? strCountry;
  final String? idVenue;
  final String? strStatus;
  final String? strPostponed;
  final String? strGroup;
  final int? intRound;

  final String? strLeagueBadge;
  final String? strHomeTeamBadge;
  final String? strAwayTeamBadge;
  final String? strThumb;
  final String? strPoster;
  final String? strFanart;
  final String? strBanner;
  final String? strVideo;

  const SportsDbEvent({
    required this.idEvent,
    required this.idLeague,
    required this.strEvent,
    required this.strHomeTeam,
    required this.strAwayTeam,
    required this.idHomeTeam,
    required this.idAwayTeam,
    required this.intHomeScore,
    required this.intAwayScore,
    required this.dateEvent,
    required this.dateEventLocal,
    required this.strTime,
    required this.strTimeLocal,
    required this.strTimestampUtc,
    required this.strVenue,
    required this.strCity,
    required this.strCountry,
    required this.idVenue,
    required this.strStatus,
    required this.strPostponed,
    required this.strGroup,
    required this.intRound,
    required this.strLeagueBadge,
    required this.strHomeTeamBadge,
    required this.strAwayTeamBadge,
    required this.strThumb,
    required this.strPoster,
    required this.strFanart,
    required this.strBanner,
    required this.strVideo,
  });

  factory SportsDbEvent.fromJson(Map<String, dynamic> json) {
    return SportsDbEvent(
      idEvent: json['idEvent']?.toString() ?? '',
      idLeague: _nullableString(json['idLeague']),
      strEvent: _nullableString(json['strEvent']),
      strHomeTeam: _nullableString(json['strHomeTeam']),
      strAwayTeam: _nullableString(json['strAwayTeam']),
      idHomeTeam: _nullableString(json['idHomeTeam']),
      idAwayTeam: _nullableString(json['idAwayTeam']),
      intHomeScore: _nullableInt(json['intHomeScore']),
      intAwayScore: _nullableInt(json['intAwayScore']),
      dateEvent: _nullableString(json['dateEvent']),
      dateEventLocal: _nullableString(json['dateEventLocal']),
      strTime: _nullableString(json['strTime']),
      strTimeLocal: _nullableString(json['strTimeLocal']),
      strTimestampUtc: _parseApiTimestampUtc(json['strTimestamp']),
      strVenue: _nullableString(json['strVenue']),
      strCity: _nullableString(json['strCity']),
      strCountry: _nullableString(json['strCountry']),
      idVenue: _nullableString(json['idVenue']),
      strStatus: _nullableString(json['strStatus']),
      strPostponed: _nullableString(json['strPostponed']),
      strGroup: _nullableString(json['strGroup']),
      intRound: _nullableInt(json['intRound']),
      strLeagueBadge: _nullableString(json['strLeagueBadge']),
      strHomeTeamBadge: _nullableString(json['strHomeTeamBadge']),
      strAwayTeamBadge: _nullableString(json['strAwayTeamBadge']),
      strThumb: _nullableString(json['strThumb']),
      strPoster: _nullableString(json['strPoster']),
      strFanart: _nullableString(json['strFanart']),
      strBanner: _nullableString(json['strBanner']),
      strVideo: _nullableString(json['strVideo']),
    );
  }

  bool get temPlacar {
    return intHomeScore != null && intAwayScore != null;
  }

  bool get isFinal {
    final status = strStatus?.toUpperCase().trim();

    return temPlacar &&
        {'FT', 'AET', 'PEN', 'FINISHED', 'MATCH FINISHED'}.contains(status);
  }

  String get statusCanonico {
    final status = strStatus?.toUpperCase().trim();
    final postponed = strPostponed?.toLowerCase().trim();

    if (postponed == 'yes' || status == 'POSTPONED' || status == 'PST') {
      return 'adiado';
    }

    if ({'FT', 'AET', 'PEN', 'FINISHED', 'MATCH FINISHED'}.contains(status)) {
      return 'encerrado';
    }

    if ({'LIVE', '1H', '2H', 'HT'}.contains(status)) {
      if (_passouDaJanelaAoVivo) {
        return 'encerrado';
      }

      return 'em_andamento';
    }

    if (strTimestampUtc == null) {
      return 'agendado';
    }

    final nowUtc = DateTime.now().toUtc();

    if (nowUtc.isBefore(strTimestampUtc!)) {
      return 'agendado';
    }

    if (nowUtc.difference(strTimestampUtc!) <= maxLiveDuration) {
      return 'em_andamento';
    }

    return 'encerrado';
  }

  bool get isEncerradoInferidoPorRelogio {
    final status = strStatus?.toUpperCase().trim();
    return temPlacar &&
        !isFinal &&
        {'LIVE', '1H', '2H', 'HT'}.contains(status) &&
        _passouDaJanelaAoVivo;
  }

  bool get _passouDaJanelaAoVivo {
    final timestamp = strTimestampUtc;
    if (timestamp == null) {
      return false;
    }

    return DateTime.now().toUtc().difference(timestamp) > maxLiveDuration;
  }

  String? get stadiumImage {
    return strThumb ?? strPoster ?? strFanart ?? strBanner;
  }

  static DateTime? _parseApiTimestampUtc(dynamic value) {
    if (value == null) {
      return null;
    }

    final text = value.toString().trim();

    if (text.isEmpty) {
      return null;
    }

    final hasOffset =
        text.endsWith('Z') || RegExp(r'[+-]\d{2}:\d{2}$').hasMatch(text);

    final normalized = hasOffset ? text : '${text}Z';

    return DateTime.tryParse(normalized)?.toUtc();
  }

  static String? _nullableString(dynamic value) {
    if (value == null) {
      return null;
    }

    final text = value.toString().trim();

    return text.isEmpty ? null : text;
  }

  static int? _nullableInt(dynamic value) {
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
}
