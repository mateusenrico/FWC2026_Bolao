import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/app_routes.dart';
import '../models/jogo.dart';
import '../plugins/api_refresh_action.dart';
import '../plugins/partida_card.dart';
import '../plugins/ranking_mode_selector.dart';
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
            title: const Text('Bolão FWC 2026'),
            actions: [ApiRefreshAction(controller: controller)],
          ),
          body: RefreshIndicator(
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 370,
                                  child: _RankingSection(
                                    controller: controller,
                                    expanded: _rankingExpandido,
                                    onToggle: () {
                                      setState(() {
                                        _rankingExpandido = !_rankingExpandido;
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: hasLive ? 'Acontecendo agora' : 'Próximo jogo',
          subtitle: jogos.length > 1
              ? '${jogos.length} partidas no mesmo horário'
              : 'Destaque do calendário',
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
                        child: _partida(context, jogo),
                      ),
                  ],
                );
              }

              return Column(
                children: [for (final jogo in jogos) _partida(context, jogo)],
              );
            },
          ),
      ],
    );
  }

  Widget _partida(BuildContext context, Jogo jogo) {
    return PartidaCard(
      jogo: jogo,
      badgeMandante: controller.badgeDoTime(jogo.mandantePrevisto),
      badgeVisitante: controller.badgeDoTime(jogo.visitantePrevisto),
      imageUrl: controller.imagemDoEstadio(jogo.jogoId),
      destaque: true,
      onTap: () {
        Navigator.pushNamed(context, AppRoutes.jogo, arguments: jogo.jogoId);
      },
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
    final ranking = controller.classificacao;
    final visible = expanded
        ? ranking
        : ranking.take(5).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Ranking parcial',
          subtitle: 'Desempate por placares exatos',
          trailing: TextButton.icon(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.ranking),
            icon: const Icon(Icons.leaderboard_outlined),
            label: const Text('Detalhes'),
          ),
        ),
        if (controller.temJogosAoVivo) ...[
          RankingModeSelector(
            value: controller.ordenacaoRanking,
            onChanged: controller.alterarOrdenacaoRanking,
          ),
          const SizedBox(height: 10),
        ],
        for (final linha in visible)
          RankingParticipanteCard(
            linha: linha,
            liveDelta:
                controller.ordenacaoRanking == OrdenacaoRanking.consolidado
                ? controller.pontosAoVivo(linha.participanteId)
                : 0,
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRoutes.participante,
                arguments: linha.participanteId,
              );
            },
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

class _GamesSection extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Partidas',
          subtitle: 'Passados, em andamento e futuros',
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
              label: 'Hoje',
              value: PeriodoJogos.hoje,
              selected: periodo == PeriodoJogos.hoje,
              onSelected: onPeriodoChanged,
            ),
            _FilterChip(
              label: 'Passados',
              value: PeriodoJogos.passados,
              selected: periodo == PeriodoJogos.passados,
              onSelected: onPeriodoChanged,
            ),
            _FilterChip(
              label: 'Futuros',
              value: PeriodoJogos.futuros,
              selected: periodo == PeriodoJogos.futuros,
              onSelected: onPeriodoChanged,
            ),
          ],
        ),
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
              badgeMandante: controller.badgeDoTime(jogo.mandantePrevisto),
              badgeVisitante: controller.badgeDoTime(jogo.visitantePrevisto),
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
}

class _DashboardHero extends StatelessWidget {
  final BolaoController controller;

  const _DashboardHero({required this.controller});

  @override
  Widget build(BuildContext context) {
    final hoje = controller.jogosPorPeriodo(PeriodoJogos.hoje).length;
    final aoVivo = controller.jogosAoVivo.length;
    final lider = controller.classificacaoConsolidada.isEmpty
        ? null
        : controller.classificacaoConsolidada.first;

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
                        const SizedBox(height: 6),
                        Text(
                          lider == null
                              ? 'Ranking em formação'
                              : 'Líder: ${lider.nome} · ${lider.pontosTotal} pts',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.82),
                                fontWeight: FontWeight.w800,
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
                          value: '${controller.data.totalParticipantes}',
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
            final columns = constraints.maxWidth >= 980
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
                  subtitle: '$hoje hoje',
                  color: FwcColors.red,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.jogos),
                ),
                _DashboardTile(
                  width: width,
                  icon: Icons.leaderboard_outlined,
                  title: 'Ranking',
                  subtitle: lider?.nome ?? 'ver lista',
                  color: FwcColors.purple,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.ranking),
                ),
                _DashboardTile(
                  width: width,
                  icon: Icons.table_chart_outlined,
                  title: 'Grupos',
                  subtitle: 'A-L',
                  color: FwcColors.green,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.grupos),
                ),
                _DashboardTile(
                  width: width,
                  icon: Icons.shield_outlined,
                  title: 'Times',
                  subtitle: '${controller.data.totalTimes}',
                  color: FwcColors.blue,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.times),
                ),
                _DashboardTile(
                  width: width,
                  icon: Icons.tune_outlined,
                  title: 'Simular',
                  subtitle: 'cenários',
                  color: FwcColors.teal,
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.simulador),
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
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _DashboardTile({
    required this.width,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
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
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
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
