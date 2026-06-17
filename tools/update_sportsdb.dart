import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'package:fwc2026_bolao/core/team_normalizer.dart';

const String apiKey = '123';
const String apiBaseUrl = 'https://www.thesportsdb.com/api/v1/json/$apiKey';

void main(List<String> args) async {
  final config = UpdateConfig.fromArgs(args);
  final updater = SportsDbJsonUpdater(config);

  await updater.run();
}

class UpdateConfig {
  final String leagueId;
  final String season;
  final bool includeDayScan;
  final DateTime dayScanStart;
  final DateTime dayScanEnd;

  const UpdateConfig({
    required this.leagueId,
    required this.season,
    required this.includeDayScan,
    required this.dayScanStart,
    required this.dayScanEnd,
  });

  factory UpdateConfig.fromArgs(List<String> args) {
    String leagueId = '4429';
    String season = '2026';
    bool includeDayScan = true;
    DateTime dayScanStart = DateTime(2026, 6, 11);
    DateTime dayScanEnd = DateTime(2026, 7, 19);

    for (final arg in args) {
      if (arg.startsWith('--league-id=')) {
        leagueId = arg.substring('--league-id='.length).trim();
      } else if (arg.startsWith('--season=')) {
        season = arg.substring('--season='.length).trim();
      } else if (arg == '--no-day-scan') {
        includeDayScan = false;
      } else if (arg == '--include-day-scan') {
        includeDayScan = true;
      } else if (arg.startsWith('--from=')) {
        final parsed = DateTime.tryParse(
          arg.substring('--from='.length).trim(),
        );
        if (parsed != null) {
          dayScanStart = parsed;
        }
      } else if (arg.startsWith('--to=')) {
        final parsed = DateTime.tryParse(arg.substring('--to='.length).trim());
        if (parsed != null) {
          dayScanEnd = parsed;
        }
      }
    }

    return UpdateConfig(
      leagueId: leagueId,
      season: season,
      includeDayScan: includeDayScan,
      dayScanStart: dayScanStart,
      dayScanEnd: dayScanEnd,
    );
  }
}

class SportsDbJsonUpdater {
  final UpdateConfig config;

  SportsDbJsonUpdater(this.config);

  final Directory dataDir = Directory('assets/data');

  File get jogosFile => File('assets/data/jogos.json');

  File get historicoFile => File('assets/data/historico_partidas.json');

  File get timesFile => File('assets/data/times_participantes.json');

  Future<void> run() async {
    _assertFilesExist();

    final backupDir = await _backupJsonFiles();

    stdout.writeln('Backup criado em: ${backupDir.path}');
    stdout.writeln('');

    final jogos = await _readJsonList(jogosFile);
    final historico = await _readJsonList(historicoFile);
    final times = await _readJsonList(timesFile);

    final apiEvents = await _fetchAllEvents();

    stdout.writeln('');
    stdout.writeln('Eventos únicos recebidos da API: ${apiEvents.length}');
    stdout.writeln('');

    final mergeResult = _mergeApiEvents(
      jogos: jogos,
      historico: historico,
      apiEvents: apiEvents,
    );

    _recalcularTimesParticipantes(
      jogos: jogos,
      historico: historico,
      times: times,
    );

    await _writeJsonList(jogosFile, jogos);
    await _writeJsonList(historicoFile, historico);
    await _writeJsonList(timesFile, times);

    stdout.writeln('Atualização concluída.');
    stdout.writeln('');
    stdout.writeln('Resumo:');
    stdout.writeln(
      '- Eventos API processados: ${mergeResult.eventosProcessados}',
    );
    stdout.writeln(
      '- Eventos ignorados sem idEvent: ${mergeResult.eventosIgnoradosSemId}',
    );
    stdout.writeln(
      '- Histórico atualizado por idEvent: ${mergeResult.historicoAtualizadoPorIdEvent}',
    );
    stdout.writeln(
      '- Histórico atualizado por jogoId: ${mergeResult.historicoAtualizadoPorJogoId}',
    );
    stdout.writeln('- Histórico inserido: ${mergeResult.historicoInserido}');
    stdout.writeln(
      '- Jogos canônicos atualizados: ${mergeResult.jogosAtualizados}',
    );
    stdout.writeln('- Jogos canônicos criados: ${mergeResult.jogosCriados}');
    stdout.writeln(
      '- Duplicatas API removidas: ${mergeResult.duplicatasApiRemovidas}',
    );
    stdout.writeln(
      '- Eventos com match canônico: ${mergeResult.eventosComMatchCanonico}',
    );
    stdout.writeln(
      '- Eventos sem match canônico: ${mergeResult.eventosSemMatchCanonico}',
    );
    stdout.writeln('');
    _printJogosEncerradosSemResultado(jogos);
  }

