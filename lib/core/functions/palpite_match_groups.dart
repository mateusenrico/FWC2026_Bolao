import '../sistema_palpites.dart';
import '../sistema_pontuacao_participantes.dart';
import '../../models/jogo.dart';
import '../../models/palpite.dart';

class PalpiteJogoAgrupado {
  final LinhaPontuacaoParticipante linha;
  final Palpite? palpite;
  final PontuacaoPalpite? pontuacao;

  const PalpiteJogoAgrupado({
    required this.linha,
    required this.palpite,
    required this.pontuacao,
  });

  ResultadoPartida get resultadoPalpite {
    return SistemaPalpites.resultadoPalpite(palpite);
  }

  int get pontosNoJogo {
    return pontuacao?.pontuavel == true ? pontuacao!.pontos : 0;
  }

  bool get pontuando => pontosNoJogo > 0;

  bool get placarExato => pontuacao?.placarExato == true;
}

class GrupoPalpitesJogo {
  final ResultadoPartida resultado;
  final List<PalpiteJogoAgrupado> palpites;
  final bool resultadoAtual;

  const GrupoPalpitesJogo({
    required this.resultado,
    required this.palpites,
    required this.resultadoAtual,
  });

  int get totalPontos {
    return palpites.fold<int>(0, (total, item) => total + item.pontosNoJogo);
  }

  int get placaresExatos {
    return palpites.where((item) => item.placarExato).length;
  }

  int get pontuandoAgora {
    return palpites.where((item) => item.pontuando).length;
  }
}

class PalpiteMatchGroups {
  const PalpiteMatchGroups._();

  static List<GrupoPalpitesJogo> build({
    required Jogo jogo,
    required List<LinhaPontuacaoParticipante> ranking,
    required Palpite? Function(String participanteId) palpiteFor,
    required PontuacaoPalpite? Function(String participanteId) pontuacaoFor,
  }) {
    final resultadoAtual = jogo.temResultado
        ? SistemaPalpites.resultadoDePlacar(
            golsMandante: jogo.golsMandante,
            golsVisitante: jogo.golsVisitante,
          )
        : ResultadoPartida.indefinido;

    final grouped = <ResultadoPartida, List<PalpiteJogoAgrupado>>{
      ResultadoPartida.mandante: [],
      ResultadoPartida.empate: [],
      ResultadoPartida.visitante: [],
      ResultadoPartida.indefinido: [],
    };

    for (final linha in ranking) {
      final palpite = palpiteFor(linha.participanteId);
      final item = PalpiteJogoAgrupado(
        linha: linha,
        palpite: palpite,
        pontuacao: pontuacaoFor(linha.participanteId),
      );
      grouped[item.resultadoPalpite]!.add(item);
    }

    for (final items in grouped.values) {
      items.sort((a, b) {
        final byPoints = b.pontosNoJogo.compareTo(a.pontosNoJogo);
        if (byPoints != 0) {
          return byPoints;
        }

        final byExact = _boolCompare(a.placarExato, b.placarExato);
        if (byExact != 0) {
          return byExact;
        }

        return a.linha.nome.compareTo(b.linha.nome);
      });
    }

    return [
      for (final resultado in const [
        ResultadoPartida.mandante,
        ResultadoPartida.empate,
        ResultadoPartida.visitante,
        ResultadoPartida.indefinido,
      ])
        if (resultado != ResultadoPartida.indefinido ||
            grouped[resultado]!.isNotEmpty)
          GrupoPalpitesJogo(
            resultado: resultado,
            palpites: List.unmodifiable(grouped[resultado]!),
            resultadoAtual: resultado == resultadoAtual,
          ),
    ];
  }

  static int _boolCompare(bool a, bool b) {
    if (a == b) {
      return 0;
    }

    return a ? -1 : 1;
  }
}
