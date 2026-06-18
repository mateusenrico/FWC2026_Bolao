import '../core/json_utils.dart';

class Palpite {
  final String palpiteId;
  final String participanteId;
  final String jogoId;

  final int? golsMandante;
  final int? golsVisitante;

  const Palpite({
    required this.palpiteId,
    required this.participanteId,
    required this.jogoId,
    required this.golsMandante,
    required this.golsVisitante,
  });

  factory Palpite.fromJson(Map<String, dynamic> json) {
    return Palpite(
      palpiteId: JsonUtils.stringValue(json, 'palpiteId'),
      participanteId: JsonUtils.stringValue(json, 'participanteId'),
      jogoId: JsonUtils.stringValue(json, 'jogoId'),
      golsMandante: JsonUtils.nullableInt(json, 'golsMandante'),
      golsVisitante: JsonUtils.nullableInt(json, 'golsVisitante'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'palpiteId': palpiteId,
      'participanteId': participanteId,
      'jogoId': jogoId,
      'golsMandante': golsMandante,
      'golsVisitante': golsVisitante,
    };
  }

  bool get isCompleto {
    return golsMandante != null && golsVisitante != null;
  }

  bool get isVazio {
    return golsMandante == null && golsVisitante == null;
  }

  bool get isIncompleto {
    return !isCompleto && !isVazio;
  }

  String get placarTexto {
    if (isVazio) {
      return '-';
    }

    final mandante = golsMandante?.toString() ?? '?';
    final visitante = golsVisitante?.toString() ?? '?';

    return '$mandante x $visitante';
  }
}
