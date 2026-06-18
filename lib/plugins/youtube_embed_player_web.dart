import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import '../core/functions/youtube_utils.dart';

class YoutubeEmbedPlayer extends StatefulWidget {
  final String url;
  final String title;

  const YoutubeEmbedPlayer({
    super.key,
    required this.url,
    this.title = 'Highlights',
  });

  @override
  State<YoutubeEmbedPlayer> createState() => _YoutubeEmbedPlayerState();
}

class _YoutubeEmbedPlayerState extends State<YoutubeEmbedPlayer> {
  String? _viewType;
  String? _embedUrl;

  @override
  void initState() {
    super.initState();
    _register();
  }

  @override
  void didUpdateWidget(covariant YoutubeEmbedPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _register();
    }
  }

  void _register() {
    final embed = YoutubeUtils.embedUrl(widget.url);
    _embedUrl = embed;

    if (embed == null) {
      _viewType = null;
      return;
    }

    final viewType =
        'youtube-embed-${identityHashCode(this)}-${embed.hashCode.abs()}';
    final iframe = web.HTMLIFrameElement()
      ..src = embed
      ..title = widget.title
      ..allow =
          'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share'
      ..referrerPolicy = 'strict-origin-when-cross-origin';

    iframe.setAttribute('allowfullscreen', 'true');
    iframe.style
      ..border = '0'
      ..width = '100%'
      ..height = '100%';

    ui_web.platformViewRegistry.registerViewFactory(viewType, (_) => iframe);
    _viewType = viewType;
  }

  @override
  Widget build(BuildContext context) {
    final embed = _embedUrl;
    final viewType = _viewType;
    final watchUrl = YoutubeUtils.watchUrl(widget.url) ?? widget.url;
    final colors = Theme.of(context).colorScheme;

    if (embed == null || viewType == null) {
      return _ExternalVideoLink(title: widget.title, url: watchUrl);
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: HtmlElementView(viewType: viewType),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Row(
              children: [
                Icon(Icons.play_circle_outline, color: colors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    web.window.open(watchUrl, '_blank');
                  },
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('YouTube'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExternalVideoLink extends StatelessWidget {
  final String title;
  final String url;

  const _ExternalVideoLink({required this.title, required this.url});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(Icons.play_circle_outline, color: colors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
            TextButton.icon(
              onPressed: () {
                web.window.open(url, '_blank');
              },
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Abrir'),
            ),
          ],
        ),
      ),
    );
  }
}
