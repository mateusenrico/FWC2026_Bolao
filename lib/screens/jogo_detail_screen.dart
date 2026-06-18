import 'package:flutter/material.dart';

import '../core/app_routes.dart';
import '../core/functions/date_time_utils.dart';
import '../core/functions/team_normalizer.dart';
import '../models/jogo.dart';
import '../plugins/api_refresh_action.dart';
import '../plugins/palpite_participante_card.dart';
import '../plugins/section_header.dart';
import '../plugins/team_badge.dart';
import '../plugins/team_match_panel.dart';
import '../services/bolao_controller.dart';

class JogoDetailScreen extends StatefulWidget {
  final BolaoController controller;
  final String jogoId;

  const JogoDetailScreen({
    super.key,
    required this.controller,
    required this.jogoId,
  });

  @override
  State<JogoDetailScreen> createState() => _JogoDetailScreenState();
}

class _JogoDetailScreenState extends State<JogoDetailScreen> {
  bool _mostrarTodosPalpites = false;

  BolaoController get controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final jogo = controller.jogoPorId(widget.jogoId);

        if (jogo == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Partida')),
            body: const Center(child: Text('Jogo não encontrado.')),
          );
        }

        final ranking = controller.classificacao;
        final visibleRanking = _mostrarTodosPalpites
            ? ranking
            : ranking.take(5).toList(growable: false);

        return Scaffold(
          appBar: AppBar(
            title: Text('Jogo ${jogo.matchNumber}'),
            actions: [ApiRefreshAction(controller: controller)],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _MatchHero(controller: controller, jogo: jogo),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1180),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _MatchMetadata(jogo: jogo),
                          const SizedBox(height: 20),
                          _TeamPanels(controller: controller, jogo: jogo),
                          const SizedBox(height: 26),
                          SectionHeader(
                            title: 'Palpites dos participantes',
                            subtitle:
                                'Pontuação parcial calculada com o placar atual',
                            trailing: ranking.length > 5
                                ? TextButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _mostrarTodosPalpites =
                                            !_mostrarTodosPalpites;
                                      });
                                    },
                                    icon: Icon(
                                      _mostrarTodosPalpites
                                          ? Icons.expand_less
                                          : Icons.expand_more,
                                    ),
                                    label: Text(
                                      _mostrarTodosPalpites
                                          ? 'Recolher'
                                          : 'Ver todos',
                                    ),
                                  )
                                : null,
                          ),
                          for (final linha in visibleRanking)
                            PalpiteParticipanteCard(
                              linha: linha,
                              palpite: controller.palpiteDoParticipanteNoJogo(
                                participanteId: linha.participanteId,
                                jogoId: jogo.jogoId,
                              ),
                              pontuacao: controller
                                  .pontuacaoDoParticipanteNoJogo(
                                    participanteId: linha.participanteId,
                                    jogoId: jogo.jogoId,
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
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MatchHero extends StatelessWidget {
  final BolaoController controller;
  final Jogo jogo;

  const _MatchHero({required this.controller, required this.jogo});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final backgroundUrl = controller.imagemDoEstadio(jogo.jogoId);

    return Container(
      constraints: const BoxConstraints(minHeight: 240),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.primary, colors.primaryContainer],
        ),
      ),
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          if (backgroundUrl != null)
            Positioned.fill(
              child: Image.network(
                backgroundUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.25),
                    Colors.black.withValues(alpha: 0.72),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 30),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _phaseLabel(jogo),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white70,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _HeroTeam(
                            teamName: jogo.visitantePrevisto,
                            badgeUrl: controller.badgeDoTime(
                              jogo.visitantePrevisto,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: _HeroScore(jogo: jogo),
                        ),
                        Expanded(
                          child: _HeroTeam(
                            teamName: jogo.mandantePrevisto,
                            badgeUrl: controller.badgeDoTime(
                              jogo.mandantePrevisto,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      AppDateTime.dataHoraBrasilia(jogo),
                      textAlign: TextAlign.center,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _phaseLabel(Jogo jogo) {
    if (jogo.isFaseDeGrupos && jogo.grupo != null) {
      return 'GRUPO ${jogo.grupo}';
    }

    return jogo.fase.toUpperCase();
  }
}

class _HeroTeam extends StatelessWidget {
  final String teamName;
  final String? badgeUrl;

  const _HeroTeam({required this.teamName, required this.badgeUrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TeamBadge(teamName: teamName, imageUrl: badgeUrl, size: 64),
        const SizedBox(height: 8),
        Text(
          TeamNormalizer.sigla(teamName),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          teamName,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.white70),
        ),
      ],
    );
  }
}

class _HeroScore extends StatelessWidget {
  final Jogo jogo;

  const _HeroScore({required this.jogo});

  @override
  Widget build(BuildContext context) {
    final hasScore =
        jogo.temResultado &&
        jogo.golsMandante != null &&
        jogo.golsVisitante != null;

    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              hasScore ? '${jogo.golsVisitante}' : '-',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                '×',
                style: Theme.of(
                  context,
                ).textTheme.headlineMedium?.copyWith(color: Colors.white70),
              ),
            ),
            Text(
              hasScore ? '${jogo.golsMandante}' : '-',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          jogo.statusTexto,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Colors.white70,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _MatchMetadata extends StatelessWidget {
  final Jogo jogo;

  const _MatchMetadata({required this.jogo});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 24,
          runSpacing: 14,
          children: [
            _Info(
              icon: Icons.schedule,
              title: 'Horário',
              value: AppDateTime.dataHoraBrasilia(jogo),
            ),
            _Info(
              icon: Icons.stadium_outlined,
              title: 'Estádio',
              value: jogo.estadio.isEmpty ? 'A definir' : jogo.estadio,
            ),
            _Info(
              icon: Icons.location_city_outlined,
              title: 'Cidade',
              value: jogo.cidadeSede.isEmpty ? 'A definir' : jogo.cidadeSede,
            ),
            _Info(
              icon: Icons.tag,
              title: 'Partida',
              value: '#${jogo.matchNumber}',
            ),
          ],
        ),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _Info({required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SizedBox(
      width: 230,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                Text(
                  value,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamPanels extends StatelessWidget {
  final BolaoController controller;
  final Jogo jogo;

  const _TeamPanels({required this.controller, required this.jogo});

  @override
  Widget build(BuildContext context) {
    final visitante = TeamMatchPanel(
      teamName: jogo.visitantePrevisto,
      badgeUrl: controller.badgeDoTime(jogo.visitantePrevisto),
      goals: jogo.golsVisitante,
      tableLine: controller.linhaDoTimeNoGrupo(
        nomeTime: jogo.visitantePrevisto,
        grupo: jogo.grupo,
      ),
      homeSide: false,
    );

    final mandante = TeamMatchPanel(
      teamName: jogo.mandantePrevisto,
      badgeUrl: controller.badgeDoTime(jogo.mandantePrevisto),
      goals: jogo.golsMandante,
      tableLine: controller.linhaDoTimeNoGrupo(
        nomeTime: jogo.mandantePrevisto,
        grupo: jogo.grupo,
      ),
      homeSide: true,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 760) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: visitante),
              const SizedBox(width: 16),
              Expanded(child: mandante),
            ],
          );
        }

        return Column(
          children: [visitante, const SizedBox(height: 12), mandante],
        );
      },
    );
  }
}
