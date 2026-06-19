import 'package:flutter_test/flutter_test.dart';
import 'package:fwc2026_bolao/models/jogo.dart';
import 'package:fwc2026_bolao/services/bolao_controller.dart';
import 'package:fwc2026_bolao/services/sportsdb_api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'refresh ao vivo preserva placar conhecido contra resposta atrasada',
    () async {
      final api = _FakeSportsDbApiService();
      final controller = await BolaoController.carregar(apiService: api);
      final jogo = controller.data.jogos.firstWhere(
        (jogo) =>
            jogo.idEventAtual != null &&
            !jogo.resultadoFinal &&
            !jogo.temResultado,
      );

      api.enqueue([
        _eventFor(jogo, homeScore: 1, awayScore: 0, status: 'LIVE'),
      ]);
      await controller.atualizarApi();

      var atualizado = controller.jogoPorId(jogo.jogoId)!;
      expect(atualizado.statusJogo, 'em_andamento');
      expect(atualizado.golsMandante, 1);
      expect(atualizado.golsVisitante, 0);

      api.enqueue([
        _eventFor(jogo, homeScore: null, awayScore: null, status: 'LIVE'),
      ]);
      await controller.atualizarApi();

      atualizado = controller.jogoPorId(jogo.jogoId)!;
      expect(atualizado.statusJogo, 'em_andamento');
      expect(atualizado.golsMandante, 1);
      expect(atualizado.golsVisitante, 0);

      api.enqueue([
        _eventFor(jogo, homeScore: 0, awayScore: 0, status: 'LIVE'),
      ]);
      await controller.atualizarApi();

      atualizado = controller.jogoPorId(jogo.jogoId)!;
      expect(atualizado.statusJogo, 'em_andamento');
      expect(atualizado.golsMandante, 1);
      expect(atualizado.golsVisitante, 0);

      api.enqueue([
        _eventFor(jogo, homeScore: 1, awayScore: 1, status: 'LIVE'),
      ]);
      await controller.atualizarApi();

      atualizado = controller.jogoPorId(jogo.jogoId)!;
      expect(atualizado.golsMandante, 1);
      expect(atualizado.golsVisitante, 1);
    },
  );

  test(
    'refresh preserva melhor placar mesmo apos encerramento inferido',
    () async {
      final api = _FakeSportsDbApiService();
      final controller = await BolaoController.carregar(apiService: api);
      final jogo = controller.data.jogos.firstWhere(
        (jogo) =>
            jogo.idEventAtual != null &&
            !jogo.resultadoFinal &&
            !jogo.temResultado,
      );

      api.enqueue([
        _eventFor(
          jogo,
          homeScore: 3,
          awayScore: 0,
          status: 'LIVE',
          timestampUtc: DateTime.now().toUtc().subtract(
            const Duration(hours: 3),
          ),
        ),
      ]);
      await controller.atualizarApi();

      var atualizado = controller.jogoPorId(jogo.jogoId)!;
      expect(atualizado.statusJogo, 'encerrado');
      expect(atualizado.resultadoFinal, isTrue);
      expect(atualizado.golsMandante, 3);
      expect(atualizado.golsVisitante, 0);

      api.enqueue([
        _eventFor(jogo, homeScore: 6, awayScore: 0, status: 'LIVE'),
      ]);
      await controller.atualizarApi();

      atualizado = controller.jogoPorId(jogo.jogoId)!;
      expect(atualizado.statusJogo, 'encerrado');
      expect(atualizado.resultadoFinal, isTrue);
      expect(atualizado.golsMandante, 6);
      expect(atualizado.golsVisitante, 0);

      api.enqueue([
        _eventFor(jogo, homeScore: 3, awayScore: 0, status: 'LIVE'),
      ]);
      await controller.atualizarApi();

      atualizado = controller.jogoPorId(jogo.jogoId)!;
      expect(atualizado.statusJogo, 'encerrado');
      expect(atualizado.golsMandante, 6);
      expect(atualizado.golsVisitante, 0);
    },
  );

  test('refresh preserva minuto ao vivo contra resposta atrasada', () async {
    final api = _FakeSportsDbApiService();
    final controller = await BolaoController.carregar(apiService: api);
    final jogo = controller.data.jogos.firstWhere(
      (jogo) =>
          jogo.idEventAtual != null &&
          !jogo.resultadoFinal &&
          !jogo.temResultado,
    );

    api.enqueue([_eventFor(jogo, homeScore: 0, awayScore: 0, status: '35')]);
    await controller.atualizarApi();
    expect(
      controller.tempoAtualDoJogo(controller.jogoPorId(jogo.jogoId)!),
      "35'",
    );

    api.enqueue([_eventFor(jogo, homeScore: 0, awayScore: 0, status: '21')]);
    await controller.atualizarApi();
    expect(
      controller.tempoAtualDoJogo(controller.jogoPorId(jogo.jogoId)!),
      "35'",
    );

    api.enqueue([_eventFor(jogo, homeScore: 0, awayScore: 0, status: 'HT')]);
    await controller.atualizarApi();
    expect(
      controller.tempoAtualDoJogo(controller.jogoPorId(jogo.jogoId)!),
      'Intervalo',
    );

    api.enqueue([_eventFor(jogo, homeScore: 0, awayScore: 0, status: '44')]);
    await controller.atualizarApi();
    expect(
      controller.tempoAtualDoJogo(controller.jogoPorId(jogo.jogoId)!),
      'Intervalo',
    );

    api.enqueue([_eventFor(jogo, homeScore: 0, awayScore: 0, status: '52')]);
    await controller.atualizarApi();
    expect(
      controller.tempoAtualDoJogo(controller.jogoPorId(jogo.jogoId)!),
      "52'",
    );

    api.enqueue([_eventFor(jogo, homeScore: 0, awayScore: 0, status: '49')]);
    await controller.atualizarApi();
    expect(
      controller.tempoAtualDoJogo(controller.jogoPorId(jogo.jogoId)!),
      "52'",
    );
  });
}

