import 'package:flutter/material.dart';

import '../core/functions/team_normalizer.dart';
import '../core/sistema_pontuacao_times.dart';
import '../models/time_participante.dart';
import '../models/time_sportsdb.dart';
import 'remote_media.dart';
import 'team_badge.dart';

class TeamOverviewCard extends StatelessWidget {
  final TimeParticipante time;
  final TimeSportsDb? sportsDb;
  final LinhaTabelaTime? tableLine;
  final String? badgeUrl;
  final String? flagUrl;
  final String? imageUrl;
  final VoidCallback? onTap;

  const TeamOverviewCard({
    super.key,
    required this.time,
    required this.sportsDb,
    required this.tableLine,
    required this.badgeUrl,
    this.flagUrl,
    this.imageUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final image = flagUrl ?? imageUrl ?? sportsDb?.melhorImagem;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                RemoteImage(
                  url: image,
                  aspectRatio: 16 / 6,
                  borderRadius: BorderRadius.zero,
                  placeholder: const _PatternPlaceholder(),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.05),
                          Colors.black.withValues(alpha: 0.58),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 14,
                  bottom: 12,
                  child: Row(
                    children: [
                      TeamBadge(
                        teamName: time.nome,
                        imageUrl: badgeUrl,
                        size: 46,
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            TeamNormalizer.sigla(time.nome),
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          Text(
                            'Grupo ${time.grupo}',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.82),
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    time.nome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Metric(
                        label: 'Pos',
                        value: tableLine == null
                            ? '-'
                            : '${tableLine!.posicao}º',
                      ),
                      _Metric(label: 'P', value: '${tableLine?.pontos ?? 0}'),
                      _Metric(label: 'J', value: '${tableLine?.jogos ?? 0}'),
                      _Metric(
                        label: 'SG',
                        value: '${tableLine?.saldoGols ?? 0}',
                      ),
                    ],
                  ),
                  if (onTap != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          'Ver jogos e detalhes',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: colors.primary,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right,
                          size: 18,
                          color: colors.primary,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;

  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      constraints: const BoxConstraints(minWidth: 48),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _PatternPlaceholder extends StatelessWidget {
  const _PatternPlaceholder();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE80012), Color(0xFF6B00FF), Color(0xFF00D8C8)],
        ),
      ),
      child: CustomPaint(painter: _PatternPainter()),
    );
  }
}

class _PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..color = Colors.white.withValues(alpha: 0.18);

    canvas.drawArc(
      Rect.fromLTWH(
        -size.width * 0.1,
        -size.height * 0.2,
        size.width,
        size.height * 1.4,
      ),
      0.2,
      2.8,
      false,
      paint,
    );
    canvas.drawArc(
      Rect.fromLTWH(
        size.width * 0.28,
        -size.height * 0.45,
        size.width,
        size.height * 1.8,
      ),
      1.2,
      2.9,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
