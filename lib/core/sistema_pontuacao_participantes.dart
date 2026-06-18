import '../models/bolao_data.dart';
import '../models/jogo.dart';
import '../models/palpite.dart';
import '../models/participante.dart';
import 'sistema_palpites.dart';
import 'sistema_pontuacao_times.dart';

class PontuacaoGrupoParticipante {
  final String participanteId;
  final String grupo;

  final String? primeiroRealKey;
  final String? primeiroRealNome;
  final String? segundoRealKey;
  final String? segundoRealNome;

  final String? primeiroPrevistoKey;
  final String? primeiroPrevistoNome;
  final String? segundoPrevistoKey;
  final String? segundoPrevistoNome;

  final bool grupoPontuavel;
  final bool ordemExata;
  final bool ordemInversa;
  final int pontos;
  final String motivo;

  const PontuacaoGrupoParticipante({
    required this.participanteId,
    required this.grupo,
    required this.primeiroRealKey,
    required this.primeiroRealNome,
    required this.segundoRealKey,
    required this.segundoRealNome,
    required this.primeiroPrevistoKey,
    required this.primeiroPrevistoNome,
    required this.segundoPrevistoKey,
    required this.segundoPrevistoNome,
    required this.grupoPontuavel,
    required this.ordemExata,
    required this.ordemInversa,
    required this.pontos,
    required this.motivo,
  });

  Map<String, dynamic> toJson() {
    return {
      'participanteId': participanteId,
      'grupo': grupo,
      'primeiroRealKey': primeiroRealKey,
      'primeiroRealNome': primeiroRealNome,
      'segundoRealKey': segundoRealKey,
      'segundoRealNome': segundoRealNome,
      'primeiroPrevistoKey': primeiroPrevistoKey,
      'primeiroPrevistoNome': primeiroPrevistoNome,
      'segundoPrevistoKey': segundoPrevistoKey,
      'segundoPrevistoNome': segundoPrevistoNome,
      'grupoPontuavel': grupoPontuavel,
      'ordemExata': ordemExata,
      'ordemInversa': ordemInversa,
      'pontos': pontos,
      'motivo': motivo,
    };
  }
}

class PontuacaoFinalParticipante {
  final String participanteId;

  final String? campeaoRealKey;
  final String? campeaoRealNome;
  final String? viceRealKey;
  final String? viceRealNome;
  final String? terceiroRealKey;
  final String? terceiroRealNome;
  final String? quartoRealKey;
  final String? quartoRealNome;

  final String? campeaoPrevistoKey;
  final String? campeaoPrevistoNome;
  final String? vicePrevistoKey;
  final String? vicePrevistoNome;
  final String? terceiroPrevistoKey;
  final String? terceiroPrevistoNome;
  final String? quartoPrevistoKey;
  final String? quartoPrevistoNome;

  final int pontosCampeao;
  final int pontosVice;
  final int pontosTerceiro;
  final int pontosQuarto;
  final List<String> avisos;

  const PontuacaoFinalParticipante({
    required this.participanteId,
    required this.campeaoRealKey,
    required this.campeaoRealNome,
    required this.viceRealKey,
    required this.viceRealNome,
    required this.terceiroRealKey,
    required this.terceiroRealNome,
    required this.quartoRealKey,
    required this.quartoRealNome,
    required this.campeaoPrevistoKey,
    required this.campeaoPrevistoNome,
    required this.vicePrevistoKey,
    required this.vicePrevistoNome,
    required this.terceiroPrevistoKey,
    required this.terceiroPrevistoNome,
    required this.quartoPrevistoKey,
    required this.quartoPrevistoNome,
    required this.pontosCampeao,
    required this.pontosVice,
    required this.pontosTerceiro,
    required this.pontosQuarto,
    required this.avisos,
  });

  int get pontos => pontosCampeao + pontosVice + pontosTerceiro + pontosQuarto;

  Map<String, dynamic> toJson() {
    return {
      'participanteId': participanteId,
      'campeaoRealKey': campeaoRealKey,
      'campeaoRealNome': campeaoRealNome,
      'viceRealKey': viceRealKey,
      'viceRealNome': viceRealNome,
      'terceiroRealKey': terceiroRealKey,
      'terceiroRealNome': terceiroRealNome,
      'quartoRealKey': quartoRealKey,
      'quartoRealNome': quartoRealNome,
      'campeaoPrevistoKey': campeaoPrevistoKey,
      'campeaoPrevistoNome': campeaoPrevistoNome,
      'vicePrevistoKey': vicePrevistoKey,
      'vicePrevistoNome': vicePrevistoNome,
      'terceiroPrevistoKey': terceiroPrevistoKey,
      'terceiroPrevistoNome': terceiroPrevistoNome,
      'quartoPrevistoKey': quartoPrevistoKey,
      'quartoPrevistoNome': quartoPrevistoNome,
      'pontosCampeao': pontosCampeao,
      'pontosVice': pontosVice,
      'pontosTerceiro': pontosTerceiro,
      'pontosQuarto': pontosQuarto,
      'pontos': pontos,
      'avisos': avisos,
    };
  }
}

