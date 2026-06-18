import 'package:flutter/material.dart';

import '../core/app_routes.dart';
import '../core/functions/date_time_utils.dart';
import '../core/functions/participant_colors.dart';
import '../core/sistema_pontuacao_participantes.dart';
import '../plugins/api_refresh_action.dart';
import '../plugins/live_matches_banner.dart';
import '../plugins/participant_identity.dart';
import '../plugins/ranking_evolution_chart.dart';
import '../plugins/ranking_mode_selector.dart';
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
  RankingEvolutionMetric _evolutionMetric = RankingEvolutionMetric.posicao;
  RangeValues? _evolutionRange;

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
        final evolutionRange = _rangeFor(points);
        final visiblePoints = _filterByRange(points, evolutionRange);
        final participantColors = ParticipantColors.mapFromParticipantes(
          controller.data.participantes,
        );
        final podiumPositions = {
          for (final linha in ranking.take(3))
            linha.participanteId: linha.posicao,
        };
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
                          SectionHeader(title: 'Evolução'),
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
                                  setState(() {
                                    _evolutionMode = value.first;
                                    _evolutionRange = null;
                                  });
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
                            participantColors: participantColors,
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
                          if (evolutionRange != null) ...[
                            const SizedBox(height: 12),
                            _EvolutionRangeFilter(
                              mode: _evolutionMode,
                              points: points,
                              value: evolutionRange,
                              onChanged: (value) {
                                setState(() => _evolutionRange = value);
                              },
                            ),
                          ],
                          const SizedBox(height: 12),
                          RankingEvolutionChart(
                            points: visiblePoints,
                            selectedParticipantes: _selecionados,
                            participantColors: participantColors,
                            podiumPositions: podiumPositions,
                            legendOrder: [
                              for (final linha in ranking) linha.participanteId,
                            ],
                            metric: _evolutionMetric,
                          ),
                          const SizedBox(height: 22),
                          const SectionHeader(title: 'Lista completa'),
                          _RankingPointsGrid(
                            ranking: ranking,
                            participantColors: participantColors,
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

  RangeValues? _rangeFor(List<RankingEvolutionPoint> points) {
    final steps = points.map((point) => point.step).toSet().toList()..sort();
    if (steps.length < 2) {
      return null;
    }

    final min = steps.first.toDouble();
    final max = steps.last.toDouble();
    final current = _evolutionRange;
    if (current == null) {
      return RangeValues(min, max);
    }

    final start = current.start.clamp(min, max).toDouble();
    final end = current.end.clamp(min, max).toDouble();
    if (start <= end) {
      return RangeValues(start, end);
    }

    return RangeValues(end, start);
  }

  List<RankingEvolutionPoint> _filterByRange(
    List<RankingEvolutionPoint> points,
    RangeValues? range,
  ) {
    if (range == null) {
      return points;
    }

    final start = range.start.round();
    final end = range.end.round();
    return [
      for (final point in points)
        if (point.step >= start && point.step <= end) point,
    ];
  }
}

class _ParticipantFilter extends StatelessWidget {
  final List<LinhaPontuacaoParticipante> ranking;
  final Set<String> selecionados;
  final Map<String, Color> participantColors;
  final void Function(String participanteId, bool selected) onChanged;

  const _ParticipantFilter({
    required this.ranking,
    required this.selecionados,
    required this.participantColors,
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
            avatar: ParticipantMarker(
              color:
                  participantColors[linha.participanteId] ??
                  Theme.of(context).colorScheme.primary,
              participanteId: linha.participanteId,
              size: 12,
            ),
            label: Text(linha.nome),
            selected: selecionados.contains(linha.participanteId),
            onSelected: (value) => onChanged(linha.participanteId, value),
          ),
      ],
    );
  }
}

class _EvolutionRangeFilter extends StatelessWidget {
  final RankingEvolutionMode mode;
  final List<RankingEvolutionPoint> points;
  final RangeValues value;
  final ValueChanged<RangeValues> onChanged;

