# Migração da camada de dados — FWC 2026

## Decisão de arquitetura

O projeto continua com dois arquivos diferentes porque eles têm funções diferentes:

- `jogos.json`: fonte canônica do app. Tem exatamente 104 partidas, IDs estáveis, agenda, grupo/fase, referências do mata-mata, placar consolidado e status.
- `historico_partidas.json`: cache secundário dos registros brutos da TheSportsDB. Ele não é necessário para calcular a pontuação do bolão.

A pontuação deve usar:

```text
jogos.json + palpites.json + participantes.json
```

O histórico serve para metadados, auditoria e informações extras da API.

## Arquivos a copiar

Copie os arquivos deste pacote mantendo os caminhos:

```text
assets/data/jogos.json
assets/data/historico_partidas.json
assets/data/times_participantes.json

tools/data/world_cup_2026_fixtures.json
tools/update_sportsdb.dart

lib/core/team_normalizer.dart

lib/models/referencia_participante_jogo.dart
lib/models/jogo.dart
lib/models/historico_partida.dart
lib/models/bolao_data.dart

lib/services/asset_loader.dart
lib/services/sportsdb_api_service.dart

lib/plugins/jogos_table.dart
lib/screens/jogos_screen.dart

.github/workflows/deploy_cloudflare.yml
```

Não substitua:

```text
assets/data/palpites.json
assets/data/participantes.json
```

Os `jogoId` existentes foram preservados justamente para esses arquivos continuarem válidos.

## O que foi corrigido

- O catálogo final possui exatamente 104 jogos.
- Os seis jogos `gapi...` duplicados foram removidos.
- Seis registros do histórico foram religados aos `jogoId` canônicos.
- Vinte e quatro horários incorretos foram substituídos pelos horários UTC da fonte completa.
- Os jogos de grupo possuem `grupo` e `rodada`.
- Os jogos de mata-mata possuem referências estruturadas:
  - posição em grupo;
  - melhor terceiro colocado;
  - vencedor de outra partida;
  - perdedor de outra partida.
- Iraque x Noruega possui resultado consolidado de 1 x 4 via FixtureDownload, mesmo sem evento correspondente na TheSportsDB.
- `jogos.json` agora contém o placar consolidado. O core do bolão não precisa procurar placar no histórico.

## Fontes usadas

Agenda canônica:

```text
tools/data/world_cup_2026_fixtures.json
```

Resultados e fallback:

```text
TheSportsDB
https://fixturedownload.com/feed/json/fifa-world-cup-2026
```

## Rodar a atualização

Na raiz do projeto:

```bash
flutter pub get
dart run tools/update_sportsdb.dart
```

O updater:

1. cria backup em `assets/data/backups/<timestamp>/`;
2. lê a agenda canônica de 104 partidas;
3. preserva os `jogoId`;
4. consulta TheSportsDB;
5. consulta FixtureDownload;
6. atualiza ou preserva resultados;
7. corrige os vínculos de histórico;
8. recalcula os grupos;
9. valida palpites, jogos, histórico e times;
10. sobrescreve os três JSONs principais.

## Verificações

```bash
flutter analyze
flutter test
flutter run -d chrome
```

Na tela de jogos deve aparecer:

```text
Jogos (104)
```

## Fluxo Git

```bash
git switch dev
git status
git add .
git commit -m "consolida fixtures, ids e resultados da Copa 2026"
git push origin dev

git switch test
git pull origin test
git merge dev
git push origin test
```

## Próximas tarefas

### Finalizadas

- [x] Flutter Web e deploy
- [x] branches `dev`, `test` e `main`
- [x] participantes e palpites
- [x] 104 partidas canônicas
- [x] IDs estáveis
- [x] grupos e seleções
- [x] histórico da TheSportsDB
- [x] fallback de resultados
- [x] atualização automática no build
- [x] modelos e carregamento dos assets
- [x] tabela provisória de jogos

### Ainda faltam

- [ ] definir formalmente a regra de pontuação
- [ ] calcular pontos por palpite
- [ ] calcular classificação geral
- [ ] definir critérios de desempate do bolão
- [ ] calcular evolução do ranking
- [ ] criar a tela principal
- [ ] criar a tela de classificação
- [ ] melhorar a lista/tabela de jogos
- [ ] criar a tela de grupos
- [ ] criar o gráfico de evolução
- [ ] adaptar visual para celular, tablet e desktop
- [ ] criar testes das regras de pontuação
- [ ] revisar acessibilidade e estados de erro
- [ ] validar a versão final no ambiente `test`
