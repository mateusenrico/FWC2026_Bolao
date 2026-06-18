import 'package:flutter/material.dart';

import '../core/functions/participant_colors.dart';

class ParticipantPositionBadge extends StatelessWidget {
  final int position;
  final Color? color;
  final double size;

  const ParticipantPositionBadge({
    super.key,
    required this.position,
    this.color,
    this.size = 38,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = color ?? _fallbackPositionColor(colors);
    final medal = ParticipantColors.medalColor(position);
    final hasMedal = position >= 1 && position <= 3;

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: accent,
        shape: BoxShape.circle,
        border: hasMedal ? Border.all(color: medal, width: 2.4) : null,
        boxShadow: [
          if (hasMedal)
            BoxShadow(
              color: medal.withValues(alpha: 0.28),
              blurRadius: 12,
              spreadRadius: 1,
            ),
        ],
      ),
      child: Text(
        '$positionº',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: ParticipantColors.foregroundFor(accent),
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Color _fallbackPositionColor(ColorScheme colors) {
    return switch (position) {
      1 => colors.primary,
      2 => colors.secondaryContainer,
      3 => colors.tertiaryContainer,
      _ => colors.surfaceContainerHighest,
    };
  }
}

class ParticipantNameInline extends StatelessWidget {
  final String name;
  final Color? color;
  final String? participantId;
  final TextStyle? style;
  final int maxLines;

  const ParticipantNameInline({
    super.key,
    required this.name,
    this.color,
    this.participantId,
    this.style,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = color ?? colors.primary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ParticipantMarker(color: accent, participanteId: participantId),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            name,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
      ],
    );
  }
}

class ParticipantMarker extends StatelessWidget {
  final Color color;
  final String? participanteId;
  final double size;

  const ParticipantMarker({
    super.key,
    required this.color,
    this.participanteId,
    this.size = 10,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _ParticipantMarkerPainter(
          color: color,
          shapeIndex: _shapeIndex(participanteId),
        ),
      ),
    );
  }

  int _shapeIndex(String? value) {
    final text = value ?? '';
    if (text.isEmpty) {
      return 0;
    }

    return text.codeUnits.fold<int>(
          0,
          (hash, charCode) => 0x1fffffff & (hash * 31 + charCode),
        ) %
        6;
  }
}

class _ParticipantMarkerPainter extends CustomPainter {
  final Color color;
  final int shapeIndex;

  const _ParticipantMarkerPainter({
    required this.color,
    required this.shapeIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final rect = Offset.zero & size;
    final center = rect.center;

    switch (shapeIndex) {
      case 1:
        canvas.drawRect(rect.deflate(size.width * 0.12), paint);
      case 2:
        final path = Path()
          ..moveTo(center.dx, 0)
          ..lineTo(size.width, center.dy)
          ..lineTo(center.dx, size.height)
          ..lineTo(0, center.dy)
          ..close();
        canvas.drawPath(path, paint);
      case 3:
        final path = Path()
          ..moveTo(center.dx, 0)
          ..lineTo(size.width, size.height)
          ..lineTo(0, size.height)
          ..close();
        canvas.drawPath(path, paint);
      case 4:
        final stroke = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * 0.28
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          Offset(size.width * 0.15, size.height * 0.15),
          Offset(size.width * 0.85, size.height * 0.85),
          stroke,
        );
        canvas.drawLine(
          Offset(size.width * 0.85, size.height * 0.15),
          Offset(size.width * 0.15, size.height * 0.85),
          stroke,
        );
      case 5:
        final stroke = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * 0.22;
        canvas.drawCircle(center, size.width * 0.37, stroke);
      default:
        canvas.drawCircle(center, size.width / 2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticipantMarkerPainter oldDelegate) {
    return color != oldDelegate.color || shapeIndex != oldDelegate.shapeIndex;
  }
}
