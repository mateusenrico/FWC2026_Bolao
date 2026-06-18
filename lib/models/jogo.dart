import '../core/functions/json_utils.dart';
import '../core/functions/place_formatters.dart';
import 'referencia_participante_jogo.dart';

class Jogo {
  final String jogoId;
  final int matchNumber;
  final int ordem;

  final String fase;
  final String faseCodigo;
  final String faseTipo;
  final String? grupo;
  final int? rodada;
  final int roundNumber;

  final String dataTorneio;
  final DateTime? dataUtc;
  final String dataLocal;
  final String horaLocal;

  final String estadio;
  final String cidadeSede;
  final String matchUrl;
  final String fonteFixture;

  final String mandantePrevisto;
  final String visitantePrevisto;
  final ReferenciaParticipanteJogo mandanteReferencia;
  final ReferenciaParticipanteJogo visitanteReferencia;

  final String? idEventAtual;
  final String statusJogo;

  final int? golsMandante;
  final int? golsVisitante;
  final String? vencedor;

  final bool temHistoricoApi;
  final bool temResultadoApi;
  final bool temResultado;
  final bool resultadoFinal;
  final String? fonteResultado;

  const Jogo({
    required this.jogoId,
    required this.matchNumber,
    required this.ordem,
    required this.fase,
    required this.faseCodigo,
    required this.faseTipo,
    required this.grupo,
    required this.rodada,
    required this.roundNumber,
    required this.dataTorneio,
    required this.dataUtc,
    required this.dataLocal,
    required this.horaLocal,
    required this.estadio,
    required this.cidadeSede,
    required this.matchUrl,
    required this.fonteFixture,
    required this.mandantePrevisto,
    required this.visitantePrevisto,
    required this.mandanteReferencia,
    required this.visitanteReferencia,
    required this.idEventAtual,
    required this.statusJogo,
    required this.golsMandante,
    required this.golsVisitante,
    required this.vencedor,
    required this.temHistoricoApi,
    required this.temResultadoApi,
    required this.temResultado,
    required this.resultadoFinal,
    required this.fonteResultado,
  });

  factory Jogo.fromJson(Map<String, dynamic> json) {
    return Jogo(
      jogoId: JsonUtils.stringValue(json, 'jogoId'),
      matchNumber: JsonUtils.intValue(json, 'matchNumber'),
      ordem: JsonUtils.intValue(json, 'ordem'),
      fase: JsonUtils.stringValue(json, 'fase'),
      faseCodigo: JsonUtils.stringValue(json, 'faseCodigo'),
      faseTipo: JsonUtils.stringValue(json, 'faseTipo'),
      grupo: JsonUtils.nullableString(json, 'grupo'),
      rodada: JsonUtils.nullableInt(json, 'rodada'),
      roundNumber: JsonUtils.intValue(json, 'roundNumber'),
      dataTorneio: JsonUtils.stringValue(json, 'dataTorneio'),
      dataUtc: JsonUtils.nullableDateTime(json, 'dataUtc'),
      dataLocal: JsonUtils.stringValue(json, 'dataLocal'),
      horaLocal: JsonUtils.stringValue(json, 'horaLocal'),
      estadio: JsonUtils.stringValue(json, 'estadio'),
      cidadeSede: JsonUtils.stringValue(json, 'cidadeSede'),
      matchUrl: JsonUtils.stringValue(json, 'matchUrl'),
      fonteFixture: JsonUtils.stringValue(json, 'fonteFixture'),
      mandantePrevisto: JsonUtils.stringValue(json, 'mandantePrevisto'),
      visitantePrevisto: JsonUtils.stringValue(json, 'visitantePrevisto'),
      mandanteReferencia: ReferenciaParticipanteJogo.fromJson(
        JsonUtils.mapValue(json, 'mandanteReferencia'),
      ),
      visitanteReferencia: ReferenciaParticipanteJogo.fromJson(
        JsonUtils.mapValue(json, 'visitanteReferencia'),
      ),
      idEventAtual: JsonUtils.nullableString(json, 'idEventAtual'),
      statusJogo: JsonUtils.stringValue(json, 'statusJogo'),
      golsMandante: JsonUtils.nullableInt(json, 'golsMandante'),
      golsVisitante: JsonUtils.nullableInt(json, 'golsVisitante'),
      vencedor: JsonUtils.nullableString(json, 'vencedor'),
      temHistoricoApi: JsonUtils.boolValue(json, 'temHistoricoApi'),
      temResultadoApi: JsonUtils.boolValue(json, 'temResultadoApi'),
      temResultado: JsonUtils.boolValue(json, 'temResultado'),
      resultadoFinal: JsonUtils.boolValue(json, 'resultadoFinal'),
      fonteResultado: JsonUtils.nullableString(json, 'fonteResultado'),
    );
  }

