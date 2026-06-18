import '../models/jogo.dart';
import '../models/palpite.dart';
import '../models/referencia_participante_jogo.dart';
import 'functions/team_normalizer.dart';

class LinhaTabelaTime {
  final String timeKey;
  final String nome;
  final String grupo;
  final int posicao;

  final int pontos;
  final int jogos;
  final int vitorias;
  final int empates;
  final int derrotas;
  final int golsPro;
  final int golsContra;
  final int saldoGols;

  final int fairPlayPontos;
  final bool classificouDireto;
  final bool classificouComoTerceiro;

  const LinhaTabelaTime({
    required this.timeKey,
    required this.nome,
    required this.grupo,
    required this.posicao,
    required this.pontos,
    required this.jogos,
    required this.vitorias,
    required this.empates,
    required this.derrotas,
    required this.golsPro,
    required this.golsContra,
    required this.saldoGols,
    required this.fairPlayPontos,
    required this.classificouDireto,
    required this.classificouComoTerceiro,
  });

  LinhaTabelaTime copyWith({
    int? posicao,
    bool? classificouDireto,
    bool? classificouComoTerceiro,
  }) {
    return LinhaTabelaTime(
      timeKey: timeKey,
      nome: nome,
      grupo: grupo,
      posicao: posicao ?? this.posicao,
      pontos: pontos,
      jogos: jogos,
      vitorias: vitorias,
      empates: empates,
      derrotas: derrotas,
      golsPro: golsPro,
      golsContra: golsContra,
      saldoGols: saldoGols,
      fairPlayPontos: fairPlayPontos,
      classificouDireto: classificouDireto ?? this.classificouDireto,
      classificouComoTerceiro:
          classificouComoTerceiro ?? this.classificouComoTerceiro,
    );
  }

  TimeProjetado toTimeProjetado() {
    return TimeProjetado(
      timeKey: timeKey,
      nome: nome,
      grupo: grupo,
      posicaoGrupo: posicao,
      origem: 'tabela_grupo',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timeKey': timeKey,
      'nome': nome,
      'grupo': grupo,
      'posicao': posicao,
      'pontos': pontos,
      'jogos': jogos,
      'vitorias': vitorias,
      'empates': empates,
      'derrotas': derrotas,
      'golsPro': golsPro,
      'golsContra': golsContra,
      'saldoGols': saldoGols,
      'fairPlayPontos': fairPlayPontos,
      'classificouDireto': classificouDireto,
      'classificouComoTerceiro': classificouComoTerceiro,
    };
  }
}

class TabelaGrupo {
  final String grupo;
  final List<LinhaTabelaTime> linhas;
  final List<PartidaGrupoComputada> partidasComputadas;

  const TabelaGrupo({
    required this.grupo,
    required this.linhas,
    required this.partidasComputadas,
  });

  LinhaTabelaTime? posicao(int posicao) {
    if (posicao < 1 || posicao > linhas.length) {
      return null;
    }

    return linhas[posicao - 1];
  }

  LinhaTabelaTime? get primeiro => posicao(1);

  LinhaTabelaTime? get segundo => posicao(2);

  LinhaTabelaTime? get terceiro => posicao(3);

  bool get grupoCompleto => partidasComputadas.length >= 6;

  Map<String, dynamic> toJson() {
    return {
      'grupo': grupo,
      'grupoCompleto': grupoCompleto,
      'linhas': linhas.map((linha) => linha.toJson()).toList(growable: false),
    };
  }
}

class ConjuntoTabelasGrupo {
  final Map<String, TabelaGrupo> tabelasPorGrupo;
  final List<LinhaTabelaTime> terceirosOrdenados;
  final List<LinhaTabelaTime> melhoresTerceiros;

  const ConjuntoTabelasGrupo({
    required this.tabelasPorGrupo,
    required this.terceirosOrdenados,
    required this.melhoresTerceiros,
  });

  TabelaGrupo? tabela(String grupo) => tabelasPorGrupo[grupo.toUpperCase()];

  LinhaTabelaTime? timePorGrupoPosicao(String grupo, int posicao) {
    return tabela(grupo)?.posicao(posicao);
  }

