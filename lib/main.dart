import 'package:flutter/material.dart';

import 'screens/jogos_screen.dart';

void main() {
  runApp(const BolaoApp());
}

class BolaoApp extends StatelessWidget {
  const BolaoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bolão FWC 2026',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      home: const JogosScreen(),
    );
  }
}
