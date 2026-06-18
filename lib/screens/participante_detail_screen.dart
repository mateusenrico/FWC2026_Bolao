import 'package:flutter/material.dart';

import '../core/app_routes.dart';
import '../core/sistema_pontuacao_participantes.dart';
import '../models/jogo.dart';
import '../plugins/api_refresh_action.dart';
import '../plugins/chaveamento_participante_card.dart';
import '../plugins/palpite_jogo_card.dart';
import '../plugins/section_header.dart';
import '../services/bolao_controller.dart';

enum FiltroPalpitesParticipante { pontuando, futuros }

class ParticipanteDetailScreen extends StatefulWidget {
  final BolaoController controller;
  final String participanteId;

  const ParticipanteDetailScreen({
    super.key,
    required this.controller,
    required this.participanteId,
  });

  @override
  State<ParticipanteDetailScreen> createState() =>
      _ParticipanteDetailScreenState();
}

class _ParticipanteDetailScreenState extends State<ParticipanteDetailScreen> {
  FiltroPalpitesParticipante _filtro = FiltroPalpitesParticipante.pontuando;

  BolaoController get controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final linha = controller.linhaParticipante(widget.participanteId);
        final participante = controller.participantePorId(
          widget.participanteId,
        );

        if (linha == null || participante == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Participante')),
            body: const Center(child: Text('Participante não encontrado.')),
          );
        }

        final jogos = _filtrarJogos(controller.data.jogosOrdenados);

        return Scaffold(
          appBar: AppBar(
            title: Text(participante.nome),
            actions: [ApiRefreshAction(controller: controller)],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 36),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ParticipantHeader(linha: linha),
                    const SizedBox(height: 12),
                    ChaveamentoParticipanteCard(
                      chaveamento: linha.chaveamentoPrevisto,
                      pontuacaoFinal: linha.pontuacaoFinal,
                    ),
                    const SizedBox(height: 24),
                    const SectionHeader(
                      title: 'Palpites',
                      subtitle: 'Jogos sempre ordenados pela numeração oficial',
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Finalizados / ao vivo'),
                          selected:
                              _filtro == FiltroPalpitesParticipante.pontuando,
                          onSelected: (_) {
                            setState(() {
                              _filtro = FiltroPalpitesParticipante.pontuando;
                            });
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Jogos futuros'),
                          selected:
                              _filtro == FiltroPalpitesParticipante.futuros,
                          onSelected: (_) {
                            setState(() {
                              _filtro = FiltroPalpitesParticipante.futuros;
                            });
                          },
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
                        PalpiteJogoCard(
                          jogo: jogo,
                          palpite: controller.palpiteDoParticipanteNoJogo(
                            participanteId: widget.participanteId,
                            jogoId: jogo.jogoId,
                          ),
                          pontuacao: controller.pontuacaoDoParticipanteNoJogo(
                            participanteId: widget.participanteId,
                            jogoId: jogo.jogoId,
                          ),
                          badgeMandante: controller.badgeDoTime(
                            jogo.mandantePrevisto,
                          ),
                          badgeVisitante: controller.badgeDoTime(
                            jogo.visitantePrevisto,
                          ),
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.jogo,
                              arguments: jogo.jogoId,
                            );
                          },
                        ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<Jogo> _filtrarJogos(List<Jogo> jogos) {
    final result =
        jogos
            .where((jogo) {
              switch (_filtro) {
                case FiltroPalpitesParticipante.pontuando:
                  return jogo.temResultado || jogo.isEmAndamento;
                case FiltroPalpitesParticipante.futuros:
                  return !jogo.temResultado && jogo.isAgendado;
              }
            })
            .toList(growable: false)
          ..sort((a, b) => a.ordem.compareTo(b.ordem));

    return result;
  }
}

class _ParticipantHeader extends StatelessWidget {
  final LinhaPontuacaoParticipante linha;

  const _ParticipantHeader({required this.linha});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      color: colors.primaryContainer.withValues(alpha: 0.42),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 620;

            final summary = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  linha.nome,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${linha.posicao}º lugar no ranking parcial',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            );

            final points = Column(
              crossAxisAlignment: compact
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.end,
              children: [
                Text(
                  '${linha.pontosTotal}',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Text('pontos'),
              ],
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (compact) ...[
                  summary,
                  const SizedBox(height: 12),
                  points,
                ] else
                  Row(
                    children: [
                      Expanded(child: summary),
                      points,
                    ],
                  ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _Metric(
                      label: 'Placar exato',
                      value: '${linha.placaresExatos}',
                    ),
                    _Metric(
                      label: 'Resultados',
                      value: '${linha.resultadosCorretos}',
                    ),
                    _Metric(
                      label: 'Pontos em jogos',
                      value: '${linha.pontosJogos}',
                    ),
                    _Metric(
                      label: 'Pontos em grupos',
                      value: '${linha.pontosGrupos}',
                    ),
                    _Metric(
                      label: 'Pontos finais',
                      value: '${linha.pontosFinal}',
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;

  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
