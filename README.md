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
| Agenda canônica auxiliar | `tools/data/world_cup_2026_fixtures.json` |
| Atualização | `tools/update_sportsdb.dart` |
| Deploy | GitHub Actions |
| Hospedagem | Cloudflare Pages |
| Fontes externas | TheSportsDB, FixtureDownload, TheStatsAPI fixture seed |
| Créditos/licenças | `THIRD_PARTY_NOTICES.md` |
| Fluxo Git | `dev` → `test` → `main` |

---

## Ambientes e branches

### `dev`

Branch de desenvolvimento.

```bash
git switch dev
git pull origin dev
flutter run -d chrome
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
Wrangler publica build/web
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
flutter run -d chrome
```

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
│   └── data/
│       ├── jogos.json
│       ├── historico_partidas.json
│       ├── times_participantes.json
│       ├── participantes.json
│       ├── palpites.json
│       ├── times_sportsdb.json
│       ├── venues_sportsdb.json
│       └── liga_sportsdb.json
│
├── docs/
│   ├── API_SAFETY.md
│   ├── MIGRACAO_DADOS.md
│   ├── README_CORE_PONTUACAO.md
│   └── README_UI_RESPONSIVA.md
│
├── tools/
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
json_utils.dart
app_routes.dart
team_normalizer.dart
functions/place_formatters.dart
```

A raiz de `core/` concentra regras de domínio e objetos centrais. Funções pequenas de ajuda ficam em `lib/core/functions/`.

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
ranking_podium.dart
ranking_evolution_chart.dart
mata_mata_bracket_view.dart
```

### `lib/screens/`

Telas do app.

Exemplos:

```text
jogos_screen.dart
ranking_screen.dart
simulador_screen.dart
debug/debug_assets_screen.dart
```

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
- [x] tela de jogos
- [x] tela de ranking com pódio, evolução e pontos projetados
- [x] tela de detalhe de participante
- [x] tela de grupos com detalhe clicável
- [x] tela de simulações
- [x] widget de jogos ao vivo em telas internas
- [x] atualização inicial automática e refresh de minuto quando houver jogo ao vivo
- [x] metadados visuais de times, venues e liga
- [x] widgets em `plugins/`
- [x] arquivo de créditos/licenças de terceiros

Ainda falta:

- [ ] tema visual definitivo
- [ ] melhorar responsividade fina das telas novas
- [ ] ampliar testes das regras de pontuação, ranking projetado e simulações
- [ ] revisar o Chrome plugin quando a extensão ficar visível para o Codex
- [ ] escolher licença própria do projeto antes de qualquer publicação open source
