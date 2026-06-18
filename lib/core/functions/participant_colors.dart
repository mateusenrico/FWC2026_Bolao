import 'package:flutter/material.dart';

import '../../models/participante.dart';

class ParticipantColors {
  const ParticipantColors._();

  static const fallbackPalette = [
    Color(0xFF0072B2),
    Color(0xFFD81B60),
    Color(0xFF00A896),
    Color(0xFFE85D04),
    Color(0xFF9ACD00),
    Color(0xFF6C63FF),
    Color(0xFF2B2D42),
    Color(0xFF008000),
    Color(0xFFE60012),
    Color(0xFFFDC500),
    Color(0xFFFB8500),
    Color(0xFF7209B7),
    Color(0xFF8A8F98),
  ];

  static Color resolve({
    required String participanteId,
    required int index,
    String? corHex,
  }) {
    final fallbackIndex = participanteId.codeUnits.fold<int>(
      index,
      (hash, charCode) => 0x1fffffff & (hash * 31 + charCode),
    );

    return parseHex(corHex) ??
        fallbackPalette[fallbackIndex % fallbackPalette.length];
  }

  static Color? parseHex(String? value) {
    final raw = value?.trim();
    if (raw == null || raw.isEmpty) {
      return null;
    }

    final normalized = raw.startsWith('#') ? raw.substring(1) : raw;
    final hex = normalized.length == 6 ? 'FF$normalized' : normalized;
    if (hex.length != 8) {
      return null;
    }

    final parsed = int.tryParse(hex, radix: 16);
    if (parsed == null) {
      return null;
    }

    return Color(parsed);
  }

  static Map<String, Color> mapFromParticipantes(
    List<Participante> participantes,
  ) {
    return {
      for (var index = 0; index < participantes.length; index++)
        participantes[index].participanteId: resolve(
          participanteId: participantes[index].participanteId,
          index: index,
          corHex: participantes[index].corHex,
        ),
    };
  }

  static Color foregroundFor(Color background) {
    return background.computeLuminance() > 0.58
        ? const Color(0xFF08090F)
        : Colors.white;
  }

  static Color softBackgroundFor(Color color, ColorScheme colors) {
    return Color.alphaBlend(
      color.withValues(
        alpha: colors.brightness == Brightness.dark ? 0.28 : 0.18,
      ),
      colors.surface,
    );
  }

  static Color medalColor(int? position) {
    return switch (position) {
      1 => const Color(0xFFFFD166),
      2 => const Color(0xFFC8D0DC),
      3 => const Color(0xFFD99058),
      _ => Colors.transparent,
    };
  }
}
