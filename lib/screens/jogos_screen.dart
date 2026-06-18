import 'package:flutter/material.dart';

import '../core/app_routes.dart';
import '../core/sistema_pontuacao_times.dart';
import '../models/jogo.dart';
import '../plugins/api_refresh_action.dart';
import '../plugins/live_matches_banner.dart';
import '../plugins/mata_mata_bracket_view.dart';
import '../plugins/partida_card.dart';
import '../plugins/section_header.dart';
import '../services/bolao_controller.dart';

enum VisualizacaoJogos { grupos, mataMata }

class JogosScreen extends StatefulWidget {
  final BolaoController controller;

  const JogosScreen({super.key, required this.controller});

  @override
  State<JogosScreen> createState() => _JogosScreenState();
}

class _JogosScreenState extends State<JogosScreen> {
  VisualizacaoJogos _visualizacao = VisualizacaoJogos.grupos;

  BolaoController get controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Partidas'),
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
                      constraints: const BoxConstraints(maxWidth: 1280),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SectionHeader(
                            title: 'Calendário',
                            subtitle:
                                'Fase de grupos separada do mata-mata para reduzir ruído',
                            trailing: SegmentedButton<VisualizacaoJogos>(
                              segments: const [
                                ButtonSegment(
                                  value: VisualizacaoJogos.grupos,
                                  icon: Icon(Icons.grid_view_outlined),
                                  label: Text('Grupos'),
                                ),
                                ButtonSegment(
                                  value: VisualizacaoJogos.mataMata,
                                  icon: Icon(Icons.account_tree_outlined),
                                  label: Text('Mata-mata'),
                                ),
                              ],
                              selected: {_visualizacao},
                              showSelectedIcon: false,
                              onSelectionChanged: (value) {
                                setState(() => _visualizacao = value.first);
                              },
                            ),
                          ),
                          if (_visualizacao == VisualizacaoJogos.grupos)
                            _GroupGames(controller: controller)
                          else
                            _KnockoutGames(controller: controller),
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
}

class _GroupGames extends StatelessWidget {
  final BolaoController controller;

  const _GroupGames({required this.controller});

  @override
  Widget build(BuildContext context) {
    final groups = controller.tabelasGrupos.tabelasPorGrupo.keys.toList()
      ..sort();

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1100
            ? 2
            : constraints.maxWidth >= 720
            ? 2
            : 1;
        final width = (constraints.maxWidth - ((columns - 1) * 12)) / columns;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final group in groups)
              SizedBox(
                width: width,
                child: _GroupBlock(controller: controller, group: group),
              ),
          ],
        );
      },
    );
  }
}

class _GroupBlock extends StatelessWidget {
  final BolaoController controller;
  final String group;

  const _GroupBlock({required this.controller, required this.group});

  @override
  Widget build(BuildContext context) {
    final jogos = controller.data.jogosOrdenados
        .where((jogo) => jogo.grupo == group && jogo.isFaseDeGrupos)
        .toList(growable: false);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Grupo $group',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Ver grupos',
                  onPressed: () => Navigator.pushNamed(
                    context,
                    AppRoutes.grupos,
                    arguments: group,
                  ),
                  icon: const Icon(Icons.table_chart_outlined),
                ),
              ],
            ),
            for (final jogo in jogos)
              PartidaCard(
                jogo: jogo,
                badgeMandante: controller.badgeDoTime(jogo.mandantePrevisto),
                badgeVisitante: controller.badgeDoTime(jogo.visitantePrevisto),
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRoutes.jogo,
                  arguments: jogo.jogoId,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _KnockoutGames extends StatelessWidget {
  final BolaoController controller;

  const _KnockoutGames({required this.controller});

  @override
  Widget build(BuildContext context) {
    final chaveamento = SistemaPontuacaoTimes.projetarChaveamento(
      jogos: controller.data.jogos,
      tabelas: controller.tabelasGrupos,
      usarResultadosReais: true,
    );

    final jogosPorFase = <String, List<Jogo>>{};
    for (final jogo in controller.data.jogosOrdenados.where(
      (jogo) => jogo.isMataMata,
    )) {
      jogosPorFase.putIfAbsent(jogo.faseCodigo, () => []).add(jogo);
    }

    final stages = [
      'round-of-32',
      'round-of-16',
      'quarter-finals',
      'semi-finals',
      'third-place',
      'final',
    ].where(jogosPorFase.containsKey).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Chaveamento projetado',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                MataMataBracketView(chaveamento: chaveamento),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        for (final stage in stages) ...[
          SectionHeader(title: _stageLabel(stage)),
          for (final jogo in jogosPorFase[stage]!)
            PartidaCard(
              jogo: jogo,
              badgeMandante: controller.badgeDoTime(jogo.mandantePrevisto),
              badgeVisitante: controller.badgeDoTime(jogo.visitantePrevisto),
              onTap: () => Navigator.pushNamed(
                context,
                AppRoutes.jogo,
                arguments: jogo.jogoId,
              ),
            ),
        ],
      ],
    );
  }

  String _stageLabel(String stage) {
    return switch (stage) {
      'round-of-32' => '16 avos de final',
      'round-of-16' => 'Oitavas de final',
      'quarter-finals' => 'Quartas de final',
      'semi-finals' => 'Semifinais',
      'third-place' => '3º e 4º lugar',
      'final' => 'Final',
      _ => stage,
    };
  }
}
