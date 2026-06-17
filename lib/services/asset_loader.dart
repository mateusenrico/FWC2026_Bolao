import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/bolao_data.dart';
import '../models/historico_partida.dart';
import '../models/jogo.dart';
import '../models/palpite.dart';
import '../models/participante.dart';
import '../models/time_participante.dart';

class AssetLoader {
  const AssetLoader._();

  static Future<BolaoData> carregarBolaoData() async {
    final jogos = await carregarJogos();
    final historicoPartidas = await carregarHistoricoPartidas();
    final participantes = await carregarParticipantes();
    final palpites = await carregarPalpites();
    final timesParticipantes = await carregarTimesParticipantes();

    return BolaoData(
      jogos: jogos,
      historicoPartidas: historicoPartidas,
      participantes: participantes,
      palpites: palpites,
      timesParticipantes: timesParticipantes,
    );
  }

  static Future<List<Jogo>> carregarJogos() async {
    final jsonList = await _loadJsonList('assets/data/jogos.json');

    return jsonList.map((item) => Jogo.fromJson(item)).toList(growable: false);
  }

  static Future<List<HistoricoPartida>> carregarHistoricoPartidas() async {
    final jsonList = await _loadJsonList('assets/data/historico_partidas.json');

    return jsonList
        .map((item) => HistoricoPartida.fromJson(item))
        .toList(growable: false);
  }

  static Future<List<Participante>> carregarParticipantes() async {
    final jsonList = await _loadJsonList('assets/data/participantes.json');

    return jsonList
        .map((item) => Participante.fromJson(item))
        .toList(growable: false);
  }

  static Future<List<Palpite>> carregarPalpites() async {
    final jsonList = await _loadJsonList('assets/data/palpites.json');

    return jsonList
        .map((item) => Palpite.fromJson(item))
        .toList(growable: false);
  }

  static Future<List<TimeParticipante>> carregarTimesParticipantes() async {
    final jsonList = await _loadJsonList(
      'assets/data/times_participantes.json',
    );

    return jsonList
        .map((item) => TimeParticipante.fromJson(item))
        .toList(growable: false);
  }

  static Future<List<Map<String, dynamic>>> _loadJsonList(
    String assetPath,
  ) async {
    final raw = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(raw);

    if (decoded is! List) {
      throw FormatException(
        'O asset $assetPath deveria conter uma lista JSON na raiz.',
      );
    }

    return decoded
        .map((item) {
          if (item is Map<String, dynamic>) {
            return item;
          }

          if (item is Map) {
            return Map<String, dynamic>.from(item);
          }

          throw FormatException(
            'Item inválido em $assetPath. Esperado objeto JSON, recebido: ${item.runtimeType}',
          );
        })
        .toList(growable: false);
  }
}
