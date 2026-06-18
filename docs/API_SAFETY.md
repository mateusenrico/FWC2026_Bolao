# API safety / atualização de dados

Este pacote endurece a camada de API para que falhas externas não corrompam a base local.

## Endpoints consultados

A atualização usa:

- `eventsseason.php?id=4429&s=2026`
- `eventsnextleague.php?id=4429`
- `eventspastleague.php?id=4429`
- `eventsday.php?d=YYYY-MM-DD&s=Soccer`, filtrando `idLeague == 4429`
- `search_all_teams.php?l=FIFA World Cup`
- `lookupleague.php?id=4429`
- `lookupvenue.php?id=<idVenue>`
- fallback: `https://fixturedownload.com/feed/json/fifa-world-cup-2026`

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
