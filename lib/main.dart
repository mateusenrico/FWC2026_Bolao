import 'dart:async';

import 'package:flutter/material.dart';

import 'core/app_routes.dart';
import 'screens/grupos_screen.dart';
import 'screens/home_screen.dart';
import 'screens/jogo_detail_screen.dart';
import 'screens/jogos_screen.dart';
import 'screens/participante_detail_screen.dart';
import 'screens/ranking_screen.dart';
import 'screens/simulador_screen.dart';
import 'services/bolao_controller.dart';

void main() {
  runApp(const BolaoApp());
}

class BolaoApp extends StatefulWidget {
  const BolaoApp({super.key});

  @override
  State<BolaoApp> createState() => _BolaoAppState();
}

class _BolaoAppState extends State<BolaoApp> {
  late final Future<BolaoController> _controllerFuture;

  @override
  void initState() {
    super.initState();
    _controllerFuture = BolaoController.carregar();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<BolaoController>(
      future: _controllerFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: _theme(),
            home: Scaffold(
              appBar: AppBar(title: const Text('Bolão FWC 2026')),
              body: Padding(
                padding: const EdgeInsets.all(20),
                child: SelectableText(
                  'Erro ao carregar o aplicativo:\n\n${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: _theme(),
            home: const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        return _BolaoNavigationApp(controller: snapshot.data!);
      },
    );
  }
}

class _BolaoNavigationApp extends StatefulWidget {
  final BolaoController controller;

  const _BolaoNavigationApp({required this.controller});

  @override
  State<_BolaoNavigationApp> createState() => _BolaoNavigationAppState();
}

class _BolaoNavigationAppState extends State<_BolaoNavigationApp> {
  BolaoController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    unawaited(controller.iniciarAtualizacaoAutomatica());
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bolão FWC 2026',
      debugShowCheckedModeBanner: false,
      theme: _theme(),
      initialRoute: AppRoutes.home,
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case AppRoutes.home:
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => HomeScreen(controller: controller),
            );
          case AppRoutes.jogo:
            final jogoId = settings.arguments as String?;
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => JogoDetailScreen(
                controller: controller,
                jogoId: jogoId ?? '',
              ),
            );
          case AppRoutes.participante:
            final participanteId = settings.arguments as String?;
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => ParticipanteDetailScreen(
                controller: controller,
                participanteId: participanteId ?? '',
              ),
            );
          case AppRoutes.grupos:
            final grupo = settings.arguments as String?;
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) =>
                  GruposScreen(controller: controller, grupoInicial: grupo),
            );
          case AppRoutes.ranking:
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => RankingScreen(controller: controller),
            );
          case AppRoutes.jogos:
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => JogosScreen(controller: controller),
            );
          case AppRoutes.simulador:
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => SimuladorScreen(controller: controller),
            );
          default:
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => HomeScreen(controller: controller),
            );
        }
      },
    );
  }
}

ThemeData _theme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF087443),
    brightness: Brightness.light,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colorScheme.surface,
    cardTheme: CardThemeData(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
    ),
    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      surfaceTintColor: Colors.transparent,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
