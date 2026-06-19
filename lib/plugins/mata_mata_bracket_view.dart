import 'package:flutter/material.dart';

import '../core/functions/team_normalizer.dart';
import '../core/sistema_pontuacao_times.dart';
import 'team_badge.dart';

typedef TeamBadgeUrlResolver = String? Function(String teamName);

const _stageOrder = [
  'round-of-32',
  'round-of-16',
  'quarter-finals',
  'semi-finals',
  'final',
  'third-place',
];

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

    final orderedStages = _stageOrder
        .where((stage) => stages.containsKey(stage))
        .toList(growable: false);

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

        if (constraints.maxWidth >= 960) {
          return _SplitBracket(
            stages: [
              for (final stage in orderedStages)
                _BracketStage(stage: stage, jogos: stages[stage]!),
            ],
            badgeUrlForTeam: badgeUrlForTeam,
          );
        }

        return _ConnectedBracket(
          stages: [
            for (final stage in orderedStages)
              _BracketStage(stage: stage, jogos: stages[stage]!),
          ],
          badgeUrlForTeam: badgeUrlForTeam,
        );
      },
    );
  }
}

class _SplitBracket extends StatelessWidget {
  final List<_BracketStage> stages;
  final TeamBadgeUrlResolver? badgeUrlForTeam;

  const _SplitBracket({required this.stages, required this.badgeUrlForTeam});

  @override
  Widget build(BuildContext context) {
    final knockoutStages = stages
        .where(
          (stage) => stage.stage != 'final' && stage.stage != 'third-place',
        )
        .toList(growable: false);
    final finalStage = stages
        .where(
          (stage) => stage.stage == 'final' || stage.stage == 'third-place',
        )
        .toList(growable: false);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _BracketHalf(
              stages: knockoutStages,
              firstHalf: true,
              badgeUrlForTeam: badgeUrlForTeam,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _FinalColumn(
                stages: finalStage,
                badgeUrlForTeam: badgeUrlForTeam,
              ),
            ),
            _BracketHalf(
              stages: knockoutStages.reversed.toList(growable: false),
              firstHalf: false,
              badgeUrlForTeam: badgeUrlForTeam,
            ),
          ],
        ),
      ),
    );
  }
}

class _BracketHalf extends StatelessWidget {
  final List<_BracketStage> stages;
  final bool firstHalf;
  final TeamBadgeUrlResolver? badgeUrlForTeam;

  const _BracketHalf({
    required this.stages,
    required this.firstHalf,
    required this.badgeUrlForTeam,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (var index = 0; index < stages.length; index++) ...[
          SizedBox(
            width: 216,
            child: _StageColumn(
              stage: stages[index].stage,
              jogos: _half(stages[index].jogos, firstHalf),
              badgeUrlForTeam: badgeUrlForTeam,
            ),
          ),
          if (index < stages.length - 1)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Icon(
                firstHalf ? Icons.chevron_right : Icons.chevron_left,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
        ],
      ],
    );
  }

  List<JogoProjetado> _half(List<JogoProjetado> jogos, bool firstHalf) {
    if (jogos.length <= 1) {
      return jogos;
    }

    final pivot = (jogos.length / 2).ceil();
    return firstHalf
        ? jogos.take(pivot).toList(growable: false)
        : jogos.skip(pivot).toList(growable: false);
  }
}

class _FinalColumn extends StatelessWidget {
  final List<_BracketStage> stages;
  final TeamBadgeUrlResolver? badgeUrlForTeam;

  const _FinalColumn({required this.stages, required this.badgeUrlForTeam});

  @override
  Widget build(BuildContext context) {
    final finals = stages
        .expand((stage) => stage.jogos)
        .toList(growable: false);

    return SizedBox(
      width: 232,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Decisão',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          for (final jogo in finals)
            _ProjectedGameTile(jogo: jogo, badgeUrlForTeam: badgeUrlForTeam),
        ],
      ),
    );
  }
}

class _ConnectedBracket extends StatelessWidget {
  final List<_BracketStage> stages;
  final TeamBadgeUrlResolver? badgeUrlForTeam;

  const _ConnectedBracket({
    required this.stages,
    required this.badgeUrlForTeam,
  });

  static const columnWidth = 220.0;
  static const columnGap = 58.0;
  static const labelHeight = 30.0;
  static const tileHeight = 96.0;
  static const rowGap = 14.0;

