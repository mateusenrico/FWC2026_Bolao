import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/app_routes.dart';
import '../core/functions/date_time_utils.dart';
import '../core/functions/participant_colors.dart';
import '../core/sistema_pontuacao_participantes.dart';
import '../models/jogo.dart';
import '../plugins/api_refresh_action.dart';
import '../plugins/live_matches_banner.dart';
import '../plugins/live_palpite_grid.dart';
import '../plugins/partida_card.dart';
import '../plugins/ranking_evolution_chart.dart';
import '../plugins/ranking_participante_card.dart';
import '../plugins/refresh_countdown_indicator.dart';
import '../plugins/section_header.dart';
import '../services/bolao_controller.dart';

class HomeScreen extends StatefulWidget {
  final BolaoController controller;

  const HomeScreen({super.key, required this.controller});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  PeriodoJogos _periodo = PeriodoJogos.hoje;
  bool _rankingExpandido = false;

  BolaoController get controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final destaques = controller.proximosDestaques;
        final jogos = controller.jogosPorPeriodo(_periodo);
        // final classificacao = controller.classificacao;

        return Scaffold(
          appBar: AppBar(
            title: const SizedBox.shrink(),
            actions: [ApiRefreshAction(controller: controller)],
          ),
          body: Column(
            children: [
              if (controller.temJogosAoVivo)
                LiveMatchesBanner(controller: controller),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: controller.atualizarApi,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 980;

                      return SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          constraints.maxWidth < 600 ? 12 : 24,
                          16,
                          constraints.maxWidth < 600 ? 12 : 24,
                          36,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1320),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _DashboardHero(controller: controller),
                                const SizedBox(height: 20),
                                _NextGamesSection(
                                  controller: controller,
                                  jogos: destaques,
                                ),
                                const SizedBox(height: 24),
                                if (wide)
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        width: 370,
                                        child: _RankingSection(
                                          controller: controller,
                                          expanded: _rankingExpandido,
                                          onToggle: () {
                                            setState(() {
                                              _rankingExpandido =
                                                  !_rankingExpandido;
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 24),
                                      Expanded(
                                        child: _GamesSection(
                                          controller: controller,
                                          periodo: _periodo,
                                          jogos: jogos,
                                          onPeriodoChanged: (value) {
                                            setState(() => _periodo = value);
                                          },
                                        ),
                                      ),
                                    ],
                                  )
                                else ...[
                                  _RankingSection(
                                    controller: controller,
                                    expanded: _rankingExpandido,
                                    onToggle: () {
                                      setState(() {
                                        _rankingExpandido = !_rankingExpandido;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 24),
                                  _GamesSection(
                                    controller: controller,
                                    periodo: _periodo,
                                    jogos: jogos,
                                    onPeriodoChanged: (value) {
                                      setState(() => _periodo = value);
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NextGamesSection extends StatelessWidget {
  final BolaoController controller;
  final List<Jogo> jogos;

  const _NextGamesSection({required this.controller, required this.jogos});

  @override
  Widget build(BuildContext context) {
    final hasLive = jogos.any((jogo) => jogo.isEmAndamento);
    final participantColors = ParticipantColors.mapFromParticipantes(
      controller.data.participantes,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: hasLive ? 'Acontecendo agora' : 'Próximo jogo',
          subtitle: jogos.length > 1
              ? '${jogos.length} partidas no mesmo horário'
              : null,
        ),
        if (jogos.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('Nenhuma partida disponível.'),
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 760 && jogos.length > 1) {
                final itemWidth = (constraints.maxWidth - 12) / 2;

                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final jogo in jogos)
                      SizedBox(
                        width: itemWidth,
                        child: _partida(context, jogo, participantColors),
                      ),
                  ],
                );
              }

              return Column(
                children: [
                  for (final jogo in jogos)
                    _partida(context, jogo, participantColors),
                ],
              );
            },
          ),
      ],
    );
  }

  Widget _partida(
    BuildContext context,
    Jogo jogo,
    Map<String, Color> participantColors,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PartidaCard(
          jogo: jogo,
          badgeMandante: controller.badgeDoTime(jogo.mandantePrevisto),
          badgeVisitante: controller.badgeDoTime(jogo.visitantePrevisto),
          imageUrl:
              controller.bannerDoJogo(jogo.jogoId) ??
              controller.imagemDoJogo(jogo.jogoId),
          liveClock: controller.tempoAtualDoJogo(jogo),
          destaque: true,
          onTap: () {
            Navigator.pushNamed(
              context,
              AppRoutes.jogo,
              arguments: jogo.jogoId,
            );
          },
        ),
        LivePalpiteGrid(
          jogo: jogo,
          groups: controller.gruposDePalpitesDoJogo(jogo.jogoId),
          participantColors: participantColors,
          onTapParticipante: (id) => () {
            Navigator.pushNamed(context, AppRoutes.participante, arguments: id);
          },
        ),
      ],
    );
  }
}

class _RankingSection extends StatelessWidget {
  final BolaoController controller;
  final bool expanded;
  final VoidCallback onToggle;

