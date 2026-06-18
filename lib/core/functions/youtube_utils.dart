class YoutubeUtils {
  const YoutubeUtils._();

  static String normalizedUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return trimmed;
    }

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }

    return 'https://$trimmed';
  }

  static String? videoId(String value) {
    final uri = Uri.tryParse(normalizedUrl(value));
    if (uri == null) {
      return null;
    }

    final host = uri.host.toLowerCase();
    if (host == 'youtu.be' && uri.pathSegments.isNotEmpty) {
      return _cleanId(uri.pathSegments.first);
    }

    if (!host.contains('youtube.com')) {
      return null;
    }

    final queryId = uri.queryParameters['v'];
    if (queryId != null && queryId.isNotEmpty) {
      return _cleanId(queryId);
    }

    final segments = uri.pathSegments;
    final embedIndex = segments.indexOf('embed');
    if (embedIndex >= 0 && segments.length > embedIndex + 1) {
      return _cleanId(segments[embedIndex + 1]);
    }

    final shortsIndex = segments.indexOf('shorts');
    if (shortsIndex >= 0 && segments.length > shortsIndex + 1) {
      return _cleanId(segments[shortsIndex + 1]);
    }

    final liveIndex = segments.indexOf('live');
    if (liveIndex >= 0 && segments.length > liveIndex + 1) {
      return _cleanId(segments[liveIndex + 1]);
    }

    return null;
  }

  static String? embedUrl(String value) {
    final id = videoId(value);
    if (id == null || id.isEmpty) {
      return null;
    }

    return 'https://www.youtube.com/embed/$id';
  }

  static String? watchUrl(String value) {
    final id = videoId(value);
    if (id == null || id.isEmpty) {
      final normalized = normalizedUrl(value);
      return normalized.isEmpty ? null : normalized;
    }

    return 'https://www.youtube.com/watch?v=$id';
  }

  static String _cleanId(String value) {
    return value.split('?').first.split('&').first.trim();
  }
}
