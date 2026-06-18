class JsonUtils {
  const JsonUtils._();

  static String stringValue(
    Map<String, dynamic> json,
    String key, {
    String fallback = '',
  }) {
    final value = json[key];

    if (value == null) {
      return fallback;
    }

    return value.toString();
  }

  static String? nullableString(Map<String, dynamic> json, String key) {
    final value = json[key];

    if (value == null) {
      return null;
    }

    final text = value.toString();

    if (text.trim().isEmpty) {
      return null;
    }

    return text;
  }

  static int intValue(
    Map<String, dynamic> json,
    String key, {
    int fallback = 0,
  }) {
    final value = json[key];

    if (value == null) {
      return fallback;
    }

    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.toInt();
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value.toString()) ?? fallback;
  }

  static int? nullableInt(Map<String, dynamic> json, String key) {
    final value = json[key];

    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.toInt();
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value.toString());
  }

  static bool boolValue(
    Map<String, dynamic> json,
    String key, {
    bool fallback = false,
  }) {
    final value = json[key];

    if (value == null) {
      return fallback;
    }

    if (value is bool) {
      return value;
    }

    final text = value.toString().toLowerCase().trim();

    if (text == 'true' || text == '1' || text == 'yes' || text == 'sim') {
      return true;
    }

    if (text == 'false' ||
        text == '0' ||
        text == 'no' ||
        text == 'nao' ||
        text == 'não') {
      return false;
    }

    return fallback;
  }

  static DateTime? nullableDateTime(Map<String, dynamic> json, String key) {
    final value = json[key];

    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString());
  }

  static List<String> stringList(Map<String, dynamic> json, String key) {
    final value = json[key];

    if (value == null) {
      return const [];
    }

    if (value is List) {
      return value.map((item) => item.toString()).toList(growable: false);
    }

    return const [];
  }

  static Map<String, dynamic> mapValue(Map<String, dynamic> json, String key) {
    final value = json[key];

    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return const {};
  }
}
