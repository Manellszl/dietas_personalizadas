import 'package:flutter/material.dart';
import '../data/perfil_repository.dart';
import '../models/perfil.dart';
import 'tela_cadastro.dart';
import 'tela_principal.dart';

class TelaInicial extends StatefulWidget {
  const TelaInicial({
    super.key,
    required this.repository,
  });

  final PerfilRepository repository;

  @override
  State<TelaInicial> createState() => _TelaInicialState();
}

class _TelaInicialState extends State<TelaInicial> {
  late Future<Perfil?> _perfilFuture;

  @override
  void initState() {
    super.initState();
    _carregarPerfil();
  }

  void _carregarPerfil() {
    _perfilFuture = widget.repository.buscarPerfil();
  }

  Future<void> _salvarPerfil(Perfil perfil) async {
    await widget.repository.salvarPerfil(perfil);
    if (!mounted) return;

    setState(_carregarPerfil);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Perfil?>(
      future: _perfilFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Color(0xFFB3261E),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Não foi possível carregar o aplicativo. '
                      'Confira o banco de dados e tente novamente.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () {
                        setState(_carregarPerfil);
                      },
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final perfil = snapshot.data;
        if (perfil == null) {
          return TelaCadastro(onSalvar: _salvarPerfil);
        }

        return TelaPrincipal(perfil: perfil);
      },
    );
  }
}