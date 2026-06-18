import 'package:flutter/material.dart';

import '../../core/functions/team_normalizer.dart';
import '../../models/bolao_data.dart';
import '../../models/jogo.dart';
import '../../plugins/jogos_table.dart';
import '../../services/asset_loader.dart';
import '../../services/sportsdb_api_service.dart';

class JogosScreen extends StatefulWidget {
  const JogosScreen({super.key});

  @override
  State<JogosScreen> createState() => _JogosScreenState();
}

class _JogosScreenState extends State<JogosScreen> {
  late Future<BolaoData> _dataFuture;

  List<SportsDbEvent> _liveEvents = const [];
  bool _isRefreshing = false;
  String? _refreshMessage;

  @override
  void initState() {
    super.initState();
    _dataFuture = AssetLoader.carregarBolaoData();
  }

  Future<void> _refreshFromApi() async {
    setState(() {
      _isRefreshing = true;
      _refreshMessage = null;
    });

    try {
      const service = SportsDbApiService();
      final result = await service.fetchRefreshResult();

      if (!mounted) {
        return;
      }

      setState(() {
        _liveEvents = result.events;
        _refreshMessage = result.summaryText;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _refreshMessage = 'Erro ao atualizar pela API: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _reloadAssets() async {
    setState(() {
      _dataFuture = AssetLoader.carregarBolaoData();
      _refreshMessage = 'Assets locais recarregados.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<BolaoData>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Jogos')),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: SelectableText(
                'Erro ao carregar os dados:\n\n${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }

        final data = snapshot.data!;
        final itens = _buildItens(data);

        return Scaffold(
          appBar: AppBar(
            title: Text('Jogos (${itens.length})'),
            actions: [
              IconButton(
                tooltip: 'Recarregar assets',
                onPressed: _reloadAssets,
                icon: const Icon(Icons.cached),
              ),
              IconButton(
                tooltip: 'Consultar SportsDB',
                onPressed: _isRefreshing ? null : _refreshFromApi,
                icon: _isRefreshing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
              ),
            ],
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_refreshMessage != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Text(_refreshMessage!),
                ),
              Expanded(child: JogosTable(itens: itens)),
            ],
          ),
        );
      },
    );
  }

  List<JogoTabelaItem> _buildItens(BolaoData data) {
    final eventsById = <String, SportsDbEvent>{
      for (final event in _liveEvents) event.idEvent: event,
    };

    final itens = data.jogos
        .map((jogo) {
          SportsDbEvent? event;

          if (jogo.idEventAtual != null) {
            event = eventsById[jogo.idEventAtual!];
          }

          event ??= _findEventForJogo(jogo: jogo, events: _liveEvents);

          return _toTabelaItem(jogo: jogo, event: event);
        })
        .toList(growable: false);

    itens.sort((a, b) => a.ordem.compareTo(b.ordem));

    return itens;
  }

  SportsDbEvent? _findEventForJogo({
    required Jogo jogo,
    required List<SportsDbEvent> events,
  }) {
    final mandanteKey = TeamNormalizer.key(jogo.mandantePrevisto);
    final visitanteKey = TeamNormalizer.key(jogo.visitantePrevisto);

    if (mandanteKey.isEmpty || visitanteKey.isEmpty) {
      return null;
    }

    SportsDbEvent? bestMatch;
    var bestDifferenceMinutes = 999999;

    for (final event in events) {
      final homeKey = TeamNormalizer.key(event.strHomeTeam ?? '');
      final awayKey = TeamNormalizer.key(event.strAwayTeam ?? '');

      final sameOrder = homeKey == mandanteKey && awayKey == visitanteKey;
      final invertedOrder = homeKey == visitanteKey && awayKey == mandanteKey;

      if (!sameOrder && !invertedOrder) {
        continue;
      }

      if (jogo.dataUtc != null && event.strTimestampUtc != null) {
        final difference = jogo.dataUtc!
            .toUtc()
            .difference(event.strTimestampUtc!)
            .inMinutes
            .abs();

        if (difference < bestDifferenceMinutes) {
          bestDifferenceMinutes = difference;
          bestMatch = event;
        }
      } else {
        bestMatch ??= event;
      }
    }

    if (bestMatch == null) {
      return null;
    }

    if (bestDifferenceMinutes == 999999 || bestDifferenceMinutes <= 36 * 60) {
      return bestMatch;
    }

    return null;
  }

  JogoTabelaItem _toTabelaItem({
    required Jogo jogo,
    required SportsDbEvent? event,
  }) {
    var golsMandante = jogo.golsMandante;
    var golsVisitante = jogo.golsVisitante;
    var status = jogo.statusTexto;

    final eventTemPlacarUtil =
        event != null &&
        event.temPlacar &&
        (event.isFinal || event.statusCanonico == 'em_andamento');

    if (eventTemPlacarUtil) {
      golsMandante = event.intHomeScore;
      golsVisitante = event.intAwayScore;
    }

    if (event != null &&
        (event.isFinal || event.statusCanonico == 'em_andamento')) {
      status = _statusTexto(event.statusCanonico);
    }

    return JogoTabelaItem(
      ordem: jogo.ordem,
      dia: jogo.diaLocalTexto,
      horario: jogo.horaLocal,
      local: event?.strVenue ?? jogo.estadio,
      timeCasa: jogo.mandantePrevisto,
      placarCasa: golsMandante?.toString() ?? '-',
      timeVisitante: jogo.visitantePrevisto,
      placarVisitante: golsVisitante?.toString() ?? '-',
      status: status,
    );
  }

  String _statusTexto(String status) {
    switch (status) {
      case 'encerrado':
        return 'Encerrado';
      case 'em_andamento':
        return 'Em andamento';
      case 'agendado':
        return 'Agendado';
      default:
        return status;
    }
  }
}
