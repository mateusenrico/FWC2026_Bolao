import '../models/jogo.dart';
import '../models/palpite.dart';

enum ResultadoPartida { mandante, visitante, empate, indefinido }

class PontuacaoPalpite {
  final String palpiteId;
  final String participanteId;
  final String jogoId;
  final int matchNumber;

  final bool pontuavel;
  final int pontos;

  final int? golsMandanteReal;
  final int? golsVisitanteReal;
  final int? golsMandantePalpite;
  final int? golsVisitantePalpite;

  final ResultadoPartida resultadoReal;
  final ResultadoPartida resultadoPalpite;

  final bool placarExato;
  final bool resultadoCorreto;
  final bool acertouGolMandante;
  final bool acertouGolVisitante;
  final bool acertouUmDosGols;

  final String motivo;

  const PontuacaoPalpite({
    required this.palpiteId,
    required this.participanteId,
    required this.jogoId,
    required this.matchNumber,
    required this.pontuavel,
    required this.pontos,
    required this.golsMandanteReal,
    required this.golsVisitanteReal,
    required this.golsMandantePalpite,
    required this.golsVisitantePalpite,
    required this.resultadoReal,
    required this.resultadoPalpite,
    required this.placarExato,
    required this.resultadoCorreto,
    required this.acertouGolMandante,
    required this.acertouGolVisitante,
    required this.acertouUmDosGols,
    required this.motivo,
  });

  bool get zerou => pontuavel && pontos == 0;

  Map<String, dynamic> toJson() {
    return {
      'palpiteId': palpiteId,
      'participanteId': participanteId,
      'jogoId': jogoId,
      'matchNumber': matchNumber,
      'pontuavel': pontuavel,
      'pontos': pontos,
      'golsMandanteReal': golsMandanteReal,
      'golsVisitanteReal': golsVisitanteReal,
      'golsMandantePalpite': golsMandantePalpite,
      'golsVisitantePalpite': golsVisitantePalpite,
      'resultadoReal': resultadoReal.name,
      'resultadoPalpite': resultadoPalpite.name,
      'placarExato': placarExato,
      'resultadoCorreto': resultadoCorreto,
      'acertouGolMandante': acertouGolMandante,
      'acertouGolVisitante': acertouGolVisitante,
      'acertouUmDosGols': acertouUmDosGols,
      'motivo': motivo,
    };
  }
}

class SistemaPalpites {
  const SistemaPalpites._();

  static ResultadoPartida resultadoDePlacar({
    required int? golsMandante,
    required int? golsVisitante,
  }) {
    if (golsMandante == null || golsVisitante == null) {
      return ResultadoPartida.indefinido;
    }

    if (golsMandante > golsVisitante) {
      return ResultadoPartida.mandante;
    }

    if (golsVisitante > golsMandante) {
      return ResultadoPartida.visitante;
    }

    return ResultadoPartida.empate;
  }