  const _RankingSection({
    required this.controller,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final hasLive = controller.temJogosAoVivo;
    final ranking = hasLive
        ? controller.classificacaoProjetada
        : controller.classificacaoConsolidada;
    final consolidadoPorParticipante = {
      for (final linha in controller.classificacaoConsolidada)
        linha.participanteId: linha,
    };
    final visible = expanded
        ? ranking
        : ranking.take(5).toList(growable: false);
    final participantColors = ParticipantColors.mapFromParticipantes(
      controller.data.participantes,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Ranking parcial',
          trailing: TextButton.icon(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.ranking),
            icon: const Icon(Icons.leaderboard_outlined),
            label: const Text('Detalhes'),
          ),
        ),
        for (final linha in visible) ...[
          Builder(
            builder: (context) {
              final consolidado =
                  consolidadoPorParticipante[linha.participanteId] ?? linha;
              final liveDelta = hasLive
                  ? linha.pontosTotal - consolidado.pontosTotal
                  : 0;
              final movementDelta = hasLive
                  ? consolidado.posicao - linha.posicao
                  : null;

              return RankingParticipanteCard(
                linha: linha,
                participantColor: participantColors[linha.participanteId],
                displayPoints: hasLive ? consolidado.pontosTotal : null,
                liveDelta: liveDelta,
                movementDelta: movementDelta,
                pointsLabel: hasLive ? 'cons. + ao vivo' : null,
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.participante,
                    arguments: linha.participanteId,
                  );
                },
              );
            },
          ),
        ],
        _RankingMiniEvolution(
          controller: controller,
          ranking: ranking,
          visible: visible,
          participantColors: participantColors,
        ),
        if (ranking.length > 5)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onToggle,
              icon: Icon(expanded ? Icons.expand_less : Icons.expand_more),
              label: Text(expanded ? 'Recolher' : 'Ver todos'),
            ),
          ),
      ],
    );
  }
}

class _RankingMiniEvolution extends StatelessWidget {
  final BolaoController controller;
  final List<LinhaPontuacaoParticipante> ranking;
  final List<LinhaPontuacaoParticipante> visible;
  final Map<String, Color> participantColors;

  const _RankingMiniEvolution({
    required this.controller,
    required this.ranking,
    required this.visible,
    required this.participantColors,
  });

