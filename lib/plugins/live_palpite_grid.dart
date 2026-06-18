import 'package:flutter/material.dart';

import '../core/functions/palpite_match_groups.dart';
import '../models/jogo.dart';

class LivePalpiteGrid extends StatelessWidget {
  final Jogo jogo;
  final List<GrupoPalpitesJogo> groups;
  final VoidCallback? Function(String participanteId) onTapParticipante;

  const LivePalpiteGrid({
    super.key,
    required this.jogo,
    required this.groups,
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

    return Card(
      margin: const EdgeInsets.only(top: 8),
      color: colors.errorContainer.withValues(alpha: 0.22),
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
                    'Palpites com o placar parcial',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  jogo.placarTexto,
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
                        maxWidth: maxWidth,
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
  final double maxWidth;
  final VoidCallback? onTap;

  const _LivePalpiteChip({
    required this.item,
    required this.maxWidth,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final score = item.pontuacao;
    final background = score?.placarExato == true
        ? colors.primary
        : item.pontuando
        ? colors.secondaryContainer
        : colors.surfaceContainerHighest;
    final foreground = score?.placarExato == true
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
                if (item.pontuando) ...[
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
