# Build, profile e deploy

## Execução local em profile

O projeto inclui configuração de workspace para o VS Code abrir o app em profile no Chrome:

```text
.vscode/launch.json
.vscode/settings.json
```

No terminal, use:

```bash
make run
```

Esse alvo executa:

```bash
flutter run -d chrome --profile
```

Observação: o binário `flutter run` puro continua sendo um comando global do Flutter e, por padrão, inicia em debug. O projeto não altera o shell global da máquina; por isso o atalho confiável no terminal é `make run` ou `flutter run -d chrome --profile`.

## Pipeline GitHub Actions

Workflow:

```text
.github/workflows/deploy_cloudflare.yml
```

O deploy continua restrito a:

```text
test
main
```

Melhorias aplicadas:

- `concurrency` por branch para cancelar deploy antigo quando chegar push novo na mesma branch.
- `timeout-minutes` no job para evitar execução presa.
- cache explícito de Flutter SDK e pub cache via `subosito/flutter-action`.
- upload dos logs de `tools/update_sportsdb.dart` como artifact.
- deploy via `cloudflare/wrangler-action`, reduzindo instalação manual de Node/Wrangler.

## Referências consultadas

- Flutter build modes: https://docs.flutter.dev/testing/build-modes
- GitHub Actions concurrency: https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency
- `subosito/flutter-action`: https://github.com/subosito/flutter-action
- `cloudflare/wrangler-action`: https://github.com/cloudflare/wrangler-action