  void _assertFilesExist() {
    if (!dataDir.existsSync()) {
      throw StateError('Pasta não encontrada: ${dataDir.path}');
    }

    for (final file in [jogosFile, historicoFile, timesFile]) {
      if (!file.existsSync()) {
        throw StateError('Arquivo não encontrado: ${file.path}');
      }
    }
  }

  Future<Directory> _backupJsonFiles() async {
    final timestamp = _timestampForPath(DateTime.now());
    final backupDir = Directory('assets/data/backups/$timestamp');

    await backupDir.create(recursive: true);

    final jsonFiles = dataDir
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.json'))
        .toList();

    for (final file in jsonFiles) {
      final fileName = file.uri.pathSegments.last;
      await file.copy('${backupDir.path}/$fileName');
    }

    return backupDir;
  }

  Future<List<Map<String, dynamic>>> _readJsonList(File file) async {
    final raw = await file.readAsString();
    final decoded = jsonDecode(raw);

    if (decoded is! List) {
      throw FormatException(
        '${file.path} deveria conter uma lista JSON na raiz.',
      );
    }

    return decoded.map((item) {
      if (item is Map<String, dynamic>) {
        return item;
      }

      if (item is Map) {
        return Map<String, dynamic>.from(item);
      }

      throw FormatException(
        'Item inválido em ${file.path}: ${item.runtimeType}',
      );
    }).toList();
  }

  Future<void> _writeJsonList(
    File file,
    List<Map<String, dynamic>> data,
  ) async {
    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString('${encoder.convert(data)}\n');
  }

  Future<List<Map<String, dynamic>>> _fetchAllEvents() async {
    final allEvents = <Map<String, dynamic>>[];

    final urls = <Uri>[
      Uri.parse(
        '$apiBaseUrl/eventsseason.php?id=${config.leagueId}&s=${config.season}',
      ),
      Uri.parse('$apiBaseUrl/eventsnextleague.php?id=${config.leagueId}'),
      Uri.parse('$apiBaseUrl/eventspastleague.php?id=${config.leagueId}'),
    ];

    for (final uri in urls) {
      final events = await _fetchEventsFromUri(uri);
      allEvents.addAll(events);
    }

    if (config.includeDayScan) {
      final dayEvents = await _fetchDayEvents(
        start: config.dayScanStart,
        end: config.dayScanEnd,
      );

      allEvents.addAll(dayEvents);
    }

    return _uniqueByIdEvent(allEvents);
  }

  Future<List<Map<String, dynamic>>> _fetchDayEvents({
    required DateTime start,
    required DateTime end,
  }) async {
    final events = <Map<String, dynamic>>[];

    var current = DateTime(start.year, start.month, start.day);
    final last = DateTime(end.year, end.month, end.day);

    while (!current.isAfter(last)) {
      final date = _dateOnly(current);
      final uri = Uri.parse('$apiBaseUrl/eventsday.php?d=$date&s=Soccer');
      final dayEvents = await _fetchEventsFromUri(uri);

      events.addAll(dayEvents);

      current = current.add(const Duration(days: 1));
    }

    return events;
  }

  Future<List<Map<String, dynamic>>> _fetchEventsFromUri(Uri uri) async {
    stdout.writeln('GET $uri');

    final response = await http.get(uri);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      stderr.writeln('Falha HTTP ${response.statusCode}: $uri');
      return const [];
    }

    final decoded = jsonDecode(response.body);
    final rawEvents = decoded['events'];

    if (rawEvents == null || rawEvents is! List) {
      return const [];
    }

