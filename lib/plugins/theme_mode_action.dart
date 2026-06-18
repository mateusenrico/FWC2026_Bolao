import 'package:flutter/material.dart';

import '../core/app_theme.dart';

class ThemeModeAction extends StatelessWidget {
  const ThemeModeAction({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = BolaoThemeScope.maybeOf(context);
    if (controller == null) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final effectiveBrightness = _effectiveBrightness(context, controller);
        final isDark = effectiveBrightness == Brightness.dark;

        return IconButton(
          tooltip: isDark ? 'Usar tema claro' : 'Usar tema escuro',
          onPressed: () => controller.toggle(context),
          onLongPress: controller.useSystem,
          icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode),
        );
      },
    );
  }

  Brightness _effectiveBrightness(
    BuildContext context,
    BolaoThemeController controller,
  ) {
    return switch (controller.mode) {
      ThemeMode.light => Brightness.light,
      ThemeMode.dark => Brightness.dark,
      ThemeMode.system => MediaQuery.platformBrightnessOf(context),
    };
  }
}
