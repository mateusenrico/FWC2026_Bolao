import '../core/functions/json_utils.dart';

class TimeParticipante {
  final String timeId;
  final String nome;
  final String nomeNormalizado;
  final String grupo;

  final List<String> jogosIds;

  final int? rankingGrupo;
  final bool rankingGrupoProvisorio;

  final EstatisticasGrupo estatisticasGrupo;

  const TimeParticipante({
    required this.timeId,
    required this.nome,
    required this.nomeNormalizado,
    required this.grupo,
    required this.jogosIds,
    required this.rankingGrupo,
    required this.rankingGrupoProvisorio,
    required this.estatisticasGrupo,
  });

  factory TimeParticipante.fromJson(Map<String, dynamic> json) {
    return TimeParticipante(
      timeId: JsonUtils.stringValue(json, 'timeId'),
      nome: JsonUtils.stringValue(json, 'nome'),
      nomeNormalizado: JsonUtils.stringValue(json, 'nomeNormalizado'),
      grupo: JsonUtils.stringValue(json, 'grupo'),
      jogosIds: JsonUtils.stringList(json, 'jogosIds'),
      rankingGrupo: JsonUtils.nullableInt(json, 'rankingGrupo'),
      rankingGrupoProvisorio: JsonUtils.boolValue(
        json,
        'rankingGrupoProvisorio',
      ),
      estatisticasGrupo: EstatisticasGrupo.fromJson(
        JsonUtils.mapValue(json, 'estatisticasGrupo'),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timeId': timeId,
      'nome': nome,
      'nomeNormalizado': nomeNormalizado,
      'grupo': grupo,
      'jogosIds': jogosIds,
      'rankingGrupo': rankingGrupo,
      'rankingGrupoProvisorio': rankingGrupoProvisorio,
      'estatisticasGrupo': estatisticasGrupo.toJson(),
    };
  }
}

class EstatisticasGrupo {
  final int pontos;
  final int jogos;
  final int vitorias;
  final int empates;
  final int derrotas;

  final int golsPro;
  final int golsContra;
  final int saldoGols;

  final int? fairPlayPontos;
  final int? cartoesAmarelos;
  final int? cartoesVermelhos;
  final int? cartoesVermelhosIndiretos;
  final int? cartoesAmareloVermelho;

  final String? observacaoDesempate;

  const EstatisticasGrupo({
    required this.pontos,
    required this.jogos,
    required this.vitorias,
    required this.empates,
    required this.derrotas,
    required this.golsPro,
    required this.golsContra,
    required this.saldoGols,
    required this.fairPlayPontos,
    required this.cartoesAmarelos,
    required this.cartoesVermelhos,
    required this.cartoesVermelhosIndiretos,
    required this.cartoesAmareloVermelho,
    required this.observacaoDesempate,
  });

  factory EstatisticasGrupo.fromJson(Map<String, dynamic> json) {
    return EstatisticasGrupo(
      pontos: JsonUtils.intValue(json, 'pontos'),
      jogos: JsonUtils.intValue(json, 'jogos'),
      vitorias: JsonUtils.intValue(json, 'vitorias'),
      empates: JsonUtils.intValue(json, 'empates'),
      derrotas: JsonUtils.intValue(json, 'derrotas'),
      golsPro: JsonUtils.intValue(json, 'golsPro'),
      golsContra: JsonUtils.intValue(json, 'golsContra'),
      saldoGols: JsonUtils.intValue(json, 'saldoGols'),
      fairPlayPontos: JsonUtils.nullableInt(json, 'fairPlayPontos'),
      cartoesAmarelos: JsonUtils.nullableInt(json, 'cartoesAmarelos'),
      cartoesVermelhos: JsonUtils.nullableInt(json, 'cartoesVermelhos'),
      cartoesVermelhosIndiretos: JsonUtils.nullableInt(
        json,
        'cartoesVermelhosIndiretos',
      ),
      cartoesAmareloVermelho: JsonUtils.nullableInt(
        json,
        'cartoesAmareloVermelho',
      ),
      observacaoDesempate: JsonUtils.nullableString(
        json,
        'observacaoDesempate',
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pontos': pontos,
      'jogos': jogos,
      'vitorias': vitorias,
      'empates': empates,
      'derrotas': derrotas,
      'golsPro': golsPro,
      'golsContra': golsContra,
      'saldoGols': saldoGols,
      'fairPlayPontos': fairPlayPontos,
      'cartoesAmarelos': cartoesAmarelos,
      'cartoesVermelhos': cartoesVermelhos,
      'cartoesVermelhosIndiretos': cartoesVermelhosIndiretos,
      'cartoesAmareloVermelho': cartoesAmareloVermelho,
      'observacaoDesempate': observacaoDesempate,
    };
  }
}