  List<LinhaTabelaTime> get classificadosDiretos {
    final result = <LinhaTabelaTime>[];

    for (final tabela in tabelasPorGrupo.values) {
      final primeiro = tabela.primeiro;
      final segundo = tabela.segundo;

      if (primeiro != null) {
        result.add(primeiro.copyWith(classificouDireto: true));
      }

      if (segundo != null) {
        result.add(segundo.copyWith(classificouDireto: true));
      }
    }

    return result;
  }

  List<LinhaTabelaTime> get classificadosRound32 {
    return [
      ...classificadosDiretos,
      ...melhoresTerceiros.map(
        (linha) => linha.copyWith(classificouComoTerceiro: true),
      ),
    ];
  }

  Map<String, dynamic> toJson() {
    return {
      'tabelasPorGrupo': {
        for (final entry in tabelasPorGrupo.entries)
          entry.key: entry.value.toJson(),
      },
      'terceirosOrdenados': terceirosOrdenados.map((e) => e.toJson()).toList(),
      'melhoresTerceiros': melhoresTerceiros.map((e) => e.toJson()).toList(),
    };
  }
}

class PartidaGrupoComputada {
  final String jogoId;
  final int matchNumber;
  final String grupo;
  final String mandanteKey;
  final String mandanteNome;
  final String visitanteKey;
  final String visitanteNome;
  final int golsMandante;
  final int golsVisitante;

  const PartidaGrupoComputada({
    required this.jogoId,
    required this.matchNumber,
    required this.grupo,
    required this.mandanteKey,
    required this.mandanteNome,
    required this.visitanteKey,
    required this.visitanteNome,
    required this.golsMandante,
    required this.golsVisitante,
  });

  bool envolve(String timeKey) {
    return mandanteKey == timeKey || visitanteKey == timeKey;
  }

  int golsPro(String timeKey) {
    if (mandanteKey == timeKey) {
      return golsMandante;
    }

    if (visitanteKey == timeKey) {
      return golsVisitante;
    }

    return 0;
  }

  int golsContra(String timeKey) {
    if (mandanteKey == timeKey) {
      return golsVisitante;
    }

    if (visitanteKey == timeKey) {
      return golsMandante;
    }

    return 0;
  }

  int pontos(String timeKey) {
    final pro = golsPro(timeKey);
    final contra = golsContra(timeKey);

    if (!envolve(timeKey)) {
      return 0;
    }

    if (pro > contra) {
      return 3;
    }

    if (pro == contra) {
      return 1;
    }

    return 0;
  }
}

class TimeProjetado {
  final String timeKey;
  final String nome;
  final String? grupo;
  final int? posicaoGrupo;
  final String origem;

  const TimeProjetado({
    required this.timeKey,
    required this.nome,
    required this.grupo,
    required this.posicaoGrupo,
    required this.origem,
  });

  bool get isValido => timeKey.isNotEmpty;

  Map<String, dynamic> toJson() {
    return {
      'timeKey': timeKey,
      'nome': nome,
      'grupo': grupo,
      'posicaoGrupo': posicaoGrupo,
      'origem': origem,
    };
  }
}

class JogoProjetado {
  final String jogoId;
  final int matchNumber;
  final String faseCodigo;
  final TimeProjetado? mandante;
  final TimeProjetado? visitante;
  final Palpite? palpiteUsado;
  final int? golsMandante;
  final int? golsVisitante;
  final TimeProjetado? vencedor;
  final TimeProjetado? perdedor;
  final List<String> avisos;

  const JogoProjetado({
    required this.jogoId,
    required this.matchNumber,
    required this.faseCodigo,
    required this.mandante,
    required this.visitante,
    required this.palpiteUsado,
    required this.golsMandante,
    required this.golsVisitante,
    required this.vencedor,
    required this.perdedor,
    required this.avisos,
  });

  bool get resolvido => vencedor != null && perdedor != null;