class LinhaPontuacaoParticipante {
  final int posicao;
  final String participanteId;
  final String nome;

  final int pontosTotal;
  final int pontosJogos;
  final int pontosGrupos;
  final int pontosFinal;

  final int palpitesPontuaveis;
  final int placaresExatos;
  final int resultadosCorretos;
  final int palpitesComTresPontos;
  final int palpitesComDoisPontos;
  final int palpitesComUmPonto;

  final List<PontuacaoPalpite> pontuacoesPalpites;
  final List<PontuacaoGrupoParticipante> pontuacoesGrupos;
  final PontuacaoFinalParticipante pontuacaoFinal;
  final ChaveamentoProjetado chaveamentoPrevisto;

  const LinhaPontuacaoParticipante({
    required this.posicao,
    required this.participanteId,
    required this.nome,
    required this.pontosTotal,
    required this.pontosJogos,
    required this.pontosGrupos,
    required this.pontosFinal,
    required this.palpitesPontuaveis,
    required this.placaresExatos,
    required this.resultadosCorretos,
    required this.palpitesComTresPontos,
    required this.palpitesComDoisPontos,
    required this.palpitesComUmPonto,
    required this.pontuacoesPalpites,
    required this.pontuacoesGrupos,
    required this.pontuacaoFinal,
    required this.chaveamentoPrevisto,
  });

  LinhaPontuacaoParticipante copyWith({required int posicao}) {
    return LinhaPontuacaoParticipante(
      posicao: posicao,
      participanteId: participanteId,
      nome: nome,
      pontosTotal: pontosTotal,
      pontosJogos: pontosJogos,
      pontosGrupos: pontosGrupos,
      pontosFinal: pontosFinal,
      palpitesPontuaveis: palpitesPontuaveis,
      placaresExatos: placaresExatos,
      resultadosCorretos: resultadosCorretos,
      palpitesComTresPontos: palpitesComTresPontos,
      palpitesComDoisPontos: palpitesComDoisPontos,
      palpitesComUmPonto: palpitesComUmPonto,
      pontuacoesPalpites: pontuacoesPalpites,
      pontuacoesGrupos: pontuacoesGrupos,
      pontuacaoFinal: pontuacaoFinal,
      chaveamentoPrevisto: chaveamentoPrevisto,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'posicao': posicao,
      'participanteId': participanteId,
      'nome': nome,
      'pontosTotal': pontosTotal,
      'pontosJogos': pontosJogos,
      'pontosGrupos': pontosGrupos,
      'pontosFinal': pontosFinal,
      'palpitesPontuaveis': palpitesPontuaveis,
      'placaresExatos': placaresExatos,
      'resultadosCorretos': resultadosCorretos,
      'palpitesComTresPontos': palpitesComTresPontos,
      'palpitesComDoisPontos': palpitesComDoisPontos,
      'palpitesComUmPonto': palpitesComUmPonto,
      'pontuacoesGrupos': pontuacoesGrupos.map((e) => e.toJson()).toList(),
      'pontuacaoFinal': pontuacaoFinal.toJson(),
    };
  }
}

class SistemaPontuacaoParticipantes {
  const SistemaPontuacaoParticipantes._();

  static List<LinhaPontuacaoParticipante> calcularClassificacao(
    BolaoData data,
  ) {
    final tabelaReal = SistemaPontuacaoTimes.calcularTabelasReais(data.jogos);
    final chaveamentoReal = SistemaPontuacaoTimes.projetarChaveamento(
      jogos: data.jogos,
      tabelas: tabelaReal,
      usarResultadosReais: true,
    );

    final linhas = <LinhaPontuacaoParticipante>[];

    for (final participante in data.participantes) {
      final palpites = data.palpitesDoParticipante(participante.participanteId);

      linhas.add(
        calcularPontuacaoParticipante(
          participante: participante,
          jogos: data.jogos,
          palpites: palpites,
          tabelaReal: tabelaReal,
          chaveamentoReal: chaveamentoReal,
        ),
      );
    }

    linhas.sort(_compararLinhas);

    return [
      for (var index = 0; index < linhas.length; index++)
        linhas[index].copyWith(posicao: index + 1),
    ];
  }

