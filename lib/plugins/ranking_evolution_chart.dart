import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/functions/participant_colors.dart';

class RankingEvolutionPoint {
  final String participanteId;
  final String nome;
  final int step;
  final String stepLabel;
  final int pontos;
  final int posicao;

  const RankingEvolutionPoint({
    required this.participanteId,
    required this.nome,
    required this.step,
    required this.stepLabel,
    required this.pontos,
    required this.posicao,
  });
}

enum RankingEvolutionMetric { pontos, posicao }

class RankingEvolutionChart extends StatelessWidget {
  final List<RankingEvolutionPoint> points;
  final Set<String> selectedParticipantes;
  final Map<String, Color> participantColors;
  final Map<String, int> podiumPositions;
  final List<String> legendOrder;
  final RankingEvolutionMetric metric;

  const RankingEvolutionChart({
    super.key,
    required this.points,
    required this.selectedParticipantes,
    this.participantColors = const {},
    this.podiumPositions = const {},
    this.legendOrder = const [],
    required this.metric,
  });

  @override
  Widget build(BuildContext context) {
    final visible = points
        .where((point) => selectedParticipantes.contains(point.participanteId))
        .toList(growable: false);

    if (visible.isEmpty) {
      return const Card(
        child: SizedBox(
          height: 240,
          child: Center(child: Text('Selecione participantes para o gráfico.')),
        ),
      );
    }

    final participants = <String, String>{};
    for (final point in visible) {
      participants.putIfAbsent(point.participanteId, () => point.nome);
    }
    final remainingLegendIds =
        participants.keys
            .where((participanteId) => !legendOrder.contains(participanteId))
            .toList()
          ..sort((a, b) => participants[a]!.compareTo(participants[b]!));
    final orderedLegendIds = [
      for (final participanteId in legendOrder)
        if (participants.containsKey(participanteId)) participanteId,
      ...remainingLegendIds,
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 280,
              child: CustomPaint(
                painter: _RankingEvolutionPainter(
                  points: visible,
                  colors: Theme.of(context).colorScheme,
                  participantColors: participantColors,
                  podiumPositions: podiumPositions,
                  metric: metric,
                ),
                child: const SizedBox.expand(),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                for (final participanteId in orderedLegendIds)
                  _LegendItem(
                    color: _colorFor(participanteId),
                    name: participants[participanteId]!,
                    podiumPosition: podiumPositions[participanteId],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _colorFor(String participanteId) {
    return participantColors[participanteId] ??
        ParticipantColors.resolve(participanteId: participanteId, index: 0);
  }
}

class _RankingEvolutionPainter extends CustomPainter {
  final List<RankingEvolutionPoint> points;
  final ColorScheme colors;
  final Map<String, Color> participantColors;
  final Map<String, int> podiumPositions;
  final RankingEvolutionMetric metric;

  const _RankingEvolutionPainter({
    required this.points,
    required this.colors,
    required this.participantColors,
    required this.podiumPositions,
    required this.metric,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final padding = const EdgeInsets.fromLTRB(34, 18, 12, 30);
    final chart = Rect.fromLTWH(
      padding.left,
      padding.top,
      size.width - padding.horizontal,
      size.height - padding.vertical,
    );

    final axisPaint = Paint()
      ..color = colors.outlineVariant
      ..strokeWidth = 1;

    canvas.drawLine(chart.bottomLeft, chart.bottomRight, axisPaint);
    canvas.drawLine(chart.bottomLeft, chart.topLeft, axisPaint);

    final maxStep = points.fold<int>(
      1,
      (max, point) => math.max(max, point.step),
    );
    final maxPoints = points.fold<int>(1, (max, point) {
      return math.max(max, point.pontos);
    });
    final maxPosition = points.fold<int>(1, (max, point) {
      return math.max(max, point.posicao);
    });

    final byParticipant = <String, List<RankingEvolutionPoint>>{};
    for (final point in points) {
      byParticipant.putIfAbsent(point.participanteId, () => []).add(point);
    }

    var index = 0;
    for (final entry in byParticipant.entries) {
      final participantPoints = entry.value
        ..sort((a, b) => a.step.compareTo(b.step));

      final path = Path();
      for (var i = 0; i < participantPoints.length; i++) {
        final point = participantPoints[i];
        final x = maxStep <= 1
            ? chart.left
            : chart.left + ((point.step - 1) / (maxStep - 1)) * chart.width;
        final y = _yForPoint(
          chart: chart,
          point: point,
          maxPoints: maxPoints,
          maxPosition: maxPosition,
        );

        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      final podiumPosition = podiumPositions[entry.key];
      final medalColor = ParticipantColors.medalColor(podiumPosition);
      final color =
          participantColors[entry.key] ??
          ParticipantColors.resolve(participanteId: entry.key, index: index);
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = podiumPosition == null ? 2.4 : 3.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      if (participantPoints.length > 1) {
        if (podiumPosition != null) {
          canvas.drawPath(
            path,
            Paint()
              ..color = medalColor.withValues(alpha: 0.34)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 6.8
              ..strokeCap = StrokeCap.round
              ..strokeJoin = StrokeJoin.round,
          );
        }
        canvas.drawPath(path, paint);
      }

      for (var i = 0; i < participantPoints.length; i++) {
        final point = participantPoints[i];
        final x = maxStep <= 1
            ? chart.left
            : chart.left + ((point.step - 1) / (maxStep - 1)) * chart.width;
        final y = _yForPoint(
          chart: chart,
          point: point,
          maxPoints: maxPoints,
          maxPosition: maxPosition,
        );
        if (podiumPosition != null && i == participantPoints.length - 1) {
          canvas.drawCircle(Offset(x, y), 7.5, Paint()..color = medalColor);
          canvas.drawCircle(Offset(x, y), 5, Paint()..color = colors.surface);
        }
        canvas.drawCircle(Offset(x, y), 3, Paint()..color = color);
      }
      index++;
    }

    _drawLabel(
      canvas,
      metric == RankingEvolutionMetric.pontos ? 'Pontos' : 'Posição',
      Offset(chart.right - 58, chart.bottom + 10),
    );
    _drawLabel(
      canvas,
      metric == RankingEvolutionMetric.pontos ? '$maxPoints pts' : '1º',
      Offset(0, chart.top - 4),
    );
    if (metric == RankingEvolutionMetric.posicao) {
      _drawLabel(canvas, '$maxPositionº', Offset(0, chart.bottom - 12));
    }
  }

  double _yForPoint({
    required Rect chart,
    required RankingEvolutionPoint point,
    required int maxPoints,
    required int maxPosition,
  }) {
    if (metric == RankingEvolutionMetric.posicao) {
      if (maxPosition <= 1) {
        return chart.top;
      }

      return chart.top +
          ((point.posicao - 1) / (maxPosition - 1)) * chart.height;
    }

    return chart.bottom - (point.pontos / maxPoints) * chart.height;
  }

  void _drawLabel(Canvas canvas, String text, Offset offset) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: colors.onSurfaceVariant,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(_RankingEvolutionPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.colors != colors ||
        oldDelegate.participantColors != participantColors ||
        oldDelegate.podiumPositions != podiumPositions ||
        oldDelegate.metric != metric;
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String name;
  final int? podiumPosition;

  const _LegendItem({
    required this.color,
    required this.name,
    required this.podiumPosition,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (podiumPosition != null) ...[
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: ParticipantColors.medalColor(podiumPosition),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$podiumPosition',
              style: const TextStyle(
                color: Color(0xFF08090F),
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 6),
        ],
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          name,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}
