# Core de pontuação do Bolão FWC 2026

Arquivos incluídos:

```text
lib/core/football_group_rules.dart
lib/core/sistema_palpites.dart
lib/core/sistema_pontuacao_times.dart
lib/core/sistema_pontuacao_participantes.dart
```

## Papel de cada arquivo

### `football_group_rules.dart`

Motor reutilizável de tabelas de grupos para futebol.

Ele calcula:

```text
pontos
jogos
vitórias
empates
derrotas
gols pró
gols contra
saldo de gols
classificados diretos
melhores terceiros, quando configurado
```

O sistema de pontos padrão é o clássico:

```text
vitória: 3 pontos
empate: 1 ponto
derrota: 0 ponto
```

Os critérios de desempate são configuráveis. O app usa hoje `FootballGroupRules.fifaStyle`, preservando a regra já usada no projeto:

```text
pontos gerais
confronto direto entre os dois times comparados: pontos, saldo e gols
saldo geral
gols pró gerais
fair play disponível na base
nome como fallback determinístico
```

Para comparar terceiros de grupos diferentes, o app usa:

```text
pontos
saldo geral
gols pró
fair play
nome
```

Observação: a base atual ainda não guarda todos os dados disciplinares/ranking FIFA necessários para reproduzir literalmente todos os últimos critérios oficiais. Por isso, `fairPlayPoints` e `nome` funcionam como critérios determinísticos com os dados disponíveis.

### `sistema_palpites.dart`

Calcula a pontuação de um palpite contra o resultado real de um jogo.

Regras implementadas:

```text
5 pontos: placar exato
3 pontos: resultado correto + um dos placares correto
2 pontos: apenas resultado correto
1 ponto: apenas um dos placares correto
0 pontos: nenhum acerto relevante
```

### `sistema_pontuacao_times.dart`

Adapta os dados do app para o motor de regras de futebol e calcula projeções de mata-mata.

Ele consegue calcular:

```text
tabela real dos grupos a partir de jogos.json, delegando para football_group_rules.dart
tabela prevista de um participante a partir dos palpites dele, delegando para football_group_rules.dart
melhores terceiros
chaveamento projetado
campeão, vice, terceiro e quarto projetados
```

Observação: a projeção de melhores terceiros usa os grupos elegíveis já presentes no `jogos.json` e escolhe deterministicamente o melhor terceiro disponível entre os elegíveis. A FIFA possui uma tabela oficial com 495 combinações em Annexe C. Esta primeira versão do core não embute as 495 combinações completas; ela é suficiente para simulação/projeção interna, mas pode ser refinada depois se você quiser refletir literalmente cada opção do Annexe C.

### `sistema_pontuacao_participantes.dart`

Agrega pontuação por participante.

Ele soma:

```text
pontos dos palpites de placar
pontos por 1º e 2º de grupo
pontos por campeão, vice, 3º e 4º
```

Também aplica o desempate principal:

```text
número de placares exatos
```

## Como usar

Exemplo conceitual:

```dart
final data = await AssetLoader.carregarBolaoData();
final classificacao = SistemaPontuacaoParticipantes.calcularClassificacao(data);
```

Cada item de `classificacao` é uma `LinhaPontuacaoParticipante` com:

```text
posicao
participanteId
nome
pontosTotal
pontosJogos
pontosGrupos
pontosFinal
placaresExatos
resultadosCorretos
pontuacoesPalpites
pontuacoesGrupos
pontuacaoFinal
chaveamentoPrevisto
```

## Reuso em outro campeonato

Para reutilizar o app em outro torneio de futebol:

```text
manter football_group_rules.dart
ajustar o arquivo/fonte de jogos
ajustar referências de mata-mata em jogos.json
rever se a pontuação do bolão continua igual
rever quantidade de classificados diretos e melhores terceiros
```

Se a competição não tiver melhores terceiros, configure `bestThirdQualifiers: 0`.

Se a competição usar critérios de desempate diferentes, crie uma configuração própria de `FootballGroupRules` em vez de espalhar `if` pela UI.

## Uso pelas telas

As telas devem renderizar dados já calculados, sem reimplementar regra de pontuação. A classificação geral vem de:

```dart
List<LinhaPontuacaoParticipante>
```
