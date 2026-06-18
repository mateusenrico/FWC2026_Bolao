import 'package:flutter/material.dart';

import '../core/sistema_pontuacao_participantes.dart';

class RankingParticipanteCard extends StatelessWidget {
  final LinhaPontuacaoParticipante linha;
  final VoidCallback? onTap;

  const RankingParticipanteCard({super.key, required this.linha, this.onTap});

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
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _positionColor(colorScheme),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${linha.posicao}º',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: _positionForeground(colorScheme),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      linha.nome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${linha.placaresExatos} exatos · ${linha.resultadosCorretos} resultados',
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
                  Text(
                    '${linha.pontosTotal}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'pontos',
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

  Color _positionForeground(ColorScheme colors) {
    return switch (linha.posicao) {
      1 => colors.onPrimary,
      2 => colors.onSecondaryContainer,
      3 => colors.onTertiaryContainer,
      _ => colors.onSurfaceVariant,
    };
  }
}
