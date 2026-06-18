import 'package:flutter/material.dart';

import '../core/sistema_pontuacao_participantes.dart';
import 'participant_identity.dart';

class RankingParticipanteCard extends StatelessWidget {
  final LinhaPontuacaoParticipante linha;
  final int liveDelta;
  final Color? participantColor;
  final int? movementDelta;
  final int? displayPoints;
  final String? pointsLabel;
  final VoidCallback? onTap;

  const RankingParticipanteCard({
    super.key,
    required this.linha,
    this.liveDelta = 0,
    this.participantColor,
    this.movementDelta,
    this.displayPoints,
    this.pointsLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              ParticipantPositionBadge(
                position: linha.posicao,
                color: participantColor ?? _positionColor(colorScheme),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (movementDelta != null) ...[
                          _MovementIndicator(delta: movementDelta!),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: ParticipantNameInline(
                            name: linha.nome,
                            color: participantColor,
                            participantId: linha.participanteId,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${linha.placaresExatos} exatos · ${linha.resultadosCorretos} resultados',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${displayPoints ?? linha.pontosTotal}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (liveDelta != 0) ...[
                        const SizedBox(width: 5),
                        Text(
                          liveDelta > 0 ? '+$liveDelta' : '$liveDelta',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: liveDelta > 0
                                    ? participantColor ?? colorScheme.primary
                                    : colorScheme.error,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    pointsLabel ?? (liveDelta > 0 ? 'proj.' : 'pontos'),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              if (onTap != null) ...[
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _positionColor(ColorScheme colors) {
    return switch (linha.posicao) {
      1 => colors.primary,
      2 => colors.secondaryContainer,
      3 => colors.tertiaryContainer,
      _ => colors.surfaceContainerHighest,
    };
  }
}

class _MovementIndicator extends StatelessWidget {
  final int delta;

  const _MovementIndicator({required this.delta});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (icon, color, label) = switch (delta) {
      > 0 => (
        Icons.arrow_upward,
        Colors.green,
        'Subiu $delta ${delta == 1 ? 'posição' : 'posições'} com o placar ao vivo',
      ),
      < 0 => (
        Icons.arrow_downward,
        colors.error,
        'Caiu ${delta.abs()} ${delta == -1 ? 'posição' : 'posições'} com o placar ao vivo',
      ),
      _ => (
        Icons.drag_handle,
        Colors.amber,
        'Manteve a posição com o placar ao vivo',
      ),
    };

    return Tooltip(
      message: label,
      child: Container(
        width: 24,
        height: 24,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.16),
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.46)),
        ),
        child: Icon(icon, size: 15, color: color),
      ),
    );
  }
}