  const _EvolutionRangeFilter({
    required this.mode,
    required this.points,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final steps = points.map((point) => point.step).toSet().toList()..sort();
    if (steps.length < 2) {
      return const SizedBox.shrink();
    }

    final minStep = steps.first;
    final maxStep = steps.last;
    final labels = <int, String>{};
    for (final point in points) {
      labels.putIfAbsent(point.step, () => point.stepLabel);
    }

    final start = value.start.round().clamp(minStep, maxStep).toInt();
    final end = value.end.round().clamp(minStep, maxStep).toInt();
    final title = mode == RankingEvolutionMode.partidas
        ? 'Partidas exibidas'
        : 'Dias exibidos';
    final currentLabel =
        '${_labelFor(labels, start)} - '
        '${_labelFor(labels, end)}';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                Text(
                  currentLabel,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            RangeSlider(
              min: minStep.toDouble(),
              max: maxStep.toDouble(),
              divisions: maxStep - minStep,
              labels: RangeLabels(
                _labelFor(labels, start),
                _labelFor(labels, end),
              ),
              values: RangeValues(start.toDouble(), end.toDouble()),
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }

  String _labelFor(Map<int, String> labels, int step) {
    return labels[step] ?? '$step';
  }
}

class _RankingPointsGrid extends StatelessWidget {
  final List<LinhaPontuacaoParticipante> ranking;
  final Map<String, Color> participantColors;
  final int Function(String participanteId) liveDelta;
  final ValueChanged<String> onTapParticipante;

  const _RankingPointsGrid({
    required this.ranking,
    required this.participantColors,
    required this.liveDelta,
    required this.onTapParticipante,
  });

  @override
  Widget build(BuildContext context) {
    if (ranking.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(18),
          child: Text('Ainda não há participantes pontuando.'),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 12.0;
        final useTwoColumns = constraints.maxWidth >= 820;
        final width = useTwoColumns
            ? (constraints.maxWidth - gap) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final linha in ranking)
              SizedBox(
                width: width,
                child: _RankingSummaryCard(
                  linha: linha,
                  color: participantColors[linha.participanteId],
                  liveDelta: liveDelta(linha.participanteId),
                  onTap: () => onTapParticipante(linha.participanteId),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _RankingSummaryCard extends StatelessWidget {
  final LinhaPontuacaoParticipante linha;
  final Color? color;
  final int liveDelta;
  final VoidCallback onTap;

  const _RankingSummaryCard({
    required this.linha,
    required this.color,
    required this.liveDelta,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = color ?? colors.primary;
    final zeros =
        linha.palpitesPontuaveis -
        linha.placaresExatos -
        linha.palpitesComTresPontos -
        linha.palpitesComDoisPontos -
        linha.palpitesComUmPonto;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: ParticipantColors.softBackgroundFor(accent, colors),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.62)),
      ),
      child: InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: accent, width: 5)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    ParticipantPositionBadge(
                      position: linha.posicao,
                      color: accent,
                      size: 34,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ParticipantNameInline(
                        name: linha.nome,
                        color: accent,
                        participantId: linha.participanteId,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${linha.pontosTotal}',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: accent,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        if (liveDelta != 0)
                          _LiveDeltaChip(value: liveDelta, color: accent)
                        else
                          Text(
                            'Total',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: colors.onSurfaceVariant),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _ScoreBreakdownPill(
                      label: 'Exato',
                      value: linha.placaresExatos,
                      color: accent,
                      highlight: linha.placaresExatos > 0,
                    ),
                    _ScoreBreakdownPill(
                      label: 'Res.+gol',
                      value: linha.palpitesComTresPontos,
                      color: accent,
                      highlight: linha.palpitesComTresPontos > 0,
                    ),
                    _ScoreBreakdownPill(
                      label: 'Resultado',
                      value: linha.palpitesComDoisPontos,
                      color: accent,
                      highlight: linha.palpitesComDoisPontos > 0,
                    ),
                    _ScoreBreakdownPill(
                      label: 'Gol',
                      value: linha.palpitesComUmPonto,
                      color: accent,
                      highlight: linha.palpitesComUmPonto > 0,
                    ),
                    _ScoreBreakdownPill(
                      label: 'Nada',
                      value: zeros.clamp(0, 999),
                      color: colors.onSurfaceVariant,
                      highlight: false,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LiveDeltaChip extends StatelessWidget {
  final int value;
  final Color color;

  const _LiveDeltaChip({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final prefix = value > 0 ? '+' : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.52)),
      ),
      child: Text(
        '$prefix$value ao vivo',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ScoreBreakdownPill extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final bool highlight;

  const _ScoreBreakdownPill({
    required this.label,
    required this.value,
    required this.color,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foreground = highlight ? color : colors.onSurfaceVariant;

    return Container(
      constraints: const BoxConstraints(minWidth: 72),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: highlight
            ? color.withValues(alpha: 0.13)
            : colors.surfaceContainerHighest.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: highlight
              ? color.withValues(alpha: 0.42)
              : colors.outlineVariant.withValues(alpha: 0.62),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
