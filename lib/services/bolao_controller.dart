import 'package:flutter/foundation.dart';

import '../core/functions/date_time_utils.dart';
import '../core/sistema_palpites.dart';
import '../core/sistema_pontuacao_participantes.dart';
import '../core/sistema_pontuacao_times.dart';
import '../core/functions/team_normalizer.dart';
import '../models/bolao_data.dart';
import '../models/historico_partida.dart';
import '../models/jogo.dart';
import '../models/palpite.dart';
import '../models/participante.dart';
import 'asset_loader.dart';
import 'sportsdb_api_service.dart';

enum PeriodoJogos { passados, hoje, semana, futuros }

class BolaoController extends ChangeNotifier {
  BolaoController._({required this._data, required this._apiService}) {
    _recalcular();
    _reconstruirMidia();
  }

  final SportsDbApiService _apiService;

  BolaoData _data;
  List<LinhaPontuacaoParticipante> _classificacao = const [];
  late ConjuntoTabelasGrupo _tabelasGrupos;

  final Map<String, SportsDbEvent> _eventoPorJogoId = {};
  final Map<String, String> _badgePorTimeKey = {};
  final Map<String, String> _imagemEstadioPorJogoId = {};

  bool _atualizandoApi = false;
  String? _mensagemAtualizacao;
  DateTime? _ultimaAtualizacao;
  SportsDbApiResult? _ultimoResultadoApi;

  static Future<BolaoController> carregar({
    SportsDbApiService apiService = const SportsDbApiService(),
  }) async {
    final data = await AssetLoader.carregarBolaoData();
    return BolaoController._(data: data, apiService: apiService);
  }

  BolaoData get data => _data;

  List<LinhaPontuacaoParticipante> get classificacao => _classificacao;

  ConjuntoTabelasGrupo get tabelasGrupos => _tabelasGrupos;

  bool get atualizandoApi => _atualizandoApi;

  String? get mensagemAtualizacao => _mensagemAtualizacao;

  DateTime? get ultimaAtualizacao => _ultimaAtualizacao;

  SportsDbApiResult? get ultimoResultadoApi => _ultimoResultadoApi;

  Future<void> atualizarApi() async {
    if (_atualizandoApi) {
      return;
    }

    _atualizandoApi = true;
    _mensagemAtualizacao = 'Consultando a SportsDB...';
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
    final linha = linhaParticipante(participanteId);
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
    final now = AppDateTime.agoraBrasilia();
    final today = AppDateTime.inicioDoDia(now);
    final tomorrow = today.add(const Duration(days: 1));
    final weekLimit = today.add(const Duration(days: 7));

    final result =
        _data.jogos
            .where((jogo) {
              final date = AppDateTime.horarioBrasilia(jogo);
              if (date == null) {
                return periodo == PeriodoJogos.futuros;
              }

              switch (periodo) {
                case PeriodoJogos.passados:
                  return date.isBefore(today);
                case PeriodoJogos.hoje:
                  return !date.isBefore(today) && date.isBefore(tomorrow);
                case PeriodoJogos.semana:
                  return !date.isBefore(tomorrow) && date.isBefore(weekLimit);
                case PeriodoJogos.futuros:
                  return !date.isBefore(weekLimit);
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
    _classificacao = SistemaPontuacaoParticipantes.calcularClassificacao(_data);
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
    final finalResult = jogo.resultadoFinal || event.isFinal;
    final hasResult = jogo.temResultado || scoreUsable;
    final homeScore = scoreUsable ? event.intHomeScore : jogo.golsMandante;
    final awayScore = scoreUsable ? event.intAwayScore : jogo.golsVisitante;

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
      fonteResultado: scoreUsable ? 'sportsdb_refresh' : jogo.fonteResultado,
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
    }

    for (final entry in _eventoPorJogoId.entries) {
      final event = entry.value;
      _adicionarBadge(event.strHomeTeam, event.strHomeTeamBadge);
      _adicionarBadge(event.strAwayTeam, event.strAwayTeamBadge);

      final image = event.stadiumImage;
      if (image != null && image.isNotEmpty) {
        _imagemEstadioPorJogoId[entry.key] = image;
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
}
