# Bolão FWC 2026

Aplicação **Flutter Web** para acompanhar um bolão da Copa do Mundo FIFA 2026.

O projeto é pessoal/privado, pensado para um grupo pequeno de participantes. A prioridade é ter uma interface visual simples para consultar jogos, palpites, classificação, grupos e estatísticas, sem transformar o projeto em uma arquitetura enterprise.

---

## Stack

| Camada | Escolha |
| --- | --- |
| UI / frontend | Flutter Web |
| Linguagem | Dart |
| Dados do app | JSON estático em `assets/data/` |
| Mídia local | Cache gerado em `assets/media/` |
| Agenda canônica auxiliar | `tools/data/world_cup_2026_fixtures.json` |
| Atualização | `tools/update_sportsdb.dart` |
| Cache de imagens | `tools/cache_media_assets.dart` |
| Deploy | GitHub Actions |
| Hospedagem | Cloudflare Pages |
| Fontes externas | TheSportsDB, FlagCDN/Flagpedia, FixtureDownload, TheStatsAPI fixture seed |
| Créditos/licenças | `THIRD_PARTY_NOTICES.md` |
| Fluxo Git | `dev` → `test` → `main` |

---

## Ambientes e branches

### `dev`

Branch de desenvolvimento.

```bash
git switch dev
git pull origin dev
make run
```

Depois de alterar código:

```bash
git status
git add .
git commit -m "mensagem clara"
git push origin dev
```

### `test`

Branch de teste/staging.

```bash
git switch test
git pull origin test
git merge dev
git push origin test
```

### `main`

Branch de produção.

```bash
git switch main
git pull origin main
git merge test
git push origin main
```

Produção:

<https://bolao2026fwc.pages.dev>

---

## Deploy

O Cloudflare Pages está desconectado do GitHub como pipeline de build direto.

O deploy real acontece assim:

```text
push em test ou main
        ↓
GitHub Actions
        ↓
instala Flutter
        ↓
roda tools/update_sportsdb.dart
        ↓
flutter build web --release
        ↓
Wrangler Action publica build/web
        ↓
Cloudflare Pages
```

Workflow:

```text
.github/workflows/deploy_cloudflare.yml
```

Branches que disparam deploy:

```text
test
main
```

Branches que não disparam deploy:

```text
dev
feature/*
```

---

## Rodar localmente

```bash
flutter pub get
make run
```

`make run` abre o app em profile no Chrome:

```bash
flutter run -d chrome --profile
```

O VS Code também possui `.vscode/launch.json` e `.vscode/settings.json` configurados para profile, facilitando inspeção pelo DevTools. Mais detalhes ficam em `docs/BUILD_DEPLOY.md`.

Build local:

```bash
flutter build web --release
```

Análise e testes:

```bash
flutter analyze
flutter test
```

Atualizar dados localmente:

```bash
dart run tools/update_sportsdb.dart
```

Atualizar o cache local de imagens:

```bash
dart run tools/cache_media_assets.dart
```

O app prefere imagens locais registradas em `assets/media/media_manifest.json`
e cai automaticamente para a URL remota quando uma imagem ainda nao foi
baixada.

UI atual:

- dashboard responsivo com placares ao vivo/proximos jogos, ranking parcial e mini grafico;
- tela de ranking com cards compactos, podio, evolucao por pontos/posicao e marcadores fixos por participante;
- chaveamento de mata-mata em duas metades no desktop, com linhas, final destacada ao centro e leitura vertical no celular;
- badges, bandeiras, imagem principal unificada de partidas, imagem de estadio e icones vindos primeiro do cache local e depois das URLs externas;
- splash inicial espera uma consulta da API antes de exibir o dashboard, preservando a base local se a API falhar.

---

## Documentação e atribuições

O `README.md` é a documentação global viva do projeto: deve explicar o estado atual, como rodar, como os dados entram e quais partes principais existem.

Documentos específicos ficam em `docs/`. Sempre que uma alteração mudar uma regra de negócio, API, migração de dados, responsividade, deploy ou fluxo de manutenção, verifique se algum arquivo em `docs/` precisa ser criado ou atualizado.

Créditos, licenças de dependências, fontes de dados, APIs, serviços externos e avisos de uso de mídia ficam em:

```text
THIRD_PARTY_NOTICES.md
```

Sempre que entrar uma dependência, asset, imagem, API, feed ou serviço externo novo, atualize esse arquivo junto com o `README.md`.

---

## Estrutura principal

