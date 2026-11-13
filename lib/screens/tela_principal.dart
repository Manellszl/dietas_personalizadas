import 'package:flutter/material.dart';
import '../models/perfil.dart';
import '../data/recomendacoes_repository.dart';
import 'tela_cadastro.dart';

class TelaPrincipal extends StatefulWidget {
  const TelaPrincipal({
    super.key,
    required this.perfil,
    required this.onEditarPerfil,
  });

  final Perfil perfil;
  final Future<void> Function(Perfil perfil) onEditarPerfil;

  @override
  State<TelaPrincipal> createState() => _TelaPrincipalState();
}

class _RefeicaoRegistro {
  _RefeicaoRegistro(this.nome);

  final String nome;
  bool concluida = false;
}

class _TelaPrincipalState extends State<TelaPrincipal> {
  int _paginaSelecionada = 0;
  int _coposAgua = 0;

  final List<_RefeicaoRegistro> _refeicoes = [
    _RefeicaoRegistro('Café da manhã'),
    _RefeicaoRegistro('Almoço'),
    _RefeicaoRegistro('Jantar'),
  ];

  List<SugestaoRefeicao> get _sugestoes =>
      RecomendacoesRepository.paraMeta(widget.perfil.meta);

  Future<void> _adicionarRefeicao() async {
    final nome = await showDialog<String>(
      context: context,
      builder: (context) => const _DialogAdicionarRefeicao(),
    );

    if (!mounted || nome == null || nome.isEmpty) return;

    setState(() {
      _refeicoes.add(_RefeicaoRegistro(nome));
    });
  }

