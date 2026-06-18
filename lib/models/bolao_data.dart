import 'historico_partida.dart';
import 'jogo.dart';
import 'palpite.dart';
import 'participante.dart';
import 'time_participante.dart';

class BolaoData {
  final List<Jogo> jogos;
  final List<HistoricoPartida> historicoPartidas;
  final List<Participante> participantes;
  final List<Palpite> palpites;
  final List<TimeParticipante> timesParticipantes;

  const BolaoData({
    required this.jogos,
    required this.historicoPartidas,
    required this.participantes,
    required this.palpites,
    required this.timesParticipantes,
  });

  BolaoData copyWith({
    List<Jogo>? jogos,
    List<HistoricoPartida>? historicoPartidas,
    List<Participante>? participantes,
    List<Palpite>? palpites,
    List<TimeParticipante>? timesParticipantes,
  }) {
    return BolaoData(
      jogos: jogos ?? this.jogos,
      historicoPartidas: historicoPartidas ?? this.historicoPartidas,
      participantes: participantes ?? this.participantes,
      palpites: palpites ?? this.palpites,
      timesParticipantes: timesParticipantes ?? this.timesParticipantes,
    );
  }

  Map<String, Jogo> get jogosPorId {
    return {for (final jogo in jogos) jogo.jogoId: jogo};
  }

  Map<int, Jogo> get jogosPorMatchNumber {
    return {for (final jogo in jogos) jogo.matchNumber: jogo};
  }

  Map<String, HistoricoPartida> get historicoPorJogoId {
    return {for (final partida in historicoPartidas) partida.jogoId: partida};
  }

  Map<String, Participante> get participantesPorId {
    return {
      for (final participante in participantes)
        participante.participanteId: participante,
    };
  }

  Map<String, TimeParticipante> get timesPorId {
    return {for (final time in timesParticipantes) time.timeId: time};
  }

  List<Jogo> get jogosOrdenados {
    final result = [...jogos];
    result.sort((a, b) => a.ordem.compareTo(b.ordem));
    return result;
  }

  List<Palpite> palpitesDoParticipante(String participanteId) {
    return palpites
        .where((palpite) => palpite.participanteId == participanteId)
        .toList(growable: false);
  }

  List<Palpite> palpitesDoJogo(String jogoId) {
    return palpites
        .where((palpite) => palpite.jogoId == jogoId)
        .toList(growable: false);
  }

  int get totalJogos => jogos.length;

  int get totalParticipantes => participantes.length;

  int get totalPalpites => palpites.length;

  int get totalTimes => timesParticipantes.length;

  int get totalHistoricoPartidas => historicoPartidas.length;
}
