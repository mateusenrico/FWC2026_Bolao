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

  Future<SportsDbApiResult> fetchRefreshResult() async {
    final nowUtc = DateTime.now().toUtc();

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
      final date = nowUtc.add(Duration(days: offset));
      final dateText = _dateOnly(date);

      requests.add(
        SportsDbEndpointRequest(
          name: 'eventsday:$dateText',
          uri: Uri.parse('$baseUrl/eventsday.php?d=$dateText&s=Soccer'),
        ),
      );
    }

    final endpointResults = await Future.wait(requests.map(_fetchEndpointSafe));

    final byId = <String, SportsDbEvent>{};

    for (final result in endpointResults) {
      for (final event in result.events) {
        if (event.idLeague == leagueId && event.idEvent.isNotEmpty) {
          byId[event.idEvent] = event;
        }
      }
    }

    return SportsDbApiResult(
      events: byId.values.toList(growable: false),
      endpoints: endpointResults,
    );
  }

  Future<List<SportsDbEvent>> fetchRefreshEvents() async {
    final result = await fetchRefreshResult();
    return result.events;
  }

  Future<List<SportsDbEvent>> fetchAllCoreEvents() {
    return fetchRefreshEvents();
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

class SportsDbEvent {
  final String idEvent;
  final String? idLeague;

  final String? strEvent;
  final String? strHomeTeam;
  final String? strAwayTeam;

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
  final String? strStatus;
  final String? strGroup;
  final int? intRound;

  final String? strHomeTeamBadge;
  final String? strAwayTeamBadge;
  final String? strThumb;
  final String? strPoster;
  final String? strFanart;
  final String? strBanner;

  const SportsDbEvent({
    required this.idEvent,
    required this.idLeague,
    required this.strEvent,
    required this.strHomeTeam,
    required this.strAwayTeam,
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
    required this.strStatus,
    required this.strGroup,
    required this.intRound,
    required this.strHomeTeamBadge,
    required this.strAwayTeamBadge,
    required this.strThumb,
    required this.strPoster,
    required this.strFanart,
    required this.strBanner,
  });

  factory SportsDbEvent.fromJson(Map<String, dynamic> json) {
    return SportsDbEvent(
      idEvent: json['idEvent']?.toString() ?? '',
      idLeague: _nullableString(json['idLeague']),
      strEvent: _nullableString(json['strEvent']),
      strHomeTeam: _nullableString(json['strHomeTeam']),
      strAwayTeam: _nullableString(json['strAwayTeam']),
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
      strStatus: _nullableString(json['strStatus']),
      strGroup: _nullableString(json['strGroup']),
      intRound: _nullableInt(json['intRound']),
      strHomeTeamBadge: _nullableString(json['strHomeTeamBadge']),
      strAwayTeamBadge: _nullableString(json['strAwayTeamBadge']),
      strThumb: _nullableString(json['strThumb']),
      strPoster: _nullableString(json['strPoster']),
      strFanart: _nullableString(json['strFanart']),
      strBanner: _nullableString(json['strBanner']),
    );
  }

  bool get temPlacar {
    return intHomeScore != null && intAwayScore != null;
  }

  bool get isFinal {
    final status = strStatus?.toUpperCase().trim();

    return temPlacar && {'FT', 'AET', 'PEN', 'FINISHED'}.contains(status);
  }

  String get statusCanonico {
    final status = strStatus?.toUpperCase().trim();

    if ({'FT', 'AET', 'PEN', 'FINISHED'}.contains(status)) {
      return 'encerrado';
    }

    if ({'LIVE', '1H', '2H', 'HT'}.contains(status)) {
      return 'em_andamento';
    }

    if (strTimestampUtc == null) {
      return 'agendado';
    }

    final nowUtc = DateTime.now().toUtc();

    if (nowUtc.isBefore(strTimestampUtc!)) {
      return 'agendado';
    }

    if (nowUtc.difference(strTimestampUtc!).inMinutes <= 180) {
      return 'em_andamento';
    }

    return 'encerrado';
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
