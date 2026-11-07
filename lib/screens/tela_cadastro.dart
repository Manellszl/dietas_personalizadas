import 'package:flutter/material.dart';
import '../models/perfil.dart';

class TelaCadastro extends StatefulWidget {
  const TelaCadastro({
    super.key,
    required this.onSalvar,
  });

  final Future<void> Function(Perfil perfil) onSalvar;

  @override
  State<TelaCadastro> createState() => _TelaCadastroState();
}

class _TelaCadastroState extends State<TelaCadastro> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _idadeController = TextEditingController();
  final _pesoController = TextEditingController();

  String? _metaSelecionada;
  bool _salvando = false;

  static const _metas = [
    'Ganhar massa muscular',
    'Perder peso',
    'Ganhar peso',
    'Manter o peso',
    'Melhorar hábitos alimentares',
  ];

  @override
  void dispose() {
    _nomeController.dispose();
    _idadeController.dispose();
    _pesoController.dispose();
    super.dispose();
  }

  Future<void> _enviarCadastro() async {
    if (!_formKey.currentState!.validate()) return;

    final perfil = Perfil(
      nome: _nomeController.text.trim(),
      idade: int.parse(_idadeController.text.trim()),
      peso: double.parse(
        _pesoController.text.trim().replaceAll(',', '.'),
      ),
      meta: _metaSelecionada!,
    );

    setState(() => _salvando = true);

    try {
      await widget.onSalvar(perfil);
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível salvar o cadastro. Tente novamente.',
            ),
          ),
        );

      setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.eco_rounded,
                      size: 54,
                      color: Color(0xFF245C47),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Vamos conhecer você',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Preencha seus dados para começar a usar o Equilibra.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nomeController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Nome',
                        border: OutlineInputBorder(),
                      ),
                      validator: (valor) {
                        if (valor == null || valor.trim().isEmpty) {
                          return 'Informe seu nome.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _idadeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Idade',
                        suffixText: 'anos',
                        border: OutlineInputBorder(),
                      ),
                      validator: (valor) {
                        final idade = int.tryParse(valor?.trim() ?? '');
                        if (idade == null || idade < 1 || idade > 120) {
                          return 'Informe uma idade válida.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _pesoController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Peso',
                        suffixText: 'kg',
                        border: OutlineInputBorder(),
                      ),
                      validator: (valor) {
                        final peso = double.tryParse(
                          (valor ?? '').trim().replaceAll(',', '.'),
                        );
                        if (peso == null || peso <= 0 || peso > 500) {
                          return 'Informe um peso válido.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: _metaSelecionada,
                      decoration: const InputDecoration(
                        labelText: 'Sua meta',
                        border: OutlineInputBorder(),
                      ),
                      items: _metas
                          .map(
                            (meta) => DropdownMenuItem(
                              value: meta,
                              child: Text(meta),
                            ),
                          )
                          .toList(),
                      onChanged: _salvando
                          ? null
                          : (valor) {
                              setState(() => _metaSelecionada = valor);
                            },
                      validator: (valor) =>
                          valor == null ? 'Escolha uma meta.' : null,
                    ),
                    const SizedBox(height: 22),
                    FilledButton(
                      onPressed: _salvando ? null : _enviarCadastro,
                      child: _salvando
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Salvar e continuar'),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'As sugestões são educativas e não substituem a '
                      'orientação de um profissional de saúde.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}