```text
fwc2026_bolao/
├── assets/
│   ├── data/
│   │   ├── jogos.json
│   │   ├── historico_partidas.json
│   │   ├── times_participantes.json
│   │   ├── participantes.json
│   │   ├── palpites.json
│   │   ├── times_sportsdb.json
│   │   ├── venues_sportsdb.json
│   │   └── liga_sportsdb.json
│   └── media/
│       ├── media_manifest.json
│       ├── app_icons/
│       ├── team_badges/
│       ├── team_flags/
│       ├── team_images/
│       ├── venue_images/
│       ├── match_images/
│       └── league_images/
│
├── docs/
│   ├── APIS_DADOS_MIDIA.md
│   ├── API_SAFETY.md
│   ├── BUILD_DEPLOY.md
│   ├── CHECKUP_PEDIDOS.md
│   ├── MIGRACAO_DADOS.md
│   ├── README_CORE_PONTUACAO.md
│   └── README_UI_RESPONSIVA.md
│
├── tools/
│   ├── cache_media_assets.dart
│   ├── update_sportsdb.dart
│   └── data/
│       └── world_cup_2026_fixtures.json
│
├── lib/
│   ├── main.dart
│   ├── core/
│   ├── models/
│   ├── plugins/
│   ├── screens/
│   └── services/
│
├── test/
├── web/
├── Makefile
├── pubspec.yaml
├── THIRD_PARTY_NOTICES.md
└── README.md
```

---

## Dados do app

Os dados carregados pelo Flutter ficam em:

```text
assets/data/
```

Esses arquivos são registrados individualmente no `pubspec.yaml`.

### `jogos.json`

Fonte canônica do app.

Contém exatamente 104 jogos, com `jogoId` estável, `matchNumber`, fase, grupo, horário, estádio, referências de participantes do jogo, placar consolidado e status.

A pontuação do bolão deve usar principalmente este arquivo junto com `palpites.json` e `participantes.json`.

### `historico_partidas.json`

Cache secundário da SportsDB.

Serve para auditoria, metadados e informação bruta da API. Não deve ser necessário para calcular a pontuação principal do bolão.

### `participantes.json`

Lista de participantes do bolão.

Cada participante pode definir `corHex`, usada como cor fixa em gráficos,
legendas e visualizações comparativas.

### `palpites.json`

Lista normalizada de palpites, conectando:

```text
participanteId + jogoId → placar apostado
```

### `times_participantes.json`

Lista de seleções, grupos, jogos do grupo e estatísticas provisórias.

### `times_sportsdb.json`

Base complementar de times vinda da TheSportsDB, incluindo IDs externos, badges e metadados visuais quando disponíveis.

### `venues_sportsdb.json`

Base complementar de estádios/venues vinda da TheSportsDB, usada para enriquecer telas de partida com cidade, país e imagens quando disponíveis.

### `liga_sportsdb.json`

Metadados da competição vindos da TheSportsDB, incluindo badge, banner e informações visuais da liga quando disponíveis.

### `assets/media/`

Cache local de imagens referenciadas pelos JSONs da TheSportsDB.

O manifesto `assets/media/media_manifest.json` mapeia cada URL remota para o
asset baixado. O `BolaoController` resolve badge, imagem de partida e imagem de
time preferindo esse asset local; se a URL nao estiver no manifesto, os widgets
continuam tentando carregar a imagem remota.

Para atualizar:

```bash
dart run tools/cache_media_assets.dart
```

---

## Agenda canônica em `tools/data/`

O arquivo:

```text
tools/data/world_cup_2026_fixtures.json
```

fica em `tools/data/` de propósito.

Ele **não** é asset do app, não deve ser listado no `pubspec.yaml` e não precisa ser baixado pelo navegador. Ele é usado apenas pelo script local/CI `tools/update_sportsdb.dart` para reconstruir e validar o catálogo canônico de 104 jogos.

A fonte declarada dentro do arquivo é TheStatsAPI, com licença de uso livre mediante atribuição à TheStatsAPI. O crédito fica registrado também em `THIRD_PARTY_NOTICES.md`.

---

## Organização de `lib/`

### `lib/core/`

Funções e utilitários centrais que não são UI.

Exemplos:

```text
football_group_rules.dart
sistema_palpites.dart
sistema_pontuacao_times.dart
sistema_pontuacao_participantes.dart
json_utils.dart
app_routes.dart
app_theme.dart
team_normalizer.dart
functions/place_formatters.dart
functions/participant_colors.dart
functions/youtube_utils.dart
```

A raiz de `core/` concentra regras de domínio e objetos centrais. Funções pequenas de ajuda ficam em `lib/core/functions/`.

### Reutilizável vs específico

