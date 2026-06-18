import 'package:flutter/material.dart';

import '../core/functions/youtube_utils.dart';

class YoutubeEmbedPlayer extends StatelessWidget {
  final String url;
  final String title;

  const YoutubeEmbedPlayer({
    super.key,
    required this.url,
    this.title = 'Highlights',
  });

  @override
  Widget build(BuildContext context) {
    final watchUrl = YoutubeUtils.watchUrl(url) ?? url;
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
                '$title disponível',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
            Flexible(
              child: SelectableText(
                watchUrl,
                maxLines: 1,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