  Map<String, dynamic> toJson() {
    return {
      'jogoId': jogoId,
      'matchNumber': matchNumber,
      'faseCodigo': faseCodigo,
      'mandante': mandante?.toJson(),
      'visitante': visitante?.toJson(),
      'palpiteId': palpiteUsado?.palpiteId,
      'golsMandante': golsMandante,
      'golsVisitante': golsVisitante,
      'vencedor': vencedor?.toJson(),
      'perdedor': perdedor?.toJson(),
      'avisos': avisos,
    };
  }
}

class ResultadoFinalTorneio {
  final TimeProjetado? campeao;
  final TimeProjetado? vice;
  final TimeProjetado? terceiro;
  final TimeProjetado? quarto;

  const ResultadoFinalTorneio({
    required this.campeao,
    required this.vice,
    required this.terceiro,
    required this.quarto,
  });

  bool get completo {
    return campeao != null &&
        vice != null &&
        terceiro != null &&
        quarto != null;
  }

  Map<String, dynamic> toJson() {
    return {
      'campeao': campeao?.toJson(),
      'vice': vice?.toJson(),
      'terceiro': terceiro?.toJson(),
      'quarto': quarto?.toJson(),
      'completo': completo,
    };
  }
}

class ChaveamentoProjetado {
  final Map<int, JogoProjetado> jogosPorMatchNumber;
  final ResultadoFinalTorneio resultadoFinal;
  final List<String> avisos;

  const ChaveamentoProjetado({
    required this.jogosPorMatchNumber,
    required this.resultadoFinal,
    required this.avisos,
  });

  JogoProjetado? jogo(int matchNumber) => jogosPorMatchNumber[matchNumber];

  Map<String, dynamic> toJson() {
    return {
      'jogosPorMatchNumber': {
        for (final entry in jogosPorMatchNumber.entries)
          entry.key.toString(): entry.value.toJson(),
      },
      'resultadoFinal': resultadoFinal.toJson(),
      'avisos': avisos,
    };
  }
}

class _AcumuladorTime {
  final String timeKey;
  final String nome;
  final String grupo;

  int pontos = 0;
  int jogos = 0;
  int vitorias = 0;
  int empates = 0;
  int derrotas = 0;
  int golsPro = 0;
  int golsContra = 0;
  int fairPlayPontos = 0;

  _AcumuladorTime({
    required this.timeKey,
    required this.nome,
    required this.grupo,
  });

  int get saldoGols => golsPro - golsContra;

  LinhaTabelaTime toLinha({required int posicao}) {
    return LinhaTabelaTime(
      timeKey: timeKey,
      nome: nome,
      grupo: grupo,
      posicao: posicao,
      pontos: pontos,
      jogos: jogos,
      vitorias: vitorias,
      empates: empates,
      derrotas: derrotas,
      golsPro: golsPro,
      golsContra: golsContra,
      saldoGols: saldoGols,
      fairPlayPontos: fairPlayPontos,
      classificouDireto: posicao <= 2,
      classificouComoTerceiro: false,
    );
  }
}

class SistemaPontuacaoTimes {
  const SistemaPontuacaoTimes._();

  static ConjuntoTabelasGrupo calcularTabelasReais(List<Jogo> jogos) {
    final partidas = <PartidaGrupoComputada>[];

    for (final jogo in jogos.where((jogo) => jogo.isFaseDeGrupos)) {
      if (!jogo.temResultado ||
          jogo.golsMandante == null ||
          jogo.golsVisitante == null ||
          jogo.grupo == null) {
        continue;
      }

      partidas.add(
        PartidaGrupoComputada(
          jogoId: jogo.jogoId,
          matchNumber: jogo.matchNumber,
          grupo: jogo.grupo!,
          mandanteKey: TeamNormalizer.key(jogo.mandantePrevisto),
          mandanteNome: jogo.mandantePrevisto,
          visitanteKey: TeamNormalizer.key(jogo.visitantePrevisto),
          visitanteNome: jogo.visitantePrevisto,
          golsMandante: jogo.golsMandante!,
          golsVisitante: jogo.golsVisitante!,
        ),
      );
    }

    return calcularTabelasAPartirDePartidas(jogos: jogos, partidas: partidas);
  }