  static PontuacaoPalpite calcularPontuacaoPalpite({
    required Jogo jogo,
    required Palpite palpite,
  }) {
    if (!palpite.isCompleto) {
      return _naoPontuavel(
        jogo: jogo,
        palpite: palpite,
        motivo: 'Palpite incompleto ou vazio.',
      );
    }

    if (!jogo.temResultado ||
        jogo.golsMandante == null ||
        jogo.golsVisitante == null) {
      return _naoPontuavel(
        jogo: jogo,
        palpite: palpite,
        motivo: 'Jogo ainda sem resultado.',
      );
    }

    final resultadoReal = resultadoDePlacar(
      golsMandante: jogo.golsMandante,
      golsVisitante: jogo.golsVisitante,
    );

    final resultadoPalpite = resultadoDePlacar(
      golsMandante: palpite.golsMandante,
      golsVisitante: palpite.golsVisitante,
    );

    final acertouGolMandante = palpite.golsMandante == jogo.golsMandante;
    final acertouGolVisitante = palpite.golsVisitante == jogo.golsVisitante;
    final acertouUmDosGols = acertouGolMandante || acertouGolVisitante;
    final placarExato = acertouGolMandante && acertouGolVisitante;
    final resultadoCorreto = resultadoReal == resultadoPalpite;

    late final int pontos;
    late final String motivo;

    if (placarExato) {
      pontos = 5;
      motivo = 'Placar exato.';
    } else if (resultadoCorreto && acertouUmDosGols) {
      pontos = 3;
      motivo = 'Resultado correto e um dos placares correto.';
    } else if (resultadoCorreto) {
      pontos = 2;
      motivo = 'Resultado correto.';
    } else if (acertouUmDosGols) {
      pontos = 1;
      motivo = 'Um dos placares correto.';
    } else {
      pontos = 0;
      motivo = 'Não pontuou.';
    }

    return PontuacaoPalpite(
      palpiteId: palpite.palpiteId,
      participanteId: palpite.participanteId,
      jogoId: palpite.jogoId,
      matchNumber: jogo.matchNumber,
      pontuavel: true,
      pontos: pontos,
      golsMandanteReal: jogo.golsMandante,
      golsVisitanteReal: jogo.golsVisitante,
      golsMandantePalpite: palpite.golsMandante,
      golsVisitantePalpite: palpite.golsVisitante,
      resultadoReal: resultadoReal,
      resultadoPalpite: resultadoPalpite,
      placarExato: placarExato,
      resultadoCorreto: resultadoCorreto,
      acertouGolMandante: acertouGolMandante,
      acertouGolVisitante: acertouGolVisitante,
      acertouUmDosGols: acertouUmDosGols,
      motivo: motivo,
    );
  }

  static List<PontuacaoPalpite> calcularPontuacoes({
    required List<Jogo> jogos,
    required List<Palpite> palpites,
  }) {
    final jogosPorId = {for (final jogo in jogos) jogo.jogoId: jogo};
    final result = <PontuacaoPalpite>[];

    for (final palpite in palpites) {
      final jogo = jogosPorId[palpite.jogoId];

      if (jogo == null) {
        result.add(
          PontuacaoPalpite(
            palpiteId: palpite.palpiteId,
            participanteId: palpite.participanteId,
            jogoId: palpite.jogoId,
            matchNumber: 0,
            pontuavel: false,
            pontos: 0,
            golsMandanteReal: null,
            golsVisitanteReal: null,
            golsMandantePalpite: palpite.golsMandante,
            golsVisitantePalpite: palpite.golsVisitante,
            resultadoReal: ResultadoPartida.indefinido,
            resultadoPalpite: resultadoDePlacar(
              golsMandante: palpite.golsMandante,
              golsVisitante: palpite.golsVisitante,
            ),
            placarExato: false,
            resultadoCorreto: false,
            acertouGolMandante: false,
            acertouGolVisitante: false,
            acertouUmDosGols: false,
            motivo: 'Jogo não encontrado para o palpite.',
          ),
        );
        continue;
      }

      result.add(calcularPontuacaoPalpite(jogo: jogo, palpite: palpite));
    }

    return result;
  }

  static ResultadoPartida resultadoPalpite(Palpite? palpite) {
    if (palpite == null || !palpite.isCompleto) {
      return ResultadoPartida.indefinido;
    }

    return resultadoDePlacar(
      golsMandante: palpite.golsMandante,
      golsVisitante: palpite.golsVisitante,
    );
  }

  static PontuacaoPalpite _naoPontuavel({
    required Jogo jogo,
    required Palpite palpite,
    required String motivo,
  }) {
    return PontuacaoPalpite(
      palpiteId: palpite.palpiteId,
      participanteId: palpite.participanteId,
      jogoId: palpite.jogoId,
      matchNumber: jogo.matchNumber,
      pontuavel: false,
      pontos: 0,
      golsMandanteReal: jogo.golsMandante,
      golsVisitanteReal: jogo.golsVisitante,
      golsMandantePalpite: palpite.golsMandante,
      golsVisitantePalpite: palpite.golsVisitante,
      resultadoReal: resultadoDePlacar(
        golsMandante: jogo.golsMandante,
        golsVisitante: jogo.golsVisitante,
      ),
      resultadoPalpite: resultadoPalpite(palpite),
      placarExato: false,
      resultadoCorreto: false,
      acertouGolMandante: false,
      acertouGolVisitante: false,
      acertouUmDosGols: false,
      motivo: motivo,
    );
  }
}
