import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/sistema_palpites.dart';
import '../core/sistema_pontuacao_participantes.dart';
import '../core/sistema_pontuacao_times.dart';
import '../core/functions/date_time_utils.dart';
import '../core/functions/palpite_match_groups.dart';
import '../core/functions/team_normalizer.dart';
import '../models/bolao_data.dart';
import '../models/historico_partida.dart';
import '../models/jogo.dart';
import '../models/palpite.dart';
import '../models/participante.dart';
import '../models/time_participante.dart';
import '../models/time_sportsdb.dart';
import '../models/venue_sportsdb.dart';
import 'asset_loader.dart';
import 'media_catalog_service.dart';
import 'sportsdb_api_service.dart';

enum PeriodoJogos {
  hoje,
  amanha,
  rodadaAtual,
  passados,
  emAndamento,
  futuros,
  todos,
}

enum OrdenacaoRanking { consolidado, projetado }

class BolaoController extends ChangeNotifier {
  BolaoController._({required this._data, required this._apiService}) {
    _recalcular();
    _reconstruirMidia();
  }

  final SportsDbApiService _apiService;

  BolaoData _data;
  List<LinhaPontuacaoParticipante> _classificacao = const [];
  List<LinhaPontuacaoParticipante> _classificacaoConsolidada = const [];
  List<LinhaPontuacaoParticipante> _classificacaoProjetada = const [];
  late ConjuntoTabelasGrupo _tabelasGrupos;

  final Map<String, SportsDbEvent> _eventoPorJogoId = {};
  final Map<String, SportsDbEventDetailsResult> _detalhesPorJogoId = {};
  final Set<String> _detalhesCarregando = {};
  BolaoMediaCatalog _mediaCatalog = const BolaoMediaCatalog.empty();

  bool _atualizandoApi = false;
  bool _autoRefreshIniciado = false;
  String? _mensagemAtualizacao;
  DateTime? _ultimaAtualizacao;
  DateTime? _proximaAtualizacao;
  SportsDbApiResult? _ultimoResultadoApi;
  OrdenacaoRanking _ordenacaoRanking = OrdenacaoRanking.consolidado;
  Timer? _refreshTimer;

  static const Duration autoRefreshInterval = Duration(seconds: 5);

  static Future<BolaoController> carregar({
    SportsDbApiService apiService = const SportsDbApiService(),
  }) async {
    final data = await AssetLoader.carregarBolaoData();
    return BolaoController._(data: data, apiService: apiService);
  }

  BolaoData get data => _data;

  List<LinhaPontuacaoParticipante> get classificacao => _classificacao;

  List<LinhaPontuacaoParticipante> get classificacaoConsolidada {
    return _classificacaoConsolidada;
  }

  List<LinhaPontuacaoParticipante> get classificacaoProjetada {
    return _classificacaoProjetada;
  }

  ConjuntoTabelasGrupo get tabelasGrupos => _tabelasGrupos;

  bool get atualizandoApi => _atualizandoApi;

  String? get mensagemAtualizacao => _mensagemAtualizacao;

  DateTime? get ultimaAtualizacao => _ultimaAtualizacao;

  DateTime? get proximaAtualizacao => _proximaAtualizacao;

  SportsDbApiResult? get ultimoResultadoApi => _ultimoResultadoApi;

  OrdenacaoRanking get ordenacaoRanking => _ordenacaoRanking;

  bool get ordenandoPorProjetado {
    return _ordenacaoRanking == OrdenacaoRanking.projetado;
  }

  List<Jogo> get jogosAoVivo {
    return _data.jogos
        .where((jogo) => jogo.isEmAndamento)
        .toList(growable: false)
      ..sort((a, b) => a.ordem.compareTo(b.ordem));
  }

  bool get temJogosAoVivo => jogosAoVivo.isNotEmpty;

  int get totalParticipantesComPalpite {
    return _participanteIdsComPalpite().length;
  }

  Set<String> get participanteIdsComPalpite {
    return Set.unmodifiable(_participanteIdsComPalpite());
  }

