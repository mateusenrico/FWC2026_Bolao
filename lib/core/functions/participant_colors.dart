import 'package:flutter/material.dart';

import '../app_theme.dart';

class ParticipantColors {
  const ParticipantColors._();

  static const fallbackPalette = [
    FwcColors.sky,
    FwcColors.magenta,
    FwcColors.teal,
    FwcColors.coral,
    FwcColors.lime,
    Color(0xFF9B5CFF),
    Color(0xFFFFD166),
    FwcColors.green,
    FwcColors.blue,
    Color(0xFFF72585),
    Color(0xFF38BDF8),
    Color(0xFFF97316),
    Color(0xFFF0ABFC),
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

  static Color medalColor(int? position) {
    return switch (position) {
      1 => const Color(0xFFFFD166),
      2 => const Color(0xFFC8D0DC),
      3 => const Color(0xFFD99058),
      _ => Colors.transparent,
    };
  }
}
