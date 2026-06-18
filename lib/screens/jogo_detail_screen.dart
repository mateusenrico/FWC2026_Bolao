import 'dart:async';

import 'package:flutter/material.dart';

import '../core/app_routes.dart';
import '../core/functions/date_time_utils.dart';
import '../core/functions/team_normalizer.dart';
import '../models/jogo.dart';
import '../plugins/api_refresh_action.dart';
import '../plugins/live_matches_banner.dart';
import '../plugins/palpite_result_group_card.dart';
import '../plugins/remote_media.dart';
import '../plugins/section_header.dart';
import '../plugins/team_badge.dart';
import '../plugins/team_match_panel.dart';
import '../plugins/youtube_embed_player.dart';
import '../services/bolao_controller.dart';
import '../services/sportsdb_api_service.dart';

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

        _solicitarDetalhesSeNecessario(jogo);
        final gruposPalpites = controller.gruposDePalpitesDoJogo(jogo.jogoId);
        final details = controller.detalhesEventoDoJogo(jogo.jogoId);
        final loadingDetails = controller.carregandoDetalhesEvento(jogo.jogoId);

        return Scaffold(
          appBar: AppBar(
            title: Text('Jogo ${jogo.matchNumber}'),
            actions: [ApiRefreshAction(controller: controller)],
          ),
          body: Column(
            children: [
              LiveMatchesBanner(controller: controller),
              Expanded(
                child: SingleChildScrollView(
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
                                _MatchMetadata(
                                  controller: controller,
                                  jogo: jogo,
                                ),
                                if (controller.videoDoJogo(jogo.jogoId) !=
                                    null) ...[
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 560,
                                      ),
                                      child: YoutubeEmbedPlayer(
                                        url: controller.videoDoJogo(
                                          jogo.jogoId,
                                        )!,
                                        title: 'Highlights da partida',
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 20),
                                _TeamPanels(controller: controller, jogo: jogo),
                                const SizedBox(height: 22),
                                _MatchApiDetails(
                                  jogo: jogo,
                                  details: details,
                                  loading: loadingDetails,
                                  liveClock: controller.tempoAtualDoJogo(jogo),
                                ),
                                const SizedBox(height: 26),
                                const SectionHeader(
                                  title: 'Palpites dos participantes',
                                  subtitle: 'Agrupados pelo resultado apostado',
                                ),
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    if (constraints.maxWidth >= 900) {
                                      return Wrap(
                                        spacing: 12,
                                        runSpacing: 12,
                                        children: [
                                          for (final group in gruposPalpites)
                                            SizedBox(
                                              width:
                                                  (constraints.maxWidth - 12) /
                                                  2,
                                              child: PalpiteResultGroupCard(
                                                jogo: jogo,
                                                group: group,
                                                onTapParticipante: (id) => () {
                                                  Navigator.pushNamed(
                                                    context,
                                                    AppRoutes.participante,
                                                    arguments: id,
                                                  );
                                                },
                                              ),
                                            ),
                                        ],
                                      );
                                    }

                                    return Column(
                                      children: [
                                        for (final group in gruposPalpites)
                                          PalpiteResultGroupCard(
                                            jogo: jogo,
                                            group: group,
                                            onTapParticipante: (id) => () {
                                              Navigator.pushNamed(
                                                context,
                                                AppRoutes.participante,
                                                arguments: id,
                                              );
                                            },
                                          ),
                                      ],
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
              ),
            ],
          ),
        );
      },
    );
  }

  void _solicitarDetalhesSeNecessario(Jogo jogo) {
    if (controller.detalhesEventoDoJogo(jogo.jogoId) != null ||
        controller.carregandoDetalhesEvento(jogo.jogoId)) {
      return;
    }

    if (jogo.idEventAtual == null &&
        controller.historicoDoJogo(jogo.jogoId)?.idEvent == null) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(controller.carregarDetalhesEventoDoJogo(jogo.jogoId));
    });
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
              child: RemoteImage(
                url: backgroundUrl,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.zero,
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
                            teamName: jogo.mandantePrevisto,
                            badgeUrl: controller.badgeDoTime(
                              jogo.mandantePrevisto,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: _HeroScore(jogo: jogo),
                        ),
                        Expanded(
                          child: _HeroTeam(
                            teamName: jogo.visitantePrevisto,
                            badgeUrl: controller.badgeDoTime(
                              jogo.visitantePrevisto,
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
          if (backgroundUrl != null)
            const Positioned(right: 16, bottom: 10, child: MediaCredit()),
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

    if (!hasScore) {
      return Column(
        children: [
          Text(
            'VS',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
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

    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${jogo.golsMandante}',
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
              '${jogo.golsVisitante}',
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
  final BolaoController controller;
  final Jogo jogo;

  const _MatchMetadata({required this.controller, required this.jogo});

  @override
  Widget build(BuildContext context) {
    final venue = controller.venueDoJogo(jogo);

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
              value: venue?.localTexto.isNotEmpty == true
                  ? venue!.localTexto
                  : jogo.localTexto,
            ),
            if (venue?.capacidade != null)
              _Info(
                icon: Icons.groups_outlined,
                title: 'Capacidade',
                value: '${venue!.capacidade} lugares',
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

class _MatchApiDetails extends StatelessWidget {
  final Jogo jogo;
  final SportsDbEventDetailsResult? details;
  final bool loading;
  final String? liveClock;

  const _MatchApiDetails({
    required this.jogo,
    required this.details,
    required this.loading,
    required this.liveClock,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final notableTimeline =
        details?.timeline
            .where((item) => item.isGoal || item.isCard)
            .toList(growable: false) ??
        const <SportsDbTimelineItem>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Dados da partida',
          subtitle: liveClock == null
              ? 'Eventos, estatísticas e escalações quando a API disponibilizar'
              : 'Ao vivo · $liveClock',
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (loading) ...[
                  const LinearProgressIndicator(),
                  const SizedBox(height: 12),
                ],
                if (details == null && loading)
                  const Text('Buscando detalhes na SportsDB...')
                else if (details == null)
                  const Text('Detalhes ainda não carregados.')
                else if (!details!.hasAnyData)
                  Text(
                    'A SportsDB ainda não trouxe timeline, estatísticas ou escalações para esta partida.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  )
                else ...[
                  if (details!.stats.isNotEmpty)
                    _StatsPreview(stats: details!.stats),
                  if (details!.stats.isNotEmpty &&
                      (notableTimeline.isNotEmpty ||
                          details!.lineup.isNotEmpty))
                    const SizedBox(height: 16),
                  if (notableTimeline.isNotEmpty)
                    _TimelinePreview(items: notableTimeline),
                  if (notableTimeline.isNotEmpty && details!.lineup.isNotEmpty)
                    const SizedBox(height: 16),
                  if (details!.lineup.isNotEmpty)
                    _LineupPreview(jogo: jogo, lineup: details!.lineup),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatsPreview extends StatelessWidget {
  final List<SportsDbEventStat> stats;

  const _StatsPreview({required this.stats});

  @override
  Widget build(BuildContext context) {
    final visible = stats.take(6).toList(growable: false);
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Estatísticas',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        for (final stat in visible)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 48,
                  child: Text(
                    stat.home ?? '-',
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    stat.name ?? 'Estatística',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 48,
                  child: Text(
                    stat.away ?? '-',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _TimelinePreview extends StatelessWidget {
  final List<SportsDbTimelineItem> items;

  const _TimelinePreview({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Gols e cartões',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [for (final item in items) _TimelineChip(item: item)],
        ),
      ],
    );
  }
}

class _TimelineChip extends StatelessWidget {
  final SportsDbTimelineItem item;

  const _TimelineChip({required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = item.isGoal
        ? colors.primaryContainer
        : item.isRedCard
        ? colors.errorContainer
        : colors.tertiaryContainer;

    return Container(
      constraints: const BoxConstraints(maxWidth: 240),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            item.minute == null ? '' : "${item.minute}' ",
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          Flexible(
            child: Text(
              [
                item.displayType,
                if (item.player != null) item.player!,
              ].join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _LineupPreview extends StatelessWidget {
  final Jogo jogo;
  final List<SportsDbLineupItem> lineup;

  const _LineupPreview({required this.jogo, required this.lineup});

  @override
  Widget build(BuildContext context) {
    final mandante = _lineupFor(jogo.mandantePrevisto);
    final visitante = _lineupFor(jogo.visitantePrevisto);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Escalações',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final panels = [
              _LineupTeamPanel(title: jogo.mandantePrevisto, items: mandante),
              _LineupTeamPanel(title: jogo.visitantePrevisto, items: visitante),
            ];

            if (constraints.maxWidth >= 680) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: panels[0]),
                  const SizedBox(width: 12),
                  Expanded(child: panels[1]),
                ],
              );
            }

            return Column(
              children: [panels[0], const SizedBox(height: 10), panels[1]],
            );
          },
        ),
      ],
    );
  }

  List<SportsDbLineupItem> _lineupFor(String teamName) {
    final teamKey = TeamNormalizer.key(teamName);
    final result = lineup
        .where((item) {
          final itemKey = TeamNormalizer.key(item.team ?? '');
          return itemKey == teamKey || itemKey.contains(teamKey);
        })
        .toList(growable: false);

    if (result.isEmpty) {
      return lineup.take(11).toList(growable: false);
    }

    return result;
  }
}

class _LineupTeamPanel extends StatelessWidget {
  final String title;
  final List<SportsDbLineupItem> items;

  const _LineupTeamPanel({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final starters = items.where((item) => !item.isSubstitute).take(11);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          if (starters.isEmpty)
            Text(
              'Escalação não disponível.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            )
          else
            for (final item in starters)
              Text(
                [
                  if (item.number != null) item.number!,
                  item.player ?? 'Jogador',
                  if (item.position != null) '(${item.position})',
                ].join(' '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
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
    final mandante = TeamMatchPanel(
      teamName: jogo.mandantePrevisto,
      badgeUrl: controller.badgeDoTime(jogo.mandantePrevisto),
      goals: jogo.golsMandante,
      tableLine: controller.linhaDoTimeNoGrupo(
        nomeTime: jogo.mandantePrevisto,
        grupo: jogo.grupo,
      ),
      homeSide: true,
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.time,
        arguments: jogo.mandantePrevisto,
      ),
    );

    final visitante = TeamMatchPanel(
      teamName: jogo.visitantePrevisto,
      badgeUrl: controller.badgeDoTime(jogo.visitantePrevisto),
      goals: jogo.golsVisitante,
      tableLine: controller.linhaDoTimeNoGrupo(
        nomeTime: jogo.visitantePrevisto,
        grupo: jogo.grupo,
      ),
      homeSide: false,
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.time,
        arguments: jogo.visitantePrevisto,
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 760) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: mandante),
              const SizedBox(width: 16),
              Expanded(child: visitante),
            ],
          );
        }

        return Column(
          children: [mandante, const SizedBox(height: 12), visitante],
        );
      },
    );
  }
}