  Jogo copyWith({
    String? jogoId,
    int? matchNumber,
    int? ordem,
    String? fase,
    String? faseCodigo,
    String? faseTipo,
    String? grupo,
    int? rodada,
    int? roundNumber,
    String? dataTorneio,
    DateTime? dataUtc,
    String? dataLocal,
    String? horaLocal,
    String? estadio,
    String? cidadeSede,
    String? matchUrl,
    String? fonteFixture,
    String? mandantePrevisto,
    String? visitantePrevisto,
    ReferenciaParticipanteJogo? mandanteReferencia,
    ReferenciaParticipanteJogo? visitanteReferencia,
    String? idEventAtual,
    String? statusJogo,
    int? golsMandante,
    int? golsVisitante,
    String? vencedor,
    bool? temHistoricoApi,
    bool? temResultadoApi,
    bool? temResultado,
    bool? resultadoFinal,
    String? fonteResultado,
  }) {
    return Jogo(
      jogoId: jogoId ?? this.jogoId,
      matchNumber: matchNumber ?? this.matchNumber,
      ordem: ordem ?? this.ordem,
      fase: fase ?? this.fase,
      faseCodigo: faseCodigo ?? this.faseCodigo,
      faseTipo: faseTipo ?? this.faseTipo,
      grupo: grupo ?? this.grupo,
      rodada: rodada ?? this.rodada,
      roundNumber: roundNumber ?? this.roundNumber,
      dataTorneio: dataTorneio ?? this.dataTorneio,
      dataUtc: dataUtc ?? this.dataUtc,
      dataLocal: dataLocal ?? this.dataLocal,
      horaLocal: horaLocal ?? this.horaLocal,
      estadio: estadio ?? this.estadio,
      cidadeSede: cidadeSede ?? this.cidadeSede,
      matchUrl: matchUrl ?? this.matchUrl,
      fonteFixture: fonteFixture ?? this.fonteFixture,
      mandantePrevisto: mandantePrevisto ?? this.mandantePrevisto,
      visitantePrevisto: visitantePrevisto ?? this.visitantePrevisto,
      mandanteReferencia: mandanteReferencia ?? this.mandanteReferencia,
      visitanteReferencia: visitanteReferencia ?? this.visitanteReferencia,
      idEventAtual: idEventAtual ?? this.idEventAtual,
      statusJogo: statusJogo ?? this.statusJogo,
      golsMandante: golsMandante ?? this.golsMandante,
      golsVisitante: golsVisitante ?? this.golsVisitante,
      vencedor: vencedor ?? this.vencedor,
      temHistoricoApi: temHistoricoApi ?? this.temHistoricoApi,
      temResultadoApi: temResultadoApi ?? this.temResultadoApi,
      temResultado: temResultado ?? this.temResultado,
      resultadoFinal: resultadoFinal ?? this.resultadoFinal,
      fonteResultado: fonteResultado ?? this.fonteResultado,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'jogoId': jogoId,
      'matchNumber': matchNumber,
      'ordem': ordem,
      'fase': fase,
      'faseCodigo': faseCodigo,
      'faseTipo': faseTipo,
      'grupo': grupo,
      'rodada': rodada,
      'roundNumber': roundNumber,
      'dataTorneio': dataTorneio,
      'dataUtc': dataUtc?.toUtc().toIso8601String(),
      'dataLocal': dataLocal,
      'horaLocal': horaLocal,
      'estadio': estadio,
      'cidadeSede': cidadeSede,
      'matchUrl': matchUrl,
      'fonteFixture': fonteFixture,
      'mandantePrevisto': mandantePrevisto,
      'visitantePrevisto': visitantePrevisto,
      'mandanteReferencia': mandanteReferencia.toJson(),
      'visitanteReferencia': visitanteReferencia.toJson(),
      'idEventAtual': idEventAtual,
      'statusJogo': statusJogo,
      'golsMandante': golsMandante,
      'golsVisitante': golsVisitante,
      'vencedor': vencedor,
      'temHistoricoApi': temHistoricoApi,
      'temResultadoApi': temResultadoApi,
      'temResultado': temResultado,
      'resultadoFinal': resultadoFinal,
      'fonteResultado': fonteResultado,
    };
  }

  bool get isFaseDeGrupos => faseTipo == 'fase_de_grupos';

  bool get isMataMata => faseTipo == 'mata_mata';

  bool get isEncerrado => statusJogo == 'encerrado';

  bool get isEmAndamento => statusJogo == 'em_andamento';

  bool get isAgendado => statusJogo == 'agendado';

  bool get isAdiado => statusJogo == 'adiado';

  String get confrontoPrevisto {
    return '$mandantePrevisto x $visitantePrevisto';
  }

  String get placarTexto {
    if (!temResultado || golsMandante == null || golsVisitante == null) {
      return '-';
    }

    return '$golsMandante x $golsVisitante';
  }

  String get diaLocalTexto {
    if (dataLocal.length < 10) {
      return dataTorneio;
    }

    final year = dataLocal.substring(0, 4);
    final month = dataLocal.substring(5, 7);
    final day = dataLocal.substring(8, 10);

    return '$day/$month/$year';
  }

  String get localTexto {
    return PlaceFormatters.localPartida(estadio: estadio, cidade: cidadeSede);
  }

  String get statusTexto {
    switch (statusJogo) {
      case 'encerrado':
        return 'Encerrado';
      case 'em_andamento':
        return 'Em andamento';
      case 'adiado':
        return 'Adiado';
      case 'agendado':
        return 'Agendado';
      default:
        return statusJogo;
    }
  }
}