    return rawEvents
        .map((item) {
          if (item is Map<String, dynamic>) {
            return item;
          }

          if (item is Map) {
            return Map<String, dynamic>.from(item);
          }

          return <String, dynamic>{};
        })
        .where((event) {
          return event.isNotEmpty &&
              event['idLeague']?.toString() == config.leagueId;
        })
        .toList();
  }

  List<Map<String, dynamic>> _uniqueByIdEvent(
    List<Map<String, dynamic>> events,
  ) {
    final byId = <String, Map<String, dynamic>>{};

    for (final event in events) {
      final idEvent = event['idEvent']?.toString();

      if (idEvent == null || idEvent.isEmpty) {
        continue;
      }

      byId[idEvent] = event;
    }

    return byId.values.toList();
  }

  MergeResult _mergeApiEvents({
    required List<Map<String, dynamic>> jogos,
    required List<Map<String, dynamic>> historico,
    required List<Map<String, dynamic>> apiEvents,
  }) {
    final historicoPorIdEvent = <String, Map<String, dynamic>>{
      for (final partida in historico)
        if (partida['idEvent'] != null) partida['idEvent'].toString(): partida,
    };

    final historicoPorJogoId = <String, Map<String, dynamic>>{
      for (final partida in historico)
        if (partida['jogoId'] != null) partida['jogoId'].toString(): partida,
    };

    final jogosPorIdEvent = <String, Map<String, dynamic>>{
      for (final jogo in jogos)
        if (jogo['idEventAtual'] != null) jogo['idEventAtual'].toString(): jogo,
    };

    int maxOrdem = 0;

    for (final jogo in jogos) {
      final ordem = _asInt(jogo['ordem']) ?? 0;

      if (ordem > maxOrdem) {
        maxOrdem = ordem;
      }
    }

    final result = MergeResult();
    final jogosParaRemover = <Map<String, dynamic>>[];

    for (final event in apiEvents) {
      result.eventosProcessados++;

      final idEvent = event['idEvent']?.toString();

      if (idEvent == null || idEvent.isEmpty) {
        result.eventosIgnoradosSemId++;
        continue;
      }

      final jogoPorIdEvent = jogosPorIdEvent[idEvent];

      final jogoCanonicoPorTimesHorario = _findCanonicalJogoByTeamsAndTime(
        event: event,
        jogos: jogos,
      );

      if (jogoCanonicoPorTimesHorario != null) {
        result.eventosComMatchCanonico++;
      } else {
        result.eventosSemMatchCanonico++;
        stdout.writeln(
          'Sem match canônico: ${event['strHomeTeam']} x ${event['strAwayTeam']} | '
          'idEvent=${event['idEvent']} | '
          'dateEvent=${event['dateEvent']} | '
          'dateEventLocal=${event['dateEventLocal']} | '
          'strTimestamp=${event['strTimestamp']}',
        );
      }

      Map<String, dynamic>? jogoEscolhido;

      if (jogoCanonicoPorTimesHorario != null) {
        jogoEscolhido = jogoCanonicoPorTimesHorario;

        if (jogoPorIdEvent != null &&
            !identical(jogoPorIdEvent, jogoEscolhido)) {
          _desvincularIdEvent(jogoPorIdEvent, idEvent);

          if (_isApiGeneratedJogo(jogoPorIdEvent)) {
            jogosParaRemover.add(jogoPorIdEvent);
          }
        }
      } else if (jogoPorIdEvent != null) {
        jogoEscolhido = jogoPorIdEvent;
      } else {
        maxOrdem++;

        jogoEscolhido = _createJogoFromApiEvent(event: event, ordem: maxOrdem);

        jogos.add(jogoEscolhido);
        result.jogosCriados++;
      }

      final jogoId = jogoEscolhido['jogoId'].toString();

      _updateJogoFromApiEvent(jogo: jogoEscolhido, event: event);

      jogosPorIdEvent[idEvent] = jogoEscolhido;

      final historicoEntry = _buildHistoricoEntry(
        event: event,
        jogo: jogoEscolhido,
      );

      final historicoById = historicoPorIdEvent[idEvent];
      final historicoByJogo = historicoPorJogoId[jogoId];

      if (historicoById != null) {
        historicoById
          ..clear()
          ..addAll(historicoEntry);

        result.historicoAtualizadoPorIdEvent++;
      } else if (historicoByJogo != null) {
        historicoByJogo
          ..clear()
          ..addAll(historicoEntry);

        result.historicoAtualizadoPorJogoId++;
      } else {
        historico.add(historicoEntry);

        historicoPorIdEvent[idEvent] = historicoEntry;
        historicoPorJogoId[jogoId] = historicoEntry;

        result.historicoInserido++;
      }

      result.jogosAtualizados++;
    }

    if (jogosParaRemover.isNotEmpty) {
      final idsParaRemover = jogosParaRemover
          .map((jogo) => jogo['jogoId']?.toString())
          .whereType<String>()
          .toSet();

      jogos.removeWhere((jogo) {
        final jogoId = jogo['jogoId']?.toString();

        return jogoId != null && idsParaRemover.contains(jogoId);
      });

      result.duplicatasApiRemovidas += idsParaRemover.length;
    }

    jogos.sort((a, b) {
      final ordemA = _asInt(a['ordem']) ?? 999999;
      final ordemB = _asInt(b['ordem']) ?? 999999;
      return ordemA.compareTo(ordemB);
    });

    historico.sort((a, b) {
      final ordemA = _asInt(a['ordemBolao']) ?? 999999;
      final ordemB = _asInt(b['ordemBolao']) ?? 999999;
      return ordemA.compareTo(ordemB);
    });

    return result;
  }

  Map<String, dynamic>? _findCanonicalJogoByTeamsAndTime({
    required Map<String, dynamic> event,
    required List<Map<String, dynamic>> jogos,
  }) {
    final homeKey = TeamNormalizer.key(event['strHomeTeam']?.toString() ?? '');
    final awayKey = TeamNormalizer.key(event['strAwayTeam']?.toString() ?? '');

    if (homeKey.isEmpty || awayKey.isEmpty) {
      return null;
    }

    final eventUtc = _apiEventDateTimeUtc(event);
    final eventDateUtc = eventUtc == null
        ? _eventDateOnly(event)
        : _dateOnly(eventUtc);
    final eventDateLocal = event['dateEventLocal']?.toString();

    Map<String, dynamic>? bestMatch;
    int bestDiffMinutes = 999999;

    for (final jogo in jogos) {
      if (_isApiGeneratedJogo(jogo)) {
        continue;
      }

      final mandanteKey = TeamNormalizer.key(
        jogo['mandantePrevisto']?.toString() ?? '',
      );
      final visitanteKey = TeamNormalizer.key(
        jogo['visitantePrevisto']?.toString() ?? '',
      );

      final sameOrder = mandanteKey == homeKey && visitanteKey == awayKey;
      final invertedOrder = mandanteKey == awayKey && visitanteKey == homeKey;

      if (!sameOrder && !invertedOrder) {
        continue;
      }

      final jogoUtc = _jogoDateTimeUtc(jogo);

      if (eventUtc != null && jogoUtc != null) {
        final diff = eventUtc.difference(jogoUtc).inMinutes.abs();

        if (diff < bestDiffMinutes) {
          bestDiffMinutes = diff;
          bestMatch = jogo;
        }

        continue;
      }

      final jogoDate = _jogoDateOnly(jogo);

      final dateMatches =
          jogoDate != null &&
          (jogoDate == eventDateUtc || jogoDate == eventDateLocal);

      if (dateMatches) {
        return jogo;
      }
    }

    if (bestMatch != null && bestDiffMinutes <= 30 * 60) {
      return bestMatch;
    }

    return null;
  }

  bool _isApiGeneratedJogo(Map<String, dynamic> jogo) {
    final origem = jogo['origem']?.toString();
    final jogoId = jogo['jogoId']?.toString() ?? '';

    return origem == 'api' || jogoId.startsWith('gapi');
  }

  void _desvincularIdEvent(Map<String, dynamic> jogo, String idEvent) {
    if (jogo['idEventAtual']?.toString() == idEvent) {
      jogo['idEventAtual'] = null;
    }

    jogo['temHistoricoApi'] = false;
    jogo['temResultadoApi'] = false;
  }

  Map<String, dynamic> _createJogoFromApiEvent({
    required Map<String, dynamic> event,
    required int ordem,
  }) {
    final idEvent = event['idEvent']?.toString() ?? '';
    final home = event['strHomeTeam']?.toString() ?? '';
    final away = event['strAwayTeam']?.toString() ?? '';
    final timestampUtc = _apiEventDateTimeUtc(event);

    final group = _extractGroup(event);
    final faseTipo = group == null ? 'desconhecido' : 'fase_de_grupos';

    return {
      'jogoId': 'gapi$idEvent',
      'ordem': ordem,
      'fase': group == null ? 'API' : 'Grupo $group',
      'faseTipo': faseTipo,
      'grupo': group,
      'rodada': _asInt(event['intRound']),
      'dataLocal': timestampUtc?.toLocal().toIso8601String(),
      'dataUtc': timestampUtc?.toUtc().toIso8601String(),
      'horaLocal': timestampUtc == null
          ? null
          : _formatTime(timestampUtc.toLocal()),
      'statusJogo': _statusCanonicoFromEvent(event),
      'mandantePrevisto': home,
      'visitantePrevisto': away,
      'idEventAtual': idEvent,
      'temHistoricoApi': true,
      'temResultadoApi': _eventHasScore(event),
      'origem': 'api',
    };
  }

  void _updateJogoFromApiEvent({
    required Map<String, dynamic> jogo,
    required Map<String, dynamic> event,
  }) {
    final idEvent = event['idEvent']?.toString();

    if (idEvent != null && idEvent.isNotEmpty) {
      jogo['idEventAtual'] = idEvent;
    }

    jogo['temHistoricoApi'] = true;
    jogo['temResultadoApi'] = _eventHasScore(event);
    jogo['statusJogo'] = _statusCanonicoFromEvent(event);

    final timestampUtc = _apiEventDateTimeUtc(event);

    if (timestampUtc != null) {
      jogo['dataUtc'] = timestampUtc.toUtc().toIso8601String();
      jogo['dataLocal'] = timestampUtc.toLocal().toIso8601String();
      jogo['horaLocal'] = _formatTime(timestampUtc.toLocal());
    }

    final group = _extractGroup(event);

    if ((jogo['grupo'] == null || jogo['grupo'].toString().isEmpty) &&
        group != null) {
      jogo['grupo'] = group;
    }

    if ((jogo['faseTipo'] == null || jogo['faseTipo'].toString().isEmpty) &&
        group != null) {
      jogo['faseTipo'] = 'fase_de_grupos';
    }
  }

  Map<String, dynamic> _buildHistoricoEntry({
    required Map<String, dynamic> event,
    required Map<String, dynamic> jogo,
  }) {
    final homeScore = _asInt(event['intHomeScore']);
    final awayScore = _asInt(event['intAwayScore']);
    final temResultado = homeScore != null && awayScore != null;
    final statusCanonico = _statusCanonicoFromEvent(event);
    final timestampUtc = _apiEventDateTimeUtc(event);

    return {
      ...event,
      'jogoId': jogo['jogoId'],
      'idEvent': event['idEvent']?.toString(),
      'strEvent': event['strEvent'],
      'strHomeTeam': event['strHomeTeam'],
      'strAwayTeam': event['strAwayTeam'],
      'intHomeScore': homeScore,
      'intAwayScore': awayScore,
      'dateEvent': event['dateEvent'],
      'dateEventLocal': event['dateEventLocal'],
      'strTime': event['strTime'],
      'strTimeLocal': event['strTimeLocal'],
      'strTimestamp': event['strTimestamp'],
      'strVenue': event['strVenue'],
      'strCity': event['strCity'],
      'strCountry': event['strCountry'],
      'strStatus': event['strStatus'],
      'eventTimeGMT': timestampUtc?.toUtc().toIso8601String(),
      'temporalStatus': statusCanonico,
      'faseTipo': jogo['faseTipo'],
      'grupo': jogo['grupo'],
      'statusJogoCanonico': statusCanonico,
      'ordemBolao': jogo['ordem'],
      'mandantePrevisto': jogo['mandantePrevisto'],
      'visitantePrevisto': jogo['visitantePrevisto'],
      'temResultado': temResultado,
    };
  }

  void _recalcularTimesParticipantes({
    required List<Map<String, dynamic>> jogos,
    required List<Map<String, dynamic>> historico,
    required List<Map<String, dynamic>> times,
  }) {
    final historicoPorJogoId = <String, Map<String, dynamic>>{
      for (final partida in historico)
        if (partida['jogoId'] != null) partida['jogoId'].toString(): partida,
    };

    final timesPorKey = <String, Map<String, dynamic>>{
      for (final time in times)
        TeamNormalizer.key(time['nome']?.toString() ?? ''): time,
    };

    for (final time in times) {
      time['estatisticasGrupo'] = {
        'pontos': 0,
        'jogos': 0,
        'vitorias': 0,
        'empates': 0,
        'derrotas': 0,
        'golsPro': 0,
        'golsContra': 0,
        'saldoGols': 0,
        'fairPlayPontos': null,
        'cartoesAmarelos': null,
        'cartoesVermelhos': null,
        'cartoesVermelhosIndiretos': null,
        'cartoesAmareloVermelho': null,
        'observacaoDesempate':
            'Ranking provisório calculado sem dados de fair play.',
      };
      time['rankingGrupo'] = null;
      time['rankingGrupoProvisorio'] = true;
    }

    for (final jogo in jogos) {
      if (jogo['faseTipo'] != 'fase_de_grupos') {
        continue;
      }

      final jogoId = jogo['jogoId']?.toString();

      if (jogoId == null) {
        continue;
      }

      final partida = historicoPorJogoId[jogoId];

      if (partida == null) {
        continue;
      }

      final homeScore = _asInt(partida['intHomeScore']);
      final awayScore = _asInt(partida['intAwayScore']);

      if (homeScore == null || awayScore == null) {
        continue;
      }

      final mandante =
          timesPorKey[TeamNormalizer.key(
            jogo['mandantePrevisto']?.toString() ?? '',
          )];
      final visitante =
          timesPorKey[TeamNormalizer.key(
            jogo['visitantePrevisto']?.toString() ?? '',
          )];

      if (mandante == null || visitante == null) {
        continue;
      }

      _aplicarResultadoGrupo(
        time: mandante,
        golsPro: homeScore,
        golsContra: awayScore,
      );

      _aplicarResultadoGrupo(
        time: visitante,
        golsPro: awayScore,
        golsContra: homeScore,
      );
    }

    final grupos = <String, List<Map<String, dynamic>>>{};

    for (final time in times) {
      final grupo = time['grupo']?.toString() ?? '';
      grupos.putIfAbsent(grupo, () => []).add(time);
    }

    for (final grupoTimes in grupos.values) {
      grupoTimes.sort((a, b) {
        final statsA = Map<String, dynamic>.from(a['estatisticasGrupo'] as Map);
        final statsB = Map<String, dynamic>.from(b['estatisticasGrupo'] as Map);

        final pontos = (_asInt(statsB['pontos']) ?? 0).compareTo(
          _asInt(statsA['pontos']) ?? 0,
        );
        if (pontos != 0) return pontos;

        final saldo = (_asInt(statsB['saldoGols']) ?? 0).compareTo(
          _asInt(statsA['saldoGols']) ?? 0,
        );
        if (saldo != 0) return saldo;

        final golsPro = (_asInt(statsB['golsPro']) ?? 0).compareTo(
          _asInt(statsA['golsPro']) ?? 0,
        );
        if (golsPro != 0) return golsPro;

        return (a['nome']?.toString() ?? '').compareTo(
          b['nome']?.toString() ?? '',
        );
      });

      for (var index = 0; index < grupoTimes.length; index++) {
        grupoTimes[index]['rankingGrupo'] = index + 1;
      }
    }
  }

  void _aplicarResultadoGrupo({
    required Map<String, dynamic> time,
    required int golsPro,
    required int golsContra,
  }) {
    final stats = Map<String, dynamic>.from(time['estatisticasGrupo'] as Map);

    stats['jogos'] = (_asInt(stats['jogos']) ?? 0) + 1;
    stats['golsPro'] = (_asInt(stats['golsPro']) ?? 0) + golsPro;
    stats['golsContra'] = (_asInt(stats['golsContra']) ?? 0) + golsContra;
    stats['saldoGols'] =
        (_asInt(stats['golsPro']) ?? 0) - (_asInt(stats['golsContra']) ?? 0);

    if (golsPro > golsContra) {
      stats['vitorias'] = (_asInt(stats['vitorias']) ?? 0) + 1;
      stats['pontos'] = (_asInt(stats['pontos']) ?? 0) + 3;
    } else if (golsPro == golsContra) {
      stats['empates'] = (_asInt(stats['empates']) ?? 0) + 1;
      stats['pontos'] = (_asInt(stats['pontos']) ?? 0) + 1;
    } else {
      stats['derrotas'] = (_asInt(stats['derrotas']) ?? 0) + 1;
    }

    time['estatisticasGrupo'] = stats;
  }

  void _printJogosEncerradosSemResultado(List<Map<String, dynamic>> jogos) {
    final pendentes = jogos.where((jogo) {
      return jogo['statusJogo'] == 'encerrado' &&
          jogo['temResultadoApi'] != true;
    }).toList();

    if (pendentes.isEmpty) {
      stdout.writeln('Nenhum jogo encerrado sem resultado API.');
      return;
    }

    stdout.writeln('Jogos encerrados ainda sem resultado API:');

    for (final jogo in pendentes) {
      stdout.writeln(
        '- ${jogo['mandantePrevisto']} x ${jogo['visitantePrevisto']} | ${jogo['dataLocal']} | ${jogo['jogoId']}',
      );
    }
  }

  bool _eventHasScore(Map<String, dynamic> event) {
    return _asInt(event['intHomeScore']) != null &&
        _asInt(event['intAwayScore']) != null;
  }

  String _statusCanonicoFromEvent(Map<String, dynamic> event) {
    final status = event['strStatus']?.toString().toUpperCase().trim();

    if (status == 'FT' ||
        status == 'AET' ||
        status == 'PEN' ||
        status == 'FINISHED') {
      return 'encerrado';
    }

    if (status == 'LIVE' ||
        status == '1H' ||
        status == '2H' ||
        status == 'HT') {
      return 'em_andamento';
    }

    if (_eventHasScore(event)) {
      return 'encerrado';
    }

    final timestampUtc = _apiEventDateTimeUtc(event);

    if (timestampUtc == null) {
      return 'agendado';
    }

    final nowUtc = DateTime.now().toUtc();

    if (nowUtc.isBefore(timestampUtc)) {
      return 'agendado';
    }

    if (nowUtc.difference(timestampUtc).inMinutes <= 130) {
      return 'em_andamento';
    }

    return 'encerrado';
  }

  DateTime? _apiEventDateTimeUtc(Map<String, dynamic> event) {
    final value = event['strTimestamp']?.toString();

    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final normalized = value.endsWith('Z') || value.contains('+')
        ? value
        : '${value}Z';

    return DateTime.tryParse(normalized)?.toUtc();
  }

  DateTime? _jogoDateTimeUtc(Map<String, dynamic> jogo) {
    final dataUtc = DateTime.tryParse(jogo['dataUtc']?.toString() ?? '');

    if (dataUtc != null) {
      return dataUtc.toUtc();
    }

    final dataLocal = DateTime.tryParse(jogo['dataLocal']?.toString() ?? '');

    if (dataLocal != null) {
      return dataLocal.toUtc();
    }

    return null;
  }

  String? _eventDateOnly(Map<String, dynamic> event) {
    final dateEvent = event['dateEvent']?.toString();

    if (dateEvent != null && dateEvent.length >= 10) {
      return dateEvent.substring(0, 10);
    }

    final timestampUtc = _apiEventDateTimeUtc(event);

    if (timestampUtc == null) {
      return null;
    }

    return _dateOnly(timestampUtc);
  }

  String? _jogoDateOnly(Map<String, dynamic> jogo) {
    final dataUtc = _jogoDateTimeUtc(jogo);

    if (dataUtc == null) {
      return null;
    }

    return _dateOnly(dataUtc);
  }

  String? _extractGroup(Map<String, dynamic> event) {
    final direct = event['strGroup']?.toString().trim();

    if (direct != null &&
        RegExp(r'^[A-L]$', caseSensitive: false).hasMatch(direct)) {
      return direct.toUpperCase();
    }

    final candidates = [
      event['strGroup'],
      event['strRound'],
      event['strDescriptionEN'],
      event['strEvent'],
    ];

    for (final candidate in candidates) {
      final text = candidate?.toString();

      if (text == null) {
        continue;
      }

      final match = RegExp(
        r'Group\s+([A-L])',
        caseSensitive: false,
      ).firstMatch(text);

      if (match != null) {
        return match.group(1)?.toUpperCase();
      }
    }

    return null;
  }

  String _dateOnly(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  String _timestampForPath(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    final second = date.second.toString().padLeft(2, '0');

    return '$year$month${day}_$hour$minute$second';
  }

  int? _asInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.toInt();
    }

    if (value is num) {
      return value.toInt();
    }

    final text = value.toString().trim();

    if (text.isEmpty) {
      return null;
    }

    return int.tryParse(text);
  }
}

class MergeResult {
  int eventosProcessados = 0;
  int eventosIgnoradosSemId = 0;

  int historicoAtualizadoPorIdEvent = 0;
  int historicoAtualizadoPorJogoId = 0;
  int historicoInserido = 0;

  int jogosAtualizados = 0;
  int jogosCriados = 0;
  int duplicatasApiRemovidas = 0;

  int eventosComMatchCanonico = 0;
  int eventosSemMatchCanonico = 0;
}
