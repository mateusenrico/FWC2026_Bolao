# Third-party notices

Este arquivo centraliza creditos, licencas e avisos de terceiros usados no Bolao FWC 2026.

O projeto ainda e pessoal/privado. Antes de qualquer publicacao como open source, escolha uma licenca propria para o codigo deste repositorio e revise este arquivo como uma checklist de compliance. Isto nao e aconselhamento juridico; e um registro pratico das fontes e dependencias que o projeto usa hoje.

## Linha de credito sugerida

Quando o app exibir uma area de creditos ou rodape publico, usar algo nesta linha:

```text
Dados e midia esportiva: TheSportsDB. Fixture base: TheStatsAPI. Fallback de agenda/resultados: FixtureDownload. App construido com Flutter.
```

## Codigo do projeto

| Item | Status |
| --- | --- |
| Codigo deste repositorio | Projeto privado/pessoal, sem licenca publica definida ainda. |
| Publicacao futura | Criar um `LICENSE` proprio antes de tornar o repositorio publico. |
| Marcas esportivas | Nomes de Copa do Mundo, selecoes, estadios e competicoes sao usados de forma descritiva. O app nao e afiliado, endossado ou operado pela FIFA, confederacoes, selecoes, estadios ou organizadores. |

## SDKs e ferramentas

| Item | Uso no projeto | Licenca/aviso | Link |
| --- | --- | --- | --- |
| Flutter SDK | Framework principal do app web | Licenca BSD-style do Flutter | <https://github.com/flutter/flutter/blob/master/LICENSE> |
| Dart SDK | Linguagem e toolchain | Licenca BSD-style do Dart SDK | <https://github.com/dart-lang/sdk/blob/main/LICENSE> |
| GitHub Actions | Pipeline de deploy | Servico externo de CI/CD | <https://github.com/features/actions> |
| Cloudflare Pages | Hospedagem do app | Servico externo de hospedagem | <https://pages.cloudflare.com/> |
| Wrangler | Publicacao no Cloudflare Pages | Ferramenta da Cloudflare | <https://developers.cloudflare.com/workers/wrangler/> |

## Dependencias Dart/Flutter

Baseado em `pubspec.lock`. As dependencias SDK (`flutter`, `flutter_test` e `sky_engine`) seguem as licencas do Flutter/Dart SDK. As licencas completas das dependencias hospedadas ficam nos respectivos pacotes em `pub.dev` e nos arquivos `LICENSE` dentro do cache local do Pub.

| Pacote | Versao | Tipo | Licenca observada | Link |
| --- | --- | --- | --- | --- |
| `flutter` | SDK | direta | Flutter SDK BSD-style | <https://github.com/flutter/flutter/blob/master/LICENSE> |
| `flutter_test` | SDK | dev direta | Flutter SDK BSD-style | <https://github.com/flutter/flutter/blob/master/LICENSE> |
| `sky_engine` | SDK | transitive | Flutter SDK BSD-style | <https://github.com/flutter/flutter/blob/master/LICENSE> |
| `cupertino_icons` | 1.0.9 | direta | MIT | <https://pub.dev/packages/cupertino_icons> |
| `http` | 1.6.0 | direta | BSD-3-Clause style, Dart authors | <https://pub.dev/packages/http> |
| `flutter_lints` | 6.0.0 | dev direta | BSD-3-Clause style, Flutter authors | <https://pub.dev/packages/flutter_lints> |
| `async` | 2.13.1 | transitive | BSD-3-Clause style, Dart authors | <https://pub.dev/packages/async> |
| `boolean_selector` | 2.1.2 | transitive | BSD-3-Clause style, Dart authors | <https://pub.dev/packages/boolean_selector> |
| `characters` | 1.4.1 | transitive | BSD-3-Clause style, Dart authors | <https://pub.dev/packages/characters> |
| `clock` | 1.1.2 | transitive | Apache-2.0 | <https://pub.dev/packages/clock> |
| `collection` | 1.19.1 | transitive | BSD-3-Clause style, Dart authors | <https://pub.dev/packages/collection> |
| `fake_async` | 1.3.3 | transitive | Apache-2.0 | <https://pub.dev/packages/fake_async> |
| `http_parser` | 4.1.2 | transitive | BSD-3-Clause style, Dart authors | <https://pub.dev/packages/http_parser> |
| `leak_tracker` | 11.0.2 | transitive | BSD-3-Clause style, Dart authors | <https://pub.dev/packages/leak_tracker> |
| `leak_tracker_flutter_testing` | 3.0.10 | transitive | BSD-3-Clause style, Dart authors | <https://pub.dev/packages/leak_tracker_flutter_testing> |
| `leak_tracker_testing` | 3.0.2 | transitive | BSD-3-Clause style, Dart authors | <https://pub.dev/packages/leak_tracker_testing> |
| `lints` | 6.1.0 | transitive | BSD-3-Clause style, Dart authors | <https://pub.dev/packages/lints> |
| `matcher` | 0.12.19 | transitive | BSD-3-Clause style, Dart authors | <https://pub.dev/packages/matcher> |
| `material_color_utilities` | 0.13.0 | transitive | Apache-2.0 | <https://pub.dev/packages/material_color_utilities> |
| `meta` | 1.18.0 | transitive | BSD-3-Clause style, Dart authors | <https://pub.dev/packages/meta> |
| `path` | 1.9.1 | transitive | BSD-3-Clause style, Dart authors | <https://pub.dev/packages/path> |
| `source_span` | 1.10.2 | transitive | BSD-3-Clause style, Dart authors | <https://pub.dev/packages/source_span> |
| `stack_trace` | 1.12.1 | transitive | BSD-3-Clause style, Dart authors | <https://pub.dev/packages/stack_trace> |
| `stream_channel` | 2.1.4 | transitive | BSD-3-Clause style, Dart authors | <https://pub.dev/packages/stream_channel> |
| `string_scanner` | 1.4.1 | transitive | BSD-3-Clause style, Dart authors | <https://pub.dev/packages/string_scanner> |
| `term_glyph` | 1.2.2 | transitive | BSD-3-Clause style, Dart authors | <https://pub.dev/packages/term_glyph> |
| `test_api` | 0.7.11 | transitive | BSD-3-Clause style, Dart authors | <https://pub.dev/packages/test_api> |
| `typed_data` | 1.4.0 | transitive | BSD-3-Clause style, Dart authors | <https://pub.dev/packages/typed_data> |
| `vector_math` | 2.2.0 | transitive | BSD-3-Clause style, Google Inc. | <https://pub.dev/packages/vector_math> |
| `vm_service` | 15.2.0 | transitive | BSD-3-Clause style, Dart authors | <https://pub.dev/packages/vm_service> |
| `web` | 1.1.1 | direta | BSD-3-Clause style, Dart authors | <https://pub.dev/packages/web> |

