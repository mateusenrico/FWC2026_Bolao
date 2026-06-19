# UI responsiva do Bolão FWC 2026

Este pacote adiciona o dashboard visual e integra o core de pontuação existente.

## O que ele implementa

- tela inicial responsiva;
- destaque para partida ao vivo ou próximo horário, com grid compacto de palpites; jogos ao vivo exibem pontos parciais;
- banner ao vivo fixo no topo da home enquanto houver partida em andamento;
- ranking parcial colapsável na home, sem toggle, ordenado por consolidado + ao vivo quando houver jogo em andamento;
- mini gráfico de evolução por posição abaixo do ranking parcial da home;
- filtros de partidas: hoje, amanhã, rodada, passados, futuros e todos;
- cards de partidas com siglas oficiais, badges/bandeiras, banner do jogo, placar e status;
- detalhe da partida;
- detalhe da partida com palpites agrupados por resultado apostado, imagem do estádio e dados de timeline/escalação/estatísticas quando a SportsDB disponibilizar;
- tela de partida com ordem: dados básicos, palpites, resumo compacto dos times, dados externos e vídeo;
- detalhe do participante com placar principal alternando entre palpite futuro e resultado/parcial real;
- ranking detalhado com pódio, cards compactos de pontos e evolução por pontos ou posição;
- filtro de evolução por participantes e por faixa de partidas ou dias;
- gráfico de evolução com eixo X reescalado conforme a faixa filtrada;
- gráfico de evolução com guias visuais por etapa e por posição/pontuação;
- cores fixas por participante, vindas de `participantes.json`, usadas no gráfico, legenda, ranking e chips de palpites;
- setas de subida, queda ou empate no ranking da home comparando posição consolidada e posição com placar ao vivo;
- participantes sem nenhum palpite completo ficam ocultos dos rankings e chips de palpites;
- destaque visual de ouro, prata e bronze para os três primeiros no gráfico;
- marcadores fixos por participante no fim de cada linha do gráfico e na legenda, sem usar `X` como símbolo;
- classificação dos grupos;
- projeção colapsável do mata-mata por participante;
- chaveamento com badges quando a tela possui catálogo de mídia;
- chaveamento de mata-mata em duas metades no desktop, com final/3º lugar no centro, e leitura vertical no celular;
- tema Material 3 seguindo o sistema por padrão, com botão claro/escuro no AppBar;
- imagens remotas com cache do Flutter/browser, `gaplessPlayback` e fallback HTML no Web para reduzir flicker e contornar CORS;
- bandeiras cacheadas em `assets/media/team_flags/` e badge da liga usado no splash/ícones web;
- clamp global de texto para reduzir sobreposição quando o navegador/celular usa fonte muito grande;
- simulador preservado no código, mas temporariamente removido da navegação principal;
- atualização incremental da SportsDB em memória a cada 5 segundos durante jogos ao vivo, preservando os assets locais se a API falhar;
- refresh anti-regressão para evitar que placares/status voltem para snapshots mais antigos da API;
- tabelas de grupos responsivas no celular, sem largura mínima que cause overflow horizontal;
- mesma regra 5/3/2/1/0 para jogos de grupos e mata-mata;
- testes básicos da regra de pontuação, incluindo placar exato no mata-mata.

## Como aplicar

Extraia o ZIP na raiz do projeto e permita sobrescrever os arquivos com o mesmo nome.

O pacote não substitui seus JSONs em `assets/data/` e não altera a tool de atualização.

Depois rode:

```bash
flutter pub get
flutter analyze
flutter test
flutter build web --release
make run
```

## Arquitetura adicionada

```text
lib/
├── core/
│   ├── app_routes.dart
│   ├── date_time_utils.dart
│   ├── sistema_palpites.dart
│   ├── sistema_pontuacao_participantes.dart
│   ├── sistema_pontuacao_times.dart
│   └── team_normalizer.dart
├── models/
│   ├── bolao_data.dart
│   └── jogo.dart
├── plugins/
│   ├── api_refresh_action.dart
│   ├── chaveamento_participante_card.dart
│   ├── grupo_table_card.dart
│   ├── live_palpite_grid.dart
│   ├── match_api_details.dart
│   ├── palpite_result_group_card.dart
│   ├── palpite_jogo_card.dart
│   ├── palpite_participante_card.dart
│   ├── participant_identity.dart
│   ├── partida_card.dart
│   ├── ranking_evolution_chart.dart
│   ├── ranking_participante_card.dart
│   ├── section_header.dart
│   ├── team_badge.dart
│   ├── theme_mode_action.dart
│   └── team_match_panel.dart
├── screens/
│   ├── grupos_screen.dart
│   ├── home_screen.dart
│   ├── jogo_detail_screen.dart
│   └── participante_detail_screen.dart
├── services/
│   ├── bolao_controller.dart
│   └── sportsdb_api_service.dart
└── main.dart
```

## Observações de regras

O sistema de palpites não filtra por fase. Portanto, qualquer jogo com resultado disponível, inclusive mata-mata, usa a mesma regra:

- 5 pontos: placar exato;
- 3 pontos: resultado correto e um dos gols correto;
- 2 pontos: somente o resultado correto;
- 1 ponto: somente um dos gols correto;
- 0 pontos: nenhum acerto.

A ordenação dos grupos segue os dados disponíveis para pontos, confronto direto, saldo geral, gols marcados e fair play. Caso todos esses dados continuem empatados, o nome é usado apenas como fallback determinístico, porque o histórico do ranking FIFA ainda não existe na base.

## Navegação

```text
Home
├── toque em uma partida → detalhe da partida
├── toque em um participante → detalhe do participante
└── botão de tabela → classificação dos grupos
```

Os AppBars mantêm o controle de tema e exibem apenas um indicador discreto enquanto a atualização automática está em andamento. A seta padrão do Navigator permite voltar para a tela anterior.