  static ConjuntoTabelasGrupo calcularTabelasPorPalpites({
    required List<Jogo> jogos,
    required List<Palpite> palpites,
  }) {
    final palpitesPorJogoId = {for (final p in palpites) p.jogoId: p};
    final partidas = <PartidaGrupoComputada>[];

    for (final jogo in jogos.where((jogo) => jogo.isFaseDeGrupos)) {
      final palpite = palpitesPorJogoId[jogo.jogoId];

      if (palpite == null || !palpite.isCompleto || jogo.grupo == null) {
        continue;
      }

      partidas.add(
        PartidaGrupoComputada(
          jogoId: jogo.jogoId,
          matchNumber: jogo.matchNumber,
          grupo: jogo.grupo!,
          mandanteKey: TeamNormalizer.key(jogo.mandantePrevisto),
          mandanteNome: jogo.mandantePrevisto,
          visitanteKey: TeamNormalizer.key(jogo.visitantePrevisto),
          visitanteNome: jogo.visitantePrevisto,
          golsMandante: palpite.golsMandante!,
          golsVisitante: palpite.golsVisitante!,
        ),
      );
    }

    return calcularTabelasAPartirDePartidas(jogos: jogos, partidas: partidas);
  }

  static ConjuntoTabelasGrupo calcularTabelasAPartirDePartidas({
    required List<Jogo> jogos,
    required List<PartidaGrupoComputada> partidas,
  }) {
    final acumuladoresPorGrupo = <String, Map<String, _AcumuladorTime>>{};
    final partidasPorGrupo = <String, List<PartidaGrupoComputada>>{};

    for (final jogo in jogos.where((jogo) => jogo.isFaseDeGrupos)) {
      final grupo = jogo.grupo;

      if (grupo == null || grupo.isEmpty) {
        continue;
      }

      final grupoKey = grupo.toUpperCase();
      final acumuladores = acumuladoresPorGrupo.putIfAbsent(grupoKey, () => {});

      _garantirTime(
        acumuladores: acumuladores,
        timeKey: TeamNormalizer.key(jogo.mandantePrevisto),
        nome: jogo.mandantePrevisto,
        grupo: grupoKey,
      );

      _garantirTime(
        acumuladores: acumuladores,
        timeKey: TeamNormalizer.key(jogo.visitantePrevisto),
        nome: jogo.visitantePrevisto,
        grupo: grupoKey,
      );
    }

    for (final partida in partidas) {
      final grupoKey = partida.grupo.toUpperCase();
      final acumuladores = acumuladoresPorGrupo.putIfAbsent(grupoKey, () => {});

      final mandante = _garantirTime(
        acumuladores: acumuladores,
        timeKey: partida.mandanteKey,
        nome: partida.mandanteNome,
        grupo: grupoKey,
      );

      final visitante = _garantirTime(
        acumuladores: acumuladores,
        timeKey: partida.visitanteKey,
        nome: partida.visitanteNome,
        grupo: grupoKey,
      );

      _aplicarResultado(
        mandante: mandante,
        visitante: visitante,
        golsMandante: partida.golsMandante,
        golsVisitante: partida.golsVisitante,
      );

      partidasPorGrupo.putIfAbsent(grupoKey, () => []).add(partida);
    }

    final tabelas = <String, TabelaGrupo>{};

    for (final entry in acumuladoresPorGrupo.entries) {
      final grupo = entry.key;
      final acumuladores = entry.value.values.toList();
      final partidasDoGrupo = partidasPorGrupo[grupo] ?? const [];

      acumuladores.sort(
        (a, b) => _compararTimes(a: a, b: b, partidasDoGrupo: partidasDoGrupo),
      );

      final linhas = <LinhaTabelaTime>[];

      for (var index = 0; index < acumuladores.length; index++) {
        linhas.add(acumuladores[index].toLinha(posicao: index + 1));
      }

      tabelas[grupo] = TabelaGrupo(
        grupo: grupo,
        linhas: linhas,
        partidasComputadas: partidasDoGrupo,
      );
    }

    final terceiros = tabelas.values
        .map((tabela) => tabela.terceiro)
        .whereType<LinhaTabelaTime>()
        .toList();

    terceiros.sort(_compararTerceiros);

    final melhoresTerceiros = terceiros
        .take(8)
        .map((linha) => linha.copyWith(classificouComoTerceiro: true))
        .toList(growable: false);

    final gruposMelhoresTerceiros = melhoresTerceiros
        .map((linha) => linha.grupo.toUpperCase())
        .toSet();

    final tabelasComClassificacao = <String, TabelaGrupo>{};

    for (final entry in tabelas.entries) {
      final linhas = entry.value.linhas
          .map((linha) {
            final classificouComoTerceiro =
                linha.posicao == 3 &&
                gruposMelhoresTerceiros.contains(linha.grupo);

            return linha.copyWith(
              classificouDireto: linha.posicao <= 2,
              classificouComoTerceiro: classificouComoTerceiro,
            );
          })
          .toList(growable: false);

      tabelasComClassificacao[entry.key] = TabelaGrupo(
        grupo: entry.value.grupo,
        linhas: linhas,
        partidasComputadas: entry.value.partidasComputadas,
      );
    }

    return ConjuntoTabelasGrupo(
      tabelasPorGrupo: tabelasComClassificacao,
      terceirosOrdenados: terceiros,
      melhoresTerceiros: melhoresTerceiros,
    );
  }

