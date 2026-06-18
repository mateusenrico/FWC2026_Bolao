import 'package:flutter/material.dart';

import '../core/functions/participant_colors.dart';
import '../core/functions/palpite_match_groups.dart';
import '../models/jogo.dart';

class LivePalpiteGrid extends StatelessWidget {
  final Jogo jogo;
  final List<GrupoPalpitesJogo> groups;
  final Map<String, Color> participantColors;
  final VoidCallback? Function(String participanteId) onTapParticipante;

  const LivePalpiteGrid({
    super.key,
    required this.jogo,
    required this.groups,
    this.participantColors = const {},
    required this.onTapParticipante,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final items =
        groups.expand((group) => group.palpites).toList(growable: false)
          ..sort((a, b) {
            final byPoints = b.pontosNoJogo.compareTo(a.pontosNoJogo);
            if (byPoints != 0) {
              return byPoints;
            }
            return a.linha.nome.compareTo(b.linha.nome);
          });
    final hasScore =
        jogo.temResultado &&
        jogo.golsMandante != null &&
        jogo.golsVisitante != null;
    final isLive = jogo.isEmAndamento;

    return Card(
      margin: const EdgeInsets.only(top: 8),
      color: isLive
          ? colors.errorContainer.withValues(alpha: 0.22)
          : colors.surfaceContainerHigh.withValues(alpha: 0.72),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.how_to_vote_outlined, color: colors.error, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isLive
                        ? 'Palpites com o placar parcial'
                        : 'Palpites para este jogo',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  hasScore ? jogo.placarTexto : '${items.length} palpites',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                final maxWidth = constraints.maxWidth < 420 ? 132.0 : 154.0;

                return Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final item in items)
                      _LivePalpiteChip(
                        item: item,
                        participantColor:
                            participantColors[item.linha.participanteId],
                        maxWidth: maxWidth,
                        showPoints: hasScore,
                        onTap: onTapParticipante(item.linha.participanteId),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _LivePalpiteChip extends StatelessWidget {
  final PalpiteJogoAgrupado item;
  final Color? participantColor;
  final double maxWidth;
  final bool showPoints;
  final VoidCallback? onTap;

  const _LivePalpiteChip({
    required this.item,
    required this.participantColor,
    required this.maxWidth,
    required this.showPoints,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final score = item.pontuacao;
    final accent = participantColor ?? colors.primary;
    final background = showPoints && score?.placarExato == true
        ? colors.primary
        : showPoints && item.pontuando
        ? colors.secondaryContainer
        : ParticipantColors.softBackgroundFor(accent, colors);
    final foreground = showPoints && score?.placarExato == true
        ? colors.onPrimary
        : colors.onSurface;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    item.linha.nome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  item.palpite?.placarTexto ?? '-',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: foreground.withValues(alpha: 0.82),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (showPoints && item.pontuando) ...[
                  const SizedBox(width: 5),
                  Text(
                    '+${item.pontosNoJogo}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
