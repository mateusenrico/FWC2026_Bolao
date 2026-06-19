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

  static const columnWidth = 216.0;
  static const centerWidth = 268.0;
  static const columnGap = 48.0;
  static const labelHeight = 30.0;
  static const tileHeight = 96.0;
  static const finalTileHeight = 126.0;
  static const thirdPlaceTileHeight = 88.0;
  static const rowGap = 14.0;

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
    final leftStages = [
      for (final stage in knockoutStages)
        _BracketStage(stage: stage.stage, jogos: _half(stage.jogos, true)),
    ];
    final rightStages = [
      for (final stage in knockoutStages.reversed)
        _BracketStage(stage: stage.stage, jogos: _half(stage.jogos, false)),
    ];
    final maxRows = leftStages.isEmpty
        ? 1
        : leftStages
              .map((stage) => stage.jogos.length)
              .fold<int>(1, (max, value) => value > max ? value : max);
    final sideColumns = leftStages.length;
    final sideWidth = sideColumns * columnWidth + (sideColumns * columnGap);
    final width = sideWidth * 2 + centerWidth;
    final height =
        labelHeight + maxRows * tileHeight + (maxRows - 1) * rowGap + 18;
    final finalGame = finalStage
        .expand((stage) => stage.stage == 'final' ? stage.jogos : const [])
        .cast<JogoProjetado?>()
        .firstOrNull;
    final thirdPlaceGame = finalStage
        .expand(
          (stage) => stage.stage == 'third-place' ? stage.jogos : const [],
        )
        .cast<JogoProjetado?>()
        .firstOrNull;
    final finalCenterY = labelHeight + (height - labelHeight) * 0.46;
    final finalTop = finalCenterY - finalTileHeight / 2;
    final thirdTop = finalTop + finalTileHeight + 24;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: width,
        height: height,
        child: CustomPaint(
          painter: _SplitBracketConnectorPainter(
            leftStages: leftStages,
            rightStages: rightStages,
            maxRows: maxRows,
            finalCenterY: finalCenterY,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          child: Stack(
            children: [
              for (var index = 0; index < leftStages.length; index++)
                _StageLabelPositioned(
                  left: _leftX(index),
                  width: columnWidth,
                  label: _stageLabel(leftStages[index].stage),
                  alignRight: false,
                ),
              for (var index = 0; index < rightStages.length; index++)
                _StageLabelPositioned(
                  left: _rightX(index, sideColumns),
                  width: columnWidth,
                  label: _stageLabel(rightStages[index].stage),
                  alignRight: true,
                ),
              for (
                var stageIndex = 0;
                stageIndex < leftStages.length;
                stageIndex++
              )
                for (
                  var gameIndex = 0;
                  gameIndex < leftStages[stageIndex].jogos.length;
                  gameIndex++
                )
                  Positioned(
                    left: _leftX(stageIndex),
                    top:
                        _centerYFor(
                          itemCount: leftStages[stageIndex].jogos.length,
                          gameIndex: gameIndex,
                          maxRows: maxRows,
                        ) -
                        tileHeight / 2,
                    width: columnWidth,
                    height: tileHeight,
                    child: _ProjectedGameTile(
                      jogo: leftStages[stageIndex].jogos[gameIndex],
                      badgeUrlForTeam: badgeUrlForTeam,
                      margin: EdgeInsets.zero,
                    ),
                  ),
              for (
                var stageIndex = 0;
                stageIndex < rightStages.length;
                stageIndex++
              )
                for (
                  var gameIndex = 0;
                  gameIndex < rightStages[stageIndex].jogos.length;
                  gameIndex++
                )
                  Positioned(
                    left: _rightX(stageIndex, sideColumns),
                    top:
                        _centerYFor(
                          itemCount: rightStages[stageIndex].jogos.length,
                          gameIndex: gameIndex,
                          maxRows: maxRows,
                        ) -
                        tileHeight / 2,
                    width: columnWidth,
                    height: tileHeight,
                    child: _ProjectedGameTile(
                      jogo: rightStages[stageIndex].jogos[gameIndex],
                      badgeUrlForTeam: badgeUrlForTeam,
                      margin: EdgeInsets.zero,
                    ),
                  ),
              Positioned(
                left: sideWidth,
                top: 0,
                width: centerWidth,
                height: labelHeight,
                child: Center(
                  child: Text(
                    'Decisão',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              if (finalGame != null)
                Positioned(
                  left: sideWidth + 10,
                  top: finalTop,
                  width: centerWidth - 20,
                  height: finalTileHeight,
                  child: _ProjectedGameTile(
                    jogo: finalGame,
                    badgeUrlForTeam: badgeUrlForTeam,
                    margin: EdgeInsets.zero,
                    highlight: true,
                    title: 'Final da Copa',
                  ),
                ),
              if (thirdPlaceGame != null)
                Positioned(
                  left: sideWidth + 24,
                  top: thirdTop,
                  width: centerWidth - 48,
                  height: thirdPlaceTileHeight,
                  child: _ProjectedGameTile(
                    jogo: thirdPlaceGame,
                    badgeUrlForTeam: badgeUrlForTeam,
                    margin: EdgeInsets.zero,
                    dense: true,
                    title: '3º lugar',
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static double _leftX(int stageIndex) {
    return stageIndex * (columnWidth + columnGap);
  }

  static double _rightX(int stageIndex, int sideColumns) {
    final sideWidth = sideColumns * columnWidth + sideColumns * columnGap;
    return sideWidth +
        centerWidth +
        columnGap +
        stageIndex * (columnWidth + columnGap);
  }

  static double _centerYFor({
    required int itemCount,
    required int gameIndex,
    required int maxRows,
  }) {
    if (itemCount <= 0) {
      return labelHeight + tileHeight / 2;
    }

    final span = maxRows / itemCount;
    final centerRow = gameIndex * span + (span - 1) / 2;
    return labelHeight + centerRow * (tileHeight + rowGap) + tileHeight / 2;
  }

  static List<JogoProjetado> _half(List<JogoProjetado> jogos, bool firstHalf) {
    if (jogos.length <= 1) {
      return jogos;
    }

    final pivot = (jogos.length / 2).ceil();
    return firstHalf
        ? jogos.take(pivot).toList(growable: false)
        : jogos.skip(pivot).toList(growable: false);
  }
}

class _StageLabelPositioned extends StatelessWidget {
  final double left;
  final double width;
  final String label;
  final bool alignRight;

  const _StageLabelPositioned({
    required this.left,
    required this.width,
    required this.label,
    required this.alignRight,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: 0,
      width: width,
      height: _SplitBracket.labelHeight,
      child: Align(
        alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _SplitBracketConnectorPainter extends CustomPainter {
  final List<_BracketStage> leftStages;
  final List<_BracketStage> rightStages;
  final int maxRows;
  final double finalCenterY;
  final Color color;

  const _SplitBracketConnectorPainter({
    required this.leftStages,
    required this.rightStages,
    required this.maxRows,
    required this.finalCenterY,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.78)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    _paintLeft(canvas, paint);
    _paintRight(canvas, paint);
    _paintFinalConnectors(canvas, paint);
  }

  void _paintLeft(Canvas canvas, Paint paint) {
    for (var stageIndex = 0; stageIndex < leftStages.length - 1; stageIndex++) {
      _paintStageConnection(
        canvas: canvas,
        paint: paint,
        fromStage: leftStages[stageIndex],
        toStage: leftStages[stageIndex + 1],
        fromX: _SplitBracket._leftX(stageIndex) + _SplitBracket.columnWidth,
        toX: _SplitBracket._leftX(stageIndex + 1),
        leftToRight: true,
      );
    }
  }

  void _paintRight(Canvas canvas, Paint paint) {
    for (
      var stageIndex = rightStages.length - 1;
      stageIndex > 0;
      stageIndex--
    ) {
      _paintStageConnection(
        canvas: canvas,
        paint: paint,
        fromStage: rightStages[stageIndex],
        toStage: rightStages[stageIndex - 1],
        fromX: _SplitBracket._rightX(stageIndex, rightStages.length),
        toX:
            _SplitBracket._rightX(stageIndex - 1, rightStages.length) +
            _SplitBracket.columnWidth,
        leftToRight: false,
      );
    }
  }

  void _paintStageConnection({
    required Canvas canvas,
    required Paint paint,
    required _BracketStage fromStage,
    required _BracketStage toStage,
    required double fromX,
    required double toX,
    required bool leftToRight,
  }) {
    if (fromStage.jogos.length < 2 || toStage.jogos.isEmpty) {
      return;
    }

    final pairCount = (fromStage.jogos.length ~/ 2).clamp(
      0,
      toStage.jogos.length,
    );
    final xMid = fromX + (toX - fromX) / 2;

    for (var pairIndex = 0; pairIndex < pairCount; pairIndex++) {
      final topGameIndex = pairIndex * 2;
      final bottomGameIndex = topGameIndex + 1;
      final yTop = _centerY(fromStage, topGameIndex);
      final yBottom = _centerY(fromStage, bottomGameIndex);
      final yTarget = _centerY(toStage, pairIndex);
      final yJoin = (yTop + yBottom) / 2;
      final path = Path()
        ..moveTo(fromX, yTop)
        ..lineTo(xMid, yTop)
        ..lineTo(xMid, yBottom)
        ..lineTo(fromX, yBottom)
        ..moveTo(xMid, yJoin)
        ..lineTo(toX, yTarget);

      canvas.drawPath(path, paint);
    }
  }

  void _paintFinalConnectors(Canvas canvas, Paint paint) {
    if (leftStages.isNotEmpty && leftStages.last.jogos.isNotEmpty) {
      final leftStart =
          _SplitBracket._leftX(leftStages.length - 1) +
          _SplitBracket.columnWidth;
      final leftEnd =
          leftStages.length *
          (_SplitBracket.columnWidth + _SplitBracket.columnGap);
      final y = _centerY(leftStages.last, 0);
      canvas.drawPath(
        Path()
          ..moveTo(leftStart, y)
          ..lineTo(leftEnd - _SplitBracket.columnGap / 2, y)
          ..lineTo(leftEnd, finalCenterY),
        paint,
      );
    }

    if (rightStages.isNotEmpty && rightStages.first.jogos.isNotEmpty) {
      final rightEnd =
          rightStages.length *
              (_SplitBracket.columnWidth + _SplitBracket.columnGap) +
          _SplitBracket.centerWidth;
      final rightStart = _SplitBracket._rightX(0, rightStages.length);
      final y = _centerY(rightStages.first, 0);
      canvas.drawPath(
        Path()
          ..moveTo(rightStart, y)
          ..lineTo(rightEnd + _SplitBracket.columnGap / 2, y)
          ..lineTo(rightEnd, finalCenterY),
        paint,
      );
    }
  }

  double _centerY(_BracketStage stage, int gameIndex) {
    return _SplitBracket._centerYFor(
      itemCount: stage.jogos.length,
      gameIndex: gameIndex,
      maxRows: maxRows,
    );
  }

  @override
  bool shouldRepaint(covariant _SplitBracketConnectorPainter oldDelegate) {
    return oldDelegate.leftStages != leftStages ||
        oldDelegate.rightStages != rightStages ||
        oldDelegate.maxRows != maxRows ||
        oldDelegate.finalCenterY != finalCenterY ||
        oldDelegate.color != color;
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
  final bool highlight;
  final bool dense;
  final String? title;

  const _ProjectedGameTile({
    required this.jogo,
    required this.badgeUrlForTeam,
    this.margin = const EdgeInsets.only(bottom: 8),
    this.highlight = false,
    this.dense = false,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      margin: margin,
      padding: EdgeInsets.all(
        highlight
            ? 14
            : dense
            ? 8
            : 10,
      ),
      decoration: BoxDecoration(
        color: highlight
            ? colors.primaryContainer.withValues(alpha: 0.72)
            : colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: highlight ? colors.primary : colors.outlineVariant,
          width: highlight ? 1.8 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title ?? 'Jogo ${jogo.matchNumber}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: highlight
                  ? colors.onPrimaryContainer
                  : colors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: dense ? 4 : 6),
          _TeamLine(
            name: jogo.mandante?.nome,
            badgeUrl: _badgeFor(jogo.mandante?.nome),
            goals: jogo.golsMandante,
            winner: jogo.vencedor?.timeKey == jogo.mandante?.timeKey,
            highlight: highlight,
            dense: dense,
          ),
          _TeamLine(
            name: jogo.visitante?.nome,
            badgeUrl: _badgeFor(jogo.visitante?.nome),
            goals: jogo.golsVisitante,
            winner: jogo.vencedor?.timeKey == jogo.visitante?.timeKey,
            highlight: highlight,
            dense: dense,
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
  final bool highlight;
  final bool dense;

  const _TeamLine({
    required this.name,
    required this.badgeUrl,
    required this.goals,
    required this.winner,
    this.highlight = false,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: dense ? 1 : 2),
      child: Row(
        children: [
          if (name != null) ...[
            TeamBadge(
              teamName: name!,
              imageUrl: badgeUrl,
              size: highlight
                  ? 28
                  : dense
                  ? 19
                  : 22,
            ),
            SizedBox(width: dense ? 5 : 7),
          ],
          Expanded(
            child: Text(
              name == null ? 'A definir' : TeamNormalizer.sigla(name!),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: winner ? FontWeight.w900 : FontWeight.w600,
                color: highlight ? colors.onPrimaryContainer : null,
                fontSize: highlight ? 16 : null,
              ),
            ),
          ),
          Text(
            goals?.toString() ?? '',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: highlight ? colors.onPrimaryContainer : null,
              fontSize: highlight ? 16 : null,
            ),
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
