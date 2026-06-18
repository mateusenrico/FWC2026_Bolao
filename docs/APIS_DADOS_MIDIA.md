# APIs e midia da Copa

Ultima revisao: 2026-06-18.

Este documento registra as fontes externas avaliadas para dados e midia do app.
O objetivo atual continua sendo uso pessoal/privado, com credito explicito e
sem alegar afiliacao com FIFA, selecoes, estadios ou provedores de dados.

## Decisao atual

| Fonte | Status | Uso |
| --- | --- | --- |
| TheSportsDB | Fonte principal | Jogos ao vivo/resultados, times, badges, imagens, venues, liga, videos e detalhes de partida quando retornados |
| FlagCDN/Flagpedia | Fonte auxiliar de midia | Bandeiras por codigo ISO quando a SportsDB nao fornece uma imagem de bandeira especifica |
| TheStatsAPI fixture seed | Fonte auxiliar/canonica inicial | Seed da agenda de 104 jogos usado como base estatica |
| FixtureDownload | Fallback | Conferencia/fallback de agenda ou resultado quando necessario |

## Cache local de imagens

O app agora possui cache local de imagens em `assets/media/`.

Fluxo:

1. `tools/update_sportsdb.dart` atualiza os JSONs em `assets/data/`.
2. `tools/cache_media_assets.dart` le esses JSONs, encontra URLs de imagens e
   baixa os arquivos para `assets/media/`.
3. `assets/media/media_manifest.json` mapeia URL remota para asset local.
4. O app prefere o asset local e usa a URL remota como fallback.

Categorias geradas hoje:

```text
assets/media/team_badges/
assets/media/team_flags/
assets/media/team_images/
assets/media/venue_images/
assets/media/match_images/
assets/media/league_images/
assets/media/app_icons/
```

Como boa pratica, se o projeto virar publico/open source, revisar termos e
permissoes de redistribuicao das imagens antes de publicar os assets.

## APIs pesquisadas

| API | O que oferece | Observacao |
| --- | --- | --- |
| TheSportsDB | API JSON gratuita/crowd-sourced, times, eventos, jogadores, arte, placares, highlights e imagens | Melhor encaixe atual; ja esta integrada |
| FlagCDN/Flagpedia | CDN publica de bandeiras em PNG/WebP/SVG/JPEG baseada em Wikimedia Commons | Integrada para bandeiras de times quando ha codigo ISO confiavel |
| football-data.org | Futebol em formato maquina, placares, fixtures, tabelas, squads, lineups/subs | Exige token para uso real; boa candidata para squads/lineups se os termos fizerem sentido |
| BALLDONTLIE FIFA World Cup API | Dados de Copa 2018/2022/2026, times, estadios, jogadores, elencos, jogos, standings, lineups, eventos, stats e odds | Exige chave; muito rica para detalhes de partida/elenco |
| API-Football / API-SPORTS | Livescore, standings, eventos, line-ups, players, odds e estatisticas | Freemium/paga; candidata forte se a SportsDB ficar incompleta |
| openfootball/worldcup.json | Dados publicos/open data de Copas em JSON | Bom para fixture/historico, nao resolve midia |
| rezarahiminia/worldcup2026 | API comunitaria para Copa 2026, com times, grupos, jogos, estadios e placares ao vivo | Fonte comunitaria a validar antes de integrar |

## Links de referencia

- TheSportsDB: <https://www.thesportsdb.com/free_sports_api>
- TheSportsDB docs de imagens: <https://www.thesportsdb.com/docs_api_guide>
- FlagCDN: <https://flagcdn.com/>
- Flagpedia API/CDN: <https://flagpedia.net/download/api>
- football-data.org docs: <https://www.football-data.org/documentation/api>
- BALLDONTLIE FIFA World Cup API: <https://fifa.balldontlie.io/>
- API-Football: <https://www.api-football.com/>
- openfootball/worldcup.json: <https://github.com/openfootball/worldcup.json>
- worldcup2026 community API: <https://github.com/rezarahiminia/worldcup2026>
