# UI responsiva do Bolão FWC 2026

Este pacote adiciona o dashboard visual e integra o core de pontuação existente.

## O que ele implementa

- tela inicial responsiva;
- destaque para partida ao vivo ou próximo horário;
- ranking parcial colapsável;
- filtros de partidas: ontem e antes, hoje, próximos sete dias e futuros;
- cards de partidas com siglas oficiais, badges/bandeiras, placar e status;
- detalhe da partida;
- detalhe do participante;
- classificação dos grupos;
- projeção colapsável do mata-mata por participante;
- atualização da SportsDB em memória, preservando os assets locais se a API falhar;
- mesma regra 5/3/2/1/0 para jogos de grupos e mata-mata;
- testes básicos da regra de pontuação, incluindo placar exato no mata-mata.

## Como aplicar

Extraia o ZIP na raiz do projeto e permita sobrescrever os arquivos com o mesmo nome.

O pacote não substitui seus JSONs em `assets/data/` e não altera a tool de atualização.

Depois rode:

```bash
flutter pub get
flutter analyze
flutter test
flutter build web --release
flutter run -d chrome
```

## Arquitetura adicionada

```text
lib/
├── core/
│   ├── app_routes.dart
│   ├── date_time_utils.dart
│   ├── sistema_palpites.dart
│   ├── sistema_pontuacao_participantes.dart
│   ├── sistema_pontuacao_times.dart
│   └── team_normalizer.dart
├── models/
│   ├── bolao_data.dart
│   └── jogo.dart
├── plugins/
│   ├── api_refresh_action.dart
│   ├── chaveamento_participante_card.dart
│   ├── grupo_table_card.dart
│   ├── palpite_jogo_card.dart
│   ├── palpite_participante_card.dart
│   ├── partida_card.dart
│   ├── ranking_participante_card.dart
│   ├── section_header.dart
│   ├── team_badge.dart
│   └── team_match_panel.dart
├── screens/
│   ├── grupos_screen.dart
│   ├── home_screen.dart
│   ├── jogo_detail_screen.dart
│   └── participante_detail_screen.dart
├── services/
│   ├── bolao_controller.dart
│   └── sportsdb_api_service.dart
└── main.dart
```

## Observações de regras

O sistema de palpites não filtra por fase. Portanto, qualquer jogo com resultado disponível, inclusive mata-mata, usa a mesma regra:

- 5 pontos: placar exato;
- 3 pontos: resultado correto e um dos gols correto;
- 2 pontos: somente o resultado correto;
- 1 ponto: somente um dos gols correto;
- 0 pontos: nenhum acerto.

A ordenação dos grupos segue os dados disponíveis para pontos, confronto direto, saldo geral, gols marcados e fair play. Caso todos esses dados continuem empatados, o nome é usado apenas como fallback determinístico, porque o histórico do ranking FIFA ainda não existe na base.

## Navegação

```text
Home
├── toque em uma partida → detalhe da partida
├── toque em um participante → detalhe do participante
└── botão de tabela → classificação dos grupos
```

Todos os AppBars possuem atualização da SportsDB. A seta padrão do Navigator permite voltar para a tela anterior.