  @override
  Widget build(BuildContext context) {
    final points = _buildEvolutionByMatch();
    if (points.isEmpty || visible.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: RankingEvolutionChart(
        points: points,
        selectedParticipantes: {
          for (final linha in visible) linha.participanteId,
        },
        participantColors: participantColors,
        podiumPositions: {
          for (final linha in ranking.take(3))
            linha.participanteId: linha.posicao,
        },
        legendOrder: [for (final linha in ranking) linha.participanteId],
        metric: RankingEvolutionMetric.posicao,
        height: 150,
        showLegend: false,
        showAxisLabel: false,
      ),
    );
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

enum _FuturosSubfiltro { amanha, semana, todos }

class _GamesSection extends StatefulWidget {
  final BolaoController controller;
  final PeriodoJogos periodo;
  final List<Jogo> jogos;
  final ValueChanged<PeriodoJogos> onPeriodoChanged;

  const _GamesSection({
    required this.controller,
    required this.periodo,
    required this.jogos,
    required this.onPeriodoChanged,
  });

  @override
  State<_GamesSection> createState() => _GamesSectionState();
}

class _GamesSectionState extends State<_GamesSection> {
  _FuturosSubfiltro _futurosSubfiltro = _FuturosSubfiltro.amanha;

  @override
  Widget build(BuildContext context) {
    final jogos = widget.periodo == PeriodoJogos.futuros
        ? _filtrarFuturos(widget.jogos)
        : widget.jogos;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Partidas',
          trailing: TextButton.icon(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.jogos),
            icon: const Icon(Icons.sports_soccer_outlined),
            label: const Text('Ver todas'),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _FilterChip(
              label: 'Passados',
              value: PeriodoJogos.passados,
              selected: widget.periodo == PeriodoJogos.passados,
              onSelected: widget.onPeriodoChanged,
            ),
            _FilterChip(
              label: 'Hoje',
              value: PeriodoJogos.hoje,
              selected: widget.periodo == PeriodoJogos.hoje,
              onSelected: widget.onPeriodoChanged,
            ),
            _FilterChip(
              label: 'Rodada',
              value: PeriodoJogos.rodadaAtual,
              selected: widget.periodo == PeriodoJogos.rodadaAtual,
              onSelected: widget.onPeriodoChanged,
            ),
            _FilterChip(
              label: 'Futuros',
              value: PeriodoJogos.futuros,
              selected: widget.periodo == PeriodoJogos.futuros,
              onSelected: widget.onPeriodoChanged,
            ),
          ],
        ),
        if (widget.periodo == PeriodoJogos.futuros) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FutureFilterChip(
                label: 'Amanhã',
                value: _FuturosSubfiltro.amanha,
                selected: _futurosSubfiltro == _FuturosSubfiltro.amanha,
                onSelected: _onFutureFilterChanged,
              ),
              _FutureFilterChip(
                label: 'Semana',
                value: _FuturosSubfiltro.semana,
                selected: _futurosSubfiltro == _FuturosSubfiltro.semana,
                onSelected: _onFutureFilterChanged,
              ),
              _FutureFilterChip(
                label: 'Todos',
                value: _FuturosSubfiltro.todos,
                selected: _futurosSubfiltro == _FuturosSubfiltro.todos,
                onSelected: _onFutureFilterChanged,
              ),
            ],
          ),
        ],
        const SizedBox(height: 14),
        if (jogos.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('Nenhum jogo nessa categoria.'),
            ),
          )
        else
          for (final jogo in jogos)
            PartidaCard(
              jogo: jogo,
              badgeMandante: widget.controller.badgeDoTime(
                jogo.mandantePrevisto,
              ),
              badgeVisitante: widget.controller.badgeDoTime(
                jogo.visitantePrevisto,
              ),
              imageUrl:
                  widget.controller.bannerDoJogo(jogo.jogoId) ??
                  widget.controller.imagemDoJogo(jogo.jogoId),
              liveClock: widget.controller.tempoAtualDoJogo(jogo),
              onTap: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.jogo,
                  arguments: jogo.jogoId,
                );
              },
            ),
      ],
    );
  }

  void _onFutureFilterChanged(_FuturosSubfiltro value) {
    setState(() => _futurosSubfiltro = value);
  }

  List<Jogo> _filtrarFuturos(List<Jogo> jogos) {
    if (_futurosSubfiltro == _FuturosSubfiltro.todos) {
      return jogos;
    }

    final hoje = AppDateTime.agoraBrasilia();
    final amanha = hoje.add(const Duration(days: 1));
    final limiteSemana = AppDateTime.inicioDoDia(
      hoje.add(const Duration(days: 7)),
    );

    return jogos
        .where((jogo) {
          final date = AppDateTime.horarioBrasilia(jogo);
          if (date == null) {
            return _futurosSubfiltro == _FuturosSubfiltro.todos;
          }

          return switch (_futurosSubfiltro) {
            _FuturosSubfiltro.amanha => AppDateTime.mesmoDia(date, amanha),
            _FuturosSubfiltro.semana =>
              date.isAfter(hoje) && date.isBefore(limiteSemana),
            _FuturosSubfiltro.todos => true,
          };
        })
        .toList(growable: false);
  }
}