  List<TimeParticipante> get timesOrdenados {
    final result = [..._data.timesParticipantes];
    result.sort((a, b) {
      final group = a.grupo.compareTo(b.grupo);
      if (group != 0) {
        return group;
      }

      return a.nome.compareTo(b.nome);
    });
    return result;
  }

  Future<void> iniciarAtualizacaoAutomatica() async {
    if (_autoRefreshIniciado) {
      return;
    }

    _autoRefreshIniciado = true;
    _aplicarRelogioLocal();
    _atualizarProximaAtualizacao();
    notifyListeners();

    unawaited(atualizarApi(automatico: true));

    _refreshTimer = Timer.periodic(autoRefreshInterval, (_) {
      _aplicarRelogioLocal();

      if (temJogosAoVivo) {
        unawaited(atualizarApi(automatico: true));
      } else {
        _proximaAtualizacao = null;
        notifyListeners();
      }
    });
  }

  void alterarOrdenacaoRanking(OrdenacaoRanking value) {
    if (_ordenacaoRanking == value) {
      return;
    }

    _ordenacaoRanking = value;
    _atualizarClassificacaoExibida();
    notifyListeners();
  }

  Future<void> atualizarApi({bool automatico = false}) async {
    if (_atualizandoApi) {
      return;
    }

    var dadosMudaram = false;
    var relogioMudou = false;
    _atualizandoApi = true;
    _mensagemAtualizacao = automatico
        ? 'Atualizando placares ao vivo...'
        : 'Consultando a SportsDB...';
    if (!automatico) {
      notifyListeners();
    }

    try {
      final result = await _apiService.fetchRefreshResult(
        eventIds: _eventIdsParaLookupIndividual(),
      );
      _ultimoResultadoApi = result;

      if (!result.hasAnySuccessfulEndpoint) {
        _mensagemAtualizacao =
            'A SportsDB não respondeu. A base local foi preservada.';
        return;
      }

      final eventosPorJogo = _associarEventosAosJogos(result.events);
      final jogosAtualizados =
          _data.jogos
              .map(
                (jogo) =>
                    _mesclarJogoComEvento(jogo, eventosPorJogo[jogo.jogoId]),
              )
              .toList(growable: false)
            ..sort((a, b) => a.ordem.compareTo(b.ordem));

      dadosMudaram =
          !_jogosDinamicosIguais(_data.jogos, jogosAtualizados) ||
          !_eventosDinamicosIguais(_eventoPorJogoId, eventosPorJogo);

      if (dadosMudaram) {
        _eventoPorJogoId
          ..clear()
          ..addAll(eventosPorJogo);

        _data = _data.copyWith(jogos: jogosAtualizados);
        for (final jogo in jogosAtualizados.where(
          (jogo) => jogo.isEmAndamento,
        )) {
          _detalhesPorJogoId.remove(jogo.jogoId);
        }

        _recalcular();
        _reconstruirMidia();
      }

      _ultimaAtualizacao = DateTime.now();
      _mensagemAtualizacao = result.hasAnyFailedEndpoint
          ? '${result.summaryText} Dados válidos foram aplicados; a base local foi mantida nos endpoints com falha.'
          : result.summaryText;
    } catch (error) {
      _mensagemAtualizacao =
          'Não foi possível atualizar a API. A base local continua ativa. $error';
    } finally {
      relogioMudou = _aplicarRelogioLocal(notificar: false);
      _atualizarProximaAtualizacao();
      _atualizandoApi = false;
      if (!automatico || dadosMudaram || relogioMudou) {
        notifyListeners();
      }
    }
  }

  Jogo? jogoPorId(String jogoId) {
    return _data.jogosPorId[jogoId];
  }

  Participante? participantePorId(String participanteId) {
    return _data.participantesPorId[participanteId];
  }

  HistoricoPartida? historicoDoJogo(String jogoId) {
    return _data.historicoPorJogoId[jogoId];
  }

  SportsDbEvent? eventoDoJogo(String jogoId) {
    return _eventoPorJogoId[jogoId];
  }

  SportsDbEventDetailsResult? detalhesEventoDoJogo(String jogoId) {
    return _detalhesPorJogoId[jogoId];
  }

