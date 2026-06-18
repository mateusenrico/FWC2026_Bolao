import '../../models/jogo.dart';

class AppDateTime {
  const AppDateTime._();

  static const Duration brasiliaOffset = Duration(hours: 3);

  static DateTime agoraBrasilia() {
    return DateTime.now().toUtc().subtract(brasiliaOffset);
  }

  static DateTime? horarioBrasilia(Jogo jogo) {
    final utc = jogo.dataUtc;

    if (utc != null) {
      return utc.toUtc().subtract(brasiliaOffset);
    }

    final parsed = DateTime.tryParse(jogo.dataLocal);
    if (parsed == null) {
      return null;
    }

    if (parsed.isUtc || parsed.timeZoneOffset != Duration.zero) {
      return parsed.toUtc().subtract(brasiliaOffset);
    }

    return parsed;
  }

  static bool mesmoDia(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static DateTime inicioDoDia(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  static DateTime fimDoDia(DateTime value) {
    return DateTime(value.year, value.month, value.day, 23, 59, 59, 999);
  }

  static String dataCurta(DateTime? value) {
    if (value == null) {
      return '--/--';
    }

    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month';
  }

  static String dataCompleta(DateTime? value) {
    if (value == null) {
      return '--/--/----';
    }

    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }

  static String horario(DateTime? value) {
    if (value == null) {
      return '--:--';
    }

    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static String diaSemana(DateTime? value) {
    if (value == null) {
      return '';
    }

    const weekdays = [
      'segunda',
      'terça',
      'quarta',
      'quinta',
      'sexta',
      'sábado',
      'domingo',
    ];

    return weekdays[value.weekday - 1];
  }

  static String dataHoraBrasilia(Jogo jogo) {
    final date = horarioBrasilia(jogo);
    if (date == null) {
      return '${jogo.diaLocalTexto} · ${jogo.horaLocal}';
    }

    return '${diaSemana(date)}, ${dataCompleta(date)} · ${horario(date)} (UTC-3)';
  }
}
