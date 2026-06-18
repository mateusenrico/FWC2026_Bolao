import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/sistema_palpites.dart';
import '../core/sistema_pontuacao_participantes.dart';
import '../core/sistema_pontuacao_times.dart';
import '../core/functions/team_normalizer.dart';
import '../models/bolao_data.dart';
import '../models/historico_partida.dart';
import '../models/jogo.dart';
import '../models/palpite.dart';
import '../models/participante.dart';
import '../models/time_sportsdb.dart';
import '../models/venue_sportsdb.dart';
import 'asset_loader.dart';
import 'sportsdb_api_service.dart';

enum PeriodoJogos { passados, emAndamento, futuros }

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
  final Map<String, String> _badgePorTimeKey = {};
  final Map<String, String> _imagemEstadioPorJogoId = {};
  final Map<String, TimeSportsDb> _timeSportsDbPorKey = {};
  final Map<String, VenueSportsDb> _venueSportsDbPorKey = {};
  final Map<String, VenueSportsDb> _venueSportsDbPorId = {};
  final Map<String, String> _videoPorJogoId = {};

  bool _atualizandoApi = false;
  bool _autoRefreshIniciado = false;
  String? _mensagemAtualizacao;
  DateTime? _ultimaAtualizacao;
  DateTime? _proximaAtualizacao;
  SportsDbApiResult? _ultimoResultadoApi;
  OrdenacaoRanking _ordenacaoRanking = OrdenacaoRanking.consolidado;
  Timer? _refreshTimer;

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

  Future<void> iniciarAtualizacaoAutomatica() async {
    if (_autoRefreshIniciado) {
      return;
    }

    _autoRefreshIniciado = true;
    _aplicarRelogioLocal();
    _atualizarProximaAtualizacao();
    notifyListeners();

    unawaited(atualizarApi(automatico: true));

    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
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

    _atualizandoApi = true;
    _mensagemAtualizacao = automatico
        ? 'Atualizando placares ao vivo...'
        : 'Consultando a SportsDB...';
    notifyListeners();

    try {
      final result = await _apiService.fetchRefreshResult();
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

      _eventoPorJogoId
        ..clear()
        ..addAll(eventosPorJogo);

      _data = _data.copyWith(jogos: jogosAtualizados);
      _ultimaAtualizacao = DateTime.now();
      _mensagemAtualizacao = result.hasAnyFailedEndpoint
          ? '${result.summaryText} Dados válidos foram aplicados; a base local foi mantida nos endpoints com falha.'
          : result.summaryText;

      _recalcular();
      _reconstruirMidia();
    } catch (error) {
      _mensagemAtualizacao =
          'Não foi possível atualizar a API. A base local continua ativa. $error';
    } finally {
      _aplicarRelogioLocal(notificar: false);
      _atualizarProximaAtualizacao();
      _atualizandoApi = false;
      notifyListeners();
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

    final result =
        _data.jogos
            .where((jogo) {
              if (jogo.isEmAndamento) {
                return periodo == PeriodoJogos.emAndamento;
              }

              final date = jogo.dataUtc?.toUtc();
              if (date == null) {
                return periodo == PeriodoJogos.futuros;
              }

              switch (periodo) {
                case PeriodoJogos.passados:
                  return jogo.isEncerrado || date.isBefore(nowUtc);
                case PeriodoJogos.emAndamento:
                  return jogo.isEmAndamento;
                case PeriodoJogos.futuros:
                  return jogo.isAgendado && date.isAfter(nowUtc);
              }
            })
            .toList(growable: false)
          ..sort((a, b) => a.ordem.compareTo(b.ordem));

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
    return _badgePorTimeKey[TeamNormalizer.key(nomeTime)];
  }

  String? imagemDoEstadio(String jogoId) {
    return _imagemEstadioPorJogoId[jogoId];
  }

  String? videoDoJogo(String jogoId) {
    return _videoPorJogoId[jogoId];
  }

  TimeSportsDb? timeSportsDb(String nomeTime) {
    return _timeSportsDbPorKey[TeamNormalizer.key(nomeTime)];
  }

  VenueSportsDb? venueDoJogo(Jogo jogo) {
    final historico = historicoDoJogo(jogo.jogoId);
    final idVenue = historico?.raw['idVenue']?.toString();

    if (idVenue != null && idVenue.isNotEmpty) {
      final byId = _venueSportsDbPorId[idVenue];
      if (byId != null) {
        return byId;
      }
    }

    return _venueSportsDbPorKey[_venueKey(jogo.estadio)];
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
    _classificacaoProjetada =
        SistemaPontuacaoParticipantes.calcularClassificacao(_data);
    _classificacaoConsolidada =
        SistemaPontuacaoParticipantes.calcularClassificacao(
          _dataSemJogosAoVivo(),
        );
    _atualizarClassificacaoExibida();
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

    final scoreUsable =
        event.temPlacar &&
        (event.isFinal || event.statusCanonico == 'em_andamento');
    final liveWithoutScore =
        !event.temPlacar && event.statusCanonico == 'em_andamento';
    final finalResult = jogo.resultadoFinal || event.isFinal;
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
        : event.statusCanonico == 'encerrado' && !scoreUsable
        ? jogo.statusJogo
        : event.statusCanonico;

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
          ? 'sportsdb_refresh'
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
    _badgePorTimeKey.clear();
    _imagemEstadioPorJogoId.clear();
    _timeSportsDbPorKey
      ..clear()
      ..addAll(_data.timesSportsDbPorKey);
    _venueSportsDbPorKey
      ..clear()
      ..addAll(_data.venuesSportsDbPorKey);
    _venueSportsDbPorId
      ..clear()
      ..addAll(_data.venuesSportsDbPorId);
    _videoPorJogoId.clear();

    for (final time in _data.timesSportsDb) {
      _adicionarBadge(time.nomeBolao, time.badgeUrl);
      if (time.nomeApi != null) {
        _adicionarBadge(time.nomeApi, time.badgeUrl);
      }
    }

    for (final historico in _data.historicoPartidas) {
      _adicionarBadge(
        historico.strHomeTeam,
        historico.raw['strHomeTeamBadge']?.toString(),
      );
      _adicionarBadge(
        historico.strAwayTeam,
        historico.raw['strAwayTeamBadge']?.toString(),
      );

      final image = _primeiraUrl([
        historico.raw['strThumb']?.toString(),
        historico.raw['strPoster']?.toString(),
        historico.raw['strFanart']?.toString(),
        historico.raw['strBanner']?.toString(),
      ]);

      if (image != null) {
        _imagemEstadioPorJogoId[historico.jogoId] = image;
      }

      final video = _primeiraUrl([historico.raw['strVideo']?.toString()]);
      if (video != null) {
        _videoPorJogoId[historico.jogoId] = video;
      }
    }

    for (final jogo in _data.jogos) {
      final venue = venueDoJogo(jogo);
      final image = venue?.melhorImagem;
      if (image != null && !_imagemEstadioPorJogoId.containsKey(jogo.jogoId)) {
        _imagemEstadioPorJogoId[jogo.jogoId] = image;
      }
    }

    for (final entry in _eventoPorJogoId.entries) {
      final event = entry.value;
      _adicionarBadge(event.strHomeTeam, event.strHomeTeamBadge);
      _adicionarBadge(event.strAwayTeam, event.strAwayTeamBadge);

      final image = event.stadiumImage;
      if (image != null && image.isNotEmpty) {
        _imagemEstadioPorJogoId[entry.key] = image;
      }

      final video = event.strVideo;
      if (video != null && video.isNotEmpty) {
        _videoPorJogoId[entry.key] = video;
      }
    }
  }

  void _adicionarBadge(String? teamName, String? url) {
    if (teamName == null || url == null || url.isEmpty) {
      return;
    }

    _badgePorTimeKey[TeamNormalizer.key(teamName)] = url;
  }

  String? _primeiraUrl(List<String?> values) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) {
        return value;
      }
    }

    return null;
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

  void _aplicarRelogioLocal({bool notificar = true}) {
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
          final deveEstarAoVivo = elapsed >= 0 && elapsed <= 180;

          if (!deveEstarAoVivo) {
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
      return;
    }

    _data = _data.copyWith(jogos: jogos);
    _recalcular();

    if (notificar) {
      notifyListeners();
    }
  }

  void _atualizarProximaAtualizacao() {
    _proximaAtualizacao = temJogosAoVivo
        ? DateTime.now().add(const Duration(minutes: 1))
        : null;
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

  String _venueKey(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
