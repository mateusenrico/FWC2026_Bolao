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
        IconButton(
          tooltip: 'Atualizar dados da SportsDB',
          onPressed: controller.atualizandoApi
              ? null
              : () async {
                  await controller.atualizarApi();

                  if (!context.mounted) {
                    return;
                  }

                  final message = controller.mensagemAtualizacao;
                  if (message == null || message.isEmpty) {
                    return;
                  }

                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      SnackBar(
                        content: Text(message),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                },
          icon: controller.atualizandoApi
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh),
        ),
      ],
    );
  }
}