  bool carregandoDetalhesEvento(String jogoId) {
    return _detalhesCarregando.contains(jogoId);
  }

  Future<void> carregarDetalhesEventoDoJogo(String jogoId) async {
    if (_detalhesPorJogoId.containsKey(jogoId) ||
        _detalhesCarregando.contains(jogoId)) {
      return;
    }

    final jogo = jogoPorId(jogoId);
    final eventId = jogo?.idEventAtual ?? historicoDoJogo(jogoId)?.idEvent;
    if (eventId == null || eventId.trim().isEmpty) {
      return;
    }

    _detalhesCarregando.add(jogoId);
    notifyListeners();

    try {
      final details = await _apiService.fetchEventDetails(eventId);
      _detalhesPorJogoId[jogoId] = details;
    } catch (_) {
      _detalhesPorJogoId[jogoId] = SportsDbEventDetailsResult(
        eventId: eventId,
        timeline: const [],
        lineup: const [],
        results: const [],
        stats: const [],
        endpoints: const [],
      );
    } finally {
      _detalhesCarregando.remove(jogoId);
      notifyListeners();
    }
  }

  LinhaPontuacaoParticipante? linhaParticipante(String participanteId) {
    for (final linha in _classificacao) {
      if (linha.participanteId == participanteId) {
        return linha;
      }
    }

    return null;
  }

  Palpite? palpiteDoParticipanteNoJogo({
    required String participanteId,
    required String jogoId,
  }) {
    for (final palpite in _data.palpites) {
      if (palpite.participanteId == participanteId &&
          palpite.jogoId == jogoId) {
        return palpite;
      }
    }

    return null;
  }

  PontuacaoPalpite? pontuacaoDoParticipanteNoJogo({
    required String participanteId,
    required String jogoId,
  }) {
    final linha = _linhaEm(_classificacaoProjetada, participanteId);
    if (linha == null) {
      return null;
    }

    for (final pontuacao in linha.pontuacoesPalpites) {
      if (pontuacao.jogoId == jogoId) {
        return pontuacao;
      }
    }

    return null;
  }

  List<Jogo> jogosPorPeriodo(PeriodoJogos periodo) {
    final nowUtc = DateTime.now().toUtc();
    final hojeBrasilia = AppDateTime.agoraBrasilia();
    final amanhaBrasilia = hojeBrasilia.add(const Duration(days: 1));
    final rodadaAtual = _rodadaAtualFaseDeGrupos();

    final result =
        _data.jogos
            .where((jogo) {
              if (periodo == PeriodoJogos.todos) {
                return true;
              }

              if (jogo.isEmAndamento) {
                return periodo == PeriodoJogos.emAndamento ||
                    periodo == PeriodoJogos.hoje;
              }

              if (periodo == PeriodoJogos.hoje) {
                final date = AppDateTime.horarioBrasilia(jogo);
                return date != null && AppDateTime.mesmoDia(date, hojeBrasilia);
              }

              if (periodo == PeriodoJogos.amanha) {
                final date = AppDateTime.horarioBrasilia(jogo);
                return date != null &&
                    AppDateTime.mesmoDia(date, amanhaBrasilia);
              }

              if (periodo == PeriodoJogos.rodadaAtual) {
                return rodadaAtual != null &&
                    jogo.isFaseDeGrupos &&
                    jogo.rodada == rodadaAtual;
              }

              final date = jogo.dataUtc?.toUtc();
              if (date == null) {
                return periodo == PeriodoJogos.futuros;
              }

              switch (periodo) {
                case PeriodoJogos.hoje:
                  return false;
                case PeriodoJogos.amanha:
                  return false;
                case PeriodoJogos.rodadaAtual:
                  return false;
                case PeriodoJogos.passados:
                  return jogo.isEncerrado || date.isBefore(nowUtc);
                case PeriodoJogos.emAndamento:
                  return jogo.isEmAndamento;
                case PeriodoJogos.futuros:
                  final brasiliaDate = AppDateTime.horarioBrasilia(jogo);
                  return jogo.isAgendado &&
                      date.isAfter(nowUtc) &&
                      (brasiliaDate == null ||
                          !AppDateTime.mesmoDia(brasiliaDate, hojeBrasilia));
                case PeriodoJogos.todos:
                  return true;
              }
            })
            .toList(growable: false)
          ..sort((a, b) => a.ordem.compareTo(b.ordem));

    return result;
  }

