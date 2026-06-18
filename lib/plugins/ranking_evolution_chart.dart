import 'dart:math' as math;

import 'package:flutter/material.dart';

class RankingEvolutionPoint {
  final String participanteId;
  final String nome;
  final int matchNumber;
  final int pontos;

  const RankingEvolutionPoint({
    required this.participanteId,
    required this.nome,
    required this.matchNumber,
    required this.pontos,
  });
}

class RankingEvolutionChart extends StatelessWidget {
  final List<RankingEvolutionPoint> points;
  final Set<String> selectedParticipantes;

  const RankingEvolutionChart({
    super.key,
    required this.points,
    required this.selectedParticipantes,
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 280,
          child: CustomPaint(
            painter: _RankingEvolutionPainter(
              points: visible,
              colors: Theme.of(context).colorScheme,
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}

class _RankingEvolutionPainter extends CustomPainter {
  final List<RankingEvolutionPoint> points;
  final ColorScheme colors;

  const _RankingEvolutionPainter({required this.points, required this.colors});

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

    final maxMatch = points.fold<int>(
      1,
      (max, point) => math.max(max, point.matchNumber),
    );
    final maxPoints = points.fold<int>(
      1,
      (max, point) => math.max(max, point.pontos),
    );

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
        ..sort((a, b) => a.matchNumber.compareTo(b.matchNumber));

      if (participantPoints.length < 2) {
        continue;
      }

      final path = Path();
      for (var i = 0; i < participantPoints.length; i++) {
        final point = participantPoints[i];
        final x = chart.left + (point.matchNumber / maxMatch) * chart.width;
        final y = chart.bottom - (point.pontos / maxPoints) * chart.height;

        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      final paint = Paint()
        ..color = palette[index % palette.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      canvas.drawPath(path, paint);
      index++;
    }

    _drawLabel(canvas, 'Jogo', Offset(chart.right - 28, chart.bottom + 10));
    _drawLabel(canvas, '$maxPoints pts', Offset(0, chart.top - 4));
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
    return oldDelegate.points != points || oldDelegate.colors != colors;
  }
}
