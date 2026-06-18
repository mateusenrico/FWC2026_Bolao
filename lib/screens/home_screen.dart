import 'package:flutter/material.dart';

import '../core/app_routes.dart';
import '../models/jogo.dart';
import '../plugins/api_refresh_action.dart';
import '../plugins/partida_card.dart';
import '../plugins/ranking_mode_selector.dart';
import '../plugins/ranking_participante_card.dart';
import '../plugins/section_header.dart';
import '../services/bolao_controller.dart';

class HomeScreen extends StatefulWidget {
  final BolaoController controller;

  const HomeScreen({super.key, required this.controller});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  PeriodoJogos _periodo = PeriodoJogos.futuros;
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
            actions: [
              IconButton(
                tooltip: 'Ranking detalhado',
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.ranking);
                },
                icon: const Icon(Icons.leaderboard_outlined),
              ),
              IconButton(
                tooltip: 'Partidas',
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.jogos);
                },
                icon: const Icon(Icons.sports_soccer_outlined),
              ),
              IconButton(
                tooltip: 'Simulações',
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.simulador);
                },
                icon: const Icon(Icons.tune_outlined),
              ),
              IconButton(
                tooltip: 'Classificação dos grupos',
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.grupos);
                },
                icon: const Icon(Icons.table_chart_outlined),
              ),
              ApiRefreshAction(controller: controller),
            ],
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
        RankingModeSelector(
          value: controller.ordenacaoRanking,
          onChanged: controller.alterarOrdenacaoRanking,
        ),
        const SizedBox(height: 10),
        for (final linha in visible)
          RankingParticipanteCard(
            linha: linha,
            liveDelta: controller.pontosAoVivo(linha.participanteId),
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
              label: 'Passados',
              value: PeriodoJogos.passados,
              selected: periodo == PeriodoJogos.passados,
              onSelected: onPeriodoChanged,
            ),
            _FilterChip(
              label: 'Em andamento',
              value: PeriodoJogos.emAndamento,
              selected: periodo == PeriodoJogos.emAndamento,
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
