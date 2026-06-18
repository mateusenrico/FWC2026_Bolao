import 'package:flutter_test/flutter_test.dart';
import 'package:fwc2026_bolao/core/functions/palpite_match_groups.dart';
import 'package:fwc2026_bolao/core/sistema_palpites.dart';
import 'package:fwc2026_bolao/core/sistema_pontuacao_participantes.dart';
import 'package:fwc2026_bolao/core/sistema_pontuacao_times.dart';
import 'package:fwc2026_bolao/models/jogo.dart';
import 'package:fwc2026_bolao/models/palpite.dart';
import 'package:fwc2026_bolao/models/referencia_participante_jogo.dart';

void main() {
  test('PalpiteMatchGroups agrupa palpites por resultado e destaca atual', () {
    final jogo = _jogo(golsMandante: 2, golsVisitante: 1);
    final palpites = {
      'a': _palpite('a', 2, 1),
      'b': _palpite('b', 1, 1),
      'c': _palpite('c', 0, 2),
    };
    final pontuacoes = {
      for (final entry in palpites.entries)
        entry.key: SistemaPalpites.calcularPontuacaoPalpite(
          jogo: jogo,
          palpite: entry.value,
        ),
    };

    final groups = PalpiteMatchGroups.build(
      jogo: jogo,
      ranking: [
        _linha('a', 'Ana', 1),
        _linha('b', 'Bia', 2),
        _linha('c', 'Caio', 3),
      ],
      palpiteFor: (id) => palpites[id],
      pontuacaoFor: (id) => pontuacoes[id],
    );

    final mandante = groups.firstWhere(
      (group) => group.resultado == ResultadoPartida.mandante,
    );
    final empate = groups.firstWhere(
      (group) => group.resultado == ResultadoPartida.empate,
    );
    final visitante = groups.firstWhere(
      (group) => group.resultado == ResultadoPartida.visitante,
    );

    expect(mandante.resultadoAtual, isTrue);
    expect(mandante.palpites.single.linha.nome, 'Ana');
    expect(mandante.totalPontos, 5);
    expect(mandante.placaresExatos, 1);
    expect(empate.palpites.single.linha.nome, 'Bia');
    expect(visitante.palpites.single.linha.nome, 'Caio');
  });
}

Jogo _jogo({required int golsMandante, required int golsVisitante}) {
  const reference = ReferenciaParticipanteJogo(
    tipo: 'time',
    descricao: 'Time',
    timeId: 'time',
    timeKey: 'time',
    nomeFonte: 'Time',
    grupo: 'A',
    posicao: null,
    gruposElegiveis: [],
    matchNumberReferencia: null,
    jogoIdReferencia: null,
  );

  return Jogo(
    jogoId: 'jogo-1',
    matchNumber: 1,
    ordem: 1,
    fase: 'Grupo A',
    faseCodigo: 'group-stage',
    faseTipo: 'fase_de_grupos',
    grupo: 'A',
    rodada: 1,
    roundNumber: 1,
    dataTorneio: '2026-06-11',
    dataUtc: DateTime.utc(2026, 6, 11, 19),
    dataLocal: '2026-06-11T16:00:00-03:00',
    horaLocal: '16:00',
    estadio: 'Estadio',
    cidadeSede: 'Cidade',
    matchUrl: '',
    fonteFixture: 'teste',
    mandantePrevisto: 'BRASIL',
    visitantePrevisto: 'ARGENTINA',
    mandanteReferencia: reference,
    visitanteReferencia: reference,
    idEventAtual: null,
    statusJogo: 'encerrado',
    golsMandante: golsMandante,
    golsVisitante: golsVisitante,
    vencedor: 'BRASIL',
    temHistoricoApi: true,
    temResultadoApi: true,
    temResultado: true,
    resultadoFinal: true,
    fonteResultado: 'teste',
  );
}

Palpite _palpite(String participanteId, int mandante, int visitante) {
  return Palpite(
    palpiteId: 'palpite-$participanteId',
    participanteId: participanteId,
    jogoId: 'jogo-1',
    golsMandante: mandante,
    golsVisitante: visitante,
  );
}

LinhaPontuacaoParticipante _linha(
  String participanteId,
  String nome,
  int posicao,
) {
  return LinhaPontuacaoParticipante(
    posicao: posicao,
    participanteId: participanteId,
    nome: nome,
    pontosTotal: 0,
    pontosJogos: 0,
    pontosGrupos: 0,
    pontosFinal: 0,
    palpitesPontuaveis: 0,
    placaresExatos: 0,
    resultadosCorretos: 0,
    palpitesComTresPontos: 0,
    palpitesComDoisPontos: 0,
    palpitesComUmPonto: 0,
    pontuacoesPalpites: const [],
    pontuacoesGrupos: const [],
    pontuacaoFinal: PontuacaoFinalParticipante(
      participanteId: participanteId,
      campeaoRealKey: null,
      campeaoRealNome: null,
      viceRealKey: null,
      viceRealNome: null,
      terceiroRealKey: null,
      terceiroRealNome: null,
      quartoRealKey: null,
      quartoRealNome: null,
      campeaoPrevistoKey: null,
      campeaoPrevistoNome: null,
      vicePrevistoKey: null,
      vicePrevistoNome: null,
      terceiroPrevistoKey: null,
      terceiroPrevistoNome: null,
      quartoPrevistoKey: null,
      quartoPrevistoNome: null,
      pontosCampeao: 0,
      pontosVice: 0,
      pontosTerceiro: 0,
      pontosQuarto: 0,
      avisos: const [],
    ),
    chaveamentoPrevisto: const ChaveamentoProjetado(
      jogosPorMatchNumber: {},
      resultadoFinal: ResultadoFinalTorneio(
        campeao: null,
        vice: null,
        terceiro: null,
        quarto: null,
      ),
      avisos: [],
    ),
  );
}
