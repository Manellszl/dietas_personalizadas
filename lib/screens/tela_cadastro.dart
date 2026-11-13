import 'package:flutter/material.dart';
import '../models/perfil.dart';

// tela de cadastro, também serve pra editar o perfil
class TelaCadastro extends StatefulWidget {
  const TelaCadastro({
    super.key,
    required this.onSalvar,
    this.perfilInicial,
  });

  final Future<void> Function(Perfil perfil) onSalvar;
  final Perfil? perfilInicial;

  bool get edicao => perfilInicial != null;

  @override
  State<TelaCadastro> createState() => _TelaCadastroState();
}

class _TelaCadastroState extends State<TelaCadastro> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeController;
  late final TextEditingController _idadeController;
  late final TextEditingController _pesoController;
  late final TextEditingController _alturaController;

  String? _metaSelecionada;
  String? _sexoSelecionado;
  bool _praticaAtividade = false;
  int _diasAtividade = 3;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    // editando: já abre com os dados salvos
    final p = widget.perfilInicial;
    _nomeController = TextEditingController(text: p?.nome ?? '');
    _idadeController = TextEditingController(text: p?.idade.toString() ?? '');
    _pesoController = TextEditingController(
      text: p == null ? '' : p.peso.toString().replaceAll('.', ','),
    );
    _alturaController =
        TextEditingController(text: p?.alturaCm?.toString() ?? '');
    _metaSelecionada = p?.meta;
    _sexoSelecionado = p?.sexo;
    _praticaAtividade = p?.praticaAtividade ?? false;
    if (p != null && p.praticaAtividade && p.diasAtividade >= 1) {
      _diasAtividade = p.diasAtividade;
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _idadeController.dispose();
    _pesoController.dispose();
    _alturaController.dispose();
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
      sexo: _sexoSelecionado,
      alturaCm: int.parse(_alturaController.text.trim()),
      praticaAtividade: _praticaAtividade,
      diasAtividade: _praticaAtividade ? _diasAtividade : 0,
    );

    setState(() => _salvando = true);

    try {
      await widget.onSalvar(perfil);
      if (!mounted) return;
      if (widget.edicao) Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível salvar. Tente novamente.',
            ),
          ),
        );

      setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final edicao = widget.edicao;
    return Scaffold(
      appBar: edicao ? AppBar(title: const Text('Editar perfil')) : null,
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
                    if (!edicao) ...[
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
                    ],
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
                        // idade entre 1 e 120
                        final idade = int.tryParse(valor?.trim() ?? '');
                        if (idade == null || idade < 1 || idade > 120) {
                          return 'Informe uma idade válida (1 a 120).';
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
                        // peso entre 20 e 500 (aceita vírgula)
                        final peso = double.tryParse(
                          (valor ?? '').trim().replaceAll(',', '.'),
                        );
                        if (peso == null || peso < 20 || peso > 500) {
                          return 'Informe um peso válido (20 a 500 kg).';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _alturaController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Altura',
                        suffixText: 'cm',
                        border: OutlineInputBorder(),
                      ),
                      validator: (valor) {
                        // altura entre 100 e 250
                        final altura = int.tryParse(valor?.trim() ?? '');
                        if (altura == null || altura < 100 || altura > 250) {
                          return 'Informe uma altura válida (100 a 250 cm).';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: _sexoSelecionado,
                      decoration: const InputDecoration(
                        labelText: 'Sexo',
                        border: OutlineInputBorder(),
                      ),
                      items: Perfil.sexos
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: _salvando
                          ? null
                          : (valor) => setState(() => _sexoSelecionado = valor),
                      validator: (valor) =>
                          valor == null ? 'Escolha uma opção.' : null,
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: _metaSelecionada,
                      decoration: const InputDecoration(
                        labelText: 'Sua meta',
                        border: OutlineInputBorder(),
                      ),
                      items: Perfil.metas
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
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Pratica atividade física?'),
                      value: _praticaAtividade,
                      onChanged: _salvando
                          ? null
                          : (v) => setState(() => _praticaAtividade = v),
                    ),
                    if (_praticaAtividade)
                      DropdownButtonFormField<int>(
                        initialValue: _diasAtividade,
                        decoration: const InputDecoration(
                          labelText: 'Quantos dias por semana?',
                          border: OutlineInputBorder(),
                        ),
                        items: List.generate(
                          7,
                          (i) => DropdownMenuItem(
                            value: i + 1,
                            child: Text(i == 0 ? '1 dia' : '${i + 1} dias'),
                          ),
                        ),
                        onChanged: _salvando
                            ? null
                            : (v) => setState(() => _diasAtividade = v ?? 3),
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
                          : Text(edicao ? 'Salvar alterações' : 'Salvar e continuar'),
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
