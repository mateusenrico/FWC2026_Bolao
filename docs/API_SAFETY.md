# API safety / atualização de dados

Este pacote endurece a camada de API para que falhas externas não corrompam a base local.

## Endpoints consultados

A atualização usa:

- `eventsseason.php?id=4429&s=2026`
- `eventsnextleague.php?id=4429`
- `eventspastleague.php?id=4429`
- `eventsday.php?d=YYYY-MM-DD&s=Soccer`, filtrando `idLeague == 4429`
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
8. mantém o build funcionando mesmo se a API estiver parcialmente indisponível.

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
