# Checkup de pedidos e cobertura

Ultima revisao: v2.6.1-dev.

Este documento consolida os pedidos feitos durante a evolucao do app e o estado
de implementacao. Quando algo depende de fonte externa, a implementacao fica
marcada como parcial por disponibilidade da API, nao por lacuna de codigo.

## Status

| Pedido / area | Status | Onde esta |
| --- | --- | --- |
| Trabalhar sempre em `dev`, promover para `test` depois de validar, nunca tocar `main` sem autorizacao explicita | Completo | Fluxo de Git usado nos releases |
| Manter organizacao de `lib`: `core`, `core/functions`, `models`, `services`, `plugins`, `screens` e debug separado | Completo | `lib/`, `test/debug/` |
| Atualizar README/docs quando regras, API, deploy ou UI mudarem | Completo | `README.md`, `docs/` |
| Criar arquivo de creditos/licencas/powered by | Completo | `THIRD_PARTY_NOTICES.md` |
| Promover `test` para `main` e `dev` para `test` antes de novos pedidos, salvo ordem contraria | Completo | Regra operacional registrada no fluxo atual |
| Widget de ao vivo em telas internas, menor que o destaque da home | Completo | `LiveMatchesBanner` |
| Home mostra ao vivo ou proximo jogo | Completo | `BolaoController.proximosDestaques`, `HomeScreen` |
| Home mantem banner ao vivo fixo ao navegar pelo dashboard | Completo | `HomeScreen`, `LiveMatchesBanner` |
| Team badges/bandeiras por URLs da SportsDB/historico | Completo | `MediaCatalogService`, `TeamBadge`, `RemoteImage` |
| Bandeiras dos times como fundo visual quando disponiveis | Completo | `CountryFlagUrls`, `TeamFlagBackdrop`, `assets/media/team_flags/` |
| Banners/thumbs/posters de jogos em cards de partidas | Completo | `MatchBannerImage`, `PartidaCard`, `MediaCatalogService` |
| Imagens remotas com cache/fallback web para CORS/flicker | Completo | `RemoteImage`, `TeamBadge` |
| Badge/banner/liga/venue/video vindos da SportsDB quando houver | Completo | `MediaCatalogService`, telas de jogo/time |
| Cache local de imagens usadas pelo app em `assets/media/` | Completo | `tools/cache_media_assets.dart`, `LocalMediaManifestService`, `assets/media/media_manifest.json` |
| Investigar times, venues, liga e endpoints auxiliares da SportsDB | Completo | `tools/update_sportsdb.dart`, `SportsDbApiService`, `assets/data/*_sportsdb.json` |
| Pesquisar outras APIs publicas/de dados da Copa | Completo | `docs/APIS_DADOS_MIDIA.md` |
| Refresh inicial ao abrir o app | Completo | `BolaoController.carregar(atualizarAntesDeExibir: true)`, splash inicial |
| Refresh automatico durante jogos ao vivo | Completo | Timer de 5s em `BolaoController` |
| Refresh automatico sem apagar a tela ou voltar para a home | Completo | Atualizacao automatica so notifica UI quando dados dinamicos mudam |
| Refresh ao vivo nao pode regredir placar/status por resposta atrasada/incompleta da API | Completo | `BolaoController`, `SportsDbApiService`, `tools/update_sportsdb.dart`, testes de regressao |
| Remover dependencia visual do botao de refresh manual | Completo | `ApiRefreshAction` mostra apenas tema e indicador |
| Barra/indicador de proxima atualizacao | Completo | `RefreshCountdownIndicator` |
| Jogos iniciados sem placar contam provisoriamente como 0x0 para ranking projetado | Completo | `BolaoController._aplicarRelogioLocal`, `_mesclarJogoComEvento` |
| Jogos futuros podem exibir 0x0 sem pontuar | Completo | `SistemaPalpites`, testes |
| Ranking consolidado vs com ao vivo, com toggle apenas quando houver ao vivo | Completo | `RankingModeSelector`, controller |
| No ranking consolidado, ordem por pontos consolidados; no projetado, ordem por pontos com ao vivo | Completo | `BolaoController.alterarOrdenacaoRanking` |
| Desempate do ranking por placares exatos quando houver empate em pontos | Completo | `SistemaPontuacaoParticipantes`, `BolaoController`, teste |
| Ranking da home sem toggle, ordenado por consolidado + ao vivo e mostrando setas de deslocamento | Completo | `_RankingSection`, `RankingParticipanteCard` |
| Ranking da home com mini grafico de evolucao por posicao | Completo | `_RankingMiniEvolution` |
| Tela de ranking detalhada com podio | Completo | `RankingScreen`, `RankingPodium` |
| Podio menor e com contraste explicito no tema escuro | Completo | `RankingPodium` |
| Grafico de evolucao por pontos ou posicao | Completo | `RankingEvolutionChart`, `RankingScreen` |
| Evolucao por partida ou por dia brasileiro | Completo | `RankingScreen` |
| Grafico reescala o eixo X ao filtrar faixa de partidas/dias | Completo | `RankingEvolutionChart` |
| Grafico com guias por etapa e por posicoes/pontos | Completo | `RankingEvolutionChart` |
| Grafico usa o marcador visual da pessoa no fim da linha e na legenda | Completo | `RankingEvolutionChart`, `ParticipantMarker` |
| Cores fixas por participante em `participantes.json` | Completo | `ParticipantColors`, testes |
| Usar cor da pessoa como acento visual global onde nomes aparecem | Completo | `ParticipantPositionBadge`, `ParticipantNameInline`, ranking e palpites |
| Aumentar diferenciacao das cores dos participantes | Completo | `assets/data/participantes.json`, `ParticipantColors` |
| Diferenciar participantes tambem por marcador visual alem da cor, sem usar `X` | Completo | `ParticipantMarker`, `ParticipantNameInline` |
| Legenda do grafico ordenada por ranking atual | Completo | `RankingEvolutionChart` |
| Lista detalhada do ranking sem tabela redundante e com +5/+3/+2/+1/0 | Completo | `RankingScreen`, cards compactos |
| Lista detalhada do ranking sem colunas redundantes de jogos/grupos/final/max/pontuaveis | Completo | `_RankingPointsGrid` |
| Tabela de ranking ocupa a largura disponivel sem sobra deslocada | Completo | `_RankingPointsGrid` |
| Participantes sem nenhum palpite completo nao aparecem nos rankings/palpites | Completo | `BolaoController` |
| Tela do participante com filtros de palpites (+5, zerados, futuros etc.) | Completo | `ParticipanteDetailScreen` |
| Tela do participante mostra palpite vs resultado/parcial com cores e pontos | Completo | `PalpiteJogoCard` |
| Separar grupos e mata-mata nas exibicoes de jogos | Completo | `JogosScreen`, `MataMataBracketView` |
| Chaveamento em formato visual para mata-mata, responsivo | Completo | `MataMataBracketView`; desktop usa metades esquerda/direita com final no centro, mobile usa colunas verticais |
| Resolver melhores terceiros de forma global antes do fallback por slot | Completo | `SistemaPontuacaoTimes._resolverSlotsMelhoresTerceiros` |
| Simulador de cenarios com busca/cards compactos | Preservado, oculto da navegacao | `SimuladorScreen` continua no codigo; rota/atalho removidos por enquanto |
| Tela de grupos clicavel com detalhe, partidas e cruzamentos provaveis | Completo | `GruposScreen`, `GrupoTableCard` |
| Tela de grupos abre todos e esconde os demais ao clicar em um grupo | Completo | `GruposScreen` |
| Tabela de grupos com dados completos de futebol | Completo | `FootballGroupRules`, `SistemaPontuacaoTimes`, testes |
| Encapsular regras classicas de grupos de futebol de forma reutilizavel | Completo | `core/football_group_rules.dart` |
| Tela de times e detalhe de time com jogos/estatisticas | Completo | `TimesScreen`, `TimeScreen` |
| Elenco/fotos de jogadores na tela do time | Parcial por API | Area reservada em `TimeScreen`; falta persistir roster por `lookup_all_players` ou fonte equivalente |
| Mandante/visitante corretos no detalhe da partida | Completo | `JogoDetailScreen`, `Jogo` |
| Nomes/local/cidade formatados sem texto bruto | Completo | `PlaceFormatters`, `VenueSportsDb` |
| Status de jogo com informacoes condicionais e sem `-` cru em futuros | Completo | `PartidaCard`, `PalpiteJogoCard` |
| Status de jogo com rotulos Finalizado/Ao Vivo/Em breve/Agendado/Adiado | Completo | `PartidaCard`, `Jogo`, SportsDB `strPostponed` |
| Tema visual mais alinhado a FWC 2026 | Completo | `app_theme.dart`, `FwcColors` |
| Tema seguindo sistema com alternancia claro/escuro | Completo | `BolaoThemeScope`, `ThemeModeAction` |
| Remover seletor Material/Cupertino/Auto porque nao agregava | Completo | `main.dart`, tema unico Material 3 |
| Ajustes mobile para evitar textos cortados/espremidos | Completo | Cards responsivos, smoke mobile sem overflow |
| Evitar sobreposicao com fonte grande do sistema | Completo | clamp global de `TextScaler` no `MaterialApp` |
| Home como dashboard, nao landing page | Completo | `HomeScreen` |
| Atalhos da home compactos no celular | Completo | `_DashboardTile` |
| AppBar da home sem titulo duplicado | Completo | `HomeScreen` |
| Dashboard sem subtitulos redundantes nos atalhos | Completo | `_DashboardHero`, `_DashboardTile` |
| Destaque ao vivo ou proximo jogo com grid compacto dos palpites | Completo | `LivePalpiteGrid`, `HomeScreen` |
| Dois ou mais jogos ao vivo em paralelo no dashboard | Completo | `HomeScreen` empilha no celular e distribui em duas colunas no desktop |
| Detalhe da partida com palpites agrupados por resultado apostado | Completo | `PalpiteMatchGroups`, `PalpiteResultGroupCard`; grupo vazio de sem palpite foi suprimido |
| Grupos de palpites mostram resumo qualitativo, nao soma total agregada | Completo | `PalpiteResultGroupCard` |
| Exibir os palpites logo abaixo dos dados basicos da partida | Completo | `JogoDetailScreen` |
| Paineis dos times abaixo dos palpites e em tamanho menor | Completo | `TeamMatchPanel(compact: true)` no detalhe de jogo |
| Player/video menor no desktop e menos central | Completo | `JogoDetailScreen`, `YoutubeEmbedPlayer` limitado |
| Dashboard: futuros nao repetem jogos de hoje | Completo | `BolaoController.jogosPorPeriodo` |
| Dashboard: filtros Passados/Hoje/Rodada/Futuros e subfiltros de futuro | Completo | `HomeScreen`, `PeriodoJogos` |
| Tempo atual/aproximado de jogo ao vivo | Completo | `BolaoController.tempoAtualDoJogo`, `PartidaCard` |
| Gols/cartoes/estatisticas/escalacao da partida pela API | Parcial por API | `MatchApiDetails`, `SportsDbApiService.fetchEventDetails`; aparece quando a SportsDB retorna dados |
| Gols anulados/VAR quando retornados pela timeline | Parcial por API | `SportsDbTimelineItem.isCancelled`, `MatchApiDetails` |
| Foto do estadio na tela da partida quando houver asset/API | Completo | `JogoDetailScreen`, `VenueSportsDb`, `MediaCatalogService` |
| Usar badge da liga como icone/splash/PWA | Completo | `assets/media/app_icons/`, `web/icons/`, `web/favicon.png` |
| Atualizar jogo encerrado que ficou preso como ao vivo | Completo | janela maxima de status ao vivo e encerramento por relogio |
| QA visual no Chrome/mobile | Completo para smoke | Build release + Playwright 390px sem overflow; QA manual fino continua continuo |
| Navegacao mobile por botoes Grupos e Times | Completo | Smoke Chrome 390px sem erro/overflow |
| Pipeline GitHub Actions/Cloudflare revisado | Completo | `docs/BUILD_DEPLOY.md`, workflow existente |
| Profile por padrao em `flutter run`/VS Code | Completo | `Makefile`, `.vscode` quando presente no ambiente |
| Mover teste placeholder antigo para debug | Completo | `test/debug/widget_test.dart` |
| Licenca propria do projeto para publicacao open source | Decisao pendente | Repo privado sem licenca publica; escolher `LICENSE` exige decisao do dono |

## Itens sem acao automatica segura

| Item | Motivo |
| --- | --- |
| Escolher uma licenca publica propria | Isto muda direitos do codigo. Enquanto o projeto for privado, `THIRD_PARTY_NOTICES.md` registra fontes e dependencias; publicar como open source deve vir com decisao explicita do dono. |
| Garantir gols/cartoes/escalacoes em todos os jogos | O app consulta os endpoints corretos, mas a SportsDB pode retornar vazio, rate-limit ou dados incompletos. A UI mostra fallback nesses casos. |

## Validacao esperada antes de promover

```bash
flutter analyze
flutter test
flutter build web --release
```

Para UI mobile, usar smoke em viewport estreita e confirmar ausencia de overflow
horizontal.