O app separa, sempre que possível, regras gerais de futebol das decisões específicas deste bolão:

```text
core/football_group_rules.dart
```

Motor reutilizável para tabelas de grupos de futebol: vitória, empate, derrota, gols pró, gols contra, saldo, critérios configuráveis de desempate, classificados diretos e melhores terceiros. Pode ser reaproveitado em outro campeonato de futebol ajustando a configuração de pontos/desempates.

```text
core/sistema_pontuacao_times.dart
```

Adaptador do app para a Copa 2026: transforma `Jogo` e `Palpite` em partidas computadas, usa as regras de grupos e projeta o mata-mata a partir das referências presentes em `jogos.json`.

```text
core/sistema_palpites.dart
core/sistema_pontuacao_participantes.dart
```

Regras do bolão: pontuação dos palpites, bônus por grupos/final e ranking dos participantes. Para outro bolão, estes arquivos podem continuar iguais se a pontuação for a mesma; se a regra do grupo mudar, a alteração deve ficar preferencialmente na configuração/uso de `FootballGroupRules`.

```text
assets/data/
tools/update_sportsdb.dart
tools/data/world_cup_2026_fixtures.json
```

Parte mais específica da Copa 2026 e das fontes externas atuais. Para reaplicar o app em outra competição, esta é a camada que provavelmente mais muda.

### `lib/models/`

Modelos tipados dos dados.

Exemplos:

```text
jogo.dart
palpite.dart
participante.dart
time_participante.dart
historico_partida.dart
referencia_participante_jogo.dart
bolao_data.dart
time_sportsdb.dart
venue_sportsdb.dart
liga_sportsdb.dart
```

### `lib/services/`

Camada de carregamento e integração externa.

Exemplos:

```text
asset_loader.dart
sportsdb_api_service.dart
bolao_controller.dart
```

### `lib/plugins/`

Widgets reutilizáveis usados pelas telas.

Exemplo:

```text
partida_card.dart
live_matches_banner.dart
refresh_countdown_indicator.dart
live_palpite_grid.dart
remote_media.dart
theme_mode_action.dart
ranking_podium.dart
ranking_evolution_chart.dart
mata_mata_bracket_view.dart
team_overview_card.dart
youtube_embed_player.dart
match_api_details.dart
```

### `lib/screens/`

Telas do app.

Exemplos:

```text
jogos_screen.dart
ranking_screen.dart
simulador_screen.dart
times_screen.dart
time_screen.dart
debug/debug_assets_screen.dart
```

O status consolidado dos pedidos feitos durante a evolucao do app fica em
`docs/CHECKUP_PEDIDOS.md`.

---

## Atualização dos dados

Fluxo da tool:

```text
fixture canônica em tools/data
        ↓
TheSportsDB
        ↓
FixtureDownload fallback
        ↓
reconstrói jogos.json
        ↓
reconstrói historico_partidas.json
        ↓
reconstrói times_sportsdb.json, venues_sportsdb.json e liga_sportsdb.json
        ↓
recalcula times_participantes.json
        ↓
valida IDs, palpites, histórico e times
```

Rodar:

```bash
dart run tools/update_sportsdb.dart
```

A tool:

1. cria backup em `assets/data/backups/<timestamp>/`;
2. consulta endpoints externos com timeout;
3. preserva dados antigos se a API falhar;
4. mantém exatamente 104 jogos;
5. valida se todos os palpites apontam para `jogoId` existentes;
6. gera logs em `logs/update_sportsdb/`.
7. tenta enriquecer times, venues e liga com metadados visuais da TheSportsDB.

No app em execução, o controller também faz uma atualização inicial ao carregar e mantém um timer de 5 segundos. A consulta automática desse timer aplica os dados dinâmicos que realmente mudaram, como placar, status, mídia e eventos associados, sem colocar a UI inteira em estado de carregamento. Fora disso, o relógio local apenas evita que jogos recém-iniciados ou já estourados fiquem com status incoerente. O refresh é monotônico para placar/status: depois que um placar maior ou encerrado é conhecido, respostas atrasadas da API não podem devolver o jogo para placar menor ou estado ao vivo mais antigo.

Na tela de detalhe da partida, o app consulta sob demanda os endpoints `lookuptimeline.php`, `lookuplineup.php`, `eventresults.php` e `lookupeventstats.php` por `idEvent`. Esses dados são cacheados por partida e invalidados quando o jogo está ao vivo, para permitir que gols/cartões/estatísticas acompanhem o refresh sem pesar a tela inicial.

