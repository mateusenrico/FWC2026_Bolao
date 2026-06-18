import 'package:flutter/material.dart';

import '../core/app_routes.dart';
import '../core/functions/date_time_utils.dart';
import '../core/sistema_pontuacao_participantes.dart';
import '../plugins/api_refresh_action.dart';
import '../plugins/live_matches_banner.dart';
import '../plugins/ranking_evolution_chart.dart';
import '../plugins/ranking_mode_selector.dart';
import '../plugins/ranking_participante_card.dart';
import '../plugins/ranking_podium.dart';
import '../plugins/section_header.dart';
import '../services/bolao_controller.dart';

enum RankingEvolutionMode { partidas, dias }

class RankingScreen extends StatefulWidget {
  final BolaoController controller;

  const RankingScreen({super.key, required this.controller});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  final Set<String> _selecionados = {};
  RankingEvolutionMode _evolutionMode = RankingEvolutionMode.partidas;
  RankingEvolutionMetric _evolutionMetric = RankingEvolutionMetric.pontos;

  BolaoController get controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final ranking = controller.classificacao;
        if (_selecionados.isEmpty && ranking.isNotEmpty) {
          _selecionados.addAll(
            ranking.take(5).map((linha) => linha.participanteId),
          );
        }

        final points = _buildEvolutionPoints(_evolutionMode);
        final showLiveDelta =
            controller.ordenacaoRanking == OrdenacaoRanking.consolidado;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Ranking do bolão'),
            actions: [ApiRefreshAction(controller: controller)],
          ),
          body: Column(
            children: [
              LiveMatchesBanner(controller: controller),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 36),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1180),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SectionHeader(
                            title: 'Classificação',
                            subtitle:
                                'Consolidados ignoram jogos ao vivo; projetados incluem placares em andamento',
                            trailing: controller.temJogosAoVivo
                                ? RankingModeSelector(
                                    value: controller.ordenacaoRanking,
                                    onChanged:
                                        controller.alterarOrdenacaoRanking,
                                  )
                                : null,
                          ),
                          RankingPodium(
                            ranking: ranking,
                            liveDelta: (id) =>
                                showLiveDelta ? controller.pontosAoVivo(id) : 0,
                            onTapParticipante: (id) {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.participante,
                                arguments: id,
                              );
                            },
                          ),
                          const SizedBox(height: 18),
                          SectionHeader(
                            title: 'Evolução',
                            subtitle: _evolutionSubtitle,
                          ),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              SegmentedButton<RankingEvolutionMode>(
                                segments: const [
                                  ButtonSegment(
                                    value: RankingEvolutionMode.partidas,
                                    label: Text('Partidas'),
                                  ),
                                  ButtonSegment(
                                    value: RankingEvolutionMode.dias,
                                    label: Text('Dias'),
                                  ),
                                ],
                                selected: {_evolutionMode},
                                showSelectedIcon: false,
                                onSelectionChanged: (value) {
                                  setState(() => _evolutionMode = value.first);
                                },
                              ),
                              SegmentedButton<RankingEvolutionMetric>(
                                segments: const [
                                  ButtonSegment(
                                    value: RankingEvolutionMetric.pontos,
                                    label: Text('Pontos'),
                                  ),
                                  ButtonSegment(
                                    value: RankingEvolutionMetric.posicao,
                                    label: Text('Posição'),
                                  ),
                                ],
                                selected: {_evolutionMetric},
                                showSelectedIcon: false,
                                onSelectionChanged: (value) {
                                  setState(
                                    () => _evolutionMetric = value.first,
                                  );
                                },
                              ),
                              TextButton.icon(
                                onPressed: () {
                                  setState(() => _selecionados.clear());
                                },
                                icon: const Icon(Icons.visibility_off_outlined),
                                label: const Text('Limpar'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _ParticipantFilter(
                            ranking: ranking,
                            selecionados: _selecionados,
                            onChanged: (id, selected) {
                              setState(() {
                                if (selected) {
                                  _selecionados.add(id);
                                } else {
                                  _selecionados.remove(id);
                                }
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          RankingEvolutionChart(
                            points: points,
                            selectedParticipantes: _selecionados,
                            metric: _evolutionMetric,
                          ),
                          const SizedBox(height: 22),
                          const SectionHeader(
                            title: 'Lista completa',
                            subtitle:
                                'Máximo por partida já pontuável: 5 pontos por jogo',
                          ),
                          _RankingPointsGrid(
                            ranking: ranking,
                            liveDelta: (id) =>
                                showLiveDelta ? controller.pontosAoVivo(id) : 0,
                            onTapParticipante: (id) {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.participante,
                                arguments: id,
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          for (final linha in ranking.take(6))
                            RankingParticipanteCard(
                              linha: linha,
                              liveDelta: showLiveDelta
                                  ? controller.pontosAoVivo(
                                      linha.participanteId,
                                    )
                                  : 0,
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.participante,
                                  arguments: linha.participanteId,
                                );
                              },
                            ),
                        ],
                      ),
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

  String get _evolutionSubtitle {
    final recorte = _evolutionMode == RankingEvolutionMode.partidas
        ? 'por partida'
        : 'por dia no horário brasileiro';
    final metric = _evolutionMetric == RankingEvolutionMetric.pontos
        ? 'pontuação acumulada'
        : 'posição no ranking';

    return '$metric $recorte';
  }

  List<RankingEvolutionPoint> _buildEvolutionPoints(RankingEvolutionMode mode) {
    return switch (mode) {
      RankingEvolutionMode.partidas => _buildEvolutionByMatch(),
      RankingEvolutionMode.dias => _buildEvolutionByDay(),
    };
  }

  List<RankingEvolutionPoint> _buildEvolutionByMatch() {
    final matchNumbers = <int>{};
    final pontosPorParticipantePartida = <String, Map<int, int>>{};

    for (final linha in controller.classificacaoProjetada) {
      final byMatch = <int, int>{};

      for (final pontuacao in linha.pontuacoesPalpites) {
        if (!pontuacao.pontuavel) {
          continue;
        }

        matchNumbers.add(pontuacao.matchNumber);
        byMatch[pontuacao.matchNumber] =
            (byMatch[pontuacao.matchNumber] ?? 0) + pontuacao.pontos;
      }

      pontosPorParticipantePartida[linha.participanteId] = byMatch;
    }

    final orderedMatches = matchNumbers.toList()..sort();
    final result = <RankingEvolutionPoint>[];

    for (final linha in controller.classificacaoProjetada) {
      final byMatch = pontosPorParticipantePartida[linha.participanteId] ?? {};
      var total = 0;

      for (final matchNumber in orderedMatches) {
        total += byMatch[matchNumber] ?? 0;
        result.add(
          RankingEvolutionPoint(
            participanteId: linha.participanteId,
            nome: linha.nome,
            step: matchNumber,
            stepLabel: 'J$matchNumber',
            pontos: total,
            posicao: 0,
          ),
        );
      }
    }

    return _withPositions(result);
  }

  List<RankingEvolutionPoint> _buildEvolutionByDay() {
    final jogosPorId = controller.data.jogosPorId;
    final days = <DateTime>{};
    final pontosPorParticipanteDia = <String, Map<DateTime, int>>{};

    for (final linha in controller.classificacaoProjetada) {
      final byDay = <DateTime, int>{};

      for (final pontuacao in linha.pontuacoesPalpites) {
        if (!pontuacao.pontuavel) {
          continue;
        }

        final jogo = jogosPorId[pontuacao.jogoId];
        final date = jogo == null ? null : AppDateTime.horarioBrasilia(jogo);
        if (date == null) {
          continue;
        }

        final day = AppDateTime.inicioDoDia(date);
        days.add(day);
        byDay[day] = (byDay[day] ?? 0) + pontuacao.pontos;
      }

      pontosPorParticipanteDia[linha.participanteId] = byDay;
    }

    final orderedDays = days.toList()..sort();
    final result = <RankingEvolutionPoint>[];

    for (final linha in controller.classificacaoProjetada) {
      final byDay = pontosPorParticipanteDia[linha.participanteId] ?? {};
      var total = 0;

      for (var index = 0; index < orderedDays.length; index++) {
        final day = orderedDays[index];
        total += byDay[day] ?? 0;
        result.add(
          RankingEvolutionPoint(
            participanteId: linha.participanteId,
            nome: linha.nome,
            step: index + 1,
            stepLabel: AppDateTime.dataCurta(day),
            pontos: total,
            posicao: 0,
          ),
        );
      }
    }

    return _withPositions(result);
  }

  List<RankingEvolutionPoint> _withPositions(
    List<RankingEvolutionPoint> points,
  ) {
    final byStep = <int, List<RankingEvolutionPoint>>{};
    for (final point in points) {
      byStep.putIfAbsent(point.step, () => []).add(point);
    }

    final result = <RankingEvolutionPoint>[];

    for (final entry in byStep.entries) {
      final stepPoints = entry.value
        ..sort((a, b) {
          final pontos = b.pontos.compareTo(a.pontos);
          if (pontos != 0) {
            return pontos;
          }

          return a.nome.compareTo(b.nome);
        });

      for (var index = 0; index < stepPoints.length; index++) {
        final point = stepPoints[index];
        result.add(
          RankingEvolutionPoint(
            participanteId: point.participanteId,
            nome: point.nome,
            step: point.step,
            stepLabel: point.stepLabel,
            pontos: point.pontos,
            posicao: index + 1,
          ),
        );
      }
    }

    result.sort((a, b) {
      final participant = a.participanteId.compareTo(b.participanteId);
      if (participant != 0) {
        return participant;
      }

      return a.step.compareTo(b.step);
    });

    return result;
  }
}

class _ParticipantFilter extends StatelessWidget {
  final List<dynamic> ranking;
  final Set<String> selecionados;
  final void Function(String participanteId, bool selected) onChanged;

  const _ParticipantFilter({
    required this.ranking,
    required this.selecionados,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final linha in ranking)
          FilterChip(
            label: Text(linha.nome),
            selected: selecionados.contains(linha.participanteId),
            onSelected: (value) => onChanged(linha.participanteId, value),
          ),
      ],
    );
  }
}

class _RankingPointsGrid extends StatelessWidget {
  final List<LinhaPontuacaoParticipante> ranking;
  final int Function(String participanteId) liveDelta;
  final ValueChanged<String> onTapParticipante;

  const _RankingPointsGrid({
    required this.ranking,
    required this.liveDelta,
    required this.onTapParticipante,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(colors.surfaceContainerHigh),
          columns: const [
            DataColumn(label: Text('#')),
            DataColumn(label: Text('Participante')),
            DataColumn(numeric: true, label: Text('Total')),
            DataColumn(numeric: true, label: Text('+Live')),
            DataColumn(numeric: true, label: Text('Jogos')),
            DataColumn(numeric: true, label: Text('Grupos')),
            DataColumn(numeric: true, label: Text('Final')),
            DataColumn(numeric: true, label: Text('Pont.')),
            DataColumn(numeric: true, label: Text('Max')),
            DataColumn(numeric: true, label: Text('+5')),
            DataColumn(numeric: true, label: Text('+3')),
            DataColumn(numeric: true, label: Text('+2')),
            DataColumn(numeric: true, label: Text('+1')),
          ],
          rows: [
            for (final linha in ranking)
              DataRow(
                onSelectChanged: (_) => onTapParticipante(linha.participanteId),
                cells: [
                  DataCell(Text('${linha.posicao}º')),
                  DataCell(Text(linha.nome)),
                  DataCell(Text('${linha.pontosTotal}')),
                  DataCell(Text('${liveDelta(linha.participanteId)}')),
                  DataCell(Text('${linha.pontosJogos}')),
                  DataCell(Text('${linha.pontosGrupos}')),
                  DataCell(Text('${linha.pontosFinal}')),
                  DataCell(Text('${linha.palpitesPontuaveis}')),
                  DataCell(Text('${linha.palpitesPontuaveis * 5}')),
                  DataCell(Text('${linha.placaresExatos}')),
                  DataCell(Text('${linha.palpitesComTresPontos}')),
                  DataCell(Text('${linha.palpitesComDoisPontos}')),
                  DataCell(Text('${linha.palpitesComUmPonto}')),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