  TimeParticipante? timeParticipantePorNome(String nomeTime) {
    final key = TeamNormalizer.key(nomeTime);

    for (final time in _data.timesParticipantes) {
      if (TeamNormalizer.key(time.nome) == key ||
          TeamNormalizer.key(time.timeId) == key ||
          TeamNormalizer.key(time.nomeNormalizado) == key) {
        return time;
      }
    }

    return null;
  }

  List<Jogo> jogosDoTime(String nomeTime) {
    final key = TeamNormalizer.key(nomeTime);

    final result = _data.jogosOrdenados
        .where((jogo) {
          return TeamNormalizer.key(jogo.mandantePrevisto) == key ||
              TeamNormalizer.key(jogo.visitantePrevisto) == key;
        })
        .toList(growable: false);

    return result;
  }

  List<Jogo> get proximosDestaques {
    final emAndamento =
        _data.jogos.where((jogo) => jogo.isEmAndamento).toList(growable: false)
          ..sort((a, b) => a.ordem.compareTo(b.ordem));

    if (emAndamento.isNotEmpty) {
      return emAndamento;
    }

    final nowUtc = DateTime.now().toUtc();
    final futuros =
        _data.jogos
            .where((jogo) {
              final date = jogo.dataUtc?.toUtc();
              return date != null && date.isAfter(nowUtc);
            })
            .toList(growable: false)
          ..sort((a, b) {
            final dateA = a.dataUtc?.toUtc();
            final dateB = b.dataUtc?.toUtc();
            if (dateA == null || dateB == null) {
              return a.ordem.compareTo(b.ordem);
            }
            return dateA.compareTo(dateB);
          });

    if (futuros.isEmpty) {
      final encerrados =
          _data.jogos.where((jogo) => jogo.isEncerrado).toList(growable: false)
            ..sort((a, b) => b.ordem.compareTo(a.ordem));
      return encerrados.take(1).toList(growable: false);
    }

    final firstDate = futuros.first.dataUtc!.toUtc();
    return futuros
        .where((jogo) {
          final date = jogo.dataUtc?.toUtc();
          return date != null &&
              date.difference(firstDate).inMinutes.abs() <= 1;
        })
        .toList(growable: false);
  }

  String? badgeDoTime(String nomeTime) {
    return _mediaCatalog.badgeForTeam(nomeTime);
  }

  String? imagemDoEstadio(String jogoId) {
    return _mediaCatalog.imageForMatch(jogoId);
  }

  String? videoDoJogo(String jogoId) {
    return _mediaCatalog.videoForMatch(jogoId);
  }

  String? tempoAtualDoJogo(Jogo jogo) {
    if (!jogo.isEmAndamento) {
      return null;
    }

    final eventStatus = _eventoPorJogoId[jogo.jogoId]?.strStatus?.trim();
    final statusMinute = _minuteFromStatus(eventStatus);
    if (statusMinute != null) {
      return "$statusMinute'";
    }

    final kickoff = jogo.dataUtc?.toUtc();
    if (kickoff == null) {
      return eventStatus == null || eventStatus.isEmpty ? null : eventStatus;
    }

    final elapsed = DateTime.now().toUtc().difference(kickoff).inMinutes;
    if (elapsed < 0) {
      return null;
    }

    if (elapsed <= 45) {
      return "${elapsed.clamp(1, 45)}'";
    }

    if (elapsed <= 60) {
      return 'Intervalo';
    }

    final secondHalfMinute = (elapsed - 15).clamp(46, 120);
    return "aprox. $secondHalfMinute'";
  }

  TimeSportsDb? timeSportsDb(String nomeTime) {
    return _mediaCatalog.teamForName(nomeTime);
  }

  VenueSportsDb? venueDoJogo(Jogo jogo) {
    return _mediaCatalog.venueForMatch(_data, jogo);
  }

