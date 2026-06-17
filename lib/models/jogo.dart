import '../core/json_utils.dart';

class Jogo {
  final String jogoId;
  final int ordem;
  final String fase;
  final String faseTipo;
  final String? grupo;
  final int? rodada;
  final DateTime? dataLocal;
  final DateTime? dataUtc;
  final String? horaLocal;
  final String statusJogo;
  final String mandantePrevisto;
  final String visitantePrevisto;
  final String? idEventAtual;
  final bool temHistoricoApi;
  final bool temResultadoApi;

  const Jogo({
    required this.jogoId,
    required this.ordem,
    required this.fase,
    required this.faseTipo,
    required this.grupo,
    required this.rodada,
    required this.dataLocal,
    required this.dataUtc,
    required this.horaLocal,
    required this.statusJogo,
    required this.mandantePrevisto,
    required this.visitantePrevisto,
    required this.idEventAtual,
    required this.temHistoricoApi,
    required this.temResultadoApi,
  });

  factory Jogo.fromJson(Map<String, dynamic> json) {
    return Jogo(
      jogoId: JsonUtils.stringValue(json, 'jogoId'),
      ordem: JsonUtils.intValue(json, 'ordem'),
      fase: JsonUtils.stringValue(json, 'fase'),
      faseTipo: JsonUtils.stringValue(json, 'faseTipo'),
      grupo: JsonUtils.nullableString(json, 'grupo'),
      rodada: JsonUtils.nullableInt(json, 'rodada'),
      dataLocal: JsonUtils.nullableDateTime(json, 'dataLocal'),
      dataUtc: JsonUtils.nullableDateTime(json, 'dataUtc'),
      horaLocal: JsonUtils.nullableString(json, 'horaLocal'),
      statusJogo: JsonUtils.stringValue(json, 'statusJogo'),
      mandantePrevisto: JsonUtils.stringValue(json, 'mandantePrevisto'),
      visitantePrevisto: JsonUtils.stringValue(json, 'visitantePrevisto'),
      idEventAtual: JsonUtils.nullableString(json, 'idEventAtual'),
      temHistoricoApi: JsonUtils.boolValue(json, 'temHistoricoApi'),
      temResultadoApi: JsonUtils.boolValue(json, 'temResultadoApi'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'jogoId': jogoId,
      'ordem': ordem,
      'fase': fase,
      'faseTipo': faseTipo,
      'grupo': grupo,
      'rodada': rodada,
      'dataLocal': dataLocal?.toIso8601String(),
      'dataUtc': dataUtc?.toUtc().toIso8601String(),
      'horaLocal': horaLocal,
      'statusJogo': statusJogo,
      'mandantePrevisto': mandantePrevisto,
      'visitantePrevisto': visitantePrevisto,
      'idEventAtual': idEventAtual,
      'temHistoricoApi': temHistoricoApi,
      'temResultadoApi': temResultadoApi,
    };
  }

  bool get isFaseDeGrupos => faseTipo == 'fase_de_grupos';

  bool get isMataMata => faseTipo == 'mata_mata';

  bool get isEncerrado => statusJogo == 'encerrado';

  bool get isEmAndamento => statusJogo == 'em_andamento';

  bool get isAgendado => statusJogo == 'agendado';

  String get confrontoPrevisto {
    return '$mandantePrevisto x $visitantePrevisto';
  }
}
