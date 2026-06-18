import 'package:flutter/material.dart';

import '../core/app_routes.dart';
import '../core/functions/team_normalizer.dart';
import '../plugins/api_refresh_action.dart';
import '../plugins/live_matches_banner.dart';
import '../plugins/section_header.dart';
import '../plugins/team_overview_card.dart';
import '../services/bolao_controller.dart';

class TimesScreen extends StatefulWidget {
  final BolaoController controller;

  const TimesScreen({super.key, required this.controller});

  @override
  State<TimesScreen> createState() => _TimesScreenState();
}

class _TimesScreenState extends State<TimesScreen> {
  String _query = '';

  BolaoController get controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final times = controller.timesOrdenados
            .where((time) {
              final query = TeamNormalizer.normalize(_query);
              if (query.isEmpty) {
                return true;
              }

              return TeamNormalizer.normalize(time.nome).contains(query) ||
                  TeamNormalizer.normalize(time.grupo).contains(query) ||
                  TeamNormalizer.sigla(time.nome).toLowerCase().contains(query);
            })
            .toList(growable: false);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Times'),
            actions: [ApiRefreshAction(controller: controller)],
          ),
          body: Column(
            children: [
              LiveMatchesBanner(controller: controller),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 36),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1280),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SectionHeader(
                            title: 'Times participantes',
                            subtitle:
                                'Escudos, grupo, pontuação e caminho para os jogos de cada seleção',
                          ),
                          TextField(
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.search),
                              hintText: 'Buscar por time, sigla ou grupo',
                            ),
                            onChanged: (value) {
                              setState(() => _query = value);
                            },
                          ),
                          const SizedBox(height: 14),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final columns = constraints.maxWidth >= 1060
                                  ? 3
                                  : constraints.maxWidth >= 720
                                  ? 2
                                  : 1;
                              final width =
                                  (constraints.maxWidth -
                                      ((columns - 1) * 12)) /
                                  columns;

                              return Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  for (final time in times)
                                    SizedBox(
                                      width: width,
                                      child: TeamOverviewCard(
                                        time: time,
                                        sportsDb: controller.timeSportsDb(
                                          time.nome,
                                        ),
                                        tableLine: controller
                                            .linhaDoTimeNoGrupo(
                                              nomeTime: time.nome,
                                              grupo: time.grupo,
                                            ),
                                        badgeUrl: controller.badgeDoTime(
                                          time.nome,
                                        ),
                                        flagUrl: controller.bandeiraDoTime(
                                          time.nome,
                                        ),
                                        imageUrl: controller.imagemDoTime(
                                          time.nome,
                                        ),
                                        onTap: () {
                                          Navigator.pushNamed(
                                            context,
                                            AppRoutes.time,
                                            arguments: time.nome,
                                          );
                                        },
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
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
