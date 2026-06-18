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

  const TeamMatchPanel({
    super.key,
    required this.teamName,
    required this.badgeUrl,
    required this.goals,
    required this.tableLine,
    required this.homeSide,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TeamBadge(teamName: teamName, imageUrl: badgeUrl, size: 54),
                const SizedBox(width: 12),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        TeamNormalizer.sigla(teamName),
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      Text(
                        teamName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
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
                              color: goals == null
                                  ? colors.onSurfaceVariant
                                  : null,
                            ),
                  ),
                  Text(
                    homeSide ? 'gols do mandante' : 'gols do visitante',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
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
                spacing: 10,
                runSpacing: 10,
                children: [
                  _Stat(label: 'POS', value: '${tableLine!.posicao}º'),
                  _Stat(label: 'PTS', value: '${tableLine!.pontos}'),
                  _Stat(label: 'SG', value: '${tableLine!.saldoGols}'),
                  _Stat(label: 'GP', value: '${tableLine!.golsPro}'),
                  _Stat(label: 'GC', value: '${tableLine!.golsContra}'),
                ],
              ),
          ],
        ),
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
