# API safety / atualização de dados

Este pacote endurece a camada de API para que falhas externas não corrompam a base local.

## Endpoints consultados

A atualização usa:

- `eventsseason.php?id=4429&s=2026`
- `eventsnextleague.php?id=4429`
- `eventspastleague.php?id=4429`
- `eventsday.php?d=YYYY-MM-DD&s=Soccer`, filtrando `idLeague == 4429`
- `lookupevent.php?id=<idEvent>`, no refresh em memória, limitado a eventos próximos/relevantes
- `lookuptimeline.php?id=<idEvent>`, sob demanda na tela de partida
- `lookuplineup.php?id=<idEvent>`, sob demanda na tela de partida
- `eventresults.php?id=<idEvent>`, sob demanda na tela de partida
- `lookupeventstats.php?id=<idEvent>`, sob demanda na tela de partida
- `search_all_teams.php?l=FIFA World Cup`
- `lookupleague.php?id=4429`
- `lookupvenue.php?id=<idVenue>`
- fallback: `https://fixturedownload.com/feed/json/fifa-world-cup-2026`

Referencia oficial dos endpoints TheSportsDB:
<https://www.thesportsdb.com/docs_api_guide>

## Garantias da tool local

`tools/update_sportsdb.dart` agora:

1. cria backup em `assets/data/backups/<timestamp>/` antes de escrever;
2. consulta todos os endpoints com timeout;
3. não interrompe a atualização por falha em um endpoint isolado;
4. ignora itens JSON malformados, registrando aviso;
5. preserva dados antigos se a API não trouxer determinado jogo;
6. usa a fixture canônica para manter os 104 jogos;
7. escreve log em `logs/update_sportsdb/<timestamp>.json`;
8. enriquece times, venues e liga quando a SportsDB retorna metadados visuais;
9. mantém o build funcionando mesmo se a API estiver parcialmente indisponível.
10. limita a janela de status ao vivo para evitar que um jogo preso em `LIVE`, `1H`, `2H` ou `HT` continue pontuando indefinidamente.

No app, `BolaoController.atualizarApi()` também passa alguns `idEvent` relevantes
para `SportsDbApiService`, que consulta `lookupevent.php`. Essa consulta é
deduplicada e limitada para complementar a janela de `eventsday` sem fazer uma
chamada individual para todos os 104 jogos a cada ciclo de 5 segundos.

Detalhes mais pesados de uma partida, como timeline, estatísticas, resultados
individuais e escalações, são carregados apenas ao abrir a tela daquele jogo.
Quando a partida está ao vivo, o cache local desses detalhes é invalidado pelo
refresh para que a tela possa buscar dados novos sem colocar esses endpoints no
loop global do dashboard.

## Atribuicoes e licencas

As fontes externas usadas pela atualização ficam registradas em `THIRD_PARTY_NOTICES.md`.

Sempre que um endpoint, feed, pacote de dados ou provedor de midia for adicionado, atualize:

1. este arquivo, com o endpoint e a garantia operacional esperada;
2. `README.md`, com o resumo global do fluxo;
3. `THIRD_PARTY_NOTICES.md`, com credito, link e aviso de licenca/termos.

## Logs em CI

O workflow publica os logs da atualização como artifact no GitHub Actions:

`update-sportsdb-logs-<branch>`

Esses logs mostram:

- endpoints consultados;
- status HTTP;
- quantidade de eventos retornados;
- duração;
- erros/avisos;
- resumo final da base.

## Importante

Os logs e backups são locais/temporários. Eles não devem entrar no Git.

Adicione ao `.gitignore`:

```gitignore
assets/data/backups/
logs/
```
