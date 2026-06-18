import 'package:flutter/material.dart';

import '../services/bolao_controller.dart';
import 'theme_mode_action.dart';

class ApiRefreshAction extends StatelessWidget {
  final BolaoController controller;

  const ApiRefreshAction({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const ThemeModeAction(),
        if (controller.atualizandoApi)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
      ],
    );
  }
}
