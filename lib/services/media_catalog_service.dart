import '../core/functions/country_flag_urls.dart';
import '../core/functions/team_normalizer.dart';
import '../models/bolao_data.dart';
import '../models/jogo.dart';
import '../models/time_sportsdb.dart';
import '../models/venue_sportsdb.dart';
import 'sportsdb_api_service.dart';

class BolaoMediaCatalog {
  final Map<String, String> badgesByTeamKey;
  final Map<String, String> flagsByTeamKey;
  final Map<String, String> teamImagesByTeamKey;
  final Map<String, String> matchImagesById;
  final Map<String, String> matchBannersById;
  final Map<String, String> matchVideosById;
  final Map<String, TimeSportsDb> teamsByKey;
  final Map<String, VenueSportsDb> venuesByKey;
  final Map<String, VenueSportsDb> venuesById;
  final String? leagueImageUrl;

  const BolaoMediaCatalog({
    required this.badgesByTeamKey,
    required this.flagsByTeamKey,
    required this.teamImagesByTeamKey,
    required this.matchImagesById,
    required this.matchBannersById,
    required this.matchVideosById,
    required this.teamsByKey,
    required this.venuesByKey,
    required this.venuesById,
    required this.leagueImageUrl,
  });

  const BolaoMediaCatalog.empty()
    : badgesByTeamKey = const {},
      flagsByTeamKey = const {},
      teamImagesByTeamKey = const {},
      matchImagesById = const {},
      matchBannersById = const {},
      matchVideosById = const {},
      teamsByKey = const {},
      venuesByKey = const {},
      venuesById = const {},
      leagueImageUrl = null;

  String? badgeForTeam(String teamName) {
    return badgesByTeamKey[TeamNormalizer.key(teamName)];
  }

  String? flagForTeam(String teamName) {
    return flagsByTeamKey[TeamNormalizer.key(teamName)];
  }

  String? imageForTeam(String teamName) {
    return teamImagesByTeamKey[TeamNormalizer.key(teamName)];
  }

  String? imageForMatch(String jogoId) {
    return matchImagesById[jogoId];
  }

  String? bannerForMatch(String jogoId) {
    return matchBannersById[jogoId];
  }

  String? videoForMatch(String jogoId) {
    return matchVideosById[jogoId];
  }

  TimeSportsDb? teamForName(String teamName) {
    return teamsByKey[TeamNormalizer.key(teamName)];
  }

  VenueSportsDb? venueForMatch(BolaoData data, Jogo jogo) {
    final historico = data.historicoPorJogoId[jogo.jogoId];
    final idVenue = historico?.raw['idVenue']?.toString();

    if (idVenue != null && idVenue.isNotEmpty) {
      final byId = venuesById[idVenue];
      if (byId != null) {
        return byId;
      }
    }

    return venuesByKey[_venueKey(jogo.estadio)];
  }
}

class MediaCatalogService {
  const MediaCatalogService._();

