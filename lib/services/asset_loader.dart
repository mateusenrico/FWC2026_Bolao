import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/bolao_data.dart';
import '../models/historico_partida.dart';
import '../models/jogo.dart';
import '../models/liga_sportsdb.dart';
import '../models/palpite.dart';
import '../models/participante.dart';
import '../models/time_participante.dart';
import '../models/time_sportsdb.dart';
import '../models/venue_sportsdb.dart';

class AssetLoader {
  const AssetLoader._();

  static Future<BolaoData> carregarBolaoData() async {
    final results = await Future.wait([
      carregarJogos(),
      carregarHistoricoPartidas(),
      carregarParticipantes(),
      carregarPalpites(),
      carregarTimesParticipantes(),
      carregarTimesSportsDb(),
      carregarVenuesSportsDb(),
      carregarLigaSportsDb(),
    ]);

    final data = BolaoData(
      jogos: results[0] as List<Jogo>,
      historicoPartidas: results[1] as List<HistoricoPartida>,
      participantes: results[2] as List<Participante>,
      palpites: results[3] as List<Palpite>,
      timesParticipantes: results[4] as List<TimeParticipante>,
      timesSportsDb: results[5] as List<TimeSportsDb>,
      venuesSportsDb: results[6] as List<VenueSportsDb>,
      ligaSportsDb: results[7] as LigaSportsDb?,
    );

    _validarDados(data);

    return data;
  }

  static Future<List<Jogo>> carregarJogos() async {
    final jsonList = await _loadJsonList('assets/data/jogos.json');

    final jogos = jsonList.map(Jogo.fromJson).toList(growable: false);

    return [...jogos]..sort((a, b) => a.ordem.compareTo(b.ordem));
  }

  static Future<List<HistoricoPartida>> carregarHistoricoPartidas() async {
    final jsonList = await _loadJsonList('assets/data/historico_partidas.json');

    return jsonList.map(HistoricoPartida.fromJson).toList(growable: false);
  }

  static Future<List<Participante>> carregarParticipantes() async {
    final jsonList = await _loadJsonList('assets/data/participantes.json');

    return jsonList.map(Participante.fromJson).toList(growable: false);
  }

  static Future<List<Palpite>> carregarPalpites() async {
    final jsonList = await _loadJsonList('assets/data/palpites.json');

    return jsonList.map(Palpite.fromJson).toList(growable: false);
  }

  static Future<List<TimeParticipante>> carregarTimesParticipantes() async {
    final jsonList = await _loadJsonList(
      'assets/data/times_participantes.json',
    );

    return jsonList.map(TimeParticipante.fromJson).toList(growable: false);
  }

  static Future<List<TimeSportsDb>> carregarTimesSportsDb() async {
    final jsonList = await _loadJsonList('assets/data/times_sportsdb.json');

    return jsonList.map(TimeSportsDb.fromJson).toList(growable: false);
  }

  static Future<List<VenueSportsDb>> carregarVenuesSportsDb() async {
    final jsonList = await _loadJsonList('assets/data/venues_sportsdb.json');

    return jsonList.map(VenueSportsDb.fromJson).toList(growable: false);
  }

  static Future<LigaSportsDb?> carregarLigaSportsDb() async {
    final json = await _loadJsonObject('assets/data/liga_sportsdb.json');

    if (json.isEmpty) {
      return null;
    }

    return LigaSportsDb.fromJson(json);
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
            'Item inválido em $assetPath. '
            'Esperado objeto JSON, recebido: ${item.runtimeType}.',
          );
        })
        .toList(growable: false);
  }

  static Future<Map<String, dynamic>> _loadJsonObject(String assetPath) async {
    final raw = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(raw);

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }

    throw FormatException(
      'O asset $assetPath deveria conter um objeto JSON na raiz.',
    );
  }

  static void _validarDados(BolaoData data) {
    if (data.jogos.length != 104) {
      throw StateError(
        'jogos.json deveria ter 104 partidas, '
        'mas possui ${data.jogos.length}.',
      );
    }

    final jogoIds = data.jogos.map((jogo) => jogo.jogoId).toSet();
    final matchNumbers = data.jogos.map((jogo) => jogo.matchNumber).toSet();

    if (jogoIds.length != data.jogos.length) {
      throw StateError('Há jogoId duplicado em jogos.json.');
    }

    if (matchNumbers.length != data.jogos.length) {
      throw StateError('Há matchNumber duplicado em jogos.json.');
    }

    final palpitesInvalidos = data.palpites.where(
      (palpite) => !jogoIds.contains(palpite.jogoId),
    );

    if (palpitesInvalidos.isNotEmpty) {
      throw StateError(
        '${palpitesInvalidos.length} palpites apontam '
        'para jogoId inexistente.',
      );
    }

    final historicosInvalidos = data.historicoPartidas.where(
      (partida) => !jogoIds.contains(partida.jogoId),
    );

    if (historicosInvalidos.isNotEmpty) {
      throw StateError(
        '${historicosInvalidos.length} registros históricos '
        'apontam para jogoId inexistente.',
      );
    }
  }
}
