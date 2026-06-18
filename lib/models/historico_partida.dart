import '../core/json_utils.dart';

class HistoricoPartida {
  final String historicoId;
  final String fonteDados;
  final int matchNumber;
  final String jogoId;
  final String? idEvent;

  final String? strEvent;
  final String? strHomeTeam;
  final String? strAwayTeam;

  final int? intHomeScore;
  final int? intAwayScore;

  final String? dateEvent;
  final String? dateEventLocal;
  final String? strTime;
  final String? strTimeLocal;
  final DateTime? strTimestamp;
  final String? strVenue;
  final String? strCity;
  final String? strCountry;
  final String? strStatus;

  final DateTime? eventTimeGMT;
  final String? fase;
  final String? faseCodigo;
  final String? faseTipo;
  final String? grupo;
  final int? rodada;
  final int? roundNumber;
  final String? statusJogoCanonico;
  final int? ordemBolao;

  final String? mandantePrevisto;
  final String? visitantePrevisto;

  final bool temResultado;
  final bool resultadoFinal;

  final Map<String, dynamic> raw;

  const HistoricoPartida({
    required this.historicoId,
    required this.fonteDados,
    required this.matchNumber,
    required this.jogoId,
    required this.idEvent,
    required this.strEvent,
    required this.strHomeTeam,
    required this.strAwayTeam,
    required this.intHomeScore,
    required this.intAwayScore,
    required this.dateEvent,
    required this.dateEventLocal,
    required this.strTime,
    required this.strTimeLocal,
    required this.strTimestamp,
    required this.strVenue,
    required this.strCity,
    required this.strCountry,
    required this.strStatus,
    required this.eventTimeGMT,
    required this.fase,
    required this.faseCodigo,
    required this.faseTipo,
    required this.grupo,
    required this.rodada,
    required this.roundNumber,
    required this.statusJogoCanonico,
    required this.ordemBolao,
    required this.mandantePrevisto,
    required this.visitantePrevisto,
    required this.temResultado,
    required this.resultadoFinal,
    required this.raw,
  });

  factory HistoricoPartida.fromJson(Map<String, dynamic> json) {
    return HistoricoPartida(
      historicoId: JsonUtils.stringValue(json, 'historicoId'),
      fonteDados: JsonUtils.stringValue(
        json,
        'fonteDados',
        fallback: 'sportsdb',
      ),
      matchNumber: JsonUtils.intValue(json, 'matchNumber'),
      jogoId: JsonUtils.stringValue(json, 'jogoId'),
      idEvent: JsonUtils.nullableString(json, 'idEvent'),
      strEvent: JsonUtils.nullableString(json, 'strEvent'),
      strHomeTeam: JsonUtils.nullableString(json, 'strHomeTeam'),
      strAwayTeam: JsonUtils.nullableString(json, 'strAwayTeam'),
      intHomeScore: JsonUtils.nullableInt(json, 'intHomeScore'),
      intAwayScore: JsonUtils.nullableInt(json, 'intAwayScore'),
      dateEvent: JsonUtils.nullableString(json, 'dateEvent'),
      dateEventLocal: JsonUtils.nullableString(json, 'dateEventLocal'),
      strTime: JsonUtils.nullableString(json, 'strTime'),
      strTimeLocal: JsonUtils.nullableString(json, 'strTimeLocal'),
      strTimestamp: JsonUtils.nullableDateTime(json, 'strTimestamp'),
      strVenue: JsonUtils.nullableString(json, 'strVenue'),
      strCity: JsonUtils.nullableString(json, 'strCity'),
      strCountry: JsonUtils.nullableString(json, 'strCountry'),
      strStatus: JsonUtils.nullableString(json, 'strStatus'),
      eventTimeGMT: JsonUtils.nullableDateTime(json, 'eventTimeGMT'),
      fase: JsonUtils.nullableString(json, 'fase'),
      faseCodigo: JsonUtils.nullableString(json, 'faseCodigo'),
      faseTipo: JsonUtils.nullableString(json, 'faseTipo'),
      grupo: JsonUtils.nullableString(json, 'grupo'),
      rodada: JsonUtils.nullableInt(json, 'rodada'),
      roundNumber: JsonUtils.nullableInt(json, 'roundNumber'),
      statusJogoCanonico: JsonUtils.nullableString(json, 'statusJogoCanonico'),
      ordemBolao: JsonUtils.nullableInt(json, 'ordemBolao'),
      mandantePrevisto: JsonUtils.nullableString(json, 'mandantePrevisto'),
      visitantePrevisto: JsonUtils.nullableString(json, 'visitantePrevisto'),
      temResultado: JsonUtils.boolValue(json, 'temResultado'),
      resultadoFinal: JsonUtils.boolValue(json, 'resultadoFinal'),
      raw: Map<String, dynamic>.from(json),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      ...raw,
      'historicoId': historicoId,
      'fonteDados': fonteDados,
      'matchNumber': matchNumber,
      'jogoId': jogoId,
      'idEvent': idEvent,
      'strEvent': strEvent,
      'strHomeTeam': strHomeTeam,
      'strAwayTeam': strAwayTeam,
      'intHomeScore': intHomeScore,
      'intAwayScore': intAwayScore,
      'dateEvent': dateEvent,
      'dateEventLocal': dateEventLocal,
      'strTime': strTime,
      'strTimeLocal': strTimeLocal,
      'strTimestamp': strTimestamp?.toIso8601String(),
      'strVenue': strVenue,
      'strCity': strCity,
      'strCountry': strCountry,
      'strStatus': strStatus,
      'eventTimeGMT': eventTimeGMT?.toUtc().toIso8601String(),
      'fase': fase,
      'faseCodigo': faseCodigo,
      'faseTipo': faseTipo,
      'grupo': grupo,
      'rodada': rodada,
      'roundNumber': roundNumber,
      'statusJogoCanonico': statusJogoCanonico,
      'ordemBolao': ordemBolao,
      'mandantePrevisto': mandantePrevisto,
      'visitantePrevisto': visitantePrevisto,
      'temResultado': temResultado,
      'resultadoFinal': resultadoFinal,
    };
  }

  String get confrontoApi {
    if (strHomeTeam != null && strAwayTeam != null) {
      return '$strHomeTeam x $strAwayTeam';
    }

    return strEvent ?? '';
  }

  String get placarTexto {
    if (!temResultado || intHomeScore == null || intAwayScore == null) {
      return '-';
    }

    return '$intHomeScore x $intAwayScore';
  }
}
