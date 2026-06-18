import 'package:flutter/material.dart';

import '../core/app_routes.dart';
import '../core/sistema_pontuacao_times.dart';
import '../models/jogo.dart';
import '../plugins/api_refresh_action.dart';
import '../plugins/grupo_table_card.dart';
import '../plugins/live_matches_banner.dart';
import '../plugins/partida_card.dart';
import '../plugins/section_header.dart';
import '../services/bolao_controller.dart';

class GruposScreen extends StatefulWidget {
  final BolaoController controller;
  final String? grupoInicial;

  const GruposScreen({super.key, required this.controller, this.grupoInicial});

  @override
  State<GruposScreen> createState() => _GruposScreenState();
}

class _GruposScreenState extends State<GruposScreen> {
  String? _grupoSelecionado;

  BolaoController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _grupoSelecionado = widget.grupoInicial;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final grupos = controller.tabelasGrupos.tabelasPorGrupo.keys.toList()
          ..sort();
        final selected =
            _grupoSelecionado ?? (grupos.isEmpty ? null : grupos.first);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Classificação dos grupos'),
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
                            title: 'Grupos A-L',
                            subtitle:
                                'Tabela completa com jogos, vitórias, empates, derrotas, saldo e gols',
                          ),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final wide = constraints.maxWidth >= 1040;
                              final grid = _GroupsGrid(
                                controller: controller,
                                grupos: grupos,
                                selected: selected,
                                onSelect: (grupo) {
                                  setState(() => _grupoSelecionado = grupo);
                                },
                              );
                              final detail = selected == null
                                  ? const SizedBox.shrink()
                                  : _GroupDetail(
                                      controller: controller,
                                      group: selected,
                                    );

                              if (!wide) {
                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    grid,
                                    const SizedBox(height: 18),
                                    detail,
                                  ],
                                );
                              }

                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(flex: 5, child: grid),
                                  const SizedBox(width: 18),
                                  Expanded(flex: 4, child: detail),
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

class _GroupsGrid extends StatelessWidget {
  final BolaoController controller;
  final List<String> grupos;
  final String? selected;
  final ValueChanged<String> onSelect;

  const _GroupsGrid({
    required this.controller,
    required this.grupos,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 720 ? 2 : 1;
        final itemWidth = (width - ((columns - 1) * 12)) / columns;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final grupo in grupos)
              SizedBox(
                width: itemWidth,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: selected == grupo
                        ? Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          )
                        : null,
                  ),
                  child: GrupoTableCard(
                    tabela: controller.tabelasGrupos.tabela(grupo)!,
                    badgeForTeam: controller.badgeDoTime,
                    onTeamTap: (nomeTime) {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.time,
                        arguments: nomeTime,
                      );
                    },
                    onTap: () => onSelect(grupo),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _GroupDetail extends StatelessWidget {
  final BolaoController controller;
  final String group;

  const _GroupDetail({required this.controller, required this.group});

  @override
  Widget build(BuildContext context) {
    final tabela = controller.tabelasGrupos.tabela(group);
    final jogos = controller.data.jogosOrdenados
        .where((jogo) => jogo.grupo == group && jogo.isFaseDeGrupos)
        .toList(growable: false);

    final provaveis = _provaveisJogosMataMata(group);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Detalhe do Grupo $group',
          subtitle: tabela?.grupoCompleto == true
              ? 'Grupo encerrado'
              : 'Classificação parcial',
        ),
        const SectionHeader(title: 'Partidas do grupo'),
        for (final jogo in jogos)
          PartidaCard(
            jogo: jogo,
            badgeMandante: controller.badgeDoTime(jogo.mandantePrevisto),
            badgeVisitante: controller.badgeDoTime(jogo.visitantePrevisto),
            onTap: () => Navigator.pushNamed(
              context,
              AppRoutes.jogo,
              arguments: jogo.jogoId,
            ),
          ),
        if (provaveis.isNotEmpty) ...[
          const SizedBox(height: 16),
          const SectionHeader(
            title: 'Cruzamentos prováveis',
            subtitle:
                'Jogos do mata-mata que citam posições deste grupo no fixture',
          ),
          for (final jogo in provaveis)
            _ProjectedReferenceCard(
              controller: controller,
              jogo: jogo,
              tabela: tabela,
            ),
        ],
      ],
    );
  }

  List<Jogo> _provaveisJogosMataMata(String group) {
    return controller.data.jogosOrdenados
        .where((jogo) {
          if (!jogo.isMataMata) {
            return false;
          }

          final refs = [jogo.mandanteReferencia, jogo.visitanteReferencia];
          return refs.any(
            (ref) => ref.grupo == group || ref.gruposElegiveis.contains(group),
          );
        })
        .toList(growable: false);
  }
}

class _ProjectedReferenceCard extends StatelessWidget {
  final BolaoController controller;
  final Jogo jogo;
  final TabelaGrupo? tabela;

  const _ProjectedReferenceCard({
    required this.controller,
    required this.jogo,
    required this.tabela,
  });

  @override
  Widget build(BuildContext context) {
    final projectedGame = jogo.copyWith(
      mandantePrevisto: _resolvedText(jogo.mandanteReferencia.descricao),
      visitantePrevisto: _resolvedText(jogo.visitanteReferencia.descricao),
    );

    return PartidaCard(
      jogo: projectedGame,
      badgeMandante: controller.badgeDoTime(projectedGame.mandantePrevisto),
      badgeVisitante: controller.badgeDoTime(projectedGame.visitantePrevisto),
      onTap: () =>
          Navigator.pushNamed(context, AppRoutes.jogo, arguments: jogo.jogoId),
    );
  }

  String _resolvedText(String descricao) {
    final primeiro = tabela?.primeiro;
    final segundo = tabela?.segundo;
    final terceiro = tabela?.terceiro;

    if (descricao.startsWith('1º') && primeiro != null) {
      return primeiro.nome;
    }

    if (descricao.startsWith('2º') && segundo != null) {
      return segundo.nome;
    }

    if (descricao.startsWith('3º') && terceiro != null) {
      return terceiro.nome;
    }

    return descricao;
  }
}
