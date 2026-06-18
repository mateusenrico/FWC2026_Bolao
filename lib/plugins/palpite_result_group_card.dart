import 'package:flutter/material.dart';

import '../core/functions/participant_colors.dart';
import '../core/functions/palpite_match_groups.dart';
import '../core/sistema_palpites.dart';
import '../models/jogo.dart';
import 'participant_identity.dart';

class PalpiteResultGroupCard extends StatelessWidget {
  final Jogo jogo;
  final GrupoPalpitesJogo group;
  final Map<String, Color> participantColors;
  final VoidCallback? Function(String participanteId) onTapParticipante;

  const PalpiteResultGroupCard({
    super.key,
    required this.jogo,
    required this.group,
    this.participantColors = const {},
    required this.onTapParticipante,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final active = group.resultadoAtual && jogo.temResultado;

    return Card(
      color: active
          ? colors.primaryContainer.withValues(alpha: 0.5)
          : colors.surface,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 380;
                final title = Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_iconFor(group.resultado), color: colors.primary),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _titleFor(jogo, group.resultado),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                );

                final summary = _GroupSummary(group: group, active: active);

                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [title, const SizedBox(height: 8), summary],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: title),
                    const SizedBox(width: 12),
                    summary,
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            if (group.palpites.isEmpty)
              Text(
                'Nenhum participante nesse grupo.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final item in group.palpites)
                    _PalpiteChip(
                      item: item,
                      participantColor:
                          participantColors[item.linha.participanteId],
                      onTap: onTapParticipante(item.linha.participanteId),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  String _titleFor(Jogo jogo, ResultadoPartida resultado) {
    return switch (resultado) {
      ResultadoPartida.mandante => 'Vitória de ${jogo.mandantePrevisto}',
      ResultadoPartida.visitante => 'Vitória de ${jogo.visitantePrevisto}',
      ResultadoPartida.empate => 'Empate',
      ResultadoPartida.indefinido => 'Sem palpite completo',
    };
  }

  IconData _iconFor(ResultadoPartida resultado) {
    return switch (resultado) {
      ResultadoPartida.mandante => Icons.home_outlined,
      ResultadoPartida.visitante => Icons.flight_land_outlined,
      ResultadoPartida.empate => Icons.drag_handle,
      ResultadoPartida.indefinido => Icons.help_outline,
    };
  }
}

class _GroupSummary extends StatelessWidget {
  final GrupoPalpitesJogo group;
  final bool active;

  const _GroupSummary({required this.group, required this.active});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _TinyPill(
          label: '${group.palpites.length}',
          suffix: 'palpites',
          color: colors.surfaceContainerHighest,
        ),
        if (active)
          _TinyPill(
            label: '+${group.totalPontos}',
            suffix: 'agora',
            color: colors.primary,
            foreground: colors.onPrimary,
          )
        else if (group.totalPontos > 0)
          _TinyPill(
            label: '+${group.totalPontos}',
            suffix: 'pts',
            color: colors.secondaryContainer,
          ),
      ],
    );
  }
}

class _PalpiteChip extends StatelessWidget {
  final PalpiteJogoAgrupado item;
  final Color? participantColor;
  final VoidCallback? onTap;

  const _PalpiteChip({
    required this.item,
    required this.participantColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pontuacao = item.pontuacao;
    final color = _colorFor(context);
    final foreground = _foregroundFor(context, color);
    final accent = participantColor ?? Theme.of(context).colorScheme.primary;

    return Material(
      color: color,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 126, maxWidth: 180),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ParticipantNameInline(
                        name: item.linha.nome,
                        color: accent,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      item.palpite?.placarTexto ?? '-',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  pontuacao?.pontuavel == true
                      ? '+${pontuacao!.pontos} · ${_shortReason(pontuacao)}'
                      : pontuacao?.motivo ?? 'Sem pontuação ainda',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: foreground.withValues(alpha: 0.78),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _colorFor(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final pontuacao = item.pontuacao;

    if (pontuacao?.placarExato == true) {
      return colors.primary;
    }

    if (pontuacao?.resultadoCorreto == true) {
      return colors.secondaryContainer;
    }

    if (pontuacao?.acertouUmDosGols == true) {
      return colors.tertiaryContainer;
    }

    if (pontuacao?.zerou == true) {
      return colors.errorContainer.withValues(alpha: 0.7);
    }

    if (participantColor != null) {
      return ParticipantColors.softBackgroundFor(participantColor!, colors);
    }

    return colors.surfaceContainerHighest;
  }

  Color _foregroundFor(BuildContext context, Color background) {
    final colors = Theme.of(context).colorScheme;
    if (background == colors.primary) {
      return colors.onPrimary;
    }

    return colors.onSurface;
  }

  String _shortReason(PontuacaoPalpite pontuacao) {
    if (pontuacao.placarExato) {
      return 'exato';
    }

    if (pontuacao.resultadoCorreto && pontuacao.acertouUmDosGols) {
      return 'resultado + gol';
    }

    if (pontuacao.resultadoCorreto) {
      return 'resultado';
    }

    if (pontuacao.acertouUmDosGols) {
      return 'um gol';
    }

    return 'zerou';
  }
}

class _TinyPill extends StatelessWidget {
  final String label;
  final String suffix;
  final Color color;
  final Color? foreground;

  const _TinyPill({
    required this.label,
    required this.suffix,
    required this.color,
    this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = foreground ?? Theme.of(context).colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label $suffix',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