  int pontosAoVivo(String participanteId) {
    final projetada = _linhaEm(
      _classificacaoProjetada,
      participanteId,
    )?.pontosTotal;
    final consolidada = _linhaEm(
      _classificacaoConsolidada,
      participanteId,
    )?.pontosTotal;

    if (projetada == null || consolidada == null) {
      return 0;
    }

    return projetada - consolidada;
  }

  int pontosConsolidados(String participanteId) {
    return _linhaEm(_classificacaoConsolidada, participanteId)?.pontosTotal ??
        0;
  }

  LinhaPontuacaoParticipante? linhaProjetadaParticipante(
    String participanteId,
  ) {
    return _linhaEm(_classificacaoProjetada, participanteId);
  }

  List<GrupoPalpitesJogo> gruposDePalpitesDoJogo(String jogoId) {
    final jogo = jogoPorId(jogoId);
    if (jogo == null) {
      return const [];
    }

    return PalpiteMatchGroups.build(
      jogo: jogo,
      ranking: _classificacaoProjetada,
      palpiteFor: (participanteId) => palpiteDoParticipanteNoJogo(
        participanteId: participanteId,
        jogoId: jogoId,
      ),
      pontuacaoFor: (participanteId) => pontuacaoDoParticipanteNoJogo(
        participanteId: participanteId,
        jogoId: jogoId,
      ),
    );
  }

  LinhaTabelaTime? linhaDoTimeNoGrupo({
    required String nomeTime,
    required String? grupo,
  }) {
    if (grupo == null || grupo.isEmpty) {
      return null;
    }

    final tabela = _tabelasGrupos.tabela(grupo);
    if (tabela == null) {
      return null;
    }

    final key = TeamNormalizer.key(nomeTime);
    for (final linha in tabela.linhas) {
      if (linha.timeKey == key) {
        return linha;
      }
    }

    return null;
  }

  void _recalcular() {
    _tabelasGrupos = SistemaPontuacaoTimes.calcularTabelasReais(_data.jogos);
    _classificacaoProjetada = _filtrarEReordenarParticipantesVisiveis(
      SistemaPontuacaoParticipantes.calcularClassificacao(_data),
    );
    _classificacaoConsolidada = _filtrarEReordenarParticipantesVisiveis(
      SistemaPontuacaoParticipantes.calcularClassificacao(
        _dataSemJogosAoVivo(),
      ),
    );
    if (!temJogosAoVivo) {
      _ordenacaoRanking = OrdenacaoRanking.consolidado;
    }
    _atualizarClassificacaoExibida();
  }

  List<LinhaPontuacaoParticipante> _filtrarEReordenarParticipantesVisiveis(
    List<LinhaPontuacaoParticipante> linhas,
  ) {
    final ativos = _participanteIdsComPalpite();
    final visiveis = linhas
        .where((linha) => ativos.contains(linha.participanteId))
        .toList(growable: false);

    return [
      for (var index = 0; index < visiveis.length; index++)
        visiveis[index].copyWith(posicao: index + 1),
    ];
  }

  Set<String> _participanteIdsComPalpite() {
    final result = <String>{};

    for (final participante in _data.participantes) {
      if (participante.jogosPalpitados > 0) {
        result.add(participante.participanteId);
      }
    }

    for (final palpite in _data.palpites) {
      if (palpite.isCompleto) {
        result.add(palpite.participanteId);
      }
    }

    return result;
  }

  List<String> _eventIdsParaLookupIndividual() {
    final nowUtc = DateTime.now().toUtc();
    final windowStart = nowUtc.subtract(const Duration(hours: 12));
    final windowEnd = nowUtc.add(const Duration(hours: 36));

    final candidates =
        _data.jogos
            .where((jogo) => jogo.idEventAtual != null)
            .where((jogo) {
              if (jogo.isEmAndamento) {
                return true;
              }

              final kickoff = jogo.dataUtc?.toUtc();
              if (kickoff == null) {
                return false;
              }

              return !kickoff.isBefore(windowStart) &&
                  !kickoff.isAfter(windowEnd);
            })
            .toList(growable: false)
          ..sort((a, b) {
            final aDate = a.dataUtc?.toUtc();
            final bDate = b.dataUtc?.toUtc();
            if (aDate == null || bDate == null) {
              return a.ordem.compareTo(b.ordem);
            }

            final aDistance = aDate.difference(nowUtc).inMinutes.abs();
            final bDistance = bDate.difference(nowUtc).inMinutes.abs();
            return aDistance.compareTo(bDistance);
          });

    return candidates
        .map((jogo) => jogo.idEventAtual!)
        .toSet()
        .take(16)
        .toList(growable: false);
  }