  @override
  Widget build(BuildContext context) {
    final firstGameCount = stages.isEmpty ? 1 : stages.first.jogos.length;
    final rowCount = firstGameCount.clamp(1, 32).toInt();
    final width = stages.length * columnWidth + (stages.length - 1) * columnGap;
    final height =
        labelHeight + rowCount * tileHeight + (rowCount - 1) * rowGap + 8;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: width,
        height: height,
        child: CustomPaint(
          painter: _BracketConnectorPainter(
            stages: stages,
            color: Theme.of(context).colorScheme.outlineVariant,
            firstGameCount: rowCount,
          ),
          child: Stack(
            children: [
              for (var stageIndex = 0; stageIndex < stages.length; stageIndex++)
                Positioned(
                  left: leftForStage(stageIndex),
                  top: 0,
                  width: columnWidth,
                  height: labelHeight,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _stageLabel(stages[stageIndex].stage),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              for (var stageIndex = 0; stageIndex < stages.length; stageIndex++)
                for (
                  var gameIndex = 0;
                  gameIndex < stages[stageIndex].jogos.length;
                  gameIndex++
                )
                  Positioned(
                    left: leftForStage(stageIndex),
                    top:
                        centerYFor(
                          stageIndex: stageIndex,
                          gameIndex: gameIndex,
                          stage: stages[stageIndex].stage,
                          firstGameCount: rowCount,
                        ) -
                        tileHeight / 2,
                    width: columnWidth,
                    height: tileHeight,
                    child: _ProjectedGameTile(
                      jogo: stages[stageIndex].jogos[gameIndex],
                      badgeUrlForTeam: badgeUrlForTeam,
                      margin: EdgeInsets.zero,
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  static double leftForStage(int stageIndex) {
    return stageIndex * (columnWidth + columnGap);
  }

  static double centerYFor({
    required int stageIndex,
    required int gameIndex,
    required String stage,
    required int firstGameCount,
  }) {
    final effectiveStageIndex = stage == 'third-place'
        ? (stageIndex - 1).clamp(0, stageIndex).toInt()
        : stageIndex;
    final span = 1 << effectiveStageIndex;
    var centerRow = gameIndex * span + (span - 1) / 2;

    if (stage == 'third-place') {
      centerRow = ((firstGameCount - 1) / 2 + 1.35).clamp(
        0,
        firstGameCount - 1,
      );
    }

    return labelHeight + centerRow * (tileHeight + rowGap) + tileHeight / 2;
  }
}

class _BracketConnectorPainter extends CustomPainter {
  final List<_BracketStage> stages;
  final Color color;
  final int firstGameCount;

  const _BracketConnectorPainter({
    required this.stages,
    required this.color,
    required this.firstGameCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.74)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (var stageIndex = 0; stageIndex < stages.length; stageIndex++) {
      final nextStageIndex = _nextConnectedStage(stageIndex);
      if (nextStageIndex == null) {
        continue;
      }

      final current = stages[stageIndex];
      final next = stages[nextStageIndex];
      if (current.jogos.length < 2 || next.jogos.isEmpty) {
        continue;
      }

      final pairCount = (current.jogos.length ~/ 2).clamp(0, next.jogos.length);
      final xStart =
          _ConnectedBracket.leftForStage(stageIndex) +
          _ConnectedBracket.columnWidth;
      final xEnd = _ConnectedBracket.leftForStage(nextStageIndex);
      final xMid = xStart + (xEnd - xStart) / 2;

      for (var pairIndex = 0; pairIndex < pairCount; pairIndex++) {
        final topGameIndex = pairIndex * 2;
        final bottomGameIndex = topGameIndex + 1;
        final yTop = _centerYFor(stageIndex, topGameIndex);
        final yBottom = _centerYFor(stageIndex, bottomGameIndex);
        final yTarget = _centerYFor(nextStageIndex, pairIndex);
        final yJoin = (yTop + yBottom) / 2;
        final path = Path()
          ..moveTo(xStart, yTop)
          ..lineTo(xMid, yTop)
          ..lineTo(xMid, yBottom)
          ..lineTo(xStart, yBottom)
          ..moveTo(xMid, yJoin)
          ..lineTo(xEnd, yTarget);

        canvas.drawPath(path, paint);
      }
    }
  }

  int? _nextConnectedStage(int stageIndex) {
    if (stages[stageIndex].stage == 'third-place') {
      return null;
    }

    for (var index = stageIndex + 1; index < stages.length; index++) {
      if (stages[index].stage == 'third-place') {
        continue;
      }

      if (stages[index].stage == 'final' ||
          stages[index].jogos.length * 2 == stages[stageIndex].jogos.length) {
        return index;
      }

      return null;
    }

    return null;
  }

  double _centerYFor(int stageIndex, int gameIndex) {
    return _ConnectedBracket.centerYFor(
      stageIndex: stageIndex,
      gameIndex: gameIndex,
      stage: stages[stageIndex].stage,
      firstGameCount: firstGameCount,
    );
  }

  @override
  bool shouldRepaint(covariant _BracketConnectorPainter oldDelegate) {
    return oldDelegate.stages != stages ||
        oldDelegate.color != color ||
        oldDelegate.firstGameCount != firstGameCount;
  }
}

class _BracketStage {
  final String stage;
  final List<JogoProjetado> jogos;

  const _BracketStage({required this.stage, required this.jogos});
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
}

class _ProjectedGameTile extends StatelessWidget {
  final JogoProjetado jogo;
  final TeamBadgeUrlResolver? badgeUrlForTeam;
  final EdgeInsetsGeometry margin;

  const _ProjectedGameTile({
    required this.jogo,
    required this.badgeUrlForTeam,
    this.margin = const EdgeInsets.only(bottom: 8),
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      margin: margin,
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
