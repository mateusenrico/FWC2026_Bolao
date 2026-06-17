import '../core/json_utils.dart';

class HistoricoPartida {
  final String jogoId;
  final String idEvent;

  final String? strEvent;
  final String? strHomeTeam;
  final String? strAwayTeam;

  final int? intHomeScore;
  final int? intAwayScore;

  final String? dateEvent;
  final String? strTime;
  final DateTime? strTimestamp;
  final String? strStatus;

  final DateTime? eventTimeGMT;
  final int? eventTimeMs;
  final String? temporalStatus;

  final String? faseTipo;
  final String? grupo;
  final String? statusJogoCanonico;
  final int? ordemBolao;

  final String? mandantePrevisto;
  final String? visitantePrevisto;

  final Map<String, dynamic> raw;

  const HistoricoPartida({
    required this.jogoId,
    required this.idEvent,
    required this.strEvent,
    required this.strHomeTeam,
    required this.strAwayTeam,
    required this.intHomeScore,
    required this.intAwayScore,
    required this.dateEvent,
    required this.strTime,
    required this.strTimestamp,
    required this.strStatus,
    required this.eventTimeGMT,
    required this.eventTimeMs,
    required this.temporalStatus,
    required this.faseTipo,
    required this.grupo,
    required this.statusJogoCanonico,
    required this.ordemBolao,
    required this.mandantePrevisto,
    required this.visitantePrevisto,
    required this.raw,
  });

  factory HistoricoPartida.fromJson(Map<String, dynamic> json) {
    return HistoricoPartida(
      jogoId: JsonUtils.stringValue(json, 'jogoId'),
      idEvent: JsonUtils.stringValue(json, 'idEvent'),
      strEvent: JsonUtils.nullableString(json, 'strEvent'),
      strHomeTeam: JsonUtils.nullableString(json, 'strHomeTeam'),
      strAwayTeam: JsonUtils.nullableString(json, 'strAwayTeam'),
      intHomeScore: JsonUtils.nullableInt(json, 'intHomeScore'),
      intAwayScore: JsonUtils.nullableInt(json, 'intAwayScore'),
      dateEvent: JsonUtils.nullableString(json, 'dateEvent'),
      strTime: JsonUtils.nullableString(json, 'strTime'),
      strTimestamp: JsonUtils.nullableDateTime(json, 'strTimestamp'),
      strStatus: JsonUtils.nullableString(json, 'strStatus'),
      eventTimeGMT: JsonUtils.nullableDateTime(json, 'eventTimeGMT'),
      eventTimeMs: JsonUtils.nullableInt(json, 'eventTimeMs'),
      temporalStatus: JsonUtils.nullableString(json, 'temporalStatus'),
      faseTipo: JsonUtils.nullableString(json, 'faseTipo'),
      grupo: JsonUtils.nullableString(json, 'grupo'),
      statusJogoCanonico: JsonUtils.nullableString(json, 'statusJogoCanonico'),
      ordemBolao: JsonUtils.nullableInt(json, 'ordemBolao'),
      mandantePrevisto: JsonUtils.nullableString(json, 'mandantePrevisto'),
      visitantePrevisto: JsonUtils.nullableString(json, 'visitantePrevisto'),
      raw: Map<String, dynamic>.from(json),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      ...raw,
      'jogoId': jogoId,
      'idEvent': idEvent,
      'strEvent': strEvent,
      'strHomeTeam': strHomeTeam,
      'strAwayTeam': strAwayTeam,
      'intHomeScore': intHomeScore,
      'intAwayScore': intAwayScore,
      'dateEvent': dateEvent,
      'strTime': strTime,
      'strTimestamp': strTimestamp?.toIso8601String(),
      'strStatus': strStatus,
      'eventTimeGMT': eventTimeGMT?.toUtc().toIso8601String(),
      'eventTimeMs': eventTimeMs,
      'temporalStatus': temporalStatus,
      'faseTipo': faseTipo,
      'grupo': grupo,
      'statusJogoCanonico': statusJogoCanonico,
      'ordemBolao': ordemBolao,
      'mandantePrevisto': mandantePrevisto,
      'visitantePrevisto': visitantePrevisto,
    };
  }

  bool get temPlacar {
    return intHomeScore != null && intAwayScore != null;
  }

  bool get isEncerrado {
    return statusJogoCanonico == 'encerrado' || strStatus == 'FT';
  }

  String get confrontoApi {
    if (strHomeTeam != null && strAwayTeam != null) {
      return '$strHomeTeam x $strAwayTeam';
    }

    return strEvent ?? '';
  }

  String get confrontoPrevisto {
    if (mandantePrevisto != null && visitantePrevisto != null) {
      return '$mandantePrevisto x $visitantePrevisto';
    }

    return confrontoApi;
  }
}
