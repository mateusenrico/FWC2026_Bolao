import 'package:flutter/material.dart';

import '../core/functions/date_time_utils.dart';
import '../core/sistema_palpites.dart';
import '../core/functions/team_normalizer.dart';
import '../models/jogo.dart';
import '../models/palpite.dart';
import 'team_badge.dart';

class PalpiteJogoCard extends StatelessWidget {
  final Jogo jogo;
  final Palpite? palpite;
  final PontuacaoPalpite? pontuacao;
  final String? badgeMandante;
  final String? badgeVisitante;
  final VoidCallback? onTap;

  const PalpiteJogoCard({
    super.key,
    required this.jogo,
    required this.palpite,
    required this.pontuacao,
    this.badgeMandante,
    this.badgeVisitante,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final date = AppDateTime.horarioBrasilia(jogo);
    final scoreIsResult = jogo.temResultado || jogo.isEmAndamento;
    final primaryScore = scoreIsResult
        ? jogo.placarTexto
        : palpite?.placarTexto ?? '-';
    final primaryLabel = scoreIsResult
        ? jogo.resultadoFinal
              ? 'Resultado'
              : 'Parcial'
        : 'Palpite';
    final comparisonText = scoreIsResult
        ? 'Palpite: ${palpite?.placarTexto ?? '-'}'
        : 'Jogo ainda não começou';
    final cardColor = _statusColor(colors);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: cardColor,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final title = Text(
                    'Jogo ${jogo.matchNumber} · ${AppDateTime.dataCurta(date)} ${AppDateTime.horario(date)}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  );
                  final points = pontuacao?.pontuavel == true
                      ? _PointsChip(pontuacao: pontuacao!)
                      : null;

                  if (points == null) {
                    return title;
                  }

                  if (constraints.maxWidth < 350) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [title, const SizedBox(height: 6), points],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: title),
                      const SizedBox(width: 8),
                      points,
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 560;
                  final veryCompact = constraints.maxWidth < 340;

                  if (compact) {
                    final teams = Row(
                      children: [
                        Expanded(
                          child: _TeamLabel(
                            teamName: jogo.mandantePrevisto,
                            badgeUrl: badgeMandante,
                            alignEnd: true,
                          ),
                        ),
                        if (!veryCompact) ...[
                          const SizedBox(width: 10),
                          _ScoreLabel(title: primaryLabel, value: primaryScore),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: _TeamLabel(
                            teamName: jogo.visitantePrevisto,
                            badgeUrl: badgeVisitante,
                            alignEnd: false,
                          ),
                        ),
                      ],
                    );

                    return Column(
                      children: [
                        teams,
                        if (veryCompact) ...[
                          const SizedBox(height: 10),
                          _ScoreLabel(title: primaryLabel, value: primaryScore),
                        ],
                        const SizedBox(height: 10),
                        Text(
                          comparisonText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(
                        child: _TeamLabel(
                          teamName: jogo.mandantePrevisto,
                          badgeUrl: badgeMandante,
                          alignEnd: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _ScoreLabel(title: primaryLabel, value: primaryScore),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(Icons.arrow_forward, size: 18),
                      ),
                      _ScoreLabel(
                        title: scoreIsResult ? 'Palpite' : 'Status',
                        value: scoreIsResult
                            ? palpite?.placarTexto ?? '-'
                            : 'Não iniciado',
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _TeamLabel(
                          teamName: jogo.visitantePrevisto,
                          badgeUrl: badgeVisitante,
                          alignEnd: false,
                        ),
                      ),
                    ],
                  );
                },
              ),
              if (pontuacao != null) ...[
                const SizedBox(height: 10),
                Text(
                  pontuacao!.motivo,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color? _statusColor(ColorScheme colors) {
    final score = pontuacao;
    if (score?.placarExato == true) {
      return colors.primaryContainer.withValues(alpha: 0.45);
    }

    if (score?.resultadoCorreto == true) {
      return colors.secondaryContainer.withValues(alpha: 0.45);
    }

    if (score?.acertouUmDosGols == true) {
      return colors.tertiaryContainer.withValues(alpha: 0.45);
    }

    if (score?.zerou == true) {
      return colors.errorContainer.withValues(alpha: 0.28);
    }

    return null;
  }
}

class _PointsChip extends StatelessWidget {
  final PontuacaoPalpite pontuacao;

  const _PointsChip({required this.pontuacao});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: pontuacao.placarExato
            ? colors.primaryContainer
            : colors.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '${pontuacao.pontos}',
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _TeamLabel extends StatelessWidget {
  final String teamName;
  final String? badgeUrl;
  final bool alignEnd;

  const _TeamLabel({
    required this.teamName,
    required this.badgeUrl,
    required this.alignEnd,
  });

  @override
  Widget build(BuildContext context) {
    final content = [
      TeamBadge(teamName: teamName, imageUrl: badgeUrl, size: 32),
      const SizedBox(width: 8),
      Flexible(
        child: Column(
          crossAxisAlignment: alignEnd
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              TeamNormalizer.sigla(teamName),
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            Text(
              teamName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: alignEnd ? TextAlign.right : TextAlign.left,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    ];

    return Row(
      mainAxisAlignment: alignEnd
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: alignEnd ? content.reversed.toList() : content,
    );
  }
}

class _ScoreLabel extends StatelessWidget {
  final String title;
  final String value;

  const _ScoreLabel({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 3),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }
}
