import 'package:flutter/material.dart';

import '../core/team_normalizer.dart';
import '../models/bolao_data.dart';
import '../models/historico_partida.dart';
import '../models/jogo.dart';
import '../services/asset_loader.dart';
import '../services/sportsdb_api_service.dart';

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

      final events = await service.fetchAllCoreEvents();

      setState(() {
        _liveEvents = events;
        _refreshMessage =
            'API atualizada em memória: ${events.length} eventos recebidos.';
      });
    } catch (error) {
      setState(() {
        _refreshMessage = 'Erro ao atualizar API: $error';
      });
    } finally {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  Future<void> _reloadAssets() async {
    setState(() {
      _dataFuture = AssetLoader.carregarBolaoData();
      _refreshMessage = 'Assets recarregados.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<BolaoData>(
      future: _dataFuture,
      builder: (context, snapshot) {
        final theme = Theme.of(context);

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
                'Erro ao carregar dados:\n\n${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }

        final data = snapshot.data!;
        final rows = _buildRows(data);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Jogos'),
            actions: [
              IconButton(
                tooltip: 'Recarregar assets',
                onPressed: _reloadAssets,
                icon: const Icon(Icons.cached),
              ),
              IconButton(
                tooltip: 'Atualizar pela API',
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
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _refreshMessage!,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Dia')),
                        DataColumn(label: Text('Horário')),
                        DataColumn(label: Text('Local')),
                        DataColumn(label: Text('Casa')),
                        DataColumn(label: Text('Placar')),
                        DataColumn(label: Text('Visitante')),
                        DataColumn(label: Text('Placar')),
                        DataColumn(label: Text('Status')),
                      ],
                      rows: rows
                          .map((row) {
                            return DataRow(
                              cells: [
                                DataCell(Text(row.dia)),
                                DataCell(Text(row.horario)),
                                DataCell(Text(row.local)),
                                DataCell(Text(row.timeCasa)),
                                DataCell(Text(row.placarCasa)),
                                DataCell(Text(row.timeVisitante)),
                                DataCell(Text(row.placarVisitante)),
                                DataCell(Text(row.status)),
                              ],
                            );
                          })
                          .toList(growable: false),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<JogoTabelaRow> _buildRows(BolaoData data) {
    final historicoPorJogoId = data.historicoPorJogoId;

    final liveEventsByIdEvent = <String, SportsDbEvent>{
      for (final event in _liveEvents) event.idEvent: event,
    };

    final rows = data.jogos
        .map((jogo) {
          final historico = historicoPorJogoId[jogo.jogoId];

          SportsDbEvent? liveEvent;

          if (jogo.idEventAtual != null) {
            liveEvent = liveEventsByIdEvent[jogo.idEventAtual!];
          }

          liveEvent ??= _findLiveEventForJogo(jogo: jogo, events: _liveEvents);

          return JogoTabelaRow.fromData(
            jogo: jogo,
            historico: historico,
            liveEvent: liveEvent,
          );
        })
        .toList(growable: false);

    rows.sort((a, b) => a.ordem.compareTo(b.ordem));

    return rows;
  }

  SportsDbEvent? _findLiveEventForJogo({
    required Jogo jogo,
    required List<SportsDbEvent> events,
  }) {
    final mandanteKey = TeamNormalizer.key(jogo.mandantePrevisto);
    final visitanteKey = TeamNormalizer.key(jogo.visitantePrevisto);

    if (mandanteKey.isEmpty || visitanteKey.isEmpty) {
      return null;
    }

    final jogoUtc = jogo.dataUtc?.toUtc() ?? jogo.dataLocal?.toUtc();

    SportsDbEvent? bestMatch;
    int bestDiffMinutes = 999999;

    for (final event in events) {
      final homeKey = TeamNormalizer.key(event.strHomeTeam ?? '');
      final awayKey = TeamNormalizer.key(event.strAwayTeam ?? '');

      final sameOrder = homeKey == mandanteKey && awayKey == visitanteKey;
      final invertedOrder = homeKey == visitanteKey && awayKey == mandanteKey;

      if (!sameOrder && !invertedOrder) {
        continue;
      }

      final eventUtc = event.strTimestampUtc;

      if (jogoUtc != null && eventUtc != null) {
        final diff = jogoUtc.difference(eventUtc).inMinutes.abs();

        if (diff < bestDiffMinutes) {
          bestDiffMinutes = diff;
          bestMatch = event;
        }
      } else {
        bestMatch ??= event;
      }
    }

    if (bestMatch != null && bestDiffMinutes <= 30 * 60) {
      return bestMatch;
    }

    return bestMatch;
  }
}

class JogoTabelaRow {
  final int ordem;
  final String dia;
  final String horario;
  final String local;
  final String timeCasa;
  final String placarCasa;
  final String timeVisitante;
  final String placarVisitante;
  final String status;

  const JogoTabelaRow({
    required this.ordem,
    required this.dia,
    required this.horario,
    required this.local,
    required this.timeCasa,
    required this.placarCasa,
    required this.timeVisitante,
    required this.placarVisitante,
    required this.status,
  });

  factory JogoTabelaRow.fromData({
    required Jogo jogo,
    required HistoricoPartida? historico,
    required SportsDbEvent? liveEvent,
  }) {
    final homeScore = liveEvent?.intHomeScore ?? historico?.intHomeScore;
    final awayScore = liveEvent?.intAwayScore ?? historico?.intAwayScore;

    final local =
        liveEvent?.strVenue ?? historico?.raw['strVenue']?.toString() ?? '-';

    final status =
        liveEvent?.statusCanonico ??
        historico?.statusJogoCanonico ??
        jogo.statusJogo;

    return JogoTabelaRow(
      ordem: jogo.ordem,
      dia: _formatDate(jogo.dataLocal ?? jogo.dataUtc),
      horario: jogo.horaLocal ?? _formatTime(jogo.dataLocal ?? jogo.dataUtc),
      local: local,
      timeCasa: jogo.mandantePrevisto,
      placarCasa: homeScore?.toString() ?? '-',
      timeVisitante: jogo.visitantePrevisto,
      placarVisitante: awayScore?.toString() ?? '-',
      status: status,
    );
  }

  static String _formatDate(DateTime? date) {
    if (date == null) {
      return '-';
    }

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month';
  }

  static String _formatTime(DateTime? date) {
    if (date == null) {
      return '-';
    }

    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }
}
