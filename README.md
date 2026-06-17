Bolão FWC 2026

Aplicação Flutter Web para visualização de um bolão da Copa do Mundo FIFA 2026.

O objetivo do projeto é fornecer uma interface simples, visual e acessível por navegador para acompanhar:

* jogos previstos;
* histórico de partidas vindo da TheSportsDB;
* palpites dos participantes;
* classificação do bolão;
* grupos, seleções e estatísticas;
* evolução do ranking ao longo da competição.

Este projeto é pessoal/privado, feito para um grupo pequeno de participantes. A prioridade é simplicidade, clareza dos dados e facilidade de atualização, não arquitetura enterprise.

⸻

Stack

* Frontend / UI: Flutter Web
* Linguagem: Dart
* Dados estáticos: JSON em assets/data/
* Deploy: GitHub Actions + Cloudflare Pages
* Hospedagem: Cloudflare Pages
* Fonte externa de partidas: TheSportsDB
* Fluxo Git: dev → test → main

⸻

Ambientes

Desenvolvimento local

Branch:

dev

Uso:

flutter run -d chrome

A branch dev é onde o desenvolvimento acontece. Commits são organizados diretamente nela, sem necessidade obrigatória de feature branches.

⸻

Teste / staging

Branch:

test

A branch test dispara o GitHub Actions e publica uma versão de teste no Cloudflare Pages.

Uso:

git switch test
git pull origin test
git merge dev
git push origin test

Depois, conferir o deployment no Cloudflare Pages ou no log do GitHub Actions.

⸻

Produção

Branch:

main

A branch main dispara o GitHub Actions e publica a versão de produção no Cloudflare Pages.

Uso:

git switch main
git pull origin main
git merge test
git push origin main

URL principal:

https://bolao2026fwc.pages.dev

⸻

Deploy

O Cloudflare Pages está desconectado do GitHub como pipeline de build direto.

O deploy real é feito por GitHub Actions:

push em test/main
→ GitHub Actions instala Flutter
→ flutter build web --release
→ Wrangler publica build/web no Cloudflare Pages

Workflow:

.github/workflows/deploy_cloudflare.yml

Branches que disparam deploy:

test
main

Branches que não disparam deploy:

dev
feature/*

⸻

Estrutura dos dados

Os arquivos principais ficam em:

assets/data/

jogos.json

Catálogo canônico dos jogos previstos pelo bolão.

Este arquivo define o jogoId, que é a chave interna do projeto.

Campos esperados incluem:

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

O jogoId é a referência usada por palpites, histórico e times.

⸻

historico_partidas.json

Camada de partidas vindas da API TheSportsDB.

Este arquivo contém os dados de API normalizados e vinculados ao jogo interno por jogoId.

A chave externa da SportsDB é idEvent.

Regra conceitual:

jogoId = chave interna do bolão
idEvent = chave externa da SportsDB

⸻

participantes.json

Lista de participantes do bolão.

Cada participante tem:

participanteId
nome
jogosPalpitados
jogosSemPalpite
totalJogosPrevistos
jogosPalpitadosFaseGrupos
jogosSemPalpiteFaseGrupos
totalJogosFaseGrupos

O participanteId é alfanumérico e não depende diretamente do nome exibido.

⸻

palpites.json

Lista normalizada de palpites.

Cada registro representa a relação:

participante + jogo → palpite

Campos:

palpiteId
participanteId
jogoId
golsMandante
golsVisitante

Quando não há palpite registrado, os gols ficam como null.

Exemplo:

{
  "palpiteId": "pl94ef65a940a2",
  "participanteId": "p40a471872e",
  "jogoId": "gb0850041021b",
  "golsMandante": 3,
  "golsVisitante": 0
}

⸻

times_participantes.json

Lista de seleções participantes, grupos e estatísticas.

Cada time contém:

timeId
nome
nomeNormalizado
grupo
jogosIds
rankingGrupo
estatisticasGrupo

As estatísticas de grupo podem ser recalculadas a partir dos jogos com resultados disponíveis.

⸻

Modelagem

O projeto usa uma abordagem simples, funcional e data-oriented.

Fonte de verdade:

jogos.json
historico_partidas.json
participantes.json
palpites.json
times_participantes.json

Dados derivados:

classificação do bolão
pontuação por participante
evolução do ranking
tabela de jogos
estatísticas de grupos

A pontuação dos participantes não deve ser tratada como dado primário. Ela deve ser calculada a partir de:

jogos encerrados
+
palpites
+
regra de pontuação

⸻

Atualização dos dados

A atualização futura deve ser feita por script separado, não pela interface Flutter.

Fluxo previsto:

TheSportsDB API
→ script local de atualização
→ atualização de historico_partidas.json
→ atualização de status em jogos.json
→ recálculo opcional de times_participantes.json
→ commit
→ push
→ deploy

Endpoints relevantes da TheSportsDB:

eventsseason.php
eventsnextleague.php
eventspastleague.php
eventsday.php

A API pública usa a base:

https://www.thesportsdb.com/api/v1/json/123

O app Flutter deve apenas ler os JSONs estáticos e exibir as projeções.

⸻

Rodar localmente

flutter pub get
flutter run -d chrome

Build local:

flutter build web --release

Análise:

flutter analyze

Testes:

flutter test

⸻

Fluxo Git

Desenvolvimento normal

git switch dev
git pull origin dev

Depois de alterar código:

git status
git add .
git commit -m "mensagem clara"
git push origin dev

⸻

Subir para teste

git switch test
git pull origin test
git merge dev
git push origin test

Isso dispara deploy de teste via GitHub Actions.

⸻

Publicar produção

git switch main
git pull origin main
git merge test
git push origin main

Isso dispara deploy de produção via GitHub Actions.

⸻

Versionamento

O projeto usa versionamento simples inspirado em SemVer:

MAJOR.MINOR.PATCH

Exemplos:

v0.1.0
v0.2.0
v1.0.0

Sugestão:

* PATCH: correção pequena ou ajuste visual simples.
* MINOR: nova tela, novo gráfico, nova regra, nova carga de dados.
* MAJOR: mudança estrutural relevante ou primeira versão considerada estável.

Durante desenvolvimento inicial, usar versões 0.x.y.

Exemplo:

v0.1.0 = primeira versão com assets e deploy funcionando
v0.2.0 = primeira tela lendo dados reais
v0.3.0 = classificação do bolão funcionando
v1.0.0 = versão completa utilizável pelo grupo

⸻

Criar uma versão Git

Criar tag local:

git tag -a v0.1.0 -m "v0.1.0 - setup inicial com Flutter Web, dados JSON e deploy"

Enviar tag para o GitHub:

git push origin v0.1.0

Listar tags:

git tag

Ver detalhes de uma tag:

git show v0.1.0

Apagar tag local:

git tag -d v0.1.0

Apagar tag remota:

git push origin --delete v0.1.0

⸻

Estado atual

Setup inicial definido:

Flutter Web
GitHub Actions
Cloudflare Pages
main = produção
test = staging
dev = desenvolvimento
dados em JSON estático

Próximos passos técnicos:

1. Criar modelos Dart para os JSONs.
2. Criar loader de assets.
3. Validar contagem de registros carregados.
4. Implementar tela inicial.
5. Implementar tabela de classificação.
6. Implementar tabela de jogos.
7. Implementar tela de grupos.
8. Implementar gráfico de evolução do ranking.