## Dados, APIs e midia

| Fonte | Uso no projeto | Arquivos/locais afetados | Credito/licenca registrada | Link |
| --- | --- | --- | --- | --- |
| TheStatsAPI | Fixture canonica dos 104 jogos da Copa do Mundo 2026 | `tools/data/world_cup_2026_fixtures.json`, `assets/data/jogos.json` (`fonteFixture: thestatsapi`) | O JSON declara: uso livre mediante atribuicao a TheStatsAPI. | <https://www.thestatsapi.com> |
| TheSportsDB | Resultados, jogos ao vivo, historico bruto, times, badges, liga, venues, banners, URLs de video, timeline, estatisticas, escalacoes e midia retornada pela API | `tools/update_sportsdb.dart`, `tools/cache_media_assets.dart`, `assets/data/historico_partidas.json`, `assets/data/times_sportsdb.json`, `assets/data/venues_sportsdb.json`, `assets/data/liga_sportsdb.json`, `assets/media/`, tela de detalhe de partida | Manter credito "Powered by TheSportsDB" quando dados/midia da API forem exibidos ou documentados. O cache local e usado para o app privado/pessoal; revisar termos de redistribuicao antes de publicar assets em repositorio publico. | <https://www.thesportsdb.com/api.php> |
| FixtureDownload | Fallback de agenda/resultados quando a SportsDB nao retorna informacao suficiente | `tools/update_sportsdb.dart`, possivel `fonteResultado` em `assets/data/jogos.json` | Manter atribuicao quando dados dessa fonte forem usados ou exportados. | <https://fixturedownload.com/> |
| YouTube | Links e embeds de highlights vindos da SportsDB (`strVideo`) | Telas de detalhe de partida, quando houver URL | O app nao armazena videos; apenas referencia, abre ou incorpora URLs externas quando disponiveis. | <https://www.youtube.com/> |

## Assets e midia remota

- Badges de times, badge/banner da liga, imagens de venues, imagens de partidas e URLs de highlights sao consumidos como URLs retornadas pelas APIs, principalmente TheSportsDB.
- O app tambem mantem cache local dessas imagens em `assets/media/` para garantir exibicao mais estavel no uso privado/pessoal.
- Antes de publicar o repositorio como open source ou distribuir os assets fora do grupo privado, revisar a licenca/termos de redistribuicao de cada fonte de midia.
- Se uma imagem, icone, fonte, audio ou asset for adicionado manualmente ao repositorio, registrar aqui a origem, autor, licenca e arquivo afetado.

## Checklist de manutencao

Atualize este arquivo sempre que:

1. adicionar, remover ou atualizar dependencias no `pubspec.yaml` ou `pubspec.lock`;
2. adicionar uma nova API, feed, planilha, scraping, pacote de dados ou fonte de fixture;
3. adicionar imagem, fonte, icone, audio, video ou asset de terceiros ao repositorio;
4. mudar o provedor de deploy, CI/CD ou hospedagem;
5. publicar o projeto ou trocar o status de privado para open source.

O `README.md` deve continuar apontando para este arquivo e resumindo as fontes externas principais.