  static ChaveamentoProjetado projetarChaveamento({
    required List<Jogo> jogos,
    required ConjuntoTabelasGrupo tabelas,
    List<Palpite> palpites = const [],
    bool usarResultadosReais = false,
  }) {
    final jogosOrdenados = [...jogos]
      ..sort((a, b) => a.matchNumber.compareTo(b.matchNumber));

    final palpitesPorJogoId = {for (final p in palpites) p.jogoId: p};
    final projetados = <int, JogoProjetado>{};
    final vencedores = <int, TimeProjetado>{};
    final perdedores = <int, TimeProjetado>{};
    final gruposDeTerceirosUsados = <String>{};
    final avisos = <String>[];

    for (final jogo in jogosOrdenados.where((jogo) => jogo.isMataMata)) {
      final mandante = _resolverReferencia(
        referencia: jogo.mandanteReferencia,
        tabelas: tabelas,
        vencedores: vencedores,
        perdedores: perdedores,
        gruposDeTerceirosUsados: gruposDeTerceirosUsados,
        avisos: avisos,
      );

      final visitante = _resolverReferencia(
        referencia: jogo.visitanteReferencia,
        tabelas: tabelas,
        vencedores: vencedores,
        perdedores: perdedores,
        gruposDeTerceirosUsados: gruposDeTerceirosUsados,
        avisos: avisos,
      );

      final palpite = palpitesPorJogoId[jogo.jogoId];
      final golsMandante = usarResultadosReais
          ? jogo.golsMandante
          : palpite?.golsMandante;
      final golsVisitante = usarResultadosReais
          ? jogo.golsVisitante
          : palpite?.golsVisitante;

      final jogoAvisos = <String>[];

      TimeProjetado? vencedor;
      TimeProjetado? perdedor;

      if (mandante == null || visitante == null) {
        jogoAvisos.add('Não foi possível resolver os participantes do jogo.');
      } else if (golsMandante == null || golsVisitante == null) {
        jogoAvisos.add('Jogo sem placar para projetar vencedor.');
      } else if (golsMandante > golsVisitante) {
        vencedor = mandante;
        perdedor = visitante;
      } else if (golsVisitante > golsMandante) {
        vencedor = visitante;
        perdedor = mandante;
      } else {
        final vencedorPorCampo = usarResultadosReais
            ? _resolverVencedorCampo(jogo.vencedor, mandante, visitante)
            : null;

        if (vencedorPorCampo != null) {
          vencedor = vencedorPorCampo;
          perdedor = vencedor.timeKey == mandante.timeKey
              ? visitante
              : mandante;
        } else {
          jogoAvisos.add(
            'Placar empatado sem vencedor por pênaltis; não é possível avançar chave.',
          );
        }
      }

      final projetado = JogoProjetado(
        jogoId: jogo.jogoId,
        matchNumber: jogo.matchNumber,
        faseCodigo: jogo.faseCodigo,
        mandante: mandante,
        visitante: visitante,
        palpiteUsado: palpite,
        golsMandante: golsMandante,
        golsVisitante: golsVisitante,
        vencedor: vencedor,
        perdedor: perdedor,
        avisos: jogoAvisos,
      );

      projetados[jogo.matchNumber] = projetado;

      if (vencedor != null) {
        vencedores[jogo.matchNumber] = vencedor;
      }

      if (perdedor != null) {
        perdedores[jogo.matchNumber] = perdedor;
      }
    }

    final finalProjetada = projetados[104];
    final terceiroProjetado = projetados[103];

    final resultadoFinal = ResultadoFinalTorneio(
      campeao: finalProjetada?.vencedor,
      vice: finalProjetada?.perdedor,
      terceiro: terceiroProjetado?.vencedor,
      quarto: terceiroProjetado?.perdedor,
    );

    for (final jogo in projetados.values) {
      avisos.addAll(jogo.avisos.map((aviso) => 'M${jogo.matchNumber}: $aviso'));
    }

    return ChaveamentoProjetado(
      jogosPorMatchNumber: projetados,
      resultadoFinal: resultadoFinal,
      avisos: avisos,
    );
  }

