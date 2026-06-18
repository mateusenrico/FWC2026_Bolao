import 'package:flutter/material.dart';

import '../core/sistema_pontuacao_times.dart';
import '../core/functions/team_normalizer.dart';
import 'team_badge.dart';

class TeamMatchPanel extends StatelessWidget {
  final String teamName;
  final String? badgeUrl;
  final int? goals;
  final LinhaTabelaTime? tableLine;
  final bool homeSide;
  final bool compact;
  final VoidCallback? onTap;

  const TeamMatchPanel({
    super.key,
    required this.teamName,
    required this.badgeUrl,
    required this.goals,
    required this.tableLine,
    required this.homeSide,
    this.compact = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final content = Padding(
      padding: EdgeInsets.all(compact ? 12 : 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TeamBadge(
                teamName: teamName,
                imageUrl: badgeUrl,
                size: compact ? 38 : 54,
              ),
              SizedBox(width: compact ? 10 : 12),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      TeamNormalizer.sigla(teamName),
                      style:
                          (compact
                                  ? Theme.of(context).textTheme.titleMedium
                                  : Theme.of(context).textTheme.headlineSmall)
                              ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      teamName,
                      maxLines: compact ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: compact
                          ? Theme.of(context).textTheme.bodySmall
                          : Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 10 : 16),
          compact
              ? _CompactScore(
                  goals: goals,
                  label: homeSide ? 'mandante' : 'visitante',
                )
              : _FullScore(
                  goals: goals,
                  label: homeSide ? 'gols do mandante' : 'gols do visitante',
                ),
          SizedBox(height: compact ? 10 : 14),
          if (tableLine == null)
            Text(
              'Sem tabela de grupo para esta fase.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            )
          else
            Wrap(
              alignment: WrapAlignment.center,
              spacing: compact ? 6 : 10,
              runSpacing: compact ? 6 : 10,
              children: [
                _Stat(label: 'POS', value: '${tableLine!.posicao}º'),
                _Stat(label: 'P', value: '${tableLine!.pontos}'),
                _Stat(label: 'SG', value: '${tableLine!.saldoGols}'),
                if (!compact) ...[
                  _Stat(label: 'GP', value: '${tableLine!.golsPro}'),
                  _Stat(label: 'GC', value: '${tableLine!.golsContra}'),
                ],
              ],
            ),
        ],
      ),
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );
  }
}

class _FullScore extends StatelessWidget {
  final int? goals;
  final String label;

  const _FullScore({required this.goals, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            goals?.toString() ?? 'A definir',
            style:
                (goals == null
                        ? Theme.of(context).textTheme.titleMedium
                        : Theme.of(context).textTheme.displaySmall)
                    ?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: goals == null ? colors.onSurfaceVariant : null,
                    ),
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

class _CompactScore extends StatelessWidget {
  final int? goals;
  final String label;

  const _CompactScore({required this.goals, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            goals?.toString() ?? '-',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;

  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      constraints: const BoxConstraints(minWidth: 52),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
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
