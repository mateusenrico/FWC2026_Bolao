import 'package:flutter_test/flutter_test.dart';
import 'package:fwc2026_bolao/core/sistema_pontuacao_participantes.dart';
import 'package:fwc2026_bolao/models/bolao_data.dart';
import 'package:fwc2026_bolao/models/jogo.dart';
import 'package:fwc2026_bolao/models/palpite.dart';
import 'package:fwc2026_bolao/models/participante.dart';
import 'package:fwc2026_bolao/models/referencia_participante_jogo.dart';

void main() {
  test('classificacao usa jogos pontuaveis e ignora futuro sem resultado', () {
    final data = BolaoData(
      jogos: [
        _jogo(
          jogoId: 'jogo-1',
          matchNumber: 1,
          golsMandante: 1,
          golsVisitante: 0,
          temResultado: true,
          resultadoFinal: true,
          statusJogo: 'encerrado',
        ),
        _jogo(
          jogoId: 'jogo-2',
          matchNumber: 2,
          golsMandante: 0,
          golsVisitante: 0,
          temResultado: false,
          resultadoFinal: false,
          statusJogo: 'agendado',
        ),
      ],
      historicoPartidas: const [],
      participantes: [_participante('a', 'Ana'), _participante('b', 'Bia')],
      palpites: [
        _palpite('a', 'jogo-1', 1, 0),
        _palpite('b', 'jogo-1', 2, 1),
        _palpite('a', 'jogo-2', 0, 0),
        _palpite('b', 'jogo-2', 4, 3),
      ],
      timesParticipantes: const [],
    );

    final ranking = SistemaPontuacaoParticipantes.calcularClassificacao(data);

    expect(ranking.map((linha) => linha.participanteId), ['a', 'b']);
    expect(ranking.first.pontosJogos, 5);
    expect(ranking.last.pontosJogos, 2);
    expect(ranking.first.pontuacoesPalpites.last.pontuavel, isFalse);
    expect(ranking.last.pontuacoesPalpites.last.pontuavel, isFalse);
  });

  test('classificacao desempata por numero de placares exatos', () {
    final data = BolaoData(
      jogos: [
        _jogo(
          jogoId: 'jogo-1',
          matchNumber: 1,
          golsMandante: 1,
          golsVisitante: 0,
          temResultado: true,
          resultadoFinal: true,
          statusJogo: 'encerrado',
        ),
        _jogo(
          jogoId: 'jogo-2',
          matchNumber: 2,
          golsMandante: 2,
          golsVisitante: 1,
          temResultado: true,
          resultadoFinal: true,
          statusJogo: 'encerrado',
        ),
      ],
      historicoPartidas: const [],
      participantes: [
        _participante('ana', 'Ana'),
        _participante('caio', 'Caio'),
      ],
      palpites: [
        _palpite('ana', 'jogo-1', 1, 0),
        _palpite('ana', 'jogo-2', 0, 0),
        _palpite('caio', 'jogo-1', 2, 0),
        _palpite('caio', 'jogo-2', 3, 2),
      ],
      timesParticipantes: const [],
    );

    final ranking = SistemaPontuacaoParticipantes.calcularClassificacao(data);

    expect(ranking.map((linha) => linha.participanteId), ['ana', 'caio']);
    expect(ranking.first.pontosTotal, ranking.last.pontosTotal);
    expect(ranking.first.placaresExatos, 1);
    expect(ranking.last.placaresExatos, 0);
  });
}

Jogo _jogo({
  required String jogoId,
  required int matchNumber,
  required int golsMandante,
  required int golsVisitante,
  required bool temResultado,
  required bool resultadoFinal,
  required String statusJogo,
}) {
  const mandante = ReferenciaParticipanteJogo(
    tipo: 'time',
    descricao: 'Brasil',
    timeId: 'brasil',
    timeKey: 'brasil',
    nomeFonte: 'Brasil',
    grupo: 'A',
    posicao: null,
    gruposElegiveis: [],
    matchNumberReferencia: null,
    jogoIdReferencia: null,
  );
  const visitante = ReferenciaParticipanteJogo(
    tipo: 'time',
    descricao: 'Argentina',
    timeId: 'argentina',
    timeKey: 'argentina',
    nomeFonte: 'Argentina',
    grupo: 'A',
    posicao: null,
    gruposElegiveis: [],
    matchNumberReferencia: null,
    jogoIdReferencia: null,
  );

  return Jogo(
    jogoId: jogoId,
    matchNumber: matchNumber,
    ordem: matchNumber,
    fase: 'Grupo A',
    faseCodigo: 'group-stage',
    faseTipo: 'fase_de_grupos',
    grupo: 'A',
    rodada: 1,
    roundNumber: 1,
    dataTorneio: '2026-06-11',
    dataUtc: DateTime.utc(2026, 6, 11 + matchNumber, 19),
    dataLocal: '2026-06-11T16:00:00-03:00',
    horaLocal: '16:00',
    estadio: 'Estadio',
    cidadeSede: 'Cidade',
    matchUrl: '',
    fonteFixture: 'teste',
    mandantePrevisto: 'BRASIL',
    visitantePrevisto: 'ARGENTINA',
    mandanteReferencia: mandante,
    visitanteReferencia: visitante,
    idEventAtual: null,
    statusJogo: statusJogo,
    golsMandante: golsMandante,
    golsVisitante: golsVisitante,
    vencedor: golsMandante > golsVisitante ? 'BRASIL' : null,
    temHistoricoApi: true,
    temResultadoApi: temResultado,
    temResultado: temResultado,
    resultadoFinal: resultadoFinal,
    fonteResultado: 'teste',
  );
}

Participante _participante(String id, String nome) {
  return Participante(
    participanteId: id,
    nome: nome,
    corHex: null,
    jogosPalpitados: 2,
    jogosSemPalpite: 0,
    jogosPalpitadosFaseGrupos: 2,
    jogosSemPalpiteFaseGrupos: 0,
    totalJogosPrevistos: 2,
    totalJogosFaseGrupos: 2,
  );
}

Palpite _palpite(
  String participanteId,
  String jogoId,
  int mandante,
  int visitante,
) {
  return Palpite(
    palpiteId: 'palpite-$participanteId-$jogoId',
    participanteId: participanteId,
    jogoId: jogoId,
    golsMandante: mandante,
    golsVisitante: visitante,
  );
}
