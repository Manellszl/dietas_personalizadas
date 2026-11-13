import 'package:flutter/material.dart';
import 'data/perfil_repository.dart';
import 'screens/tela_inicial.dart';

class EquilibraApp extends StatelessWidget {
  const EquilibraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Equilibra',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 46, 111, 87),
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F8F4),
      ),
      home: TelaInicial(repository: PerfilRepository()),
    );
  }
}
