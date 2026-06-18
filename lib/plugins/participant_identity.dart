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
  final TextStyle? style;
  final int maxLines;

  const ParticipantNameInline({
    super.key,
    required this.name,
    this.color,
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
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
        ),
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
