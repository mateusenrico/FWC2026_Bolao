import '../core/functions/json_utils.dart';

class TimeSportsDb {
  final String timeKey;
  final String nomeBolao;
  final String? grupo;
  final String? idTeam;
  final String? nomeApi;
  final String? siglaApi;
  final String? pais;
  final String? badgeUrl;
  final String? logoUrl;
  final String? bannerUrl;
  final String? fanartUrl;
  final String? equipamentoUrl;
  final String? corPrimaria;
  final String? corSecundaria;
  final String? estadio;
  final String? idVenue;
  final String? descricao;
  final String fonte;
  final Map<String, dynamic> raw;

  const TimeSportsDb({
    required this.timeKey,
    required this.nomeBolao,
    required this.grupo,
    required this.idTeam,
    required this.nomeApi,
    required this.siglaApi,
    required this.pais,
    required this.badgeUrl,
    required this.logoUrl,
    required this.bannerUrl,
    required this.fanartUrl,
    required this.equipamentoUrl,
    required this.corPrimaria,
    required this.corSecundaria,
    required this.estadio,
    required this.idVenue,
    required this.descricao,
    required this.fonte,
    required this.raw,
  });

  factory TimeSportsDb.fromJson(Map<String, dynamic> json) {
    return TimeSportsDb(
      timeKey: JsonUtils.stringValue(json, 'timeKey'),
      nomeBolao: JsonUtils.stringValue(json, 'nomeBolao'),
      grupo: JsonUtils.nullableString(json, 'grupo'),
      idTeam: JsonUtils.nullableString(json, 'idTeam'),
      nomeApi: JsonUtils.nullableString(json, 'nomeApi'),
      siglaApi: JsonUtils.nullableString(json, 'siglaApi'),
      pais: JsonUtils.nullableString(json, 'pais'),
      badgeUrl: JsonUtils.nullableString(json, 'badgeUrl'),
      logoUrl: JsonUtils.nullableString(json, 'logoUrl'),
      bannerUrl: JsonUtils.nullableString(json, 'bannerUrl'),
      fanartUrl: JsonUtils.nullableString(json, 'fanartUrl'),
      equipamentoUrl: JsonUtils.nullableString(json, 'equipamentoUrl'),
      corPrimaria: JsonUtils.nullableString(json, 'corPrimaria'),
      corSecundaria: JsonUtils.nullableString(json, 'corSecundaria'),
      estadio: JsonUtils.nullableString(json, 'estadio'),
      idVenue: JsonUtils.nullableString(json, 'idVenue'),
      descricao: JsonUtils.nullableString(json, 'descricao'),
      fonte: JsonUtils.stringValue(json, 'fonte', fallback: 'assets'),
      raw: JsonUtils.mapValue(json, 'raw'),
    );
  }

  String? get melhorImagem {
    return fanartUrl ?? bannerUrl ?? logoUrl ?? badgeUrl;
  }

  Map<String, dynamic> toJson() {
    return {
      'timeKey': timeKey,
      'nomeBolao': nomeBolao,
      'grupo': grupo,
      'idTeam': idTeam,
      'nomeApi': nomeApi,
      'siglaApi': siglaApi,
      'pais': pais,
      'badgeUrl': badgeUrl,
      'logoUrl': logoUrl,
      'bannerUrl': bannerUrl,
      'fanartUrl': fanartUrl,
      'equipamentoUrl': equipamentoUrl,
      'corPrimaria': corPrimaria,
      'corSecundaria': corSecundaria,
      'estadio': estadio,
      'idVenue': idVenue,
      'descricao': descricao,
      'fonte': fonte,
      'raw': raw,
    };
  }
}