  void _atualizarClassificacaoExibida() {
    _classificacao = _ordenacaoRanking == OrdenacaoRanking.projetado
        ? _classificacaoProjetada
        : _classificacaoConsolidada;
  }

  Map<String, SportsDbEvent> _associarEventosAosJogos(
    List<SportsDbEvent> events,
  ) {
    final byIdEvent = <String, SportsDbEvent>{
      for (final event in events) event.idEvent: event,
    };
    final result = <String, SportsDbEvent>{};

    for (final jogo in _data.jogos) {
      SportsDbEvent? matched;

      if (jogo.idEventAtual != null) {
        matched = byIdEvent[jogo.idEventAtual!];
      }

      matched ??= _buscarEventoPorTimesEHorario(jogo, events);

      if (matched != null) {
        result[jogo.jogoId] = matched;
      }
    }

    return result;
  }

  SportsDbEvent? _buscarEventoPorTimesEHorario(
    Jogo jogo,
    List<SportsDbEvent> events,
  ) {
    final homeKey = TeamNormalizer.key(jogo.mandantePrevisto);
    final awayKey = TeamNormalizer.key(jogo.visitantePrevisto);

    if (homeKey.isEmpty || awayKey.isEmpty) {
      return null;
    }

    SportsDbEvent? best;
    var bestDifference = 999999;

    for (final event in events) {
      final eventHome = TeamNormalizer.key(event.strHomeTeam ?? '');
      final eventAway = TeamNormalizer.key(event.strAwayTeam ?? '');
      final sameOrder = eventHome == homeKey && eventAway == awayKey;
      final invertedOrder = eventHome == awayKey && eventAway == homeKey;

      if (!sameOrder && !invertedOrder) {
        continue;
      }

      if (jogo.dataUtc != null && event.strTimestampUtc != null) {
        final difference = jogo.dataUtc!
            .toUtc()
            .difference(event.strTimestampUtc!)
            .inMinutes
            .abs();

        if (difference < bestDifference) {
          bestDifference = difference;
          best = event;
        }
      } else {
        best ??= event;
      }
    }

    if (best == null) {
      return null;
    }

    if (bestDifference == 999999 || bestDifference <= 36 * 60) {
      return best;
    }

    return null;
  }

  Jogo _mesclarJogoComEvento(Jogo jogo, SportsDbEvent? event) {
    if (event == null) {
      return jogo;
    }

    final eventStatus = event.statusCanonico;
    final finalInferredByClock = event.isEncerradoInferidoPorRelogio;
    final finalResult =
        jogo.resultadoFinal || event.isFinal || finalInferredByClock;
    final scoreUsable =
        event.temPlacar && (finalResult || eventStatus == 'em_andamento');
    final liveWithoutScore = !event.temPlacar && eventStatus == 'em_andamento';
    final hasResult = jogo.temResultado || scoreUsable || liveWithoutScore;
    final homeScore = scoreUsable
        ? event.intHomeScore
        : liveWithoutScore
        ? 0
        : jogo.golsMandante;
    final awayScore = scoreUsable
        ? event.intAwayScore
        : liveWithoutScore
        ? 0
        : jogo.golsVisitante;

    final status = finalResult
        ? 'encerrado'
        : eventStatus == 'encerrado'
        ? 'encerrado'
        : eventStatus;

    return jogo.copyWith(
      idEventAtual: event.idEvent,
      statusJogo: status,
      golsMandante: homeScore,
      golsVisitante: awayScore,
      vencedor: _vencedor(
        jogo.mandantePrevisto,
        jogo.visitantePrevisto,
        homeScore,
        awayScore,
      ),
      temHistoricoApi: true,
      temResultadoApi: jogo.temResultadoApi || scoreUsable,
      temResultado: hasResult,
      resultadoFinal: finalResult,
      fonteResultado: scoreUsable
          ? finalInferredByClock
                ? 'sportsdb_encerrado_por_relogio'
                : 'sportsdb_refresh'
          : liveWithoutScore
          ? 'sportsdb_ao_vivo_zerado'
          : jogo.fonteResultado,
    );
  }

