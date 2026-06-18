class TeamNormalizer {
  const TeamNormalizer._();

  static String key(String value) {
    final normalized = normalize(value);
    return _aliases[normalized] ?? normalized;
  }

  static String sigla(String value) {
    final canonicalKey = key(value);
    return _siglas[canonicalKey] ?? _fallbackSigla(value);
  }

  static String normalize(String value) {
    return value
        .toLowerCase()
        .trim()
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ä', 'a')
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ì', 'i')
        .replaceAll('î', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ò', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('ö', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ù', 'u')
        .replaceAll('û', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ç', 'c')
        .replaceAll('&', ' and ')
        .replaceAll(RegExp(r"['’]"), ' ')
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String _fallbackSigla(String value) {
    final text = value.trim();

    final groupPosition = RegExp(
      r'([123])\s*[ºo]?\s*(?:do\s+)?grupo\s+([A-L])',
      caseSensitive: false,
    ).firstMatch(text);

    if (groupPosition != null) {
      return '${groupPosition.group(1)}${groupPosition.group(2)!.toUpperCase()}';
    }

    final matchReference = RegExp(
      r'(vencedor|perdedor).*?(\d+)',
      caseSensitive: false,
    ).firstMatch(text);

    if (matchReference != null) {
      final prefix = matchReference.group(1)!.toLowerCase().startsWith('v')
          ? 'V'
          : 'P';
      return '$prefix${matchReference.group(2)}';
    }

    final bestThird = RegExp(
      r'(?:melhor|3)[^A-L]*([A-L](?:\s*[,/-]\s*[A-L])*)',
      caseSensitive: false,
    ).firstMatch(text);

    if (bestThird != null) {
      return '3º';
    }

    final words = normalize(
      text,
    ).split(' ').where((word) => word.isNotEmpty).toList(growable: false);

    if (words.isEmpty) {
      return '---';
    }

    if (words.length == 1) {
      final length = words.first.length < 3 ? words.first.length : 3;
      return words.first.substring(0, length).toUpperCase();
    }

    final initials = words.map((word) => word[0]).join();
    final length = initials.length < 3 ? initials.length : 3;
    return initials.substring(0, length).toUpperCase();
  }

  static const Map<String, String> _aliases = {
    'africa do sul': 'south africa',
    'korea republic': 'south korea',
    'republic of korea': 'south korea',
    'coreia do sul': 'south korea',
    'czech republic': 'czechia',
    'republica tcheca': 'czechia',
    'bosnia herzegovina': 'bosnia and herzegovina',
    'bosnia e herzegovina': 'bosnia and herzegovina',
    'usa': 'united states',
    'us': 'united states',
    'estados unidos': 'united states',
    'paraguai': 'paraguay',
    'turkiye': 'turkey',
    'turquia': 'turkey',
    'alemanha': 'germany',
    'curacau': 'curacao',
    'cote d ivoire': 'ivory coast',
    'cote divoire': 'ivory coast',
    'costa do marfim': 'ivory coast',
    'equador': 'ecuador',
    'holanda': 'netherlands',
    'paises baixos': 'netherlands',
    'japao': 'japan',
    'suecia': 'sweden',
    'belgica': 'belgium',
    'egito': 'egypt',
    'ir iran': 'iran',
    'ira': 'iran',
    'irao': 'iran',
    'nova zelandia': 'new zealand',
    'espanha': 'spain',
    'cape verde': 'cape verde',
    'cabo verde': 'cape verde',
    'arabia saudita': 'saudi arabia',
    'uruguai': 'uruguay',
    'franca': 'france',
    'iraque': 'iraq',
    'noruega': 'norway',
    'argelia': 'algeria',
    'jordania': 'jordan',
    'dr congo': 'dr congo',
    'rd congo': 'dr congo',
    'congo dr': 'dr congo',
    'congo rd': 'dr congo',
    'democratic republic of congo': 'dr congo',
    'congo democratic republic': 'dr congo',
    'uzbequistao': 'uzbekistan',
    'inglaterra': 'england',
    'croacia': 'croatia',
    'gana': 'ghana',
    'brasil': 'brazil',
    'marrocos': 'morocco',
    'escocia': 'scotland',
    'catar': 'qatar',
    'suica': 'switzerland',
  };

  static const Map<String, String> _siglas = {
    'mexico': 'MEX',
    'south korea': 'KOR',
    'czechia': 'CZE',
    'south africa': 'RSA',
    'bosnia and herzegovina': 'BIH',
    'canada': 'CAN',
    'qatar': 'QAT',
    'switzerland': 'SUI',
    'scotland': 'SCO',
    'brazil': 'BRA',
    'morocco': 'MAR',
    'haiti': 'HAI',
    'united states': 'USA',
    'australia': 'AUS',
    'turkey': 'TUR',
    'paraguay': 'PAR',
    'germany': 'GER',
    'ivory coast': 'CIV',
    'ecuador': 'ECU',
    'curacao': 'CUW',
    'sweden': 'SWE',
    'netherlands': 'NED',
    'japan': 'JPN',
    'tunisia': 'TUN',
    'iran': 'IRN',
    'new zealand': 'NZL',
    'belgium': 'BEL',
    'egypt': 'EGY',
    'saudi arabia': 'KSA',
    'uruguay': 'URU',
    'cape verde': 'CPV',
    'spain': 'ESP',
    'norway': 'NOR',
    'france': 'FRA',
    'senegal': 'SEN',
    'iraq': 'IRQ',
    'argentina': 'ARG',
    'austria': 'AUT',
    'jordan': 'JOR',
    'algeria': 'ALG',
    'colombia': 'COL',
    'portugal': 'POR',
    'dr congo': 'COD',
    'uzbekistan': 'UZB',
    'england': 'ENG',
    'ghana': 'GHA',
    'panama': 'PAN',
    'croatia': 'CRO',
  };
}
