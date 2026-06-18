import 'package:flutter/material.dart';

import '../core/app_routes.dart';
import '../core/functions/team_normalizer.dart';
import '../core/sistema_pontuacao_times.dart';
import '../models/time_participante.dart';
import '../plugins/api_refresh_action.dart';
import '../plugins/live_matches_banner.dart';
import '../plugins/partida_card.dart';
import '../plugins/remote_media.dart';
import '../plugins/section_header.dart';
import '../plugins/team_badge.dart';
import '../services/bolao_controller.dart';

class TimeScreen extends StatelessWidget {
  final BolaoController controller;
  final String nomeTime;

  const TimeScreen({
    super.key,
    required this.controller,
    required this.nomeTime,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final time = controller.timeParticipantePorNome(nomeTime);

        if (time == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Time')),
            body: const Center(child: Text('Time não encontrado.')),
          );
        }

        final sportsDb = controller.timeSportsDb(time.nome);
        final linha = controller.linhaDoTimeNoGrupo(
          nomeTime: time.nome,
          grupo: time.grupo,
        );
        final jogos = controller.jogosDoTime(time.nome);

        return Scaffold(
          appBar: AppBar(
            title: Text(time.nome),
            actions: [ApiRefreshAction(controller: controller)],
          ),
          body: Column(
            children: [
              LiveMatchesBanner(controller: controller),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 36),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _TeamHero(
                        time: time,
                        imageUrl: sportsDb?.melhorImagem,
                        badgeUrl: controller.badgeDoTime(time.nome),
                      ),
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1120),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _TeamStats(time: time, linha: linha),
                                const SizedBox(height: 22),
                                const SectionHeader(
                                  title: 'Jogos do time',
                                  subtitle:
                                      'Partidas da fase de grupos associadas a esta seleção',
                                ),
                                for (final jogo in jogos)
                                  PartidaCard(
                                    jogo: jogo,
                                    badgeMandante: controller.badgeDoTime(
                                      jogo.mandantePrevisto,
                                    ),
                                    badgeVisitante: controller.badgeDoTime(
                                      jogo.visitantePrevisto,
                                    ),
                                    onTap: () {
                                      Navigator.pushNamed(
                                        context,
                                        AppRoutes.jogo,
                                        arguments: jogo.jogoId,
                                      );
                                    },
                                  ),
                                if (sportsDb?.descricao != null &&
                                    sportsDb!.descricao!.isNotEmpty) ...[
                                  const SizedBox(height: 18),
                                  const SectionHeader(title: 'Notas'),
                                  Card(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Text(
                                        sportsDb.descricao!,
                                        maxLines: 6,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
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

class _TeamHero extends StatelessWidget {
  final TimeParticipante time;
  final String? imageUrl;
  final String? badgeUrl;

  const _TeamHero({
    required this.time,
    required this.imageUrl,
    required this.badgeUrl,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      child: Stack(
        fit: StackFit.expand,
        children: [
          RemoteImage(
            url: imageUrl,
            borderRadius: BorderRadius.zero,
            placeholder: const ColoredBox(color: Color(0xFF060606)),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.12),
                  Colors.black.withValues(alpha: 0.78),
                ],
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TeamBadge(teamName: time.nome, imageUrl: badgeUrl, size: 76),
                const SizedBox(height: 12),
                Text(
                  TeamNormalizer.sigla(time.nome),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '${time.nome} · Grupo ${time.grupo}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.86),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 16,
            bottom: 12,
            child: imageUrl == null
                ? const SizedBox.shrink()
                : const MediaCredit(),
          ),
        ],
      ),
    );
  }
}

class _TeamStats extends StatelessWidget {
  final TimeParticipante time;
  final LinhaTabelaTime? linha;

  const _TeamStats({required this.time, required this.linha});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _Metric(
              label: 'Posição',
              value: linha == null ? '-' : '${linha!.posicao}º',
              color: colors.primaryContainer,
            ),
            _Metric(label: 'Grupo', value: time.grupo),
            _Metric(label: 'Pontos', value: '${linha?.pontos ?? 0}'),
            _Metric(label: 'Jogos', value: '${linha?.jogos ?? 0}'),
            _Metric(label: 'Vitórias', value: '${linha?.vitorias ?? 0}'),
            _Metric(label: 'Empates', value: '${linha?.empates ?? 0}'),
            _Metric(label: 'Derrotas', value: '${linha?.derrotas ?? 0}'),
            _Metric(label: 'GP', value: '${linha?.golsPro ?? 0}'),
            _Metric(label: 'GC', value: '${linha?.golsContra ?? 0}'),
            _Metric(label: 'SG', value: '${linha?.saldoGols ?? 0}'),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _Metric({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      constraints: const BoxConstraints(minWidth: 86),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color ?? colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
