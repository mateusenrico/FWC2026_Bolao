import 'package:flutter/material.dart';

import '../core/app_routes.dart';
import '../core/sistema_pontuacao_participantes.dart';
import '../core/sistema_pontuacao_times.dart';
import '../models/bolao_data.dart';
import '../models/jogo.dart';
import '../plugins/api_refresh_action.dart';
import '../plugins/live_matches_banner.dart';
import '../plugins/mata_mata_bracket_view.dart';
import '../plugins/ranking_participante_card.dart';
import '../plugins/section_header.dart';
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
                          _SimulationInputs(
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
    final jogos = controller.data.jogosOrdenados
        .where((jogo) {
          if (jogo.resultadoFinal) {
            return false;
          }

          return _fase == SimuladorFase.grupos
              ? jogo.isFaseDeGrupos
              : jogo.isMataMata;
        })
        .take(18)
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
}

class _SimulationInputs extends StatelessWidget {
  final List<Jogo> jogos;
  final Map<String, TextEditingController> homeControllers;
  final Map<String, TextEditingController> awayControllers;
  final VoidCallback onChanged;

  const _SimulationInputs({
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

    return Column(
      children: [
        for (final jogo in jogos)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  SizedBox(
                    width: 68,
                    child: Text(
                      'Jogo ${jogo.matchNumber}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      jogo.confrontoPrevisto,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _ScoreInput(
                    controller: homeControllers.putIfAbsent(
                      jogo.jogoId,
                      TextEditingController.new,
                    ),
                    onChanged: onChanged,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('×'),
                  ),
                  _ScoreInput(
                    controller: awayControllers.putIfAbsent(
                      jogo.jogoId,
                      TextEditingController.new,
                    ),
                    onChanged: onChanged,
                  ),
                ],
              ),
            ),
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