  static LinhaPontuacaoParticipante calcularPontuacaoParticipante({
    required Participante participante,
    required List<Jogo> jogos,
    required List<Palpite> palpites,
    required ConjuntoTabelasGrupo tabelaReal,
    required ChaveamentoProjetado chaveamentoReal,
  }) {
    final pontuacoesPalpites = SistemaPalpites.calcularPontuacoes(
      jogos: jogos,
      palpites: palpites,
    );

    final pontuacoesPontuaveis = pontuacoesPalpites
        .where((pontuacao) => pontuacao.pontuavel)
        .toList(growable: false);

    final pontosJogos = pontuacoesPontuaveis.fold<int>(
      0,
      (total, pontuacao) => total + pontuacao.pontos,
    );

    final placaresExatos = pontuacoesPontuaveis
        .where((p) => p.placarExato)
        .length;
    final resultadosCorretos = pontuacoesPontuaveis
        .where((p) => p.resultadoCorreto)
        .length;
    final palpitesComTresPontos = pontuacoesPontuaveis
        .where((p) => p.pontos == 3)
        .length;
    final palpitesComDoisPontos = pontuacoesPontuaveis
        .where((p) => p.pontos == 2)
        .length;
    final palpitesComUmPonto = pontuacoesPontuaveis
        .where((p) => p.pontos == 1)
        .length;

    final tabelaPrevista = SistemaPontuacaoTimes.calcularTabelasPorPalpites(
      jogos: jogos,
      palpites: palpites,
    );

    final pontuacoesGrupos = calcularPontuacoesGrupos(
      participanteId: participante.participanteId,
      tabelaReal: tabelaReal,
      tabelaPrevista: tabelaPrevista,
    );

    final pontosGrupos = pontuacoesGrupos.fold<int>(
      0,
      (total, pontuacao) => total + pontuacao.pontos,
    );

    final chaveamentoPrevisto = SistemaPontuacaoTimes.projetarChaveamento(
      jogos: jogos,
      tabelas: tabelaPrevista,
      palpites: palpites,
      usarResultadosReais: false,
    );

    final pontuacaoFinal = calcularPontuacaoFinal(
      participanteId: participante.participanteId,
      real: chaveamentoReal.resultadoFinal,
      previsto: chaveamentoPrevisto.resultadoFinal,
      avisosPrevisao: chaveamentoPrevisto.avisos,
    );

    final pontosFinal = pontuacaoFinal.pontos;
    final pontosTotal = pontosJogos + pontosGrupos + pontosFinal;

    return LinhaPontuacaoParticipante(
      posicao: 0,
      participanteId: participante.participanteId,
      nome: participante.nome,
      pontosTotal: pontosTotal,
      pontosJogos: pontosJogos,
      pontosGrupos: pontosGrupos,
      pontosFinal: pontosFinal,
      palpitesPontuaveis: pontuacoesPontuaveis.length,
      placaresExatos: placaresExatos,
      resultadosCorretos: resultadosCorretos,
      palpitesComTresPontos: palpitesComTresPontos,
      palpitesComDoisPontos: palpitesComDoisPontos,
      palpitesComUmPonto: palpitesComUmPonto,
      pontuacoesPalpites: pontuacoesPalpites,
      pontuacoesGrupos: pontuacoesGrupos,
      pontuacaoFinal: pontuacaoFinal,
      chaveamentoPrevisto: chaveamentoPrevisto,
    );
  }

