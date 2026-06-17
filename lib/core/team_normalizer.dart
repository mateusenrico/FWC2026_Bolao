class TeamNormalizer {
  const TeamNormalizer._();

  static String key(String value) {
    final normalized = normalize(value);
    return _teamAliases[normalized] ?? normalized;
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
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

const Map<String, String> _teamAliases = {
  'mexico': 'mexico',

  'south africa': 'south africa',
  'africa do sul': 'south africa',

  'south korea': 'south korea',
  'coreia do sul': 'south korea',
  'korea republic': 'south korea',

  'czechia': 'czechia',
  'republica tcheca': 'czechia',

  'canada': 'canada',

  'bosnia and herzegovina': 'bosnia and herzegovina',
  'bosnia e herzegovina': 'bosnia and herzegovina',
  'bosnia herzegovina': 'bosnia and herzegovina',

  'qatar': 'qatar',
  'catar': 'qatar',

  'switzerland': 'switzerland',
  'suica': 'switzerland',
  'suíca': 'switzerland',
  'suiça': 'switzerland',

  'brazil': 'brazil',
  'brasil': 'brazil',

  'morocco': 'morocco',
  'marrocos': 'morocco',

  'haiti': 'haiti',

  'scotland': 'scotland',
  'escocia': 'scotland',
  'escócia': 'scotland',

  'united states': 'united states',
  'usa': 'united states',
  'us': 'united states',
  'estados unidos': 'united states',

  'paraguay': 'paraguay',
  'paraguai': 'paraguay',

  'australia': 'australia',

  'turkey': 'turkey',
  'turkiye': 'turkey',
  'turquia': 'turkey',

  'germany': 'germany',
  'alemanha': 'germany',

  'curacao': 'curacao',
  'curacau': 'curacao',

  'ivory coast': 'ivory coast',
  'cote d ivoire': 'ivory coast',
  'côte d ivoire': 'ivory coast',
  'costa do marfim': 'ivory coast',

  'ecuador': 'ecuador',

  'netherlands': 'netherlands',
  'holanda': 'netherlands',
  'paises baixos': 'netherlands',
  'países baixos': 'netherlands',

  'japan': 'japan',
  'japao': 'japan',
  'japão': 'japan',

  'sweden': 'sweden',
  'suecia': 'sweden',
  'suécia': 'sweden',

  'tunisia': 'tunisia',
  'tunisia pt': 'tunisia',

  'belgium': 'belgium',
  'belgica': 'belgium',
  'bélgica': 'belgium',

  'egypt': 'egypt',
  'egito': 'egypt',

  'iran': 'iran',
  'ira': 'iran',
  'irã': 'iran',
  'irao': 'iran',
  'irão': 'iran',

  'new zealand': 'new zealand',
  'nova zelandia': 'new zealand',
  'nova zelândia': 'new zealand',

  'spain': 'spain',
  'espanha': 'spain',

  'cape verde': 'cape verde',
  'cabo verde': 'cape verde',

  'saudi arabia': 'saudi arabia',
  'arabia saudita': 'saudi arabia',
  'arábia saudita': 'saudi arabia',

  'uruguay': 'uruguay',
  'uruguai': 'uruguay',

  'france': 'france',
  'franca': 'france',
  'frança': 'france',

  'senegal': 'senegal',

  'iraq': 'iraq',
  'iraque': 'iraq',

  'norway': 'norway',
  'noruega': 'norway',

  'argentina': 'argentina',

  'algeria': 'algeria',
  'argelia': 'algeria',
  'argélia': 'algeria',

  'austria': 'austria',
  'áustria': 'austria',

  'jordan': 'jordan',
  'jordania': 'jordan',
  'jordânia': 'jordan',

  'portugal': 'portugal',

  'dr congo': 'dr congo',
  'rd congo': 'dr congo',
  'congo dr': 'dr congo',
  'democratic republic of congo': 'dr congo',
  'congo democratic republic': 'dr congo',
  'congo rd': 'dr congo',

  'uzbekistan': 'uzbekistan',
  'uzbequistao': 'uzbekistan',
  'uzbequistão': 'uzbekistan',

  'colombia': 'colombia',
  'colômbia': 'colombia',

  'england': 'england',
  'inglaterra': 'england',

  'croatia': 'croatia',
  'croacia': 'croatia',
  'croácia': 'croatia',

  'ghana': 'ghana',

  'panama': 'panama',
  'panamá': 'panama',
};
