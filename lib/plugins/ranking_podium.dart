import 'package:flutter/material.dart';

import '../core/sistema_pontuacao_participantes.dart';

class RankingPodium extends StatelessWidget {
  final List<LinhaPontuacaoParticipante> ranking;
  final int Function(String participanteId) liveDelta;
  final ValueChanged<String>? onTapParticipante;

  const RankingPodium({
    super.key,
    required this.ranking,
    required this.liveDelta,
    this.onTapParticipante,
  });

  @override
  Widget build(BuildContext context) {
    final top = ranking.take(3).toList(growable: false);

    if (top.isEmpty) {
      return const SizedBox.shrink();
    }

    final ordered = [
      if (top.length > 1) top[1],
      top[0],
      if (top.length > 2) top[2],
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 640;

        if (compact) {
          return Column(
            children: [
              for (final linha in top)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _PodiumTile(
                    linha: linha,
                    height: 88,
                    delta: liveDelta(linha.participanteId),
                    onTap: onTapParticipante == null
                        ? null
                        : () => onTapParticipante!(linha.participanteId),
                  ),
                ),
            ],
          );
        }

        return SizedBox(
          height: 190,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final linha in ordered)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: _PodiumTile(
                      linha: linha,
                      height: linha.posicao == 1 ? 178 : 142,
                      delta: liveDelta(linha.participanteId),
                      onTap: onTapParticipante == null
                          ? null
                          : () => onTapParticipante!(linha.participanteId),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _PodiumTile extends StatelessWidget {
  final LinhaPontuacaoParticipante linha;
  final double height;
  final int delta;
  final VoidCallback? onTap;

  const _PodiumTile({
    required this.linha,
    required this.height,
    required this.delta,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final medal = _medalColor(colors);

    return SizedBox(
      height: height,
      child: Card(
        color: medal.background,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: medal.foreground,
                  ),
                  child: Text(
                    '${linha.posicao}º',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: medal.onForeground,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  linha.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${linha.pontosTotal} pts',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (delta > 0) ...[
                      const SizedBox(width: 6),
                      Text(
                        '+$delta',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  '${linha.placaresExatos} exatos',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _MedalColors _medalColor(ColorScheme colors) {
    return switch (linha.posicao) {
      1 => _MedalColors(
        background: const Color(0xFFFFF4C7),
        foreground: const Color(0xFFB77900),
        onForeground: Colors.white,
      ),
      2 => _MedalColors(
        background: colors.surfaceContainerHigh,
        foreground: const Color(0xFF8A8F98),
        onForeground: Colors.white,
      ),
      3 => _MedalColors(
        background: const Color(0xFFFFE1CD),
        foreground: const Color(0xFFB56028),
        onForeground: Colors.white,
      ),
      _ => _MedalColors(
        background: colors.surfaceContainerLow,
        foreground: colors.surfaceContainerHighest,
        onForeground: colors.onSurfaceVariant,
      ),
    };
  }
}

class _MedalColors {
  final Color background;
  final Color foreground;
  final Color onForeground;

  const _MedalColors({
    required this.background,
    required this.foreground,
    required this.onForeground,
  });
}