class _FakeSportsDbApiService extends SportsDbApiService {
  final List<List<SportsDbEvent>> _batches = [];

  _FakeSportsDbApiService() : super(timeout: const Duration(milliseconds: 1));

  void enqueue(List<SportsDbEvent> events) {
    _batches.add(events);
  }

  @override
  Future<SportsDbApiResult> fetchRefreshResult({
    Iterable<String> eventIds = const [],
  }) async {
    final events = _batches.isEmpty ? <SportsDbEvent>[] : _batches.removeAt(0);

    return SportsDbApiResult(
      events: events,
      endpoints: [
        SportsDbEndpointResult(
          name: 'fake',
          uri: 'fake://sportsdb',
          ok: true,
          events: events,
          durationMs: 1,
        ),
      ],
    );
  }
}

SportsDbEvent _eventFor(
  Jogo jogo, {
  required int? homeScore,
  required int? awayScore,
  required String status,
  DateTime? timestampUtc,
}) {
  return SportsDbEvent(
    idEvent: jogo.idEventAtual!,
    idLeague: SportsDbApiService().leagueId,
    strEvent: jogo.confrontoPrevisto,
    strHomeTeam: jogo.mandantePrevisto,
    strAwayTeam: jogo.visitantePrevisto,
    idHomeTeam: null,
    idAwayTeam: null,
    intHomeScore: homeScore,
    intAwayScore: awayScore,
    dateEvent: null,
    dateEventLocal: null,
    strTime: null,
    strTimeLocal: null,
    strTimestampUtc: timestampUtc ?? DateTime.now().toUtc(),
    strVenue: jogo.estadio,
    strCity: jogo.cidadeSede,
    strCountry: null,
    idVenue: null,
    strStatus: status,
    strPostponed: null,
    strGroup: jogo.grupo,
    intRound: jogo.rodada,
    strLeagueBadge: null,
    strHomeTeamBadge: null,
    strAwayTeamBadge: null,
    strThumb: null,
    strPoster: null,
    strFanart: null,
    strBanner: null,
    strVideo: null,
  );
}
