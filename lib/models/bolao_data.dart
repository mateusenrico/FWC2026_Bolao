import 'historico_partida.dart';
import 'jogo.dart';
import 'liga_sportsdb.dart';
import 'palpite.dart';
import 'participante.dart';
import 'time_participante.dart';
import 'time_sportsdb.dart';
import 'venue_sportsdb.dart';

class BolaoData {
  final List<Jogo> jogos;
  final List<HistoricoPartida> historicoPartidas;
  final List<Participante> participantes;
  final List<Palpite> palpites;
  final List<TimeParticipante> timesParticipantes;
  final List<TimeSportsDb> timesSportsDb;
  final List<VenueSportsDb> venuesSportsDb;
  final LigaSportsDb? ligaSportsDb;

  const BolaoData({
    required this.jogos,
    required this.historicoPartidas,
    required this.participantes,
    required this.palpites,
    required this.timesParticipantes,
    this.timesSportsDb = const [],
    this.venuesSportsDb = const [],
    this.ligaSportsDb,
  });

  BolaoData copyWith({
    List<Jogo>? jogos,
    List<HistoricoPartida>? historicoPartidas,
    List<Participante>? participantes,
    List<Palpite>? palpites,
    List<TimeParticipante>? timesParticipantes,
    List<TimeSportsDb>? timesSportsDb,
    List<VenueSportsDb>? venuesSportsDb,
    LigaSportsDb? ligaSportsDb,
  }) {
    return BolaoData(
      jogos: jogos ?? this.jogos,
      historicoPartidas: historicoPartidas ?? this.historicoPartidas,
      participantes: participantes ?? this.participantes,
      palpites: palpites ?? this.palpites,
      timesParticipantes: timesParticipantes ?? this.timesParticipantes,
      timesSportsDb: timesSportsDb ?? this.timesSportsDb,
      venuesSportsDb: venuesSportsDb ?? this.venuesSportsDb,
      ligaSportsDb: ligaSportsDb ?? this.ligaSportsDb,
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

  Map<String, TimeSportsDb> get timesSportsDbPorKey {
    return {for (final time in timesSportsDb) time.timeKey: time};
  }

  Map<String, VenueSportsDb> get venuesSportsDbPorKey {
    return {for (final venue in venuesSportsDb) venue.venueKey: venue};
  }

  Map<String, VenueSportsDb> get venuesSportsDbPorId {
    return {
      for (final venue in venuesSportsDb)
        if (venue.idVenue != null && venue.idVenue!.isNotEmpty)
          venue.idVenue!: venue,
    };
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

  int get totalTimesSportsDb => timesSportsDb.length;

  int get totalVenuesSportsDb => venuesSportsDb.length;
}
