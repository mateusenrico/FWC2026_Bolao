class LinhaClassificacao {
  final int posicao;
  final String participanteId;
  final String nome;

  final int pontos;
  final int placaresExatos;
  final int vencedoresAcertados;
  final int saldosAcertados;
  final int palpitesComputados;

  const LinhaClassificacao({
    required this.posicao,
    required this.participanteId,
    required this.nome,
    required this.pontos,
    required this.placaresExatos,
    required this.vencedoresAcertados,
    required this.saldosAcertados,
    required this.palpitesComputados,
  });

  Map<String, dynamic> toJson() {
    return {
      'posicao': posicao,
      'participanteId': participanteId,
      'nome': nome,
      'pontos': pontos,
      'placaresExatos': placaresExatos,
      'vencedoresAcertados': vencedoresAcertados,
      'saldosAcertados': saldosAcertados,
      'palpitesComputados': palpitesComputados,
    };
  }
}
