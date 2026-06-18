import 'package:flutter/material.dart';

import '../core/functions/date_time_utils.dart';
import '../core/functions/team_normalizer.dart';
import '../models/jogo.dart';
import 'remote_media.dart';
import 'team_badge.dart';

class PartidaCard extends StatelessWidget {
  final Jogo jogo;
  final String? badgeMandante;
  final String? badgeVisitante;
  final String? imageUrl;
  final VoidCallback? onTap;
  final bool destaque;

  const PartidaCard({
    super.key,
    required this.jogo,
    this.badgeMandante,
    this.badgeVisitante,
    this.imageUrl,
    this.onTap,
    this.destaque = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final date = AppDateTime.horarioBrasilia(jogo);
    final hasImage = destaque && imageUrl != null && imageUrl!.isNotEmpty;
    final content = _PartidaCardContent(
      jogo: jogo,
      date: date,
      badgeMandante: badgeMandante,
      badgeVisitante: badgeVisitante,
      onTap: onTap,
    );

    return Card(
      elevation: 0,
      color: jogo.isEmAndamento
          ? colorScheme.errorContainer.withValues(alpha: destaque ? 0.42 : 0.24)
          : destaque
          ? colorScheme.surfaceContainerHigh
          : null,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (!hasImage) {
              return Padding(padding: const EdgeInsets.all(16), child: content);
            }

            if (constraints.maxWidth >= 620) {
              return Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 176,
                      child: RemoteImage(
                        url: imageUrl,
                        height: 126,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: content),
                  ],
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 96,
                  child: RemoteImage(
                    url: imageUrl,
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                Padding(padding: const EdgeInsets.all(16), child: content),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PartidaCardContent extends StatelessWidget {
  final Jogo jogo;
  final DateTime? date;
  final String? badgeMandante;
  final String? badgeVisitante;
  final VoidCallback? onTap;

  const _PartidaCardContent({
    required this.jogo,
    required this.date,
    required this.badgeMandante,
    required this.badgeVisitante,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final headerText = Text(
      'Jogo ${jogo.matchNumber} · ${_faseTexto(jogo)}',
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.labelLarge?.copyWith(
        color: colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w800,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 330) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  headerText,
                  const SizedBox(height: 6),
                  _StatusChip(status: jogo.statusJogo),
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: headerText),
                const SizedBox(width: 8),
                _StatusChip(status: jogo.statusJogo),
              ],
            );
          },
        ),
        const SizedBox(height: 6),
        Text(
          '${AppDateTime.diaSemana(date)} · ${AppDateTime.dataCurta(date)} · ${AppDateTime.horario(date)} (UTC-3)',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 470;
            final veryCompact = constraints.maxWidth < 340;

            final teamsRow = Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: _TeamSide(
                    teamName: jogo.mandantePrevisto,
                    badgeUrl: badgeMandante,
                    alignEnd: true,
                    compact: compact,
                  ),
                ),
                if (!veryCompact) ...[
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 16),
                    child: _ScoreCenter(jogo: jogo, compact: compact),
                  ),
                ],
                Expanded(
                  child: _TeamSide(
                    teamName: jogo.visitantePrevisto,
                    badgeUrl: badgeVisitante,
                    alignEnd: false,
                    compact: compact,
                  ),
                ),
              ],
            );

            if (veryCompact) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  teamsRow,
                  const SizedBox(height: 10),
                  _ScoreCenter(jogo: jogo, compact: true),
                ],
              );
            }

            return teamsRow;
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(
              Icons.location_on_outlined,
              size: 16,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                jogo.localTexto.isEmpty ? 'Local a definir' : jogo.localTexto,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
            ],
          ],
        ),
      ],
    );
  }

  String _faseTexto(Jogo jogo) {
    if (jogo.isFaseDeGrupos && jogo.grupo != null) {
      final rodada = jogo.rodada == null ? '' : ' · Rodada ${jogo.rodada}';
      return 'Grupo ${jogo.grupo}$rodada';
    }

    if (jogo.fase.isNotEmpty) {
      return jogo.fase;
    }

    return jogo.faseCodigo;
  }
}

class _TeamSide extends StatelessWidget {
  final String teamName;
  final String? badgeUrl;
  final bool alignEnd;
  final bool compact;

  const _TeamSide({
    required this.teamName,
    required this.badgeUrl,
    required this.alignEnd,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final code = TeamNormalizer.sigla(teamName);
    final alignment = alignEnd
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;

    return Column(
      crossAxisAlignment: alignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        TeamBadge(
          teamName: teamName,
          imageUrl: badgeUrl,
          size: compact ? 34 : 44,
        ),
        const SizedBox(height: 6),
        Text(
          code,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        if (!compact)
          Text(
            teamName,
            textAlign: alignEnd ? TextAlign.right : TextAlign.left,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
    );
  }
}

class _ScoreCenter extends StatelessWidget {
  final Jogo jogo;
  final bool compact;

  const _ScoreCenter({required this.jogo, required this.compact});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final hasScore =
        jogo.temResultado &&
        jogo.golsMandante != null &&
        jogo.golsVisitante != null;

    if (!hasScore) {
      if (jogo.isAgendado) {
        return Opacity(
          opacity: 0.54,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ScoreBox(value: '0', compact: compact),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: compact ? 5 : 8),
                child: Text(
                  '×',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              _ScoreBox(value: '0', compact: compact),
            ],
          ),
        );
      }

      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 14,
          vertical: compact ? 7 : 9,
        ),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.58),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'VS',
          style: textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ScoreBox(value: jogo.golsMandante.toString(), compact: compact),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: compact ? 5 : 8),
          child: Text(
            '×',
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
        _ScoreBox(value: jogo.golsVisitante.toString(), compact: compact),
      ],
    );
  }
}

class _ScoreBox extends StatelessWidget {
  final String value;
  final bool compact;

  const _ScoreBox({required this.value, required this.compact});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: compact ? 34 : 44,
      height: compact ? 40 : 50,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        value,
        style: Theme.of(
          context,
        ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (label, background, foreground) = switch (status) {
      'em_andamento' => ('AO VIVO', colorScheme.error, colorScheme.onError),
      'encerrado' => (
        'FINAL',
        colorScheme.secondaryContainer,
        colorScheme.onSecondaryContainer,
      ),
      _ => (
        'AGENDADO',
        colorScheme.surfaceContainerHighest,
        colorScheme.onSurfaceVariant,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
