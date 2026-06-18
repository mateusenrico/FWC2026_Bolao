import 'package:flutter/material.dart';

import '../core/functions/team_normalizer.dart';
import '../models/jogo.dart';
import '../services/sportsdb_api_service.dart';
import 'section_header.dart';

class MatchApiDetails extends StatelessWidget {
  final Jogo jogo;
  final SportsDbEventDetailsResult? details;
  final bool loading;
  final String? liveClock;

  const MatchApiDetails({
    super.key,
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
              : 'Ao vivo - $liveClock',
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
              ].join(' - '),
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
