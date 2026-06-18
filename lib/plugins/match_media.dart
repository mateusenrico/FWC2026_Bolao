import 'package:flutter/material.dart';

import 'remote_media.dart';

class MatchBannerImage extends StatelessWidget {
  final String? imageUrl;
  final bool destaque;
  final BorderRadius borderRadius;

  const MatchBannerImage({
    super.key,
    required this.imageUrl,
    this.destaque = false,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final height = destaque ? 126.0 : 82.0;

    return RemoteImage(
      url: imageUrl,
      height: height,
      fit: BoxFit.cover,
      borderRadius: borderRadius,
      placeholder: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: borderRadius,
        ),
        child: CustomPaint(painter: _MatchMediaPatternPainter(colors.primary)),
      ),
    );
  }
}

class TeamFlagBackdrop extends StatelessWidget {
  final String? flagUrl;
  final String? fallbackImageUrl;
  final Widget child;

  const TeamFlagBackdrop({
    super.key,
    required this.flagUrl,
    required this.fallbackImageUrl,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final background = flagUrl ?? fallbackImageUrl;

    return Stack(
      fit: StackFit.expand,
      children: [
        RemoteImage(
          url: background,
          fit: BoxFit.cover,
          borderRadius: BorderRadius.zero,
          placeholder: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colors.primary, colors.tertiary, colors.secondary],
              ),
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.18),
                Colors.black.withValues(alpha: 0.76),
              ],
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class TeamMediaStrip extends StatelessWidget {
  final String? flagUrl;
  final String? teamImageUrl;

  const TeamMediaStrip({
    super.key,
    required this.flagUrl,
    required this.teamImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    if (flagUrl == null && teamImageUrl == null) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 640 &&
            flagUrl != null &&
            teamImageUrl != null) {
          return Row(
            children: [
              Expanded(
                child: _MediaTile(url: flagUrl, label: 'Bandeira'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MediaTile(url: teamImageUrl, label: 'Imagem'),
              ),
            ],
          );
        }

        return _MediaTile(
          url: flagUrl ?? teamImageUrl,
          label: flagUrl == null ? 'Imagem' : 'Bandeira',
        );
      },
    );
  }
}

class _MediaTile extends StatelessWidget {
  final String? url;
  final String label;

  const _MediaTile({required this.url, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        alignment: Alignment.bottomLeft,
        children: [
          RemoteImage(
            url: url,
            aspectRatio: 16 / 7,
            fit: BoxFit.cover,
            borderRadius: BorderRadius.zero,
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.48),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: colors.outlineVariant),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchMediaPatternPainter extends CustomPainter {
  final Color color;

  const _MatchMediaPatternPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..color = color.withValues(alpha: 0.24);

    for (var i = -1; i < 4; i++) {
      canvas.drawArc(
        Rect.fromLTWH(
          size.width * (i * 0.28),
          -size.height * 0.65,
          size.width * 0.58,
          size.height * 2.3,
        ),
        0.25,
        3.0,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MatchMediaPatternPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