class _DashboardHero extends StatelessWidget {
  final BolaoController controller;

  const _DashboardHero({required this.controller});

  @override
  Widget build(BuildContext context) {
    final hoje = controller.jogosPorPeriodo(PeriodoJogos.hoje).length;
    final aoVivo = controller.jogosAoVivo.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              Positioned.fill(child: const _FwcPattern()),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.black.withValues(alpha: 0.82),
                        Colors.black.withValues(alpha: 0.34),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 760;

                    final title = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bolão FWC 2026',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ],
                    );

                    final metrics = Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _HeroMetric(label: 'Hoje', value: '$hoje'),
                        _HeroMetric(label: 'Ao vivo', value: '$aoVivo'),
                        _HeroMetric(
                          label: 'Participantes',
                          value: '${controller.totalParticipantesComPalpite}',
                        ),
                      ],
                    );

                    if (compact) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          title,
                          const SizedBox(height: 18),
                          metrics,
                          const SizedBox(height: 14),
                          RefreshCountdownIndicator(controller: controller),
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(child: title),
                        const SizedBox(width: 18),
                        SizedBox(
                          width: 420,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Align(
                                alignment: Alignment.centerRight,
                                child: metrics,
                              ),
                              const SizedBox(height: 12),
                              RefreshCountdownIndicator(controller: controller),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 560;
            final columns = compact
                ? constraints.maxWidth < 360
                      ? 3
                      : 5
                : constraints.maxWidth >= 980
                ? 5
                : constraints.maxWidth >= 680
                ? 3
                : constraints.maxWidth >= 390
                ? 2
                : 1;
            final width =
                (constraints.maxWidth - ((columns - 1) * 10)) / columns;

            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _DashboardTile(
                  width: width,
                  icon: Icons.sports_soccer_outlined,
                  title: 'Partidas',
                  color: FwcColors.red,
                  compact: compact,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.jogos),
                ),
                _DashboardTile(
                  width: width,
                  icon: Icons.leaderboard_outlined,
                  title: 'Ranking',
                  color: FwcColors.purple,
                  compact: compact,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.ranking),
                ),
                _DashboardTile(
                  width: width,
                  icon: Icons.table_chart_outlined,
                  title: 'Grupos',
                  color: FwcColors.green,
                  compact: compact,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.grupos),
                ),
                _DashboardTile(
                  width: width,
                  icon: Icons.shield_outlined,
                  title: 'Times',
                  color: FwcColors.blue,
                  compact: compact,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.times),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _HeroMetric extends StatelessWidget {
  final String label;
  final String value;

  const _HeroMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 82),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.78),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardTile extends StatelessWidget {
  final double width;
  final IconData icon;
  final String title;
  final Color color;
  final bool compact;
  final VoidCallback onTap;

  const _DashboardTile({
    required this.width,
    required this.icon,
    required this.title,
    required this.color,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(compact ? 8 : 14),
            child: Column(
              crossAxisAlignment: compact
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  width: compact ? 30 : 38,
                  height: compact ? 30 : 38,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: compact ? 18 : 24),
                ),
                SizedBox(height: compact ? 6 : 12),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: compact ? TextAlign.center : TextAlign.left,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FwcPattern extends StatelessWidget {
  const _FwcPattern();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            FwcColors.red,
            FwcColors.purple,
            FwcColors.blue,
            FwcColors.teal,
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final PeriodoJogos value;
  final bool selected;
  final ValueChanged<PeriodoJogos> onSelected;

  const _FilterChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(value),
    );
  }
}

class _FutureFilterChip extends StatelessWidget {
  final String label;
  final _FuturosSubfiltro value;
  final bool selected;
  final ValueChanged<_FuturosSubfiltro> onSelected;

  const _FutureFilterChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(value),
      visualDensity: VisualDensity.compact,
    );
  }
}
