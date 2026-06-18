class TeamNormalizer {
  const TeamNormalizer._();

  static String key(String value) {
    final normalized = normalize(value);
    return _aliases[normalized] ?? normalized;
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
}
