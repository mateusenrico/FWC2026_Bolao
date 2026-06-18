import '../core/functions/json_utils.dart';

class LigaSportsDb {
  final String idLeague;
  final String nome;
  final String? badgeUrl;
  final String? logoUrl;
  final String? posterUrl;
  final String? bannerUrl;
  final String? fanartUrl;
  final String? youtubeUrl;
  final Map<String, dynamic> raw;

  const LigaSportsDb({
    required this.idLeague,
    required this.nome,
    required this.badgeUrl,
    required this.logoUrl,
    required this.posterUrl,
    required this.bannerUrl,
    required this.fanartUrl,
    required this.youtubeUrl,
    required this.raw,
  });

  factory LigaSportsDb.fromJson(Map<String, dynamic> json) {
    return LigaSportsDb(
      idLeague: JsonUtils.stringValue(json, 'idLeague', fallback: '4429'),
      nome: JsonUtils.stringValue(json, 'nome', fallback: 'FIFA World Cup'),
      badgeUrl: JsonUtils.nullableString(json, 'badgeUrl'),
      logoUrl: JsonUtils.nullableString(json, 'logoUrl'),
      posterUrl: JsonUtils.nullableString(json, 'posterUrl'),
      bannerUrl: JsonUtils.nullableString(json, 'bannerUrl'),
      fanartUrl: JsonUtils.nullableString(json, 'fanartUrl'),
      youtubeUrl: JsonUtils.nullableString(json, 'youtubeUrl'),
      raw: JsonUtils.mapValue(json, 'raw'),
    );
  }

  String? get melhorImagem {
    return fanartUrl ?? posterUrl ?? bannerUrl ?? logoUrl ?? badgeUrl;
  }

  Map<String, dynamic> toJson() {
    return {
      'idLeague': idLeague,
      'nome': nome,
      'badgeUrl': badgeUrl,
      'logoUrl': logoUrl,
      'posterUrl': posterUrl,
      'bannerUrl': bannerUrl,
      'fanartUrl': fanartUrl,
      'youtubeUrl': youtubeUrl,
      'raw': raw,
    };
  }
}