  static _AcumuladorTime _garantirTime({
    required Map<String, _AcumuladorTime> acumuladores,
    required String timeKey,
    required String nome,
    required String grupo,
  }) {
    return acumuladores.putIfAbsent(
      timeKey,
      () => _AcumuladorTime(timeKey: timeKey, nome: nome, grupo: grupo),
    );
  }

  static void _aplicarResultado({
    required _AcumuladorTime mandante,
    required _AcumuladorTime visitante,
    required int golsMandante,
    required int golsVisitante,
  }) {
    mandante.jogos++;
    visitante.jogos++;

    mandante.golsPro += golsMandante;
    mandante.golsContra += golsVisitante;

    visitante.golsPro += golsVisitante;
    visitante.golsContra += golsMandante;

    if (golsMandante > golsVisitante) {
      mandante.vitorias++;
      visitante.derrotas++;
      mandante.pontos += 3;
    } else if (golsVisitante > golsMandante) {
      visitante.vitorias++;
      mandante.derrotas++;
      visitante.pontos += 3;
    } else {
      mandante.empates++;
      visitante.empates++;
      mandante.pontos += 1;
      visitante.pontos += 1;
    }
  }

  static int _compararTimes({
    required _AcumuladorTime a,
    required _AcumuladorTime b,
    required List<PartidaGrupoComputada> partidasDoGrupo,
  }) {
    // FIFA World Cup 2026, art. 13:
    // pontos gerais; entre os empatados, confronto direto (pontos, saldo e
    // gols); depois saldo geral, gols gerais e fair play.
    final pontosGerais = b.pontos.compareTo(a.pontos);
    if (pontosGerais != 0) {
      return pontosGerais;
    }

    final confrontoDireto = _compararHeadToHead(a, b, partidasDoGrupo);
    if (confrontoDireto != 0) {
      return confrontoDireto;
    }

    final saldoGeral = b.saldoGols.compareTo(a.saldoGols);
    if (saldoGeral != 0) {
      return saldoGeral;
    }

    final golsGerais = b.golsPro.compareTo(a.golsPro);
    if (golsGerais != 0) {
      return golsGerais;
    }

    final fairPlay = b.fairPlayPontos.compareTo(a.fairPlayPontos);
    if (fairPlay != 0) {
      return fairPlay;
    }

    // A base ainda não armazena o histórico do ranking FIFA. O nome é usado
    // somente como fallback determinístico caso todos os dados disponíveis
    // permaneçam empatados.
    return a.nome.compareTo(b.nome);
  }

