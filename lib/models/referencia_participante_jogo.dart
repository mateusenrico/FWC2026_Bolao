import '../core/json_utils.dart';

class ReferenciaParticipanteJogo {
  final String tipo;
  final String descricao;
  final String? timeId;
  final String? timeKey;
  final String? nomeFonte;
  final String? grupo;
  final int? posicao;
  final List<String> gruposElegiveis;
  final int? matchNumberReferencia;
  final String? jogoIdReferencia;

  const ReferenciaParticipanteJogo({
    required this.tipo,
    required this.descricao,
    required this.timeId,
    required this.timeKey,
    required this.nomeFonte,
    required this.grupo,
    required this.posicao,
    required this.gruposElegiveis,
    required this.matchNumberReferencia,
    required this.jogoIdReferencia,
  });

  factory ReferenciaParticipanteJogo.fromJson(
    Map<String, dynamic> json,
  ) {
    return ReferenciaParticipanteJogo(
      tipo: JsonUtils.stringValue(json, 'tipo'),
      descricao: JsonUtils.stringValue(json, 'descricao'),
      timeId: JsonUtils.nullableString(json, 'timeId'),
      timeKey: JsonUtils.nullableString(json, 'timeKey'),
      nomeFonte: JsonUtils.nullableString(json, 'nomeFonte'),
      grupo: JsonUtils.nullableString(json, 'grupo'),
      posicao: JsonUtils.nullableInt(json, 'posicao'),
      gruposElegiveis: JsonUtils.stringList(json, 'gruposElegiveis'),
      matchNumberReferencia:
          JsonUtils.nullableInt(json, 'matchNumberReferencia'),
      jogoIdReferencia:
          JsonUtils.nullableString(json, 'jogoIdReferencia'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tipo': tipo,
      'descricao': descricao,
      'timeId': timeId,
      'timeKey': timeKey,
      'nomeFonte': nomeFonte,
      'grupo': grupo,
      'posicao': posicao,
      'gruposElegiveis': gruposElegiveis,
      'matchNumberReferencia': matchNumberReferencia,
      'jogoIdReferencia': jogoIdReferencia,
    };
  }

  bool get isTime => tipo == 'time';

  bool get isPosicaoGrupo => tipo == 'posicao_grupo';

  bool get isMelhorTerceiro => tipo == 'melhor_terceiro';

  bool get isVencedorJogo => tipo == 'vencedor_jogo';

  bool get isPerdedorJogo => tipo == 'perdedor_jogo';
}
