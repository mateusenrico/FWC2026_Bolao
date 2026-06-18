import '../core/functions/json_utils.dart';

class VenueSportsDb {
  final String venueKey;
  final String nome;
  final String? idVenue;
  final String? cidade;
  final String? pais;
  final int? capacidade;
  final String? thumbUrl;
  final String? fanartUrl;
  final String? descricao;
  final String fonte;
  final Map<String, dynamic> raw;

  const VenueSportsDb({
    required this.venueKey,
    required this.nome,
    required this.idVenue,
    required this.cidade,
    required this.pais,
    required this.capacidade,
    required this.thumbUrl,
    required this.fanartUrl,
    required this.descricao,
    required this.fonte,
    required this.raw,
  });

  factory VenueSportsDb.fromJson(Map<String, dynamic> json) {
    return VenueSportsDb(
      venueKey: JsonUtils.stringValue(json, 'venueKey'),
      nome: JsonUtils.stringValue(json, 'nome'),
      idVenue: JsonUtils.nullableString(json, 'idVenue'),
      cidade: JsonUtils.nullableString(json, 'cidade'),
      pais: JsonUtils.nullableString(json, 'pais'),
      capacidade: JsonUtils.nullableInt(json, 'capacidade'),
      thumbUrl: JsonUtils.nullableString(json, 'thumbUrl'),
      fanartUrl: JsonUtils.nullableString(json, 'fanartUrl'),
      descricao: JsonUtils.nullableString(json, 'descricao'),
      fonte: JsonUtils.stringValue(json, 'fonte', fallback: 'assets'),
      raw: JsonUtils.mapValue(json, 'raw'),
    );
  }

  String? get melhorImagem {
    return thumbUrl ?? fanartUrl;
  }

  String get localTexto {
    final partes = [
      if (cidade != null && cidade!.isNotEmpty) cidade,
      if (pais != null && pais!.isNotEmpty) pais,
    ];

    return partes.join(' · ');
  }

  Map<String, dynamic> toJson() {
    return {
      'venueKey': venueKey,
      'nome': nome,
      'idVenue': idVenue,
      'cidade': cidade,
      'pais': pais,
      'capacidade': capacidade,
      'thumbUrl': thumbUrl,
      'fanartUrl': fanartUrl,
      'descricao': descricao,
      'fonte': fonte,
      'raw': raw,
    };
  }
}
