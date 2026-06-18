import 'package:flutter/material.dart';

import '../core/app_routes.dart';
import '../core/functions/team_normalizer.dart';
import '../core/sistema_pontuacao_participantes.dart';
import '../core/sistema_pontuacao_times.dart';
import '../models/bolao_data.dart';
import '../models/jogo.dart';
import '../plugins/api_refresh_action.dart';
import '../plugins/live_matches_banner.dart';
import '../plugins/mata_mata_bracket_view.dart';
import '../plugins/ranking_participante_card.dart';
import '../plugins/section_header.dart';
import '../plugins/team_badge.dart';
import '../services/bolao_controller.dart';

enum SimuladorFase { grupos, mataMata }

class SimuladorScreen extends StatefulWidget {
  final BolaoController controller;

  const SimuladorScreen({super.key, required this.controller});

  @override
  State<SimuladorScreen> createState() => _SimuladorScreenState();
}

class _SimuladorScreenState extends State<SimuladorScreen> {
  SimuladorFase _fase = SimuladorFase.grupos;
  String _query = '';
  final Map<String, TextEditingController> _homeControllers = {};
  final Map<String, TextEditingController> _awayControllers = {};

  BolaoController get controller => widget.controller;

  @override
  void dispose() {
    for (final controller in _homeControllers.values) {
      controller.dispose();
    }
    for (final controller in _awayControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final jogos = _jogosSimulaveis();
        final dataSimulada = _dataSimulada();
        final ranking = SistemaPontuacaoParticipantes.calcularClassificacao(
          dataSimulada,
        );
        final tabelas = SistemaPontuacaoTimes.calcularTabelasReais(
          dataSimulada.jogos,
        );
        final chaveamento = SistemaPontuacaoTimes.projetarChaveamento(
          jogos: dataSimulada.jogos,
          tabelas: tabelas,
          usarResultadosReais: true,
        );

        return Scaffold(
          appBar: AppBar(
            title: const Text('Simulações'),
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
                            title: 'Simular placares',
                            subtitle:
                                'Os valores aqui só existem nesta tela e não alteram os assets',
                            trailing: SegmentedButton<SimuladorFase>(
                              segments: const [
                                ButtonSegment(
                                  value: SimuladorFase.grupos,
                                  icon: Icon(Icons.grid_view_outlined),
                                  label: Text('Grupos'),
                                ),
                                ButtonSegment(
                                  value: SimuladorFase.mataMata,
                                  icon: Icon(Icons.account_tree_outlined),
                                  label: Text('Mata-mata'),
                                ),
                              ],
                              selected: {_fase},
                              showSelectedIcon: false,
                              onSelectionChanged: (value) {
                                setState(() => _fase = value.first);
                              },
                            ),
                          ),
                          TextField(
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.search),
                              hintText: 'Buscar jogo, time, grupo ou fase',
                            ),
                            onChanged: (value) {
                              setState(() => _query = value);
                            },
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: _temPlacarSimulado
                                  ? _limparSimulacao
                                  : null,
                              icon: const Icon(Icons.backspace_outlined),
                              label: const Text('Limpar placares'),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _SimulationInputs(
                            controller: controller,
                            jogos: jogos,
                            homeControllers: _homeControllers,
                            awayControllers: _awayControllers,
                            onChanged: () => setState(() {}),
                          ),
                          const SizedBox(height: 22),
                          const SectionHeader(
                            title: 'Ranking simulado',
                            subtitle:
                                'Inclui os placares digitados como resultados provisórios',
                          ),
                          for (final linha in ranking)
                            RankingParticipanteCard(
                              linha: linha,
                              onTap: () => Navigator.pushNamed(
                                context,
                                AppRoutes.participante,
                                arguments: linha.participanteId,
                              ),
                            ),
                          const SizedBox(height: 22),
                          const SectionHeader(title: 'Chaveamento simulado'),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: MataMataBracketView(
                                chaveamento: chaveamento,
                                badgeUrlForTeam: controller.badgeDoTime,
                              ),
                            ),
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

  List<Jogo> _jogosSimulaveis() {
    final query = TeamNormalizer.normalize(_query);
    final jogos = controller.data.jogosOrdenados
        .where((jogo) {
          if (jogo.resultadoFinal) {
            return false;
          }

          return _fase == SimuladorFase.grupos
              ? jogo.isFaseDeGrupos
              : jogo.isMataMata;
        })
        .where((jogo) {
          if (query.isEmpty) {
            return true;
          }

          final haystack = TeamNormalizer.normalize(
            [
              jogo.matchNumber.toString(),
              jogo.mandantePrevisto,
              jogo.visitantePrevisto,
              jogo.grupo ?? '',
              jogo.fase,
            ].join(' '),
          );

          return haystack.contains(query);
        })
        .take(12)
        .toList(growable: false);

    return jogos;
  }

  BolaoData _dataSimulada() {
    final jogos = controller.data.jogos
        .map((jogo) {
          final home = int.tryParse(_homeControllers[jogo.jogoId]?.text ?? '');
          final away = int.tryParse(_awayControllers[jogo.jogoId]?.text ?? '');

          if (home == null || away == null) {
            return jogo;
          }

          return Jogo.fromJson({
            ...jogo.toJson(),
            'statusJogo': 'em_andamento',
            'golsMandante': home,
            'golsVisitante': away,
            'temResultado': true,
            'resultadoFinal': false,
            'fonteResultado': 'simulador',
          });
        })
        .toList(growable: false);

    return controller.data.copyWith(jogos: jogos);
  }

  bool get _temPlacarSimulado {
    bool preenchido(TextEditingController controller) {
      return controller.text.trim().isNotEmpty;
    }

    return _homeControllers.values.any(preenchido) ||
        _awayControllers.values.any(preenchido);
  }

  void _limparSimulacao() {
    for (final controller in _homeControllers.values) {
      controller.clear();
    }
    for (final controller in _awayControllers.values) {
      controller.clear();
    }
    setState(() {});
  }
}

class _SimulationInputs extends StatelessWidget {
  final BolaoController controller;
  final List<Jogo> jogos;
  final Map<String, TextEditingController> homeControllers;
  final Map<String, TextEditingController> awayControllers;
  final VoidCallback onChanged;

