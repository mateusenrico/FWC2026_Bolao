import 'team_normalizer.dart';

class CountryFlagUrls {
  const CountryFlagUrls._();

  static String? forTeamName(String? value, {int width = 640}) {
    return _urlForCode(_codesByName[TeamNormalizer.key(value ?? '')], width);
  }

  static String? forCountry(String? value, {int width = 640}) {
    return _urlForCode(_codesByName[TeamNormalizer.key(value ?? '')], width);
  }

  static String? _urlForCode(String? code, int width) {
    if (code == null || code.isEmpty) {
      return null;
    }

    return 'https://flagcdn.com/w$width/${code.toLowerCase()}.png';
  }

  static const _codesByName = {
    'africa do sul': 'za',
    'alemanha': 'de',
    'algeria': 'dz',
    'argelia': 'dz',
    'arabia saudita': 'sa',
    'argentina': 'ar',
    'australia': 'au',
    'austria': 'at',
    'belgium': 'be',
    'belgica': 'be',
    'bosnia and herzegovina': 'ba',
    'bosnia e herzegovina': 'ba',
    'brasil': 'br',
    'brazil': 'br',
    'cabo verde': 'cv',
    'canada': 'ca',
    'cape verde': 'cv',
    'catar': 'qa',
    'colombia': 'co',
    'coreia do sul': 'kr',
    'costa do marfim': 'ci',
    'croatia': 'hr',
    'croacia': 'hr',
    'curacao': 'cw',
    'czechia': 'cz',
    'ecuador': 'ec',
    'dr congo': 'cd',
    'egito': 'eg',
    'egypt': 'eg',
    'equador': 'ec',
    'england': 'gb-eng',
    'escocia': 'gb-sct',
    'espanha': 'es',
    'estados unidos': 'us',
    'france': 'fr',
    'franca': 'fr',
    'germany': 'de',
    'ghana': 'gh',
    'haiti': 'ht',
    'holanda': 'nl',
    'inglaterra': 'gb-eng',
    'ira': 'ir',
    'iraq': 'iq',
    'iraque': 'iq',
    'iran': 'ir',
    'ivory coast': 'ci',
    'japao': 'jp',
    'japan': 'jp',
    'jordan': 'jo',
    'jordania': 'jo',
    'marrocos': 'ma',
    'mexico': 'mx',
    'morocco': 'ma',
    'netherlands': 'nl',
    'new zealand': 'nz',
    'nova zelandia': 'nz',
    'norway': 'no',
    'noruega': 'no',
    'panama': 'pa',
    'paraguay': 'py',
    'paraguai': 'py',
    'portugal': 'pt',
    'qatar': 'qa',
    'rd congo': 'cd',
    'republica tcheca': 'cz',
    'saudi arabia': 'sa',
    'scotland': 'gb-sct',
    'senegal': 'sn',
    'south africa': 'za',
    'south korea': 'kr',
    'spain': 'es',
    'suecia': 'se',
    'suica': 'ch',
    'sweden': 'se',
    'switzerland': 'ch',
    'tunisia': 'tn',
    'turkey': 'tr',
    'turquia': 'tr',
    'uruguay': 'uy',
    'uruguai': 'uy',
    'united states': 'us',
    'usa': 'us',
    'uzbekistan': 'uz',
    'uzbequistao': 'uz',
  };
}