  static BolaoMediaCatalog build({
    required BolaoData data,
    Map<String, SportsDbEvent> eventosPorJogoId = const {},
  }) {
    final badges = <String, String>{};
    final flags = <String, String>{};
    final teamImages = <String, String>{};
    final matchImages = <String, String>{};
    final matchBanners = <String, String>{};
    final matchVideos = <String, String>{};
    final teamsByKey = <String, TimeSportsDb>{};
    final venuesByKey = <String, VenueSportsDb>{
      for (final venue in data.venuesSportsDb) venue.venueKey: venue,
    };
    final venuesById = <String, VenueSportsDb>{
      for (final venue in data.venuesSportsDb)
        if (venue.idVenue != null && venue.idVenue!.isNotEmpty)
          venue.idVenue!: venue,
    };
    final jogosPorId = data.jogosPorId;

    for (final time in data.timesSportsDb) {
      final badge = _firstUrl([time.badgeUrl, time.logoUrl]);
      final teamImage = _firstUrl([
        time.fanartUrl,
        time.bannerUrl,
        time.raw['strFanart2']?.toString(),
        time.raw['strFanart3']?.toString(),
        time.raw['strFanart4']?.toString(),
        time.equipamentoUrl,
        time.logoUrl,
        time.badgeUrl,
      ]);
      final flag = _firstUrl([
        CountryFlagUrls.forTeamName(time.nomeBolao),
        CountryFlagUrls.forTeamName(time.timeKey),
        CountryFlagUrls.forCountry(time.pais),
        CountryFlagUrls.forCountry(time.raw['strCountry']?.toString()),
      ]);
      _addTeam(teamsByKey, time.timeKey, time);
      _addTeam(teamsByKey, time.nomeBolao, time);
      _addTeam(teamsByKey, time.nomeApi, time);
      _addTeam(teamsByKey, time.siglaApi, time);
      _addTeam(teamsByKey, time.pais, time);

      _addBadge(badges, time.nomeBolao, badge);
      _addBadge(badges, time.nomeApi, badge);
      _addBadge(badges, time.timeKey, badge);
      _addBadge(badges, time.siglaApi, badge);
      _addBadge(badges, time.pais, badge);
      _addBadge(badges, time.raw['strTeam']?.toString(), badge);
      _addBadge(badges, time.raw['strTeamShort']?.toString(), badge);
      _addMedia(flags, time.nomeBolao, flag);
      _addMedia(flags, time.nomeApi, flag);
      _addMedia(flags, time.timeKey, flag);
      _addMedia(flags, time.siglaApi, flag);
      _addMedia(flags, time.pais, flag);
      _addMedia(flags, time.raw['strTeam']?.toString(), flag);
      _addMedia(flags, time.raw['strTeamShort']?.toString(), flag);
      _addMedia(teamImages, time.nomeBolao, teamImage);
      _addMedia(teamImages, time.nomeApi, teamImage);
      _addMedia(teamImages, time.timeKey, teamImage);
      _addMedia(teamImages, time.siglaApi, teamImage);
      _addMedia(teamImages, time.pais, teamImage);
      _addMedia(teamImages, time.raw['strTeam']?.toString(), teamImage);
      _addMedia(teamImages, time.raw['strTeamShort']?.toString(), teamImage);
      for (final alias in _splitAliases(time.raw['strTeamAlternate'])) {
        _addBadge(badges, alias, badge);
        _addMedia(flags, alias, flag);
        _addMedia(teamImages, alias, teamImage);
        _addTeam(teamsByKey, alias, time);
      }
    }

    for (final historico in data.historicoPartidas) {
      final homeBadge = historico.raw['strHomeTeamBadge']?.toString();
      final awayBadge = historico.raw['strAwayTeamBadge']?.toString();
      final jogo = jogosPorId[historico.jogoId];

      _addBadge(badges, historico.strHomeTeam, homeBadge);
      _addBadge(badges, historico.strAwayTeam, awayBadge);
      _addBadge(badges, historico.mandantePrevisto, homeBadge);
      _addBadge(badges, historico.visitantePrevisto, awayBadge);
      _addBadge(badges, jogo?.mandantePrevisto, homeBadge);
      _addBadge(badges, jogo?.visitantePrevisto, awayBadge);
      _addBadge(badges, jogo?.mandanteReferencia.timeKey, homeBadge);
      _addBadge(badges, jogo?.visitanteReferencia.timeKey, awayBadge);
      _addBadge(badges, jogo?.mandanteReferencia.nomeFonte, homeBadge);
      _addBadge(badges, jogo?.visitanteReferencia.nomeFonte, awayBadge);

      final banner = _firstUrl([
        historico.raw['strBanner']?.toString(),
        historico.raw['strThumb']?.toString(),
        historico.raw['strPoster']?.toString(),
        historico.raw['strFanart']?.toString(),
      ]);
      final image = _firstUrl([
        historico.raw['strThumb']?.toString(),
        historico.raw['strPoster']?.toString(),
        historico.raw['strFanart']?.toString(),
        historico.raw['strBanner']?.toString(),
      ]);

      if (banner != null) {
        matchBanners[historico.jogoId] = banner;
      }

      if (image != null) {
        matchImages[historico.jogoId] = image;
      }

      final video = _firstUrl([historico.raw['strVideo']?.toString()]);
      if (video != null) {
        matchVideos[historico.jogoId] = video;
      }
    }

    for (final jogo in data.jogos) {
      final homeBadge = _badgeByName(badges, jogo.mandanteReferencia.timeKey);
      final awayBadge = _badgeByName(badges, jogo.visitanteReferencia.timeKey);
      final homeFlag = _mediaByName(flags, jogo.mandanteReferencia.timeKey);
      final awayFlag = _mediaByName(flags, jogo.visitanteReferencia.timeKey);
      final homeImage = _mediaByName(
        teamImages,
        jogo.mandanteReferencia.timeKey,
      );
      final awayImage = _mediaByName(
        teamImages,
        jogo.visitanteReferencia.timeKey,
      );
      _addBadge(badges, jogo.mandantePrevisto, homeBadge);
      _addBadge(badges, jogo.visitantePrevisto, awayBadge);
      _addBadge(badges, jogo.mandanteReferencia.nomeFonte, homeBadge);
      _addBadge(badges, jogo.visitanteReferencia.nomeFonte, awayBadge);
      _addMedia(flags, jogo.mandantePrevisto, homeFlag);
      _addMedia(flags, jogo.visitantePrevisto, awayFlag);
      _addMedia(flags, jogo.mandanteReferencia.nomeFonte, homeFlag);
      _addMedia(flags, jogo.visitanteReferencia.nomeFonte, awayFlag);
      _addMedia(teamImages, jogo.mandantePrevisto, homeImage);
      _addMedia(teamImages, jogo.visitantePrevisto, awayImage);
      _addMedia(teamImages, jogo.mandanteReferencia.nomeFonte, homeImage);
      _addMedia(teamImages, jogo.visitanteReferencia.nomeFonte, awayImage);

      final venue = _venueForMatch(
        data: data,
        jogo: jogo,
        venuesByKey: venuesByKey,
        venuesById: venuesById,
      );
      final image = venue?.melhorImagem;
      if (image != null && !matchImages.containsKey(jogo.jogoId)) {
        matchImages[jogo.jogoId] = image;
      }
      if (image != null && !matchBanners.containsKey(jogo.jogoId)) {
        matchBanners[jogo.jogoId] = image;
      }
    }

    for (final entry in eventosPorJogoId.entries) {
      final event = entry.value;
      final jogo = jogosPorId[entry.key];

      _addBadge(badges, event.strHomeTeam, event.strHomeTeamBadge);
      _addBadge(badges, event.strAwayTeam, event.strAwayTeamBadge);
      _addBadge(badges, jogo?.mandantePrevisto, event.strHomeTeamBadge);
      _addBadge(badges, jogo?.visitantePrevisto, event.strAwayTeamBadge);
      _addBadge(
        badges,
        jogo?.mandanteReferencia.timeKey,
        event.strHomeTeamBadge,
      );
      _addBadge(
        badges,
        jogo?.visitanteReferencia.timeKey,
        event.strAwayTeamBadge,
      );

      final image = event.stadiumImage;
      if (image != null && image.isNotEmpty) {
        matchImages[entry.key] = image;
      }

      final banner = _firstUrl([event.strBanner, image]);
      if (banner != null && banner.isNotEmpty) {
        matchBanners[entry.key] = banner;
      }

      final video = event.strVideo;
      if (video != null && video.isNotEmpty) {
        matchVideos[entry.key] = video;
      }
    }

    return BolaoMediaCatalog(
      badgesByTeamKey: Map.unmodifiable(badges),
      flagsByTeamKey: Map.unmodifiable(flags),
      teamImagesByTeamKey: Map.unmodifiable(teamImages),
      matchImagesById: Map.unmodifiable(matchImages),
      matchBannersById: Map.unmodifiable(matchBanners),
      matchVideosById: Map.unmodifiable(matchVideos),
      teamsByKey: Map.unmodifiable(teamsByKey),
      venuesByKey: Map.unmodifiable(venuesByKey),
      venuesById: Map.unmodifiable(venuesById),
      leagueImageUrl: data.ligaSportsDb?.melhorImagem,
    );
  }