Jogos ao vivo sem placar começam provisoriamente em 0x0 para ranking projetado. Se a janela máxima de jogo ao vivo expira e a API ainda não confirmou `FT`/final, o app deixa de exibir a partida como ao vivo; quando há placar da SportsDB nessa situação, ele pode ser tratado como encerrado por relógio para evitar que a tela fique presa no estado `2H`/`LIVE`.

Esses diretórios não devem entrar no Git:

```gitignore
assets/data/backups/
logs/
```

---

## Versionamento

O projeto usa tags Git no padrão:

```text
v0.1.0
v0.2.0
v0.3.0
```

Criar tag:

```bash
git tag -a v0.2.0 -m "v0.2.0 - dados canônicos, SportsDB e tela de jogos"
git push origin v0.2.0
```

---

## Estado atual

Finalizado ou praticamente fechado:

- [x] Flutter Web e deploy
- [x] branches `dev`, `test`, `main`
- [x] deploy via GitHub Actions + Cloudflare Pages
- [x] participantes e palpites
- [x] catálogo canônico dos 104 jogos
- [x] IDs estáveis dos jogos
- [x] vínculo entre jogos e histórico SportsDB
- [x] fallback de resultados
- [x] atualização automática antes do build
- [x] models principais
- [x] asset loader
- [x] serviço SportsDB resiliente
- [x] refresh em memória com `lookupevent` para eventos próximos/relevantes
- [x] detalhe de partida com timeline, estatísticas e escalação quando a SportsDB disponibilizar
- [x] tela de jogos
- [x] tela de ranking com pódio, evolução e pontos projetados
- [x] ranking da home simplificado, ordenado por consolidado + ao vivo quando houver jogo em andamento
- [x] ranking da home com mini gráfico de evolução por posição
- [x] ranking com evolução por partida ou por dia brasileiro
- [x] ranking com gráfico por pontos ou posição e recorte por faixa de partidas/dias
- [x] gráfico do ranking reescala o eixo X conforme o recorte filtrado
- [x] gráfico do ranking com guias por etapa e por faixa de posições/pontos
- [x] ranking com cores fixas por participante e destaque ouro/prata/bronze no gráfico
- [x] ranking com tabela detalhada de pontos, acento visual por participante e contagem de +5/+3/+2/+1/0
- [x] ranking e palpites ocultam participantes sem nenhum palpite completo
- [x] ranking da home com setas de subida/queda/empate comparando posição consolidada e posição ao vivo
- [x] tela de detalhe de participante
- [x] tela de participante com palpites em grid responsivo e placar principal unico por jogo
- [x] tela de grupos com detalhe clicável
- [x] tela de simulações preservada no código
- [ ] simulador exposto na navegação principal
- [x] simulador retirado temporariamente da navegação enquanto a experiência não estiver no padrão visual do restante do app
- [x] tela de lista de times
- [x] lista de times em ordem alfabetica
- [x] tela de detalhe de time com jogos e estatísticas
- [x] dashboard inicial com cards de navegação
- [x] dashboard mobile com atalhos compactos por ícone
- [x] dashboard sem subtítulos redundantes nos atalhos
- [x] destaque ao vivo ou próximo jogo com grid compacto dos palpites; jogos ao vivo mostram pontos parciais
- [x] tema Material 3 seguindo sistema por padrão, com alternância claro/escuro no AppBar
- [x] paleta visual inspirada na identidade FWC 2026
- [x] widget de jogos ao vivo em telas internas
- [x] indicador visual de próxima atualização automática
- [x] atualização inicial automática e refresh incremental de 5 segundos quando houver jogo ao vivo
- [x] refresh anti-regressão no app e no tool de deploy para evitar oscilação de placar/status
- [x] navegação mobile para Grupos e Times validada sem overflow horizontal
- [x] metadados visuais de times, venues e liga
- [x] widgets de imagem remota para badges, banners, venues e liga
- [x] imagens remotas com cache do Flutter/browser, `gaplessPlayback` e fallback HTML no Web para CORS
- [x] badges no chaveamento quando a tela possui catálogo de mídia
- [x] player/embed de YouTube para highlights quando houver `strVideo`
- [x] palpites da partida agrupados por vitória do mandante, empate e vitória do visitante
- [x] widgets em `plugins/`
- [x] arquivo de créditos/licenças de terceiros

Pontos de acompanhamento continuo:

- QA visual fino continua sendo feito a cada rodada de UI, com smoke mobile antes de promover.
- Dados de gols, cartões e escalações dependem da disponibilidade da SportsDB por `idEvent`.
- A licença própria do projeto deve ser escolhida antes de qualquer publicação open source.
