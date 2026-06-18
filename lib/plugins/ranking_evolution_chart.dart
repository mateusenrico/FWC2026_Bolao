import 'dart:math' as math;

import 'package:flutter/material.dart';

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
  final RankingEvolutionMetric metric;

  const RankingEvolutionChart({
    super.key,
    required this.points,
    required this.selectedParticipantes,
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

    final palette = _palette(Theme.of(context).colorScheme);

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
                  palette: palette,
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
                for (final entry
                    in participants.entries.toList().asMap().entries)
                  _LegendItem(
                    color: palette[entry.key % palette.length],
                    name: entry.value.value,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Color> _palette(ColorScheme colors) {
    return [
      colors.primary,
      colors.tertiary,
      const Color(0xFF00AFA0),
      const Color(0xFF276BFF),
      const Color(0xFFE80012),
      const Color(0xFFFF0B6D),
      const Color(0xFF008A3D),
      const Color(0xFFC99B28),
      const Color(0xFFFFFFFF),
      const Color(0xFF35A7FF),
    ];
  }
}

class _RankingEvolutionPainter extends CustomPainter {
  final List<RankingEvolutionPoint> points;
  final ColorScheme colors;
  final List<Color> palette;
  final RankingEvolutionMetric metric;

  const _RankingEvolutionPainter({
    required this.points,
    required this.colors,
    required this.palette,
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

    final palette = [
      colors.primary,
      colors.secondary,
      colors.tertiary,
      const Color(0xFF0F766E),
      const Color(0xFFB42318),
      const Color(0xFF7C3AED),
      const Color(0xFFCA8A04),
      const Color(0xFF2563EB),
    ];

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

      final color = palette[index % palette.length];
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      if (participantPoints.length > 1) {
        canvas.drawPath(path, paint);
      }

      for (final point in participantPoints) {
        final x = maxStep <= 1
            ? chart.left
            : chart.left + ((point.step - 1) / (maxStep - 1)) * chart.width;
        final y = _yForPoint(
          chart: chart,
          point: point,
          maxPoints: maxPoints,
          maxPosition: maxPosition,
        );
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
        oldDelegate.palette != palette ||
        oldDelegate.metric != metric;
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String name;

  const _LegendItem({required this.color, required this.name});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
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