  static VenueSportsDb? _venueForMatch({
    required BolaoData data,
    required Jogo jogo,
    required Map<String, VenueSportsDb> venuesByKey,
    required Map<String, VenueSportsDb> venuesById,
  }) {
    final historico = data.historicoPorJogoId[jogo.jogoId];
    final idVenue = historico?.raw['idVenue']?.toString();

    if (idVenue != null && idVenue.isNotEmpty) {
      final byId = venuesById[idVenue];
      if (byId != null) {
        return byId;
      }
    }

    return venuesByKey[_venueKey(jogo.estadio)];
  }

  static void _addBadge(
    Map<String, String> badges,
    String? teamName,
    String? url,
  ) {
    if (teamName == null || url == null || url.trim().isEmpty) {
      return;
    }

    badges[TeamNormalizer.key(teamName)] = url.trim();
  }

  static void _addMedia(Map<String, String> values, String? key, String? url) {
    if (key == null || url == null || url.trim().isEmpty) {
      return;
    }

    values[TeamNormalizer.key(key)] = url.trim();
  }

  static String? _badgeByName(Map<String, String> badges, String? teamName) {
    if (teamName == null || teamName.trim().isEmpty) {
      return null;
    }

    return badges[TeamNormalizer.key(teamName)];
  }

  static String? _mediaByName(Map<String, String> values, String? key) {
    if (key == null || key.trim().isEmpty) {
      return null;
    }

    return values[TeamNormalizer.key(key)];
  }

  static void _addTeam(
    Map<String, TimeSportsDb> teamsByKey,
    String? teamName,
    TimeSportsDb team,
  ) {
    if (teamName == null || teamName.trim().isEmpty) {
      return;
    }

    teamsByKey[TeamNormalizer.key(teamName)] = team;
  }

  static List<String> _splitAliases(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) {
      return const [];
    }

    return text
        .split(',')
        .map((alias) => alias.trim())
        .where((alias) => alias.isNotEmpty)
        .toList(growable: false);
  }

  static String? _firstUrl(List<String?> values) {
    for (final value in values) {
      final normalized = value?.trim();
      if (normalized != null && normalized.isNotEmpty) {
        return normalized;
      }
    }

    return null;
  }
}

String _venueKey(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
}
