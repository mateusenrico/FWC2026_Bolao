# Core de pontuação do Bolão FWC 2026

Arquivos incluídos:

```text
lib/core/sistema_palpites.dart
lib/core/sistema_pontuacao_times.dart
lib/core/sistema_pontuacao_participantes.dart
```

## Papel de cada arquivo

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

Calcula tabelas de grupos e projeções de mata-mata.

Ele consegue calcular:

```text
tabela real dos grupos a partir de jogos.json
tabela prevista de um participante a partir dos palpites dele
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

## Próximo passo visual

Com esses arquivos, a tela de classificação pode ser apenas uma renderização de:

```dart
List<LinhaPontuacaoParticipante>
```

Sugestão para UI:

```text
plugins/ranking_table.dart
plugins/participante_score_card.dart
screens/classificacao_screen.dart
```
