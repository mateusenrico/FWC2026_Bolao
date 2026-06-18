import 'package:flutter/material.dart';

import '../core/sistema_pontuacao_times.dart';
import '../core/functions/team_normalizer.dart';
import 'team_badge.dart';

class GrupoTableCard extends StatelessWidget {
  final TabelaGrupo tabela;
  final VoidCallback? onTap;
  final String? Function(String nomeTime)? badgeForTeam;
  final ValueChanged<String>? onTeamTap;

  const GrupoTableCard({
    super.key,
    required this.tabela,
    this.onTap,
    this.badgeForTeam,
    this.onTeamTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final content = Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Grupo ${tabela.grupo}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                tabela.grupoCompleto ? 'Final' : 'Parcial',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
              ],
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final tableWidth = constraints.maxWidth < 380
                  ? 380.0
                  : constraints.maxWidth;

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: tableWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _HeaderRow(),
                      const Divider(height: 16),
                      for (final linha in tabela.linhas)
                        _TeamRow(
                          linha: linha,
                          qualified:
                              linha.posicao <= 2 ||
                              linha.classificouComoTerceiro,
                          badgeUrl: badgeForTeam?.call(linha.nome),
                          onTap: onTeamTap == null
                              ? null
                              : () => onTeamTap!(linha.nome),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.w800,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );

    return Row(
      children: [
        SizedBox(width: 34, child: Text('#', style: style)),
        Expanded(child: Text('TIME', style: style)),
        SizedBox(
          width: 34,
          child: Text('J', textAlign: TextAlign.center, style: style),
        ),
        SizedBox(
          width: 34,
          child: Text('V', textAlign: TextAlign.center, style: style),
        ),
        SizedBox(
          width: 34,
          child: Text('E', textAlign: TextAlign.center, style: style),
        ),
        SizedBox(
          width: 34,
          child: Text('D', textAlign: TextAlign.center, style: style),
        ),
        SizedBox(
          width: 44,
          child: Text('PTS', textAlign: TextAlign.center, style: style),
        ),
        SizedBox(
          width: 44,
          child: Text('SG', textAlign: TextAlign.center, style: style),
        ),
        SizedBox(
          width: 44,
          child: Text('GP', textAlign: TextAlign.center, style: style),
        ),
      ],
    );
  }
}

class _TeamRow extends StatelessWidget {
  final LinhaTabelaTime linha;
  final bool qualified;
  final String? badgeUrl;
  final VoidCallback? onTap;

  const _TeamRow({
    required this.linha,
    required this.qualified,
    required this.badgeUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final content = Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 9),
      decoration: BoxDecoration(
        color: qualified
            ? colors.primaryContainer.withValues(alpha: 0.30)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Text(
              '${linha.posicao}º',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
          ),
          TeamBadge(teamName: linha.nome, imageUrl: badgeUrl, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              TeamNormalizer.sigla(linha.nome),
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
          ),
          _Value(value: linha.jogos, width: 34),
          _Value(value: linha.vitorias, width: 34),
          _Value(value: linha.empates, width: 34),
          _Value(value: linha.derrotas, width: 34),
          _Value(value: linha.pontos),
          _Value(value: linha.saldoGols),
          _Value(value: linha.golsPro),
        ],
      ),
    );

    if (onTap == null) {
      return content;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: content,
    );
  }
}

class _Value extends StatelessWidget {
  final int value;
  final double width;

  const _Value({required this.value, this.width = 44});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(
        '$value',
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}