  String? _vencedor(
    String mandante,
    String visitante,
    int? golsMandante,
    int? golsVisitante,
  ) {
    if (golsMandante == null || golsVisitante == null) {
      return null;
    }

    if (golsMandante > golsVisitante) {
      return mandante;
    }

    if (golsVisitante > golsMandante) {
      return visitante;
    }

    return 'empate';
  }

  void _reconstruirMidia() {
    _mediaCatalog = MediaCatalogService.build(
      data: _data,
      eventosPorJogoId: _eventoPorJogoId,
    );
  }

  BolaoData _dataSemJogosAoVivo() {
    final jogos = _data.jogos
        .map((jogo) {
          if (!jogo.isEmAndamento || jogo.resultadoFinal) {
            return jogo;
          }

          return Jogo.fromJson({
            ...jogo.toJson(),
            'golsMandante': null,
            'golsVisitante': null,
            'temResultado': false,
            'resultadoFinal': false,
            'fonteResultado': null,
          });
        })
        .toList(growable: false);

    return _data.copyWith(jogos: jogos);
  }

  bool _aplicarRelogioLocal({bool notificar = true}) {
    final nowUtc = DateTime.now().toUtc();
    var mudou = false;

    final jogos = _data.jogos
        .map((jogo) {
          if (jogo.resultadoFinal) {
            return jogo;
          }

          final kickoff = jogo.dataUtc?.toUtc();
          if (kickoff == null) {
            return jogo;
          }

          final elapsed = nowUtc.difference(kickoff).inMinutes;
          final deveEstarAoVivo =
              elapsed >= 0 &&
              elapsed <= SportsDbEvent.maxLiveDuration.inMinutes;

          if (!deveEstarAoVivo) {
            if (jogo.isEmAndamento &&
                elapsed > SportsDbEvent.maxLiveDuration.inMinutes) {
              mudou = true;

              return Jogo.fromJson({
                ...jogo.toJson(),
                'statusJogo': 'encerrado',
                'golsMandante': jogo.temResultadoApi ? jogo.golsMandante : null,
                'golsVisitante': jogo.temResultadoApi
                    ? jogo.golsVisitante
                    : null,
                'temResultado': jogo.temResultadoApi,
                'resultadoFinal': jogo.temResultadoApi,
                'fonteResultado': jogo.temResultadoApi
                    ? jogo.fonteResultado ?? 'encerrado_por_relogio'
                    : null,
              });
            }

            return jogo;
          }

          if (jogo.isEmAndamento &&
              jogo.golsMandante != null &&
              jogo.golsVisitante != null &&
              jogo.temResultado) {
            return jogo;
          }

          mudou = true;

          return Jogo.fromJson({
            ...jogo.toJson(),
            'statusJogo': 'em_andamento',
            'golsMandante': jogo.golsMandante ?? 0,
            'golsVisitante': jogo.golsVisitante ?? 0,
            'temResultado': true,
            'resultadoFinal': false,
            'fonteResultado': jogo.fonteResultado ?? 'relogio_local_ao_vivo',
          });
        })
        .toList(growable: false);

    if (!mudou) {
      return false;
    }

    _data = _data.copyWith(jogos: jogos);
    _recalcular();

    if (notificar) {
      notifyListeners();
    }

    return true;
  }

  void _atualizarProximaAtualizacao() {
    _proximaAtualizacao = temJogosAoVivo
        ? DateTime.now().add(autoRefreshInterval)
        : null;
  }

