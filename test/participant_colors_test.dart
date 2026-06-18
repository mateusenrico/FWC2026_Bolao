import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fwc2026_bolao/core/functions/participant_colors.dart';
import 'package:fwc2026_bolao/models/participante.dart';

void main() {
  group('ParticipantColors', () {
    test('parseHex aceita RGB com # e injeta alpha opaco', () {
      expect(ParticipantColors.parseHex('#35A7FF'), const Color(0xFF35A7FF));
    });

    test('resolve usa cor configurada antes do fallback', () {
      expect(
        ParticipantColors.resolve(
          participanteId: 'participante',
          index: 0,
          corHex: '#FF0B6D',
        ),
        const Color(0xFFFF0B6D),
      );
    });

    test('resolve mantém fallback estável por participante', () {
      final first = ParticipantColors.resolve(
        participanteId: 'participante',
        index: 2,
      );
      final second = ParticipantColors.resolve(
        participanteId: 'participante',
        index: 2,
      );

      expect(first, second);
    });

    test('mapFromParticipantes preserva cores configuradas', () {
      final colors = ParticipantColors.mapFromParticipantes([
        _participante('ana', 'Ana', '#35A7FF'),
        _participante('bia', 'Bia', '#FF0B6D'),
      ]);

      expect(colors['ana'], const Color(0xFF35A7FF));
      expect(colors['bia'], const Color(0xFFFF0B6D));
    });
  });
}

Participante _participante(String id, String nome, String corHex) {
  return Participante(
    participanteId: id,
    nome: nome,
    corHex: corHex,
    jogosPalpitados: 0,
    jogosSemPalpite: 0,
    jogosPalpitadosFaseGrupos: 0,
    jogosSemPalpiteFaseGrupos: 0,
    totalJogosPrevistos: 0,
    totalJogosFaseGrupos: 0,
  );
}
