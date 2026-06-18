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

## Estrutura principal

```text
fwc2026_bolao/
├── assets/
│   └── data/
│       ├── jogos.json
│       ├── historico_partidas.json
│       ├── times_participantes.json
│       ├── participantes.json
│       └── palpites.json
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

---

## Agenda canônica em `tools/data/`

O arquivo:

```text
tools/data/world_cup_2026_fixtures.json
```

fica em `tools/data/` de propósito.

Ele **não** é asset do app, não deve ser listado no `pubspec.yaml` e não precisa ser baixado pelo navegador. Ele é usado apenas pelo script local/CI `tools/update_sportsdb.dart` para reconstruir e validar o catálogo canônico de 104 jogos.

A fonte declarada dentro do arquivo é TheStatsAPI, com licença de uso livre mediante atribuição à TheStatsAPI.

---

## Organização de `lib/`

### `lib/core/`

Funções e utilitários centrais que não são UI.

Exemplos:

```text
json_utils.dart
team_normalizer.dart
```

Depois, esta pasta também pode receber regras do bolão, como pontuação e critérios de desempate.

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
```

### `lib/services/`

Camada de carregamento e integração externa.

Exemplos:

```text
asset_loader.dart
sportsdb_api_service.dart
```

### `lib/plugins/`

Widgets reutilizáveis usados pelas telas.

Exemplo:

```text
jogos_table.dart
```

### `lib/screens/`

Telas do app.

Exemplos:

```text
jogos_screen.dart
debug_assets_screen.dart
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
- [x] tela provisória de jogos
- [x] widgets em `plugins/`

Ainda falta:

- [ ] definir regra de pontuação do bolão
- [ ] calcular pontos por palpite
- [ ] calcular classificação geral
- [ ] critérios de desempate do bolão
- [ ] tela de classificação
- [ ] tela de detalhe de participante
- [ ] tela de grupos
- [ ] gráfico de evolução do ranking
- [ ] tema visual definitivo
- [ ] layout responsivo mais bonito
- [ ] testes das regras de pontuação
