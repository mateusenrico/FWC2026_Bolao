import 'package:flutter/material.dart';

import '../core/functions/team_normalizer.dart';
import '../core/sistema_pontuacao_times.dart';
import 'team_badge.dart';

typedef TeamBadgeUrlResolver = String? Function(String teamName);

class MataMataBracketView extends StatelessWidget {
  final ChaveamentoProjetado chaveamento;
  final TeamBadgeUrlResolver? badgeUrlForTeam;

  const MataMataBracketView({
    super.key,
    required this.chaveamento,
    this.badgeUrlForTeam,
  });

  @override
  Widget build(BuildContext context) {
    final stages = <String, List<JogoProjetado>>{};

    for (final jogo in chaveamento.jogosPorMatchNumber.values) {
      stages.putIfAbsent(jogo.faseCodigo, () => []).add(jogo);
    }

    for (final jogos in stages.values) {
      jogos.sort((a, b) => a.matchNumber.compareTo(b.matchNumber));
    }

    final orderedStages = [
      'round-of-32',
      'round-of-16',
      'quarter-finals',
      'semi-finals',
      'third-place',
      'final',
    ].where((stage) => stages.containsKey(stage)).toList(growable: false);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 720) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final stage in orderedStages)
                _StageColumn(
                  stage: stage,
                  jogos: stages[stage]!,
                  badgeUrlForTeam: badgeUrlForTeam,
                ),
            ],
          );
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final stage in orderedStages)
                SizedBox(
                  width: stage == 'round-of-32' ? 230 : 210,
                  child: _StageColumn(
                    stage: stage,
                    jogos: stages[stage]!,
                    badgeUrlForTeam: badgeUrlForTeam,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _StageColumn extends StatelessWidget {
  final String stage;
  final List<JogoProjetado> jogos;
  final TeamBadgeUrlResolver? badgeUrlForTeam;

  const _StageColumn({
    required this.stage,
    required this.jogos,
    required this.badgeUrlForTeam,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _stageLabel(stage),
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          for (final jogo in jogos)
            _ProjectedGameTile(jogo: jogo, badgeUrlForTeam: badgeUrlForTeam),
        ],
      ),
    );
  }

  String _stageLabel(String stage) {
    return switch (stage) {
      'round-of-32' => '16 avos',
      'round-of-16' => 'Oitavas',
      'quarter-finals' => 'Quartas',
      'semi-finals' => 'Semifinais',
      'third-place' => '3º lugar',
      'final' => 'Final',
      _ => stage,
    };
  }
}

class _ProjectedGameTile extends StatelessWidget {
  final JogoProjetado jogo;
  final TeamBadgeUrlResolver? badgeUrlForTeam;

  const _ProjectedGameTile({required this.jogo, required this.badgeUrlForTeam});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Jogo ${jogo.matchNumber}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          _TeamLine(
            name: jogo.mandante?.nome,
            badgeUrl: _badgeFor(jogo.mandante?.nome),
            goals: jogo.golsMandante,
            winner: jogo.vencedor?.timeKey == jogo.mandante?.timeKey,
          ),
          _TeamLine(
            name: jogo.visitante?.nome,
            badgeUrl: _badgeFor(jogo.visitante?.nome),
            goals: jogo.golsVisitante,
            winner: jogo.vencedor?.timeKey == jogo.visitante?.timeKey,
          ),
        ],
      ),
    );
  }

  String? _badgeFor(String? name) {
    if (name == null || badgeUrlForTeam == null) {
      return null;
    }

    return badgeUrlForTeam!(name);
  }
}

class _TeamLine extends StatelessWidget {
  final String? name;
  final String? badgeUrl;
  final int? goals;
  final bool winner;

  const _TeamLine({
    required this.name,
    required this.badgeUrl,
    required this.goals,
    required this.winner,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          if (name != null) ...[
            TeamBadge(teamName: name!, imageUrl: badgeUrl, size: 22),
            const SizedBox(width: 7),
          ],
          Expanded(
            child: Text(
              name == null ? 'A definir' : TeamNormalizer.sigla(name!),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: winner ? FontWeight.w900 : FontWeight.w600,
              ),
            ),
          ),
          Text(
            goals?.toString() ?? '',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}
