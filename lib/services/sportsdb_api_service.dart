import 'dart:convert';

import 'package:http/http.dart' as http;

class SportsDbApiService {
  static const String apiKey = '123';
  static const String baseUrl =
      'https://www.thesportsdb.com/api/v1/json/$apiKey';

  final String leagueId;
  final String season;

  const SportsDbApiService({this.leagueId = '4429', this.season = '2026'});

  Future<List<SportsDbEvent>> fetchSeasonEvents() async {
    final uri = Uri.parse('$baseUrl/eventsseason.php?id=$leagueId&s=$season');
    return _fetchEvents(uri);
  }

  Future<List<SportsDbEvent>> fetchNextLeagueEvents() async {
    final uri = Uri.parse('$baseUrl/eventsnextleague.php?id=$leagueId');
    return _fetchEvents(uri);
  }

  Future<List<SportsDbEvent>> fetchPastLeagueEvents() async {
    final uri = Uri.parse('$baseUrl/eventspastleague.php?id=$leagueId');
    return _fetchEvents(uri);
  }

  Future<List<SportsDbEvent>> fetchDayEvents(DateTime date) async {
    final dateText = _dateOnly(date);
    final uri = Uri.parse('$baseUrl/eventsday.php?d=$dateText&s=Soccer');
    final events = await _fetchEvents(uri);

    return events
        .where((event) => event.idLeague == leagueId)
        .toList(growable: false);
  }

  Future<List<SportsDbEvent>> fetchDayScan({
    DateTime? start,
    DateTime? end,
  }) async {
    final startDate = start ?? DateTime(2026, 6, 11);
    final endDate = end ?? DateTime(2026, 7, 19);

    final allEvents = <SportsDbEvent>[];

    var current = DateTime(startDate.year, startDate.month, startDate.day);
    final last = DateTime(endDate.year, endDate.month, endDate.day);

    while (!current.isAfter(last)) {
      final events = await fetchDayEvents(current);
      allEvents.addAll(events);
      current = current.add(const Duration(days: 1));
    }

    return allEvents;
  }

  Future<List<SportsDbEvent>> fetchAllCoreEvents() async {
    final allEvents = <SportsDbEvent>[
      ...await fetchSeasonEvents(),
      ...await fetchNextLeagueEvents(),
      ...await fetchPastLeagueEvents(),
      ...await fetchDayScan(),
    ];

    final byId = <String, SportsDbEvent>{};

    for (final event in allEvents) {
      if (event.idEvent.isNotEmpty) {
        byId[event.idEvent] = event;
      }
    }

    return byId.values.toList(growable: false);
  }

  Future<List<SportsDbEvent>> _fetchEvents(Uri uri) async {
    final response = await http.get(uri);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Falha HTTP ${response.statusCode} em $uri');
    }

    final decoded = jsonDecode(response.body);
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
        .where((event) {
          return event.idLeague == leagueId;
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
    );
  }

  bool get temPlacar {
    return intHomeScore != null && intAwayScore != null;
  }

  String get statusCanonico {
    final status = strStatus?.toUpperCase().trim();

    if (status == 'FT' ||
        status == 'AET' ||
        status == 'PEN' ||
        status == 'FINISHED') {
      return 'encerrado';
    }

    if (status == 'LIVE' ||
        status == '1H' ||
        status == '2H' ||
        status == 'HT') {
      return 'em_andamento';
    }

    if (temPlacar) {
      return 'encerrado';
    }

    if (strTimestampUtc == null) {
      return 'agendado';
    }

    final nowUtc = DateTime.now().toUtc();

    if (nowUtc.isBefore(strTimestampUtc!)) {
      return 'agendado';
    }

    if (nowUtc.difference(strTimestampUtc!).inMinutes <= 130) {
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

    final normalized = text.endsWith('Z') || text.contains('+')
        ? text
        : '${text}Z';

    return DateTime.tryParse(normalized)?.toUtc();
  }

  static String? _nullableString(dynamic value) {
    if (value == null) {
      return null;
    }

    final text = value.toString().trim();

    if (text.isEmpty) {
      return null;
    }

    return text;
  }

  static int? _nullableInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.toInt();
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value.toString());
  }
}
