import 'package:flutter/material.dart';

import '../plugins/api_refresh_action.dart';
import '../plugins/grupo_table_card.dart';
import '../plugins/section_header.dart';
import '../services/bolao_controller.dart';

class GruposScreen extends StatelessWidget {
  final BolaoController controller;

  const GruposScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final grupos = controller.tabelasGrupos.tabelasPorGrupo.keys.toList()
          ..sort();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Classificação dos grupos'),
            actions: [ApiRefreshAction(controller: controller)],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 36),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SectionHeader(
                      title: 'Grupos A–L',
                      subtitle:
                          'Ordenação parcial por pontos, saldo e gols marcados',
                    ),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        final columns = width >= 1120
                            ? 3
                            : width >= 720
                            ? 2
                            : 1;
                        final itemWidth =
                            (width - ((columns - 1) * 12)) / columns;

                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            for (final grupo in grupos)
                              SizedBox(
                                width: itemWidth,
                                child: GrupoTableCard(
                                  tabela: controller.tabelasGrupos.tabela(
                                    grupo,
                                  )!,
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
        );
      },
    );
  }
}
