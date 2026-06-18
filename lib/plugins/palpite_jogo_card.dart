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

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Jogo ${jogo.matchNumber} · ${AppDateTime.dataCurta(date)} ${AppDateTime.horario(date)}',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (pontuacao?.pontuavel == true)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: pontuacao?.placarExato == true
                            ? colors.primaryContainer
                            : colors.secondaryContainer,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${pontuacao!.pontos} pts',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 560;

                  if (compact) {
                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _TeamLabel(
                                teamName: jogo.mandantePrevisto,
                                badgeUrl: badgeMandante,
                                alignEnd: true,
                              ),
                            ),
                            const SizedBox(width: 10),
                            _ScoreLabel(
                              title: 'Palpite',
                              value: palpite?.placarTexto ?? '-',
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _TeamLabel(
                                teamName: jogo.visitantePrevisto,
                                badgeUrl: badgeVisitante,
                                alignEnd: false,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Resultado: ${jogo.temResultado ? jogo.placarTexto : '-'}',
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
                      _ScoreLabel(
                        title: 'Palpite',
                        value: palpite?.placarTexto ?? '-',
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(Icons.arrow_forward, size: 18),
                      ),
                      _ScoreLabel(
                        title: 'Resultado',
                        value: jogo.temResultado ? jogo.placarTexto : '-',
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
