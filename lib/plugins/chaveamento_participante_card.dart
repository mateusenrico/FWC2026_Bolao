import 'package:flutter/material.dart';

import '../core/sistema_pontuacao_participantes.dart';
import '../core/sistema_pontuacao_times.dart';
import '../core/functions/team_normalizer.dart';
import 'mata_mata_bracket_view.dart';

class ChaveamentoParticipanteCard extends StatelessWidget {
  final ChaveamentoProjetado chaveamento;
  final PontuacaoFinalParticipante pontuacaoFinal;

  const ChaveamentoParticipanteCard({
    super.key,
    required this.chaveamento,
    required this.pontuacaoFinal,
  });

  @override
  Widget build(BuildContext context) {
    final jogos = chaveamento.jogosPorMatchNumber.values.toList()
      ..sort((a, b) => a.matchNumber.compareTo(b.matchNumber));

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        title: Text(
          'Projeção do mata-mata',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          pontuacaoFinal.campeaoPrevistoNome == null
              ? 'Chave ainda depende de palpites ou resultados futuros'
              : 'Campeão previsto: '
                    '${TeamNormalizer.sigla(pontuacaoFinal.campeaoPrevistoNome!)}',
        ),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        children: [
          _FinalFour(pontuacao: pontuacaoFinal),
          const SizedBox(height: 12),
          MataMataBracketView(chaveamento: chaveamento),
          const SizedBox(height: 12),
          for (final jogo in jogos.take(6)) _ProjectedMatchRow(jogo: jogo),
          if (chaveamento.avisos.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              '${chaveamento.avisos.length} etapa(s) ainda dependem de '
              'palpites, resultados ou da definição dos classificados.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FinalFour extends StatelessWidget {
  final PontuacaoFinalParticipante pontuacao;

  const _FinalFour({required this.pontuacao});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _PodiumChip(
          label: 'Campeão',
          name: pontuacao.campeaoPrevistoNome,
          points: pontuacao.pontosCampeao,
        ),
        _PodiumChip(
          label: 'Vice',
          name: pontuacao.vicePrevistoNome,
          points: pontuacao.pontosVice,
        ),
        _PodiumChip(
          label: '3º',
          name: pontuacao.terceiroPrevistoNome,
          points: pontuacao.pontosTerceiro,
        ),
        _PodiumChip(
          label: '4º',
          name: pontuacao.quartoPrevistoNome,
          points: pontuacao.pontosQuarto,
        ),
      ],
    );
  }
}

class _PodiumChip extends StatelessWidget {
  final String label;
  final String? name;
  final int points;

  const _PodiumChip({
    required this.label,
    required this.name,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            name == null ? '—' : TeamNormalizer.sigla(name!),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          if (points > 0)
            Text(
              '+$points',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
        ],
      ),
    );
  }
}

class _ProjectedMatchRow extends StatelessWidget {
  final JogoProjetado jogo;

  const _ProjectedMatchRow({required this.jogo});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final home = jogo.mandante?.nome;
    final away = jogo.visitante?.nome;
    final winner = jogo.vencedor?.nome;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 46,
            child: Text(
              'M${jogo.matchNumber}',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '${home == null ? '—' : TeamNormalizer.sigla(home)} '
              '${jogo.golsMandante ?? '-'} × ${jogo.golsVisitante ?? '-'} '
              '${away == null ? '—' : TeamNormalizer.sigla(away)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (winner != null)
            Text(
              '→ ${TeamNormalizer.sigla(winner)}',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
        ],
      ),
    );
  }
}
