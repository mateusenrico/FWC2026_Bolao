import 'dart:convert';

import 'package:http/http.dart' as http;

class SportsDbApiService {
  static const String apiKey = '123';
  static const String baseUrl =
      'https://www.thesportsdb.com/api/v1/json/$apiKey';

  final String leagueId;
  final String season;

  const SportsDbApiService({this.leagueId = '4429', this.season = '2026'});

  Future<List<SportsDbEvent>> fetchRefreshEvents() async {
    final nowUtc = DateTime.now().toUtc();

    final uris = <Uri>[
      Uri.parse('$baseUrl/eventsseason.php?id=$leagueId&s=$season'),
      Uri.parse('$baseUrl/eventsnextleague.php?id=$leagueId'),
      Uri.parse('$baseUrl/eventspastleague.php?id=$leagueId'),
    ];

    for (var offset = -3; offset <= 1; offset++) {
      final date = nowUtc.add(Duration(days: offset));
      uris.add(
        Uri.parse(
          '$baseUrl/eventsday.php'
          '?d=${_dateOnly(date)}&s=Soccer',
        ),
      );
    }

    final responses = await Future.wait(uris.map(_fetchEventsSafe));

    final byId = <String, SportsDbEvent>{};

    for (final events in responses) {
      for (final event in events) {
        if (event.idLeague == leagueId && event.idEvent.isNotEmpty) {
          byId[event.idEvent] = event;
        }
      }
    }

    return byId.values.toList(growable: false);
  }

  Future<List<SportsDbEvent>> fetchAllCoreEvents() {
    return fetchRefreshEvents();
  }

  Future<List<SportsDbEvent>> _fetchEventsSafe(Uri uri) async {
    try {
      return await _fetchEvents(uri);
    } catch (_) {
      return const [];
    }
  }

  Future<List<SportsDbEvent>> _fetchEvents(Uri uri) async {
    final response = await http.get(uri);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Falha HTTP ${response.statusCode} em $uri');
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map) {
      return const [];
    }

    final rawEvents = decoded['events'];

    if (rawEvents == null || rawEvents is! List) {
      return const [];
    }

    return rawEvents
        .map((item) {
          if (item is Map<String, dynamic>) {
            return SportsDbEvent.fromJson(item);
          }

          if (item is Map) {
            return SportsDbEvent.fromJson(Map<String, dynamic>.from(item));
          }

          throw FormatException(
            'Evento inválido vindo da API: ${item.runtimeType}',
          );
        })
        .toList(growable: false);
  }

  static String _dateOnly(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }
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