  int? _rodadaAtualFaseDeGrupos() {
    final jogosGrupo = _data.jogos
        .where((jogo) => jogo.isFaseDeGrupos && jogo.rodada != null)
        .toList(growable: false);

    if (jogosGrupo.isEmpty) {
      return null;
    }

    final aoVivo = jogosGrupo.where((jogo) => jogo.isEmAndamento).toList();
    if (aoVivo.isNotEmpty) {
      aoVivo.sort((a, b) => a.ordem.compareTo(b.ordem));
      return aoVivo.first.rodada;
    }

    final hoje = AppDateTime.agoraBrasilia();
    final hojeJogos = jogosGrupo.where((jogo) {
      final date = AppDateTime.horarioBrasilia(jogo);
      return date != null && AppDateTime.mesmoDia(date, hoje);
    }).toList();
    if (hojeJogos.isNotEmpty) {
      hojeJogos.sort((a, b) => a.ordem.compareTo(b.ordem));
      return hojeJogos.first.rodada;
    }

    final nowUtc = DateTime.now().toUtc();
    final futuros = jogosGrupo.where((jogo) {
      final date = jogo.dataUtc?.toUtc();
      return date != null && date.isAfter(nowUtc);
    }).toList();
    if (futuros.isNotEmpty) {
      futuros.sort((a, b) {
        final dateA = a.dataUtc?.toUtc();
        final dateB = b.dataUtc?.toUtc();
        if (dateA == null || dateB == null) {
          return a.ordem.compareTo(b.ordem);
        }
        return dateA.compareTo(dateB);
      });
      return futuros.first.rodada;
    }

    jogosGrupo.sort((a, b) => b.ordem.compareTo(a.ordem));
    return jogosGrupo.first.rodada;
  }

  int? _minuteFromStatus(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    final match = RegExp(r'^(\d{1,3})').firstMatch(value);
    return int.tryParse(match?.group(1) ?? '');
  }

  LinhaPontuacaoParticipante? _linhaEm(
    List<LinhaPontuacaoParticipante> linhas,
    String participanteId,
  ) {
    for (final linha in linhas) {
      if (linha.participanteId == participanteId) {
        return linha;
      }
    }

    return null;
  }

  bool _jogosDinamicosIguais(List<Jogo> atuais, List<Jogo> novos) {
    if (atuais.length != novos.length) {
      return false;
    }

    final atuaisPorId = {for (final jogo in atuais) jogo.jogoId: jogo};

    for (final novo in novos) {
      final atual = atuaisPorId[novo.jogoId];
      if (atual == null || !_jogoDinamicoIgual(atual, novo)) {
        return false;
      }
    }

    return true;
  }

  bool _jogoDinamicoIgual(Jogo atual, Jogo novo) {
    return atual.idEventAtual == novo.idEventAtual &&
        atual.statusJogo == novo.statusJogo &&
        atual.golsMandante == novo.golsMandante &&
        atual.golsVisitante == novo.golsVisitante &&
        atual.vencedor == novo.vencedor &&
        atual.temHistoricoApi == novo.temHistoricoApi &&
        atual.temResultadoApi == novo.temResultadoApi &&
        atual.temResultado == novo.temResultado &&
        atual.resultadoFinal == novo.resultadoFinal &&
        atual.fonteResultado == novo.fonteResultado;
  }

  bool _eventosDinamicosIguais(
    Map<String, SportsDbEvent> atuais,
    Map<String, SportsDbEvent> novos,
  ) {
    if (atuais.length != novos.length) {
      return false;
    }

    for (final entry in novos.entries) {
      final atual = atuais[entry.key];
      if (atual == null || !_eventoDinamicoIgual(atual, entry.value)) {
        return false;
      }
    }

    return true;
  }

  bool _eventoDinamicoIgual(SportsDbEvent atual, SportsDbEvent novo) {
    return atual.idEvent == novo.idEvent &&
        atual.strStatus == novo.strStatus &&
        atual.intHomeScore == novo.intHomeScore &&
        atual.intAwayScore == novo.intAwayScore &&
        atual.strTimestampUtc == novo.strTimestampUtc &&
        atual.strHomeTeamBadge == novo.strHomeTeamBadge &&
        atual.strAwayTeamBadge == novo.strAwayTeamBadge &&
        atual.stadiumImage == novo.stadiumImage &&
        atual.strVideo == novo.strVideo;
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
