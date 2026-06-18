import 'package:flutter/material.dart';

import '../services/asset_loader.dart';

class DebugAssetsScreen extends StatefulWidget {
  const DebugAssetsScreen({super.key});

  @override
  State<DebugAssetsScreen> createState() => _DebugAssetsScreenState();
}

class _DebugAssetsScreenState extends State<DebugAssetsScreen> {
  late final Future<String> _diagnosticoFuture;

  @override
  void initState() {
    super.initState();
    _diagnosticoFuture = _carregarDiagnostico();
  }

  Future<String> _carregarDiagnostico() async {
    final data = await AssetLoader.carregarBolaoData();

    final palpitesCompletos = data.palpites
        .where((palpite) => palpite.isCompleto)
        .length;
    final palpitesVazios = data.palpites
        .where((palpite) => palpite.isVazio)
        .length;
    final palpitesIncompletos = data.palpites
        .where((palpite) => palpite.isIncompleto)
        .length;

    final jogosComHistorico = data.jogos
        .where((jogo) => jogo.temHistoricoApi)
        .length;
    final jogosComResultado = data.jogos
        .where((jogo) => jogo.temResultadoApi)
        .length;

    return '''
Assets carregados com sucesso.

Jogos: ${data.jogos.length}
Histórico/API: ${data.historicoPartidas.length}
Participantes: ${data.participantes.length}
Palpites: ${data.palpites.length}
Times participantes: ${data.timesParticipantes.length}

Palpites completos: $palpitesCompletos
Palpites vazios: $palpitesVazios
Palpites incompletos: $palpitesIncompletos

Jogos com histórico API: $jogosComHistorico
Jogos com resultado API: $jogosComResultado

Primeiro jogo:
${data.jogos.isEmpty ? '-' : data.jogos.first.confrontoPrevisto}

Primeiro participante:
${data.participantes.isEmpty ? '-' : data.participantes.first.nome}

Primeiro palpite:
${data.palpites.isEmpty ? '-' : data.palpites.first.placarTexto}
''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Debug assets')),
      body: FutureBuilder<String>(
        future: _diagnosticoFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: SelectableText(
                'Erro ao carregar assets:\n\n${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: SelectableText(
              snapshot.data ?? 'Sem dados.',
              style: const TextStyle(fontSize: 16),
            ),
          );
        },
      ),
    );
  }
}
