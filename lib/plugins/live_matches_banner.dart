import 'package:flutter/material.dart';

import '../core/app_routes.dart';
import '../core/functions/date_time_utils.dart';
import '../core/functions/team_normalizer.dart';
import '../models/jogo.dart';
import '../services/bolao_controller.dart';
import 'refresh_countdown_indicator.dart';
import 'team_badge.dart';

class LiveMatchesBanner extends StatelessWidget {
  final BolaoController controller;
  final bool showWhenEmpty;

  const LiveMatchesBanner({
    super.key,
    required this.controller,
    this.showWhenEmpty = false,
  });

  @override
  Widget build(BuildContext context) {
    final jogos = controller.jogosAoVivo;

    if (jogos.isEmpty) {
      if (!showWhenEmpty) {
        return const SizedBox.shrink();
      }

      return const SizedBox.shrink();
    }

    final colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.errorContainer.withValues(alpha: 0.36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.sensors, size: 18, color: colors.error),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            jogos.length == 1
                                ? 'Ao vivo agora'
                                : '${jogos.length} jogos ao vivo agora',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                        RefreshCountdownIndicator(
                          controller: controller,
                          compact: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final jogo in jogos)
                          _LiveMatchChip(controller: controller, jogo: jogo),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveMatchChip extends StatelessWidget {
  final BolaoController controller;
  final Jogo jogo;

  const _LiveMatchChip({required this.controller, required this.jogo});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 260, maxWidth: 420),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.pushNamed(context, AppRoutes.jogo, arguments: jogo.jogoId);
        },
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: colors.surface.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _TeamMini(
                name: jogo.mandantePrevisto,
                badgeUrl: controller.badgeDoTime(jogo.mandantePrevisto),
              ),
              const SizedBox(width: 8),
              _ScoreText(jogo: jogo),
              const SizedBox(width: 8),
              _TeamMini(
                name: jogo.visitantePrevisto,
                badgeUrl: controller.badgeDoTime(jogo.visitantePrevisto),
              ),
              const Spacer(),
              Text(
                AppDateTime.horario(AppDateTime.horarioBrasilia(jogo)),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeamMini extends StatelessWidget {
  final String name;
  final String? badgeUrl;

  const _TeamMini({required this.name, required this.badgeUrl});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TeamBadge(teamName: name, imageUrl: badgeUrl, size: 24),
        const SizedBox(width: 5),
        Text(
          TeamNormalizer.sigla(name),
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class _ScoreText extends StatelessWidget {
  final Jogo jogo;

  const _ScoreText({required this.jogo});

  @override
  Widget build(BuildContext context) {
    final home = jogo.golsMandante ?? 0;
    final away = jogo.golsVisitante ?? 0;

    return Text(
      '$home × $away',
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
    );
  }
}