  void _editarPerfil() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TelaCadastro(
          perfilInicial: widget.perfil,
          onSalvar: widget.onEditarPerfil,
        ),
      ),
    );
  }

  void _abrirRefeicoes() {
    setState(() => _paginaSelecionada = 1);
  }

  Widget _construirInicio(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
          color: const Color(0xFFF4510B),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.access_time, color: Colors.white, size: 16),
                  SizedBox(width: 7),
                  Text(
                    'Sugestões baseadas na sua meta',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  Spacer(),
                  Icon(Icons.restaurant, color: Colors.white, size: 22),
                ],
              ),
              SizedBox(height: 8),
              Text(
                'Opções para você',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFAEB),
                  border: Border.all(color: const Color(0xFFFFD9A8)),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         Expanded(
                          child: Text(
                            _sugestoes.first.nome,
                            style: TextStyle(
                              color: Color(0xFF263238),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4510B),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _sugestoes.first.categoria,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Meta: ${widget.perfil.meta}',
                      style: const TextStyle(
                        color: Color(0xFF667085),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _sugestoes.first.descricao,
                      style: const TextStyle(
                        color: Color(0xFF475467),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Mais sugestões para sua meta',
                style: TextStyle(
                  color: Color(0xFF475467),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              ..._sugestoes.skip(1).map(_cartaoSugestao),
              const SizedBox(height: 12),
              const Text(
                'Sugestões educativas; escolha os alimentos conforme suas '
                'preferências e disponibilidade. Não substituem orientação '
                'individual de nutricionista.',
                style: TextStyle(
                  color: Color(0xFF667085),
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              _construirControleAgua(),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _abrirRefeicoes,
                icon: const Icon(Icons.restaurant_menu),
                label: const Text('Registrar refeições'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 238, 83, 5),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _cartaoSugestao(SugestaoRefeicao sugestao) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xFFE4E7EC)),
        borderRadius: BorderRadius.circular(11),
      ),
      child: ListTile(
        leading: const Icon(
          Icons.restaurant_menu,
          color: Color.fromARGB(255, 129, 129, 130)
        ),
        title: Text(
          sugestao.nome,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF344054),
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text('${sugestao.categoria} · ${sugestao.descricao}'),
        ),
      ),
    );
  }

  Widget _construirControleAgua() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.water_drop, color: Color.fromARGB(255, 53, 161, 255), size: 30),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Água',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('Copos registrados: $_coposAgua'),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Remover um copo',
              onPressed: _coposAgua == 0
                  ? null
                  : () => setState(() => _coposAgua--),
              icon: const Icon(Icons.remove_circle_outline),
            ),
            IconButton(
              tooltip: 'Adicionar um copo',
              onPressed: () => setState(() => _coposAgua++),
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirRefeicoes() {
    final concluidas = _refeicoes.where((refeicao) => refeicao.concluida).length;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Registro de refeições',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text('$concluidas de ${_refeicoes.length} refeições marcadas.'),
        const SizedBox(height: 12),
        if (_refeicoes.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Ainda não há refeições. Toque em “Adicionar” para começar.',
              ),
            ),
          ),
        ..._refeicoes.asMap().entries.map((entrada) {
          final indice = entrada.key;
          final refeicao = entrada.value;

          return Card(
            child: Row(
              children: [
                Expanded(
                  child: CheckboxListTile(
                    value: refeicao.concluida,
                    title: Text(refeicao.nome),
                    secondary: const Icon(Icons.restaurant),
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (marcada) {
                      setState(() {
                        refeicao.concluida = marcada ?? false;
                      });
                    },
                    subtitle: refeicao.concluida
                        ? const Text('Marcada como consumida')
                        : null,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Remover refeição',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () {
                    setState(() => _refeicoes.removeAt(indice));
                  },
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 72),
      ],
    );
  }

  Widget _linhaPerfil(IconData icone, String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icone, size: 18, color: const Color(0xFF98A2B3)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              titulo,
              style: const TextStyle(
                color: Color(0xFF667085),
                fontSize: 13,
              ),
            ),
          ),
          Text(
            valor,
            style: const TextStyle(
              color: Color(0xFF344054),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirPerfil() {
    final perfil = widget.perfil;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
          color: const Color(0xFF00A64F),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 25,
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.person_outline,
                  color: Color(0xFF00A64F),
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bem-vinda(o)!',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      perfil.nome,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Dados pessoais',
                style: TextStyle(
                  color: Color(0xFF667085),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Column(
                    children: [
                      _linhaPerfil(
                        Icons.monitor_heart_outlined,
                        'Idade',
                        '${perfil.idade} anos',
                      ),
                      const Divider(height: 1),
                      _linhaPerfil(
                        Icons.monitor_weight_outlined,
                        'Peso',
                        '${perfil.peso.toStringAsFixed(1)} kg',
                      ),
                      const Divider(height: 1),
                      _linhaPerfil(
                        Icons.height,
                        'Altura',
                        perfil.alturaCm == null
                            ? 'Não informada'
                            : '${perfil.alturaCm} cm',
                      ),
                      const Divider(height: 1),
                      _linhaPerfil(
                        Icons.person_outline,
                        'Sexo',
                        perfil.sexo ?? 'Não informado',
                      ),
                      const Divider(height: 1),
                      _linhaPerfil(
                        Icons.directions_run,
                        'Atividade física',
                        perfil.praticaAtividade
                            ? '${perfil.diasAtividade} dia(s) por semana'
                            : 'Não pratica',
                      ),
                      const Divider(height: 1),
                      _linhaPerfil(
                        Icons.favorite_border,
                        'IMC',
                        perfil.imc == null
                            ? 'Não calculado'
                            : perfil.imc!.toStringAsFixed(1),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              // aviso pra quem cadastrou antes e não tem altura/sexo
              if (perfil.incompleto)
                const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Text(
                    'Complete seu perfil: faltam altura e sexo.',
                    style: TextStyle(color: Color(0xFFB3261E)),
                  ),
                ),
              FilledButton.icon(
                onPressed: _editarPerfil,
                icon: const Icon(Icons.edit),
                label: const Text('Editar perfil'),
              ),
              const SizedBox(height: 14),
              const Text(
                'Restrições alimentares',
                style: TextStyle(
                  color: Color(0xFF667085),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE8E8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Não informadas',
                  style: TextStyle(
                    color: Color(0xFFB42318),
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Meta nutricional',
                style: TextStyle(
                  color: Color(0xFF667085),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 0,
                color: const Color(0xFFF0F5FF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const Icon(
                    Icons.flag_outlined,
                    color: Color(0xFF246BFD),
                  ),
                  title: Text(
                    perfil.meta,
                    style: const TextStyle(
                      color: Color(0xFF344054),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text(
                    'Calorias diárias: não calculadas',
                    style: TextStyle(
                      color: Color(0xFF667085),
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Seus dados de perfil são salvos no banco do aplicativo. '
                'Os registros de refeições e água são temporários nesta versão.',
                style: TextStyle(
                  color: Color(0xFF667085),
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const titulos = ['Sugestões para você', 'Refeições', 'Perfil'];
    final corCabecalho = _paginaSelecionada == 0
        ? const Color(0xFFF4510B)
        : const Color(0xFF00A64F);

    return Scaffold(
      appBar: AppBar(
        title: Text(titulos[_paginaSelecionada]),
        backgroundColor: corCabecalho,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: IndexedStack(
        index: _paginaSelecionada,
        children: [
          _construirInicio(context),
          _construirRefeicoes(),
          _construirPerfil(),
        ],
      ),
      floatingActionButton: _paginaSelecionada == 1
          ? FloatingActionButton.extended(
              onPressed: _adicionarRefeicao,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _paginaSelecionada,
        onDestinationSelected: (indice) {
          setState(() => _paginaSelecionada = indice);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_menu_outlined),
            selectedIcon: Icon(Icons.restaurant_menu),
            label: 'Refeições',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

class _DialogAdicionarRefeicao extends StatefulWidget {
  const _DialogAdicionarRefeicao();

  @override
  State<_DialogAdicionarRefeicao> createState() =>
      _DialogAdicionarRefeicaoState();
}

class _DialogAdicionarRefeicaoState extends State<_DialogAdicionarRefeicao> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _enviar() {
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Adicionar refeição'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          labelText: 'Nome da refeição',
          hintText: 'Ex.: Lanche da tarde',
          border: OutlineInputBorder(),
        ),
        onSubmitted: (_) => _enviar(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _enviar,
          child: const Text('Adicionar'),
        ),
      ],
    );
  }
}