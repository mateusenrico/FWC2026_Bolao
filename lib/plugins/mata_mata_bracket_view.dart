import 'package:flutter/material.dart';

import '../core/functions/team_normalizer.dart';
import '../core/sistema_pontuacao_times.dart';

class MataMataBracketView extends StatelessWidget {
  final ChaveamentoProjetado chaveamento;

  const MataMataBracketView({super.key, required this.chaveamento});

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
                _StageColumn(stage: stage, jogos: stages[stage]!),
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
                  child: _StageColumn(stage: stage, jogos: stages[stage]!),
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

  const _StageColumn({required this.stage, required this.jogos});

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
          for (final jogo in jogos) _ProjectedGameTile(jogo: jogo),
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

  const _ProjectedGameTile({required this.jogo});

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
            goals: jogo.golsMandante,
            winner: jogo.vencedor?.timeKey == jogo.mandante?.timeKey,
          ),
          _TeamLine(
            name: jogo.visitante?.nome,
            goals: jogo.golsVisitante,
            winner: jogo.vencedor?.timeKey == jogo.visitante?.timeKey,
          ),
        ],
      ),
    );
  }
}

class _TeamLine extends StatelessWidget {
  final String? name;
  final int? goals;
  final bool winner;

  const _TeamLine({
    required this.name,
    required this.goals,
    required this.winner,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
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
