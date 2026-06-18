import '../core/functions/json_utils.dart';

class Participante {
  final String participanteId;
  final String nome;
  final String? corHex;

  final int jogosPalpitados;
  final int jogosSemPalpite;

  final int jogosPalpitadosFaseGrupos;
  final int jogosSemPalpiteFaseGrupos;

  final int totalJogosPrevistos;
  final int totalJogosFaseGrupos;

  const Participante({
    required this.participanteId,
    required this.nome,
    required this.corHex,
    required this.jogosPalpitados,
    required this.jogosSemPalpite,
    required this.jogosPalpitadosFaseGrupos,
    required this.jogosSemPalpiteFaseGrupos,
    required this.totalJogosPrevistos,
    required this.totalJogosFaseGrupos,
  });

  factory Participante.fromJson(Map<String, dynamic> json) {
    return Participante(
      participanteId: JsonUtils.stringValue(json, 'participanteId'),
      nome: JsonUtils.stringValue(json, 'nome'),
      corHex: JsonUtils.nullableString(json, 'corHex'),
      jogosPalpitados: JsonUtils.intValue(json, 'jogosPalpitados'),
      jogosSemPalpite: JsonUtils.intValue(json, 'jogosSemPalpite'),
      jogosPalpitadosFaseGrupos: JsonUtils.intValue(
        json,
        'jogosPalpitadosFaseGrupos',
      ),
      jogosSemPalpiteFaseGrupos: JsonUtils.intValue(
        json,
        'jogosSemPalpiteFaseGrupos',
      ),
      totalJogosPrevistos: JsonUtils.intValue(json, 'totalJogosPrevistos'),
      totalJogosFaseGrupos: JsonUtils.intValue(json, 'totalJogosFaseGrupos'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'participanteId': participanteId,
      'nome': nome,
      'corHex': corHex,
      'jogosPalpitados': jogosPalpitados,
      'jogosSemPalpite': jogosSemPalpite,
      'jogosPalpitadosFaseGrupos': jogosPalpitadosFaseGrupos,
      'jogosSemPalpiteFaseGrupos': jogosSemPalpiteFaseGrupos,
      'totalJogosPrevistos': totalJogosPrevistos,
      'totalJogosFaseGrupos': totalJogosFaseGrupos,
    };
  }
}
