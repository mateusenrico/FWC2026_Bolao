# Bolão FWC 2026

Aplicação **Flutter Web** para acompanhar um bolão da Copa do Mundo FIFA 2026.

O projeto é pessoal/privado, pensado para um grupo pequeno de participantes. A prioridade é ter uma interface visual simples para consultar jogos, palpites, classificação e estatísticas, sem transformar o projeto em uma arquitetura enterprise.

---

## Stack

| Camada | Escolha |
|---|---|
| UI / frontend | Flutter Web |
| Linguagem | Dart |
| Dados | JSON estático em `assets/data/` |
| Deploy | GitHub Actions |
| Hospedagem | Cloudflare Pages |
| Fonte externa | TheSportsDB |
| Fluxo Git | `dev` → `test` → `main` |

---

## Ambientes e branches

### `dev`

Branch de desenvolvimento.

Use para codar, organizar commits e testar localmente.

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

---

### `test`

Branch de teste/staging.

Recebe o que foi consolidado em `dev` e dispara deploy de teste via GitHub Actions.

```bash
git switch test
git pull origin test
git merge dev
git push origin test
```

Use essa branch para validar o app publicado antes de mandar para produção.

---

### `main`

Branch de produção.

Recebe o que foi validado em `test` e dispara deploy de produção via GitHub Actions.

```bash
git switch main
git pull origin main
git merge test
git push origin main
```

URL de produção:

```text
https://bolao2026fwc.pages.dev
```

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

Instalar dependências:

```bash
flutter pub get
```

Rodar no Chrome:

```bash
flutter run -d chrome
```

Build local de release:

```bash
flutter build web --release
```

Análise estática:

```bash
flutter analyze
```

Testes:

```bash
flutter test
```

---

## Estrutura principal

```text
bolao_app/
├── assets/
│   └── data/
│       ├── jogos.json
│       ├── historico_partidas.json
│       ├── times_participantes.json
│       ├── participantes.json
│       └── palpites.json
│
├── lib/
│   ├── main.dart
│   ├── models/
│   ├── services/
│   ├── domain/
│   └── screens/
│
├── test/
├── web/
├── pubspec.yaml
└── README.md
```

---

## Dados

Os dados ficam em:

```text
assets/data/
```

Esses arquivos são registrados no `pubspec.yaml` e carregados pelo Flutter como assets.

### `jogos.json`

Catálogo canônico dos jogos previstos pelo bolão.

Este arquivo define o `jogoId`, que é a chave interna do projeto.

Exemplos de campos:

```text
jogoId
data
fase
faseTipo
grupo
mandante
visitante
statusJogo
temHistoricoApi
temResultadoApi
```

O `jogoId` é a referência usada por palpites, histórico e times.

---

### `historico_partidas.json`

Camada de histórico/API.

Contém partidas vindas da TheSportsDB, normalizadas e vinculadas aos jogos do bolão por `jogoId`.

Regra conceitual:

```text
jogoId = chave interna do bolão
idEvent = chave externa da TheSportsDB
```

---

### `participantes.json`

Lista de participantes do bolão.

Cada participante possui:

```text
participanteId
nome
jogosPalpitados
jogosSemPalpite
totalJogosPrevistos
jogosPalpitadosFaseGrupos
jogosSemPalpiteFaseGrupos
totalJogosFaseGrupos
```

O `participanteId` é alfanumérico e não depende diretamente do nome exibido.

---

### `palpites.json`

Lista normalizada de palpites.

Cada registro representa a relação:

```text
participante + jogo → palpite
```

Campos:

```text
palpiteId
participanteId
jogoId
golsMandante
golsVisitante
```

Quando não há palpite registrado, os gols ficam como `null`.

Exemplo:

```json
{
  "palpiteId": "pl94ef65a940a2",
  "participanteId": "p40a471872e",
  "jogoId": "gb0850041021b",
  "golsMandante": 3,
  "golsVisitante": 0
}
```

---

### `times_participantes.json`

Lista de seleções participantes, grupos e estatísticas.

Cada time possui:

```text
timeId
nome
nomeNormalizado
grupo
jogosIds
rankingGrupo
estatisticasGrupo
```

As estatísticas de grupo podem ser recalculadas a partir dos jogos com resultados disponíveis.

---

## Modelagem

O projeto segue uma abordagem simples, funcional e data-oriented.

Fonte de verdade:

```text
jogos.json
historico_partidas.json
participantes.json
palpites.json
times_participantes.json
```

Dados derivados:

```text
classificação do bolão
pontuação por participante
evolução do ranking
tabela de jogos
estatísticas de grupos
```

A pontuação dos participantes não deve ser tratada como dado primário. Ela deve ser calculada a partir de:

```text
jogos encerrados
+
palpites
+
regra de pontuação
```

---

## Organização de `lib/`

### `lib/models/`

Modelos de dados tipados.

