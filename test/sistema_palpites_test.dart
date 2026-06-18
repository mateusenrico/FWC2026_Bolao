import 'package:flutter_test/flutter_test.dart';
import 'package:fwc2026_bolao/core/sistema_palpites.dart';
import 'package:fwc2026_bolao/models/jogo.dart';
import 'package:fwc2026_bolao/models/palpite.dart';
import 'package:fwc2026_bolao/models/referencia_participante_jogo.dart';

void main() {
  group('SistemaPalpites', () {
    test('placar exato vale 5 pontos também no mata-mata', () {
      final pontuacao = SistemaPalpites.calcularPontuacaoPalpite(
        jogo: _jogo(faseTipo: 'mata_mata', golsMandante: 2, golsVisitante: 1),
        palpite: _palpite(2, 1),
      );

      expect(pontuacao.pontos, 5);
      expect(pontuacao.placarExato, isTrue);
    });

    test('resultado correto e um placar correto vale 3 pontos', () {
      final pontuacao = SistemaPalpites.calcularPontuacaoPalpite(
        jogo: _jogo(golsMandante: 2, golsVisitante: 1),
        palpite: _palpite(2, 0),
      );

      expect(pontuacao.pontos, 3);
    });

    test('somente resultado correto vale 2 pontos', () {
      final pontuacao = SistemaPalpites.calcularPontuacaoPalpite(
        jogo: _jogo(golsMandante: 2, golsVisitante: 1),
        palpite: _palpite(3, 0),
      );

      expect(pontuacao.pontos, 2);
    });

    test('um placar correto com resultado errado vale 1 ponto', () {
      final pontuacao = SistemaPalpites.calcularPontuacaoPalpite(
        jogo: _jogo(golsMandante: 2, golsVisitante: 1),
        palpite: _palpite(2, 3),
      );

      expect(pontuacao.pontos, 1);
    });

    test('sem acerto vale 0 pontos', () {
      final pontuacao = SistemaPalpites.calcularPontuacaoPalpite(
        jogo: _jogo(golsMandante: 2, golsVisitante: 1),
        palpite: _palpite(0, 3),
      );

      expect(pontuacao.pontos, 0);
    });

    test('jogo futuro com placar visual 0x0 nao pontua', () {
      final pontuacao = SistemaPalpites.calcularPontuacaoPalpite(
        jogo: _jogo(
          golsMandante: 0,
          golsVisitante: 0,
          statusJogo: 'agendado',
          temResultado: false,
          resultadoFinal: false,
        ),
        palpite: _palpite(0, 0),
      );

      expect(pontuacao.pontuavel, isFalse);
      expect(pontuacao.pontos, 0);
      expect(pontuacao.motivo, 'Jogo ainda sem resultado.');
    });
  });
}

Jogo _jogo({
  String faseTipo = 'fase_de_grupos',
  required int golsMandante,
  required int golsVisitante,
  String statusJogo = 'encerrado',
  bool temResultado = true,
  bool resultadoFinal = true,
}) {
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
    fase: faseTipo == 'mata_mata' ? 'Oitavas' : 'A',
    faseCodigo: faseTipo == 'mata_mata' ? 'round-of-32' : 'group-stage',
    faseTipo: faseTipo,
    grupo: faseTipo == 'fase_de_grupos' ? 'A' : null,
    rodada: 1,
    roundNumber: 1,
    dataTorneio: '2026-06-11',
    dataUtc: DateTime.utc(2026, 6, 11, 19),
    dataLocal: '2026-06-11T16:00:00-03:00',
    horaLocal: '16:00',
    estadio: 'Estádio',
    cidadeSede: 'Cidade',
    matchUrl: '',
    fonteFixture: 'teste',
    mandantePrevisto: 'BRASIL',
    visitantePrevisto: 'ARGENTINA',
    mandanteReferencia: reference,
    visitanteReferencia: reference,
    idEventAtual: null,
    statusJogo: statusJogo,
    golsMandante: golsMandante,
    golsVisitante: golsVisitante,
    vencedor: 'BRASIL',
    temHistoricoApi: true,
    temResultadoApi: true,
    temResultado: temResultado,
    resultadoFinal: resultadoFinal,
    fonteResultado: 'teste',
  );
}

Palpite _palpite(int mandante, int visitante) {
  return Palpite(
    palpiteId: 'palpite-1',
    participanteId: 'participante-1',
    jogoId: 'jogo-1',
    golsMandante: mandante,
    golsVisitante: visitante,
  );
}
