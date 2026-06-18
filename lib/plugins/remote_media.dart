import 'package:flutter/material.dart';

class RemoteImage extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final double? aspectRatio;
  final BoxFit fit;
  final BorderRadius borderRadius;
  final Widget? placeholder;

  const RemoteImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.aspectRatio,
    this.fit = BoxFit.cover,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    final image = _ImageBody(
      url: url,
      width: width,
      height: height,
      fit: fit,
      placeholder: placeholder,
    );

    final clipped = ClipRRect(borderRadius: borderRadius, child: image);

    if (aspectRatio == null) {
      return clipped;
    }

    return AspectRatio(aspectRatio: aspectRatio!, child: clipped);
  }
}

class _ImageBody extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;

  const _ImageBody({
    required this.url,
    required this.width,
    required this.height,
    required this.fit,
    required this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final fallback =
        placeholder ??
        ColoredBox(
          color: colors.surfaceContainerHighest,
          child: Center(
            child: Icon(
              Icons.image_not_supported_outlined,
              color: colors.onSurfaceVariant,
            ),
          ),
        );

    final value = url?.trim();
    if (value == null || value.isEmpty) {
      return SizedBox(width: width, height: height, child: fallback);
    }

    return Image.network(
      value,
      width: width,
      height: height,
      fit: fit,
      gaplessPlayback: true,
      webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }

        return SizedBox(
          width: width,
          height: height,
          child: ColoredBox(
            color: colors.surfaceContainerHighest,
            child: const Center(
              child: SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        );
      },
      errorBuilder: (_, _, _) {
        return SizedBox(width: width, height: height, child: fallback);
      },
    );
  }
}

class MediaCredit extends StatelessWidget {
  final String text;

  const MediaCredit({super.key, this.text = 'Powered by TheSportsDB'});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
