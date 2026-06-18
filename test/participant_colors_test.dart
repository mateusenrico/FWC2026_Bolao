import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fwc2026_bolao/core/functions/participant_colors.dart';

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
  });
}
