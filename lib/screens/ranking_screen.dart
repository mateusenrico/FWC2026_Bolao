import 'package:flutter/material.dart';

import '../core/app_routes.dart';
import '../plugins/api_refresh_action.dart';
import '../plugins/live_matches_banner.dart';
import '../plugins/ranking_evolution_chart.dart';
import '../plugins/ranking_mode_selector.dart';
import '../plugins/ranking_participante_card.dart';
import '../plugins/ranking_podium.dart';
import '../plugins/section_header.dart';
import '../services/bolao_controller.dart';

class RankingScreen extends StatefulWidget {
  final BolaoController controller;

  const RankingScreen({super.key, required this.controller});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  final Set<String> _selecionados = {};

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

        final points = _buildEvolutionPoints();

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
                            trailing: RankingModeSelector(
                              value: controller.ordenacaoRanking,
                              onChanged: controller.alterarOrdenacaoRanking,
                            ),
                          ),
                          RankingPodium(
                            ranking: ranking,
                            liveDelta: controller.pontosAoVivo,
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
                            subtitle:
                                'Pontuação acumulada por partida finalizada ou ao vivo',
                            trailing: TextButton.icon(
                              onPressed: () {
                                setState(() => _selecionados.clear());
                              },
                              icon: const Icon(Icons.visibility_off_outlined),
                              label: const Text('Limpar'),
                            ),
                          ),
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
                          ),
                          const SizedBox(height: 22),
                          const SectionHeader(
                            title: 'Lista completa',
                            subtitle:
                                'Máximo por partida já pontuável: 5 pontos por jogo',
                          ),
                          for (final linha in ranking)
                            RankingParticipanteCard(
                              linha: linha,
                              liveDelta: controller.pontosAoVivo(
                                linha.participanteId,
                              ),
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

  List<RankingEvolutionPoint> _buildEvolutionPoints() {
    final result = <RankingEvolutionPoint>[];

    for (final linha in controller.classificacaoProjetada) {
      final pontuacoes =
          linha.pontuacoesPalpites
              .where((pontuacao) => pontuacao.pontuavel)
              .toList(growable: false)
            ..sort((a, b) => a.matchNumber.compareTo(b.matchNumber));

      var total = 0;
      for (final pontuacao in pontuacoes) {
        total += pontuacao.pontos;
        result.add(
          RankingEvolutionPoint(
            participanteId: linha.participanteId,
            nome: linha.nome,
            matchNumber: pontuacao.matchNumber,
            pontos: total,
          ),
        );
      }
    }

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
