class PlaceFormatters {
  const PlaceFormatters._();

  static const Map<String, String> _hostCities = {
    'atlanta': 'Atlanta',
    'boston': 'Boston',
    'dallas': 'Dallas',
    'guadalajara': 'Guadalajara',
    'houston': 'Houston',
    'kansas-city': 'Kansas City',
    'los-angeles': 'Los Angeles',
    'mexico-city': 'Cidade do Mexico',
    'miami': 'Miami',
    'monterrey': 'Monterrey',
    'new-york': 'New York',
    'philadelphia': 'Philadelphia',
    'san-francisco': 'San Francisco',
    'seattle': 'Seattle',
    'toronto': 'Toronto',
    'vancouver': 'Vancouver',
  };

  static String cidadeSede(String value) {
    final normalized = value.trim().toLowerCase();

    if (normalized.isEmpty) {
      return '';
    }

    final mapped = _hostCities[normalized];

    if (mapped != null) {
      return mapped;
    }

    return normalized
        .split(RegExp(r'[-_\s]+'))
        .where((part) => part.isNotEmpty)
        .map(_capitalize)
        .join(' ');
  }

  static String localPartida({
    required String estadio,
    required String cidade,
  }) {
    final cidadeFormatada = cidadeSede(cidade);

    if (estadio.trim().isEmpty) {
      return cidadeFormatada;
    }

    if (cidadeFormatada.isEmpty) {
      return estadio;
    }

    return '$estadio · $cidadeFormatada';
  }

  static String _capitalize(String value) {
    if (value.isEmpty) {
      return value;
    }

    return value[0].toUpperCase() + value.substring(1);
  }
}