  static List<PontuacaoGrupoParticipante> calcularPontuacoesGrupos({
    required String participanteId,
    required ConjuntoTabelasGrupo tabelaReal,
    required ConjuntoTabelasGrupo tabelaPrevista,
  }) {
    final result = <PontuacaoGrupoParticipante>[];
    final grupos = tabelaReal.tabelasPorGrupo.keys.toList()..sort();

    for (final grupo in grupos) {
      final real = tabelaReal.tabela(grupo);
      final prevista = tabelaPrevista.tabela(grupo);

      final primeiroReal = real?.primeiro;
      final segundoReal = real?.segundo;
      final primeiroPrevisto = prevista?.primeiro;
      final segundoPrevisto = prevista?.segundo;

      final grupoPontuavel =
          real?.grupoCompleto == true &&
          primeiroReal != null &&
          segundoReal != null &&
          primeiroPrevisto != null &&
          segundoPrevisto != null;

      var pontos = 0;
      var ordemExata = false;
      var ordemInversa = false;
      var motivo = 'Grupo ainda não pontuável.';

      if (grupoPontuavel) {
        ordemExata =
            primeiroReal.timeKey == primeiroPrevisto.timeKey &&
            segundoReal.timeKey == segundoPrevisto.timeKey;

        ordemInversa =
            primeiroReal.timeKey == segundoPrevisto.timeKey &&
            segundoReal.timeKey == primeiroPrevisto.timeKey;

        if (ordemExata) {
          pontos = 5;
          motivo = '1º e 2º colocados corretos na ordem exata.';
        } else if (ordemInversa) {
          pontos = 3;
          motivo = '1º e 2º colocados corretos na ordem inversa.';
        } else {
          motivo = 'Não acertou 1º e 2º do grupo.';
        }
      }

      result.add(
        PontuacaoGrupoParticipante(
          participanteId: participanteId,
          grupo: grupo,
          primeiroRealKey: primeiroReal?.timeKey,
          primeiroRealNome: primeiroReal?.nome,
          segundoRealKey: segundoReal?.timeKey,
          segundoRealNome: segundoReal?.nome,
          primeiroPrevistoKey: primeiroPrevisto?.timeKey,
          primeiroPrevistoNome: primeiroPrevisto?.nome,
          segundoPrevistoKey: segundoPrevisto?.timeKey,
          segundoPrevistoNome: segundoPrevisto?.nome,
          grupoPontuavel: grupoPontuavel,
          ordemExata: ordemExata,
          ordemInversa: ordemInversa,
          pontos: pontos,
          motivo: motivo,
        ),
      );
    }

    return result;
  }

  static PontuacaoFinalParticipante calcularPontuacaoFinal({
    required String participanteId,
    required ResultadoFinalTorneio real,
    required ResultadoFinalTorneio previsto,
    required List<String> avisosPrevisao,
  }) {
    final pontosCampeao = _mesmoTime(real.campeao, previsto.campeao) ? 15 : 0;
    final pontosVice = _mesmoTime(real.vice, previsto.vice) ? 10 : 0;
    final pontosTerceiro = _mesmoTime(real.terceiro, previsto.terceiro) ? 7 : 0;
    final pontosQuarto = _mesmoTime(real.quarto, previsto.quarto) ? 4 : 0;

    return PontuacaoFinalParticipante(
      participanteId: participanteId,
      campeaoRealKey: real.campeao?.timeKey,
      campeaoRealNome: real.campeao?.nome,
      viceRealKey: real.vice?.timeKey,
      viceRealNome: real.vice?.nome,
      terceiroRealKey: real.terceiro?.timeKey,
      terceiroRealNome: real.terceiro?.nome,
      quartoRealKey: real.quarto?.timeKey,
      quartoRealNome: real.quarto?.nome,
      campeaoPrevistoKey: previsto.campeao?.timeKey,
      campeaoPrevistoNome: previsto.campeao?.nome,
      vicePrevistoKey: previsto.vice?.timeKey,
      vicePrevistoNome: previsto.vice?.nome,
      terceiroPrevistoKey: previsto.terceiro?.timeKey,
      terceiroPrevistoNome: previsto.terceiro?.nome,
      quartoPrevistoKey: previsto.quarto?.timeKey,
      quartoPrevistoNome: previsto.quarto?.nome,
      pontosCampeao: pontosCampeao,
      pontosVice: pontosVice,
      pontosTerceiro: pontosTerceiro,
      pontosQuarto: pontosQuarto,
      avisos: avisosPrevisao,
    );
  }

  static int _compararLinhas(
    LinhaPontuacaoParticipante a,
    LinhaPontuacaoParticipante b,
  ) {
    final pontos = b.pontosTotal.compareTo(a.pontosTotal);
    if (pontos != 0) return pontos;

    final exatos = b.placaresExatos.compareTo(a.placaresExatos);
    if (exatos != 0) return exatos;

    final resultados = b.resultadosCorretos.compareTo(a.resultadosCorretos);
    if (resultados != 0) return resultados;

    return a.nome.compareTo(b.nome);
  }

  static bool _mesmoTime(TimeProjetado? a, TimeProjetado? b) {
    if (a == null || b == null) {
      return false;
    }

    return a.timeKey == b.timeKey;
  }
}