Devem representar os formatos principais usados pelo app.

Exemplos:

```text
jogo.dart
participante.dart
palpite.dart
time_participante.dart
historico_partida.dart
linha_classificacao.dart
```

Esses arquivos não devem concentrar regra pesada de negócio. Eles servem principalmente para tipar dados e facilitar leitura do JSON.

---

### `lib/services/`

Serviços de infraestrutura.

Devem conter código que carrega, busca ou prepara dados vindos de fora da lógica pura do domínio.

Exemplos:

```text
data_loader.dart
json_asset_service.dart
sportsdb_update_service.dart
```

No estágio atual, o serviço mais importante é o carregamento dos JSONs em `assets/data/`.

---

### `lib/domain/`

Regras de domínio e funções puras.

Aqui entram cálculos e transformações que não dependem diretamente da UI.

Exemplos:

```text
calcular_classificacao.dart
calcular_pontuacao.dart
calcular_grupos.dart
calcular_evolucao_ranking.dart
normalizar_times.dart
```

A ideia é que essa camada receba listas de modelos e devolva projeções prontas para a interface.

Exemplo conceitual:

```text
jogos + participantes + palpites
        ↓
calcularClassificacao(...)
        ↓
List<LinhaClassificacao>
```

---

### `lib/screens/`

Telas do app.

Devem conter a composição visual principal.

Exemplos:

```text
home_screen.dart
jogos_screen.dart
classificacao_screen.dart
grupos_screen.dart
ranking_screen.dart
debug_assets_screen.dart
```

A tela deve ser relativamente “burra”: ela recebe dados já tratados e renderiza widgets.

---

## Pasta `test/`

Pasta de testes automatizados do Flutter.

No começo, ela pode ficar praticamente sem uso. Mais tarde, pode receber testes de funções puras da camada `domain`.

Exemplos úteis de testes futuros:

```text
calcular pontuação de placar exato
calcular pontuação de vencedor correto
ordenar classificação por pontos
calcular saldo e pontos de grupos
```

---

## Pasta `web/`

Pasta com arquivos específicos do Flutter Web.

Aqui ficam arquivos usados pelo navegador, como:

```text
index.html
manifest.json
icons/
favicon.png
```

Coisas que podem ser ajustadas nessa pasta:

- título que aparece no navegador;
- favicon;
- ícones usados quando o app é salvo na tela inicial;
- cor/tema do manifesto web;
- metadados básicos do app.

Para alterar o nome exibido no navegador, verifique:

```text
web/index.html
web/manifest.json
```

---

## Atualização dos dados

A atualização futura deve ser feita por script separado, não pela interface Flutter.

Fluxo previsto:

```text
TheSportsDB API
        ↓
script local de atualização
        ↓
atualiza historico_partidas.json
        ↓
atualiza status em jogos.json
        ↓
recalcula times_participantes.json, se necessário
        ↓
commit
        ↓
push
        ↓
deploy
```

Endpoints relevantes da TheSportsDB:

```text
eventsseason.php
eventsnextleague.php
eventspastleague.php
eventsday.php
```

Base pública:

```text
https://www.thesportsdb.com/api/v1/json/123
```

---

## Versionamento

O projeto usa versionamento simples inspirado em SemVer:

```text
MAJOR.MINOR.PATCH
```

Exemplos:

```text
v0.1.0
v0.2.0
v1.0.0
```

Sugestão de uso:

- `PATCH`: correção pequena ou ajuste visual simples.
- `MINOR`: nova tela, novo gráfico, nova regra, nova carga de dados.
- `MAJOR`: mudança estrutural relevante ou primeira versão considerada estável.

Durante desenvolvimento inicial, usar versões `0.x.y`.

Sugestão de sequência:

```text
v0.1.0 = setup, deploy e dados estáticos
v0.2.0 = app lê JSONs e mostra diagnóstico
v0.3.0 = classificação do bolão
v0.4.0 = tabela de jogos
v0.5.0 = grupos e seleções
v0.6.0 = gráfico de evolução
v1.0.0 = versão usável pelo grupo
```

Criar tag local:

```bash
git tag -a v0.1.0 -m "v0.1.0 - setup inicial com Flutter Web, JSONs e deploy"
```

Enviar tag para o GitHub:

```bash
git push origin v0.1.0
```

Listar tags:

```bash
git tag
```

Ver uma tag:

```bash
git show v0.1.0
```

Apagar tag local:

```bash
git tag -d v0.1.0
```

Apagar tag remota:

```bash
git push origin --delete v0.1.0
```

---

## Próximos passos

1. Criar modelos Dart para os JSONs.
2. Criar loader de assets.
3. Validar contagem de registros carregados.
4. Implementar tela inicial.
5. Implementar tabela de classificação.
6. Implementar tabela de jogos.
7. Implementar tela de grupos.
8. Implementar gráfico de evolução do ranking.
