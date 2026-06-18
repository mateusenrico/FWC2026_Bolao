import 'package:flutter/material.dart';

import '../core/sistema_pontuacao_times.dart';
import '../core/functions/team_normalizer.dart';

class GrupoTableCard extends StatelessWidget {
  final TabelaGrupo tabela;

  const GrupoTableCard({super.key, required this.tabela});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
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
              ],
            ),
            const SizedBox(height: 12),
            const _HeaderRow(),
            const Divider(height: 16),
            for (final linha in tabela.linhas)
              _TeamRow(
                linha: linha,
                qualified: linha.posicao <= 2 || linha.classificouComoTerceiro,
              ),
          ],
        ),
      ),
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
          width: 44,
          child: Text('PTS', textAlign: TextAlign.center, style: style),
        ),
        SizedBox(
          width: 44,
          child: Text('SG', textAlign: TextAlign.center, style: style),
        ),
      ],
    );
  }
}

class _TeamRow extends StatelessWidget {
  final LinhaTabelaTime linha;
  final bool qualified;

  const _TeamRow({required this.linha, required this.qualified});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
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
          Expanded(
            child: Text(
              TeamNormalizer.sigla(linha.nome),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6,
              ),
            ),
          ),
          _Value(value: linha.pontos),
          _Value(value: linha.saldoGols),
        ],
      ),
    );
  }
}

class _Value extends StatelessWidget {
  final int value;

  const _Value({required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
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
