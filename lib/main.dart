import 'dart:async';

import 'package:flutter/material.dart';

import 'core/app_theme.dart';
import 'core/app_routes.dart';
import 'screens/grupos_screen.dart';
import 'screens/home_screen.dart';
import 'screens/jogo_detail_screen.dart';
import 'screens/jogos_screen.dart';
import 'screens/participante_detail_screen.dart';
import 'screens/ranking_screen.dart';
import 'screens/simulador_screen.dart';
import 'screens/time_screen.dart';
import 'screens/times_screen.dart';
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
  late final BolaoThemeController _themeController;

  @override
  void initState() {
    super.initState();
    _themeController = BolaoThemeController();
    _controllerFuture = BolaoController.carregar(atualizarAntesDeExibir: true);
  }

  @override
  void dispose() {
    _themeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BolaoThemeScope(
      controller: _themeController,
      child: AnimatedBuilder(
        animation: _themeController,
        builder: (context, _) {
          return FutureBuilder<BolaoController>(
            future: _controllerFuture,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return MaterialApp(
                  debugShowCheckedModeBanner: false,
                  theme: buildBolaoTheme(Brightness.light),
                  darkTheme: buildBolaoTheme(Brightness.dark),
                  themeMode: _themeController.mode,
                  builder: _clampedTextBuilder,
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
                  theme: buildBolaoTheme(Brightness.light),
                  darkTheme: buildBolaoTheme(Brightness.dark),
                  themeMode: _themeController.mode,
                  builder: _clampedTextBuilder,
                  home: const _BolaoSplashScreen(),
                );
              }

              return _BolaoNavigationApp(
                controller: snapshot.data!,
                themeController: _themeController,
              );
            },
          );
        },
      ),
    );
  }
}

class _BolaoNavigationApp extends StatefulWidget {
  final BolaoController controller;
  final BolaoThemeController themeController;

  const _BolaoNavigationApp({
    required this.controller,
    required this.themeController,
  });

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
      theme: buildBolaoTheme(Brightness.light),
      darkTheme: buildBolaoTheme(Brightness.dark),
      themeMode: widget.themeController.mode,
      builder: _clampedTextBuilder,
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
          case AppRoutes.times:
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => TimesScreen(controller: controller),
            );
          case AppRoutes.time:
            final nomeTime = settings.arguments as String?;
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) =>
                  TimeScreen(controller: controller, nomeTime: nomeTime ?? ''),
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

Widget _clampedTextBuilder(BuildContext context, Widget? child) {
  final media = MediaQuery.of(context);
  return MediaQuery(
    data: media.copyWith(
      textScaler: media.textScaler.clamp(
        minScaleFactor: 0.9,
        maxScaleFactor: 1.28,
      ),
    ),
    child: child ?? const SizedBox.shrink(),
  );
}

class _BolaoSplashScreen extends StatelessWidget {
  const _BolaoSplashScreen();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 86,
                height: 86,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: colors.outlineVariant),
                ),
                child: Image.asset(
                  'assets/media/app_icons/league_badge.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.sports_soccer,
                      color: colors.primary,
                      size: 42,
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Bolão FWC 2026',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Atualizando placares antes de abrir...',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 22),
              const SizedBox(
                width: 180,
                child: LinearProgressIndicator(minHeight: 4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