  const _SimulationInputs({
    required this.controller,
    required this.jogos,
    required this.homeControllers,
    required this.awayControllers,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (jogos.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('Não há jogos disponíveis para simular nesta fase.'),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1020
            ? 3
            : constraints.maxWidth >= 680
            ? 2
            : 1;
        final width = (constraints.maxWidth - ((columns - 1) * 12)) / columns;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final jogo in jogos)
              SizedBox(
                width: width,
                child: _SimulationCard(
                  controller: controller,
                  jogo: jogo,
                  homeController: homeControllers.putIfAbsent(
                    jogo.jogoId,
                    TextEditingController.new,
                  ),
                  awayController: awayControllers.putIfAbsent(
                    jogo.jogoId,
                    TextEditingController.new,
                  ),
                  onChanged: onChanged,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SimulationCard extends StatelessWidget {
  final BolaoController controller;
  final Jogo jogo;
  final TextEditingController homeController;
  final TextEditingController awayController;
  final VoidCallback onChanged;

  const _SimulationCard({
    required this.controller,
    required this.jogo,
    required this.homeController,
    required this.awayController,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Jogo ${jogo.matchNumber} · ${jogo.grupo == null ? jogo.fase : 'Grupo ${jogo.grupo}'}',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _SimulationTeam(
                    name: jogo.mandantePrevisto,
                    badgeUrl: controller.badgeDoTime(jogo.mandantePrevisto),
                    alignEnd: true,
                  ),
                ),
                const SizedBox(width: 10),
                _ScoreInput(controller: homeController, onChanged: onChanged),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 7),
                  child: Text('×'),
                ),
                _ScoreInput(controller: awayController, onChanged: onChanged),
                const SizedBox(width: 10),
                Expanded(
                  child: _SimulationTeam(
                    name: jogo.visitantePrevisto,
                    badgeUrl: controller.badgeDoTime(jogo.visitantePrevisto),
                    alignEnd: false,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SimulationTeam extends StatelessWidget {
  final String name;
  final String? badgeUrl;
  final bool alignEnd;

  const _SimulationTeam({
    required this.name,
    required this.badgeUrl,
    required this.alignEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        TeamBadge(teamName: name, imageUrl: badgeUrl, size: 34),
        const SizedBox(height: 5),
        Text(
          TeamNormalizer.sigla(name),
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: alignEnd ? TextAlign.right : TextAlign.left,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }
}

class _ScoreInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onChanged;

  const _ScoreInput({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      child: TextField(
        controller: controller,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        ),
        onChanged: (_) => onChanged(),
      ),
    );
  }
}