  static int _compararHeadToHead(
    _AcumuladorTime a,
    _AcumuladorTime b,
    List<PartidaGrupoComputada> partidasDoGrupo,
  ) {
    final confrontos = partidasDoGrupo.where((partida) {
      return partida.envolve(a.timeKey) && partida.envolve(b.timeKey);
    }).toList();

    if (confrontos.isEmpty) {
      return 0;
    }

    var pontosA = 0;
    var pontosB = 0;
    var golsA = 0;
    var golsB = 0;

    for (final partida in confrontos) {
      pontosA += partida.pontos(a.timeKey);
      pontosB += partida.pontos(b.timeKey);
      golsA += partida.golsPro(a.timeKey);
      golsB += partida.golsPro(b.timeKey);
    }

    final pontos = pontosB.compareTo(pontosA);
    if (pontos != 0) return pontos;

    final saldoA = golsA - golsB;
    final saldoB = golsB - golsA;
    final saldo = saldoB.compareTo(saldoA);
    if (saldo != 0) return saldo;

    return golsB.compareTo(golsA);
  }

  static int _compararTerceiros(LinhaTabelaTime a, LinhaTabelaTime b) {
    final pontos = b.pontos.compareTo(a.pontos);
    if (pontos != 0) return pontos;

    final saldo = b.saldoGols.compareTo(a.saldoGols);
    if (saldo != 0) return saldo;

    final golsPro = b.golsPro.compareTo(a.golsPro);
    if (golsPro != 0) return golsPro;

    final fairPlay = b.fairPlayPontos.compareTo(a.fairPlayPontos);
    if (fairPlay != 0) return fairPlay;

    return a.nome.compareTo(b.nome);
  }

  static TimeProjetado? _resolverReferencia({
    required ReferenciaParticipanteJogo referencia,
    required ConjuntoTabelasGrupo tabelas,
    required Map<int, TimeProjetado> vencedores,
    required Map<int, TimeProjetado> perdedores,
    required Set<String> gruposDeTerceirosUsados,
    required List<String> avisos,
  }) {
    if (referencia.isTime) {
      final nome = referencia.nomeFonte ?? referencia.descricao;
      final key = referencia.timeKey ?? TeamNormalizer.key(nome);

      return TimeProjetado(
        timeKey: key,
        nome: nome,
        grupo: referencia.grupo,
        posicaoGrupo: referencia.posicao,
        origem: 'time',
      );
    }

    if (referencia.isPosicaoGrupo &&
        referencia.grupo != null &&
        referencia.posicao != null) {
      final linha = tabelas.timePorGrupoPosicao(
        referencia.grupo!,
        referencia.posicao!,
      );

      return linha?.toTimeProjetado();
    }

    if (referencia.isMelhorTerceiro) {
      for (final terceiro in tabelas.melhoresTerceiros) {
        final grupo = terceiro.grupo.toUpperCase();

        if (!referencia.gruposElegiveis.contains(grupo)) {
          continue;
        }

        if (gruposDeTerceirosUsados.contains(grupo)) {
          continue;
        }

        gruposDeTerceirosUsados.add(grupo);
        return terceiro.toTimeProjetado();
      }

      avisos.add(
        'Não foi possível resolver melhor terceiro para ${referencia.descricao}.',
      );
      return null;
    }

    if (referencia.isVencedorJogo && referencia.matchNumberReferencia != null) {
      return vencedores[referencia.matchNumberReferencia!];
    }

    if (referencia.isPerdedorJogo && referencia.matchNumberReferencia != null) {
      return perdedores[referencia.matchNumberReferencia!];
    }

    avisos.add('Referência não resolvida: ${referencia.descricao}.');
    return null;
  }

  static TimeProjetado? _resolverVencedorCampo(
    String? vencedor,
    TimeProjetado mandante,
    TimeProjetado visitante,
  ) {
    if (vencedor == null || vencedor.isEmpty) {
      return null;
    }

    final vencedorKey = TeamNormalizer.key(vencedor);

    if (vencedorKey == mandante.timeKey) {
      return mandante;
    }

    if (vencedorKey == visitante.timeKey) {
      return visitante;
    }

    return null;
  }
}
