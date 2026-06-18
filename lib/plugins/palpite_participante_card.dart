import 'package:flutter/material.dart';

import '../core/sistema_palpites.dart';
import '../core/sistema_pontuacao_participantes.dart';
import '../models/palpite.dart';

class PalpiteParticipanteCard extends StatelessWidget {
  final LinhaPontuacaoParticipante linha;
  final Palpite? palpite;
  final PontuacaoPalpite? pontuacao;
  final VoidCallback? onTap;

  const PalpiteParticipanteCard({
    super.key,
    required this.linha,
    required this.palpite,
    required this.pontuacao,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final gamePoints = pontuacao?.pontuavel == true ? pontuacao!.pontos : 0;
    final basePoints = linha.pontosTotal - gamePoints;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              SizedBox(
                width: 42,
                child: Text(
                  '${linha.posicao}º',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(width: 8),
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
                    const SizedBox(height: 3),
                    Text(
                      'Sem este jogo: $basePoints',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  palpite?.placarTexto ?? '-',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 52,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      pontuacao?.pontuavel == true ? '+$gamePoints' : '—',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: pontuacao?.placarExato == true
                            ? colors.primary
                            : colors.onSurface,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'neste jogo',
                      textAlign: TextAlign.right,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
