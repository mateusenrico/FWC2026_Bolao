import 'package:flutter/material.dart';

import '../core/functions/team_normalizer.dart';

class TeamBadge extends StatelessWidget {
  final String teamName;
  final String? imageUrl;
  final double size;
  final bool showCode;

  const TeamBadge({
    super.key,
    required this.teamName,
    this.imageUrl,
    this.size = 42,
    this.showCode = false,
  });

  @override
  Widget build(BuildContext context) {
    final code = TeamNormalizer.sigla(teamName);
    final colorScheme = Theme.of(context).colorScheme;
    final value = imageUrl?.trim();
    final fallback = Center(
      child: Text(
        code,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800),
      ),
    );

    final badge = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.surfaceContainerHighest,
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: value == null || value.isEmpty
          ? fallback
          : value.startsWith('assets/')
          ? Image.asset(
              value,
              fit: BoxFit.contain,
              gaplessPlayback: true,
              errorBuilder: (_, _, _) => fallback,
            )
          : Image.network(
              value,
              fit: BoxFit.contain,
              gaplessPlayback: true,
              webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
              errorBuilder: (_, _, _) => fallback,
            ),
    );

    if (!showCode) {
      return badge;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        badge,
        const SizedBox(height: 4),
        Text(
          code,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}
