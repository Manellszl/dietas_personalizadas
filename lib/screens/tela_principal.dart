import 'dart:async';
import 'package:flutter/material.dart';

import '../models/perfil.dart';
import '../data/recomendacoes_repository.dart';
import '../data/calorias_repository.dart';
import '../data/refeicoes_repository.dart';
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

class _TelaPrincipalState extends State<TelaPrincipal> {
  final RefeicoesRepository _repository = RefeicoesRepository();

  int _paginaSelecionada = 0;
  int _coposAgua = 0;
  int _metaAgua = 2000;
  bool _salvandoAgua = false;
  bool _inicioCarregando = true;
  bool _maisSugestoes = false;
  List<RefeicaoSalva> _refeicoesHoje = [];
  int _metasMesHoje = 0;
  int _pedidoInicio = 0;
  static const _laranja = Color(0xFFF4510B);

  DateTime _dataSelecionada = DateTime.now();
  DateTime _mesCalendario = DateTime.now();

  List<RefeicaoSalva> _refeicoes = [];
  Map<String, ResumoDia> _resumos = {};

  Map<String, ResumoDia> _semana = {};
  final Set<int> _expandidas = {};
  bool _carregando = true;
  Timer? _timerDia;
  DateTime _ultimoHoje = DateTime.now();

  @override
  void dispose() {
    _timerDia?.cancel();
    super.dispose();
  }


  List<SugestaoRefeicao> get _sugestoes =>
      RecomendacoesRepository.paraMeta(widget.perfil.meta);

  int get _caloriasConsumidas {
    return _refeicoes
        .fold<double>(0, (total, refeicao) => total + refeicao.calorias)
        .round();
  }

  int? get _metaCaloriasDia {
    return CaloriasRepository.metaCaloricaDiaria(widget.perfil);
  }

  bool get _objetivoPerderPeso => widget.perfil.meta == 'Perder peso';

  bool get _objetivoGanharPeso =>
      widget.perfil.meta == 'Ganhar peso' ||
      widget.perfil.meta == 'Ganhar massa muscular';

  String _chaveData(DateTime data) {
    return _repository.dataComoTexto(data);
  }

  bool _avaliarMeta(int consumidas, int meta) {
    if (_objetivoPerderPeso) {
      return consumidas <= meta;
    }

    if (_objetivoGanharPeso) {
      return consumidas >= meta;
    }

    final margem = (meta * 0.05).round();

    return (consumidas - meta).abs() <= margem;
  }

  @override
  void initState() {
    super.initState();
    _carregarDia();
    _carregarCalendario();
    _carregarInicio();
    _timerDia = Timer.periodic(const Duration(seconds: 30), (_) {
      final agora = DateTime.now();
      if (_chaveData(agora) == _chaveData(_ultimoHoje)) return;
      final estavaHoje = _chaveData(_dataSelecionada) == _chaveData(_ultimoHoje);
      _ultimoHoje = agora;
      _carregarInicio();
      if (estavaHoje && mounted && !_carregando && ModalRoute.of(context)?.isCurrent == true) {
        _selecionarDia(agora);
      }
    });
  }

  Future<void> _carregarDia() async {
    if (mounted) {
      setState(() => _carregando = true);
    }

    try {
      await _repository.criarRefeicoesIniciaisSeVazio(_dataSelecionada);

      final resultado = await _repository.buscarRefeicoesDoDia(
        _dataSelecionada,
      );

      if (!mounted) return;

      setState(() {
        _refeicoes = resultado;
        _carregando = false;
      });
      await _carregarInicio();
    } catch (e) {
      if (!mounted) return;

      setState(() => _carregando = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao carregar refeições: $e')));
    }
  }

  Future<void> _carregarCalendario() async {
    try {
      final mes = _mesCalendario;
      final dia = _dataSelecionada;
      final inicio = DateTime(dia.year, dia.month, dia.day - dia.weekday + 1);
      final resultado = await _repository.buscarResumosDoMes(mes);
      final semana = await _repository.buscarResumosPeriodo(inicio, DateTime(inicio.year, inicio.month, inicio.day + 6));
      if (_chaveData(dia) != _chaveData(_dataSelecionada) || mes.year != _mesCalendario.year || mes.month != _mesCalendario.month) return;

      if (!mounted) return;

      setState(() {
        _resumos = resultado;
        _semana = semana;
      });
    } catch (e) {
      debugPrint('Erro ao carregar calendário: $e');
    }
  }

  Future<void> _atualizarResumoDia() async {
    if (!mounted) return;
    final meta = _metaCaloriasDia;

    if (meta == null) return;

    final possuiAlimentos = _refeicoes.any(
      (refeicao) => refeicao.alimentos.isNotEmpty,
    );

    if (!possuiAlimentos) {
      await _repository.removerResumoDia(_dataSelecionada);
      await _carregarCalendario();
      await _carregarInicio();
      return;
    }

    await _repository.salvarResumoDia(
      data: _dataSelecionada,
      meta: meta,
      consumidas: _caloriasConsumidas,
      atingiuMeta: _avaliarMeta(_caloriasConsumidas, meta),
    );

    await _carregarCalendario();
    await _carregarInicio();
  }

  Future<void> _selecionarDia(DateTime data) async {
    setState(() {
      _dataSelecionada = DateTime(data.year, data.month, data.day);

      _mesCalendario = DateTime(data.year, data.month);
    });

    await _carregarDia();
    await _carregarCalendario();
  }

  Future<void> _adicionarRefeicao() async {
    final nome = await showDialog<String>(
      context: context,
      builder: (_) => const _DialogAdicionarRefeicao(),
    );

    if (!mounted || nome == null || nome.trim().isEmpty) return;

    try {
      await _repository.adicionarRefeicaoRotina(nome.trim(), _dataSelecionada);

      await _carregarDia();
    } catch (e) {
      _mostrarErro('Não foi possível adicionar a refeição.');
    }
  }

  Future<void> _removerRefeicao(RefeicaoSalva refeicao) async {
    final id = refeicao.id;
    if (id == null) return;
    final rotina = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir refeição'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Como deseja excluir ${refeicao.nome}?'),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Somente deste dia'),
              subtitle: const Text('Exclui a refeição e seus alimentos nesta data.'),
              onTap: () => Navigator.pop(dialogContext, false),
            ),
            ListTile(
              leading: const Icon(Icons.event_busy, color: Colors.red),
              title: const Text('Excluir da rotina'),
              subtitle: const Text('Exclui desta data em diante, inclusive alimentos já registrados. Preserva os dias anteriores.'),
              onTap: () => Navigator.pop(dialogContext, true),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
        ],
      ),
    );
    if (!mounted || rotina == null) return;
    try {
      if (rotina) {
        final confirmar = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Confirmar exclusão da rotina'),
            content: Text('Excluir ${refeicao.nome} e seus alimentos desta data em diante? Esta ação não pode ser desfeita.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Excluir')),
            ],
          ),
        );
        if (!mounted || confirmar != true) return;
        await _repository.removerRefeicaoDaRotina(id: id, metaAtual: _metaCaloriasDia, avaliarMeta: _avaliarMeta);
      } else {
        await _repository.removerRefeicao(id);
      }
      if (!mounted) return;
      await _carregarDia();
      if (rotina) {
        await _carregarCalendario();
        await _carregarInicio();
      } else {
        await _atualizarResumoDia();
      }
    } catch (e) {
      if (mounted) _mostrarErro('Não foi possível excluir a refeição.');
    }
  }

  Future<void> _marcarRefeicao(RefeicaoSalva refeicao, bool marcada) async {
    if (refeicao.id == null) return;

    await _repository.salvarRefeicao(refeicao.copiarCom(concluida: marcada));

    await _carregarDia();
  }

  Future<void> _adicionarAlimento(RefeicaoSalva refeicao) async {
    if (refeicao.id == null) return;

    try {
      final personalizados = await _repository.buscarAlimentosPersonalizados();
      final favoritos = await _repository.buscarFavoritos();
      final recentes = await _repository.buscarRecentes();
      if (!mounted) return;
      final resultado = await showDialog<_RegistroAlimento>(
        context: context,
        builder: (_) => _DialogAlimento(
          catalogo: [...CaloriasRepository.alimentos, ...personalizados],
          favoritos: favoritos, recentes: recentes,
          onFavorito: _repository.definirFavorito,
        ),
      );
      if (!mounted || resultado == null) return;
      await _repository.adicionarAlimento(
        AlimentoSalvo(
          refeicaoId: refeicao.id!, nome: resultado.alimento.nome,
          gramas: resultado.gramas,
          caloriasPor100g: resultado.alimento.caloriasPor100g,
        ), personalizado: resultado.personalizado,
      );
      await _carregarDia();
      await _atualizarResumoDia();
    } catch (e) {
      _mostrarErro('Não foi possível salvar o alimento: $e');
    }
  }

  Future<void> _removerAlimento(AlimentoSalvo alimento) async {
    if (alimento.id == null) return;

    await _repository.removerAlimento(alimento.id!);

    await _carregarDia();
    await _atualizarResumoDia();
  }

  void _mostrarErro(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensagem)));
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

  // =========================================================
  // INÍCIO
  // =========================================================

  Future<void> _carregarInicio() async {
    final pedido = ++_pedidoInicio;
    final hoje = DateTime.now();
    try {
      await _repository.criarRefeicoesIniciaisSeVazio(hoje);
      final refeicoes = await _repository.buscarRefeicoesDoDia(hoje);
      final resumos = await _repository.buscarResumosDoMes(hoje);
      final agua = await _repository.buscarHidratacao(hoje);
      if (!mounted || pedido != _pedidoInicio || _chaveData(hoje) != _chaveData(DateTime.now())) return;
      setState(() {
        _refeicoesHoje = refeicoes;
        _metasMesHoje = resumos.values.where((r) => r.atingiuMeta && !r.data.isAfter(hoje)).length;
        if (!_salvandoAgua) {
          _coposAgua = agua.copos;
          _metaAgua = agua.metaMl;
        }
        _inicioCarregando = false;
      });
    } catch (e) {
      if (!mounted || pedido != _pedidoInicio) return;
      setState(() => _inicioCarregando = false);
      _mostrarErro('Erro ao carregar início: $e');
    }
  }

  Future<void> _salvarAgua(int copos, int meta) async {
    if (_salvandoAgua || copos < 0 || meta <= 0) return;
    final hoje = DateTime.now();
    setState(() => _salvandoAgua = true);
    try {
      await _repository.salvarHidratacao(hoje, copos, meta);
      if (!mounted) return;
      if (_chaveData(hoje) == _chaveData(DateTime.now())) {
        setState(() { _coposAgua = copos; _metaAgua = meta; });
      }
    } catch (e) {
      _mostrarErro('Erro ao salvar hidratação: $e');
    } finally {
      if (mounted) {
        setState(() => _salvandoAgua = false);
        await _carregarInicio();
      }
    }
  }

  Future<void> _configurarAgua() async {
    final meta = await showDialog<int>(context: context, builder: (ctx) => SimpleDialog(
      title: const Text('Meta de hidratação'),
      children: [for (final ml in {1500, 2000, 2500, 3000, _metaAgua})
        SimpleDialogOption(onPressed: () => Navigator.pop(ctx, ml), child: Text('$ml ml'))],
    ));
    if (mounted && meta != null) await _salvarAgua(_coposAgua, meta);
  }

  Future<void> _abrirRefeicoesHoje() async {
    setState(() => _paginaSelecionada = 1);
    await _selecionarDia(DateTime.now());
  }

  Widget _cardInicio(Widget filho, {Color cor = Colors.white}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: cor, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE8E8E8))),
    child: filho,
  );

  Widget _resumoInicio(IconData icone, String titulo, String valor, String detalhe) => _cardInicio(Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [Icon(icone, color: _laranja, size: 28), const SizedBox(height: 10), Text(titulo, style: const TextStyle(fontSize: 12, color: Colors.black54)), const SizedBox(height: 5), Text(valor, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), Text(detalhe, style: const TextStyle(fontSize: 12, color: Colors.black54))],
  ));

  Widget _construirInicio() {
    final hoje = DateTime.now();
    const dias = ['Segunda-feira', 'Terça-feira', 'Quarta-feira', 'Quinta-feira', 'Sexta-feira', 'Sábado', 'Domingo'];
    const meses = ['janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho', 'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro'];
    const dicas = ['Varie os alimentos ao longo da semana.', 'Inclua frutas e verduras nas refeições.', 'Prefira água a bebidas açucaradas.', 'Coma com calma e preste atenção à saciedade.', 'Planeje suas refeições com antecedência.', 'Prefira alimentos in natura ou minimamente processados.', 'Respeite sua fome e mantenha hábitos sustentáveis.'];
    final nome = widget.perfil.nome.trim().split(RegExp(r'\s+')).first;
    final total = _refeicoesHoje.fold<double>(0, (s, r) => s + r.calorias).round();
    final meta = _metaCaloriasDia;
    final progresso = meta == null || meta <= 0 ? 0.0 : (total / meta).clamp(0.0, 1.0).toDouble();
    final registradas = _refeicoesHoje.where((r) => r.alimentos.isNotEmpty).length;
    final saldo = meta == null ? 0 : meta - total;
    return RefreshIndicator(
      color: _laranja, onRefresh: _carregarInicio,
      child: ListView(physics: const AlwaysScrollableScrollPhysics(), padding: EdgeInsets.zero, children: [
        Container(width: double.infinity, color: _laranja, padding: const EdgeInsets.fromLTRB(22, 12, 22, 26), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${dias[hoje.weekday - 1]}, ${hoje.day} de ${meses[hoje.month - 1]}', style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 10), Text('Olá, $nome!', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5), const Text('Sua alimentação, seu equilíbrio.', style: TextStyle(color: Colors.white)),
        ])),
        Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (_inicioCarregando) const LinearProgressIndicator(color: _laranja),
          _cardInicio(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Seu objetivo', style: TextStyle(color: Colors.black54)), Text(widget.perfil.meta, style: const TextStyle(color: _laranja, fontSize: 17, fontWeight: FontWeight.bold))])), const Icon(Icons.flag_outlined, color: _laranja, size: 32)]),
            const Divider(height: 28),
            Row(children: [SizedBox(width: 108, height: 108, child: Stack(alignment: Alignment.center, children: [SizedBox.expand(child: CircularProgressIndicator(value: progresso, strokeWidth: 10, color: _laranja, backgroundColor: const Color(0xFFFDE8DC))), Column(mainAxisSize: MainAxisSize.min, children: [Text(meta == null || meta <= 0 ? '—' : '${(total / meta * 100).round()}%', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), const Text('da meta', style: TextStyle(fontSize: 11))])])), const SizedBox(width: 18), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Consumidas hoje', style: TextStyle(color: Colors.black54)), Text('$total kcal', style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold)), Text(meta == null ? 'Complete seu perfil' : 'Meta: $meta kcal'), if (meta != null) Text(saldo > 0 ? 'Restam $saldo kcal até a meta' : saldo == 0 ? 'Valor da meta alcançado' : '${-saldo} kcal acima da meta', style: const TextStyle(color: _laranja, fontWeight: FontWeight.w600))]))]),
            const SizedBox(height: 20), SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: _abrirRefeicoesHoje, style: FilledButton.styleFrom(backgroundColor: _laranja, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(48)), icon: const Icon(Icons.add_circle_outline), label: const Text('Registrar refeições'))),
          ])),
          const SizedBox(height: 12), Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: _resumoInicio(Icons.restaurant_menu, 'Refeições de hoje', '$registradas de ${_refeicoesHoje.length}', 'Com alimentos')), const SizedBox(width: 10), Expanded(child: _resumoInicio(Icons.emoji_events_outlined, 'Metas atingidas', '$_metasMesHoje dias', 'Neste mês'))]),
          const SizedBox(height: 24), const Text('Sugestões para você', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)), const SizedBox(height: 10),
          if (_sugestoes.isNotEmpty) _cardInicio(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [const Icon(Icons.restaurant_menu, color: _laranja, size: 30), const Spacer(), Flexible(child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: _laranja, borderRadius: BorderRadius.circular(8)), child: Text(_sugestoes.first.categoria, style: const TextStyle(color: Colors.white))))]), const SizedBox(height: 12), Text(_sugestoes.first.nome, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)), const SizedBox(height: 6), Text(_sugestoes.first.descricao, style: const TextStyle(height: 1.4)), const Divider(height: 24), const Text('Sugestão em destaque', style: TextStyle(color: _laranja, fontWeight: FontWeight.w600))]), cor: const Color(0xFFFFFAEB)),
          if (_sugestoes.length > 1) ...[const SizedBox(height: 8), OutlinedButton.icon(onPressed: () => setState(() => _maisSugestoes = !_maisSugestoes), style: OutlinedButton.styleFrom(foregroundColor: _laranja), icon: Icon(_maisSugestoes ? Icons.expand_less : Icons.expand_more), label: Text(_maisSugestoes ? 'Ocultar sugestões' : 'Ver mais sugestões')), if (_maisSugestoes) ..._sugestoes.skip(1).map((s) => Card(child: ListTile(leading: const Icon(Icons.restaurant_menu, color: _laranja), title: Text(s.nome), subtitle: Text('${s.categoria} · ${s.descricao}'))))],
          const SizedBox(height: 16), _construirControleAgua(), const SizedBox(height: 16),
          _cardInicio(Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.lightbulb_outline, color: _laranja, size: 30), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Dica do dia', style: TextStyle(color: _laranja, fontWeight: FontWeight.bold)), const SizedBox(height: 5), Text(dicas[hoje.weekday - 1])]))]), cor: const Color(0xFFFFF0E5)),
        ])),
      ]),
    );
  }

  Widget _construirControleAgua() {
    final ml = _coposAgua * 250;
    final quantidadeIcones = (_metaAgua / 250).ceil();
    return _cardInicio(Column(children: [
      Row(children: [const Icon(Icons.water_drop_outlined, color: Colors.blue, size: 30), const SizedBox(width: 10), const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Hidratação', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)), Text('Seu consumo de água hoje', style: TextStyle(color: Colors.black54, fontSize: 12))])), IconButton(onPressed: _salvandoAgua || _inicioCarregando ? null : _configurarAgua, tooltip: 'Alterar meta', icon: const Icon(Icons.settings_outlined))]),
      const SizedBox(height: 12), Text('${(ml / 1000).toStringAsFixed(2).replaceAll('.', ',')} L', style: const TextStyle(color: Colors.blue, fontSize: 28, fontWeight: FontWeight.bold)), Text('Meta escolhida: $_metaAgua ml'), const SizedBox(height: 12),
      Wrap(alignment: WrapAlignment.center, children: [for (var i = 0; i < quantidadeIcones; i++) IconButton(visualDensity: VisualDensity.compact, tooltip: 'Registrar ${i + 1} copos', onPressed: _salvandoAgua || _inicioCarregando ? null : () => _salvarAgua(i + 1, _metaAgua), icon: Icon(Icons.local_drink, color: i < _coposAgua ? Colors.blue : Colors.grey.shade300))]),
      const SizedBox(height: 8), LinearProgressIndicator(value: (ml / _metaAgua).clamp(0.0, 1.0).toDouble(), color: Colors.blue, backgroundColor: const Color(0xFFE0F2FE), minHeight: 8), const SizedBox(height: 12),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [IconButton(onPressed: _coposAgua == 0 || _salvandoAgua || _inicioCarregando ? null : () => _salvarAgua(_coposAgua - 1, _metaAgua), icon: const Icon(Icons.remove_circle_outline, color: Colors.blue)), Column(children: [Text('$_coposAgua copos', style: const TextStyle(fontWeight: FontWeight.bold)), Text('$ml ml · 250 ml por copo')]), IconButton(onPressed: _salvandoAgua || _inicioCarregando ? null : () => _salvarAgua(_coposAgua + 1, _metaAgua), icon: const Icon(Icons.add_circle_outline, color: Colors.blue))]),
    ]));
  }

  // =========================================================
  // CALENDÁRIO
  // =========================================================

  Widget _construirCalendario() {
    final ano = _mesCalendario.year;
    final mes = _mesCalendario.month;

    final primeiroDia = DateTime(ano, mes, 1);
    final diasNoMes = DateTime(ano, mes + 1, 0).day;
    final deslocamento = primeiroDia.weekday - 1;

    const diasSemana = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

    const meses = [
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      _mesCalendario = DateTime(ano, mes - 1);
                    });
                    _carregarCalendario();
                  },
                  icon: const Icon(Icons.chevron_left),
                ),

                Text(
                  '${meses[mes - 1]} $ano',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                IconButton(
                  onPressed: () {
                    setState(() {
                      _mesCalendario = DateTime(ano, mes + 1);
                    });
                    _carregarCalendario();
                  },
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              children: diasSemana.map((dia) {
                return Expanded(
                  child: Center(
                    child: Text(
                      dia,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Color(0xFF667085),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 10),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 42,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 5,
                crossAxisSpacing: 5,
              ),
              itemBuilder: (context, indice) {
                final dia = indice - deslocamento + 1;

                if (dia < 1 || dia > diasNoMes) {
                  return const SizedBox();
                }

                final data = DateTime(ano, mes, dia);
                final chave = _chaveData(data);
                final resumo = _resumos[chave];

                final selecionado = _chaveData(_dataSelecionada) == chave;

                final hoje = _chaveData(DateTime.now()) == chave;

                Color cor = Colors.transparent;

                if (resumo != null) {
                  cor = resumo.atingiuMeta
                      ? const Color(0xFFB9EBC9)
                      : const Color(0xFFFFC5C5);
                }

                final Color corBordaSelecionada = resumo == null
                    ? Colors.grey
                    : resumo.atingiuMeta
                    ? const Color(0xFF16A34A)
                    : const Color(0xFFDC2626);

                return InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: () => _selecionarDia(data),
                  child: Container(
                    decoration: BoxDecoration(
                      color: cor,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: selecionado
                            ? corBordaSelecionada
                            : hoje
                            ? Colors.blue
                            : Colors.transparent,
                        width: selecionado || hoje ? 2 : 0,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$dia',
                      style: TextStyle(
                        fontWeight: selecionado || hoje
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: resumo != null
                            ? const Color(0xFF263238)
                            : Colors.black87,
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            const Wrap(
              alignment: WrapAlignment.center,
              spacing: 18,
              runSpacing: 8,
              children: [
                _LegendaCalendario(
                  cor: Color(0xFFB9EBC9),
                  texto: 'Meta atingida',
                ),
                _LegendaCalendario(
                  cor: Color(0xFFFFC5C5),
                  texto: 'Meta não atingida',
                ),
                _LegendaCalendario(cor: Colors.grey, texto: 'Sem registro'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // REFEIÇÕES
  // =========================================================

  Future<void> _editarAlimento(AlimentoSalvo alimento) async {
    if (alimento.id == null) return;
    final gramas = await showDialog<double>(context: context, builder: (_) => _DialogQuantidade(alimento: alimento));
    if (!mounted || gramas == null) return;
    try {
      await _repository.editarQuantidade(alimento.id!, gramas);
      await _carregarDia();
      await _atualizarResumoDia();
    } catch (e) { _mostrarErro('Não foi possível editar: $e'); }
  }

  Future<void> _copiarRefeicoes([String? nome]) async {
    final destino = _dataSelecionada;
    final ontem = DateTime(destino.year, destino.month, destino.day - 1);
    final origem = await showDatePicker(context: context, initialDate: ontem,
      firstDate: DateTime(1900), lastDate: DateTime(destino.year + 1),
      helpText: 'Escolha o dia de origem');
    if (!mounted || origem == null) return;
    if (_chaveData(origem) == _chaveData(destino)) { _mostrarErro('Escolha um dia diferente.'); return; }
    final confirmar = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text(nome == null ? 'Copiar refeições' : 'Copiar $nome'),
      content: const Text('Somente refeições vazias serão preenchidas. Os alimentos já registrados serão preservados.'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Copiar'))]));
    if (!mounted || confirmar != true) return;
    try {
      final total = await _repository.copiarAlimentos(origem, destino, nome: nome);
      if (!mounted) return;
      await _carregarDia();
      await _atualizarResumoDia();
      _mostrarErro(total == 0 ? 'Nenhum alimento copiado. Confira a origem e as refeições já preenchidas.' : '$total alimentos copiados.');
    } catch (e) { _mostrarErro('Não foi possível copiar: $e'); }
  }

  Widget _indicador(String titulo, String valor, Color cor) => Expanded(child: Column(children: [
    Text(titulo, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
    const SizedBox(height: 4), Text(valor, textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cor)),
  ]));

  Widget _painelCalorias() {
    final meta = _metaCaloriasDia;
    final total = _caloriasConsumidas;
    final saldo = meta == null ? 0 : meta - total;
    final progresso = meta == null || meta <= 0 ? 0.0 : (total / meta).clamp(0.0, 1.0).toDouble();
    final cor = meta != null && total > meta && !_objetivoGanharPeso ? Colors.red : const Color(0xFF00A64F);
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
      const Text('Resumo de calorias', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
      const SizedBox(height: 18),
      SizedBox(width: 190, height: 190, child: Stack(alignment: Alignment.center, children: [
        SizedBox.expand(child: CircularProgressIndicator(value: progresso, strokeWidth: 13, backgroundColor: Colors.grey.shade200, color: cor)),
        Column(mainAxisSize: MainAxisSize.min, children: [const Text('Consumidas'), Text('$total', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)), Text(meta == null ? 'kcal' : 'de $meta kcal')]),
      ])),
      const SizedBox(height: 20),
      Row(children: [_indicador('Meta', meta == null ? '—' : '$meta', Colors.blueGrey), _indicador('Consumidas', '$total', cor), _indicador(saldo < 0 ? 'Acima da meta' : 'Restantes', meta == null ? '—' : '${saldo.abs()}', cor)]),
      const SizedBox(height: 12),
      Text(meta == null ? 'Complete altura e sexo no perfil.' : _objetivoPerderPeso ? 'Objetivo: consumir até a meta diária.' : _objetivoGanharPeso ? 'Objetivo: consumir pelo menos a meta diária.' : 'Objetivo: permanecer próximo da meta diária.', textAlign: TextAlign.center),
      const SizedBox(height: 8), const Text('Estimativa educativa; não substitui avaliação nutricional.', style: TextStyle(fontSize: 11), textAlign: TextAlign.center),
    ])));
  }

  IconData _iconeRefeicao(String nome) {
    final n = CaloriasRepository.normalizar(nome);
    if (n.contains('cafe')) return Icons.coffee;
    if (n.contains('jantar')) return Icons.nightlight_round;
    if (n.contains('lanche')) return Icons.apple;
    return Icons.restaurant;
  }

  Widget _estatisticas() {
    final hoje = DateTime.now();
    final inicio = DateTime(_mesCalendario.year, _mesCalendario.month, 1);
    final fim = DateTime(_mesCalendario.year, _mesCalendario.month + 1, 0);
    final dias = inicio.isAfter(hoje) ? 0 : (fim.isBefore(hoje) ? fim.day : hoje.day);
    final registros = _resumos.values.where((r) => _chaveData(r.data).compareTo(_chaveData(hoje)) <= 0).toList();
    final atingidas = registros.where((r) => r.atingiuMeta).length;
    final falhas = registros.length - atingidas;
    final sem = (dias - registros.length).clamp(0, dias);
    final taxa = registros.isEmpty ? 0.0 : atingidas / registros.length;
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
      Text('Estatísticas — ${inicio.month}/${inicio.year}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
      const SizedBox(height: 16), Row(children: [_indicador('Atingidas', '$atingidas', Colors.green), _indicador('Não atingidas', '$falhas', Colors.red), _indicador('Sem registro', '$sem', Colors.grey)]),
      const SizedBox(height: 12), Text(registros.isEmpty ? 'Sem registros no mês' : 'Taxa de sucesso: ${(taxa * 100).round()}%'),
      const SizedBox(height: 8), LinearProgressIndicator(value: taxa, color: Colors.green),
      const SizedBox(height: 8), const Text('Considera dias registrados até hoje. O resultado de hoje ainda pode mudar.', style: TextStyle(fontSize: 11)),
    ])));
  }

  Widget _graficoSemana() {
    final d = _dataSelecionada;
    final inicio = DateTime(d.year, d.month, d.day - d.weekday + 1);
    final dias = List.generate(7, (i) => DateTime(inicio.year, inicio.month, inicio.day + i));
    final valores = dias.map((dia) => _semana[_chaveData(dia)]).toList();
    var maximo = 1;
    for (final r in valores) { if (r != null) { if (r.meta > maximo) maximo = r.meta; if (r.consumidas > maximo) maximo = r.consumidas; } }
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
      const Text('Consumo semanal', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
      Text('${inicio.day}/${inicio.month} a ${dias.last.day}/${dias.last.month}'),
      const SizedBox(height: 16),
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: List.generate(7, (i) {
        final r = valores[i];
        return Expanded(child: Tooltip(message: r == null ? 'Sem registro' : '${r.consumidas} kcal / meta ${r.meta}', child: Column(children: [
          SizedBox(height: 110, child: Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
            Flexible(child: Container(width: 12, height: r == null ? 0 : 110 * r.consumidas / maximo, color: Colors.green)), const SizedBox(width: 3),
            Flexible(child: Container(width: 12, height: r == null ? 0 : 110 * r.meta / maximo, color: Colors.blueGrey.shade300)),
          ])), const SizedBox(height: 4), Text(['S','T','Q','Q','S','S','D'][i]), Text(r == null ? '—' : '${r.consumidas}', style: const TextStyle(fontSize: 9)),
        ])));
      })), const SizedBox(height: 12), const Wrap(spacing: 12, children: [Text('■ Consumidas', style: TextStyle(color: Colors.green)), Text('■ Meta', style: TextStyle(color: Colors.blueGrey))]),
    ])));
  }

  Widget _construirRefeicoes() {
    return ListView(padding: const EdgeInsets.all(16), children: [
      const Text('Registro de refeições', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      Text('Data selecionada: ${_dataSelecionada.day}/${_dataSelecionada.month}/${_dataSelecionada.year}'),
      const SizedBox(height: 12), _construirCalendario(), const SizedBox(height: 12),
      if (_carregando) const Center(child: CircularProgressIndicator()) else ...[
        _painelCalorias(), const SizedBox(height: 12),
        Row(children: [Expanded(child: Text('${_refeicoes.length} refeições', style: const TextStyle(fontWeight: FontWeight.bold))), TextButton.icon(onPressed: () => _copiarRefeicoes(), icon: const Icon(Icons.copy), label: const Text('Copiar dia'))]),
        ..._refeicoes.map((r) => Card(margin: const EdgeInsets.only(bottom: 10), child: ExpansionTile(
          key: ValueKey(r.id), initiallyExpanded: _expandidas.contains(r.id),
          onExpansionChanged: (aberto) { if (r.id != null) { if (aberto) { _expandidas.add(r.id!); } else { _expandidas.remove(r.id); } } },
          leading: CircleAvatar(backgroundColor: const Color(0xFFE8F7EE), child: Icon(_iconeRefeicao(r.nome), color: const Color(0xFF00A64F))),
          title: Text(r.nome, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text('${r.alimentos.length} alimentos · ${r.calorias.toStringAsFixed(0)} kcal'),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12), children: [
            CheckboxListTile(value: r.concluida, onChanged: (v) => _marcarRefeicao(r, v ?? false), title: const Text('Refeição consumida'), controlAffinity: ListTileControlAffinity.leading),
            if (r.alimentos.isEmpty) const Padding(padding: EdgeInsets.all(8), child: Text('Nenhum alimento registrado.')),
            ...r.alimentos.map((a) => ListTile(contentPadding: EdgeInsets.zero, title: Text(a.nome), subtitle: Text('${a.gramas.toStringAsFixed(1)} g · ${a.calorias.toStringAsFixed(0)} kcal'), trailing: Row(mainAxisSize: MainAxisSize.min, children: [IconButton(tooltip: 'Editar quantidade', onPressed: () => _editarAlimento(a), icon: const Icon(Icons.edit_outlined)), IconButton(tooltip: 'Remover alimento', onPressed: () => _removerAlimento(a), icon: const Icon(Icons.delete_outline, color: Colors.red))]))),
            const Divider(), Wrap(alignment: WrapAlignment.center, children: [TextButton.icon(onPressed: () => _adicionarAlimento(r), icon: const Icon(Icons.add), label: const Text('Adicionar alimento')), TextButton.icon(onPressed: () => _copiarRefeicoes(r.nome), icon: const Icon(Icons.copy), label: const Text('Copiar refeição')), IconButton(tooltip: 'Remover refeição', onPressed: () => _removerRefeicao(r), icon: const Icon(Icons.delete_outline, color: Colors.red))]),
          ],
        ))),
      ],
      const SizedBox(height: 12), _estatisticas(), const SizedBox(height: 12), _graficoSemana(), const SizedBox(height: 80),
    ]);
  }

  // =========================================================
  // PERFIL
  // =========================================================

  Widget _linhaPerfil(IconData icone, String titulo, String valor) {
    return ListTile(
      leading: Icon(icone, color: const Color(0xFF98A2B3)),
      title: Text(titulo, style: const TextStyle(fontSize: 13)),
      trailing: Text(
        valor,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _construirPerfil() {
    final perfil = widget.perfil;
    final meta = _metaCaloriasDia;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: const Color(0xFF00A64F),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, color: Color(0xFF00A64F)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    perfil.nome,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        const Text(
          'Dados pessoais',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),

        Card(
          child: Column(
            children: [
              _linhaPerfil(
                Icons.cake_outlined,
                'Idade',
                '${perfil.idade} anos',
              ),
              _linhaPerfil(
                Icons.monitor_weight_outlined,
                'Peso',
                '${perfil.peso.toStringAsFixed(1)} kg',
              ),
              _linhaPerfil(
                Icons.height,
                'Altura',
                perfil.alturaCm == null
                    ? 'Não informada'
                    : '${perfil.alturaCm} cm',
              ),
              _linhaPerfil(
                Icons.person_outline,
                'Sexo',
                perfil.sexo ?? 'Não informado',
              ),
              _linhaPerfil(
                Icons.directions_run,
                'Atividade física',
                perfil.praticaAtividade
                    ? '${perfil.diasAtividade} dias por semana'
                    : 'Não pratica',
              ),
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

        const SizedBox(height: 12),

        if (perfil.incompleto)
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text(
              'Complete seu perfil informando altura e sexo.',
              style: TextStyle(color: Colors.red),
            ),
          ),

        FilledButton.icon(
          onPressed: _editarPerfil,
          icon: const Icon(Icons.edit),
          label: const Text('Editar perfil'),
        ),

        const SizedBox(height: 16),

        const Text(
          'Meta nutricional',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),

        Card(
          color: const Color(0xFFF0F5FF),
          child: ListTile(
            leading: const Icon(Icons.flag_outlined, color: Color(0xFF246BFD)),
            title: Text(perfil.meta),
            subtitle: Text(
              meta == null
                  ? 'Calorias diárias não calculadas'
                  : 'Meta diária: $meta kcal',
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // CONSTRUÇÃO PRINCIPAL
  // =========================================================

  @override
  Widget build(BuildContext context) {
    const titulos = ['Equilibra', 'Refeições', 'Meu perfil'];

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
          _construirInicio(),
          _construirRefeicoes(),
          _construirPerfil(),
        ],
      ),

      floatingActionButton: _paginaSelecionada == 1
          ? FloatingActionButton.extended(
              onPressed: _adicionarRefeicao,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar refeição'),
            )
          : null,

      bottomNavigationBar: NavigationBar(
        selectedIndex: _paginaSelecionada,
        indicatorColor: corCabecalho.withValues(alpha: 0.15),
        onDestinationSelected: (indice) {
          setState(() {
            _paginaSelecionada = indice;
          });
          if (indice == 0) _carregarInicio();
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

class _LegendaCalendario extends StatelessWidget {
  const _LegendaCalendario({required this.cor, required this.texto});

  final Color cor;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(texto, style: const TextStyle(fontSize: 11)),
      ],
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
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _enviar() {
    final nome = _controller.text.trim();

    if (nome.isEmpty) return;

    Navigator.of(context).pop(nome);
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
        FilledButton(onPressed: _enviar, child: const Text('Adicionar')),
      ],
    );
  }
}

class _RegistroAlimento {
  const _RegistroAlimento(this.alimento, this.gramas, this.personalizado);
  final AlimentoInfo alimento;
  final double gramas;
  final bool personalizado;
}

class _DialogAlimento extends StatefulWidget {
  const _DialogAlimento({required this.catalogo, required this.favoritos, required this.recentes, required this.onFavorito});
  final List<AlimentoInfo> favoritos, recentes;
  final Future<void> Function(AlimentoInfo, bool) onFavorito;
  final List<AlimentoInfo> catalogo;
  @override
  State<_DialogAlimento> createState() => _DialogAlimentoState();
}

class _DialogAlimentoState extends State<_DialogAlimento> {
  final _form = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _gramas = TextEditingController();
  final _calorias = TextEditingController();
  AlimentoInfo? _selecionado;
  bool _novo = false;
  int _aba = 0;
  late final List<AlimentoInfo> _favoritos = [...widget.favoritos];
  bool _favorito(AlimentoInfo a) => _favoritos.any((f) => CaloriasRepository.normalizar(f.nome) == CaloriasRepository.normalizar(a.nome));
  Future<void> _alternarFavorito(AlimentoInfo a) async {
    final novo = !_favorito(a);
    try {
      await widget.onFavorito(a, novo);
      if (!mounted) return;
      setState(() { if (novo) { _favoritos.add(a); } else { _favoritos.removeWhere((f) => CaloriasRepository.normalizar(f.nome) == CaloriasRepository.normalizar(a.nome)); } });
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao salvar favorito: $e'))); }
  }

  @override
  void dispose() {
    _nome.dispose();
    _gramas.dispose();
    _calorias.dispose();
    super.dispose();
  }

  double? _numero(String texto) => double.tryParse(texto.trim().replaceAll(',', '.'));

  void _salvar() {
    if (!_form.currentState!.validate()) return;
    final alimento = _novo
        ? AlimentoInfo(nome: _nome.text.trim(), caloriasPor100g: _numero(_calorias.text)!)
        : _selecionado!;
    FocusScope.of(context).unfocus();
    Navigator.of(context).pop(_RegistroAlimento(alimento, _numero(_gramas.text)!, _novo));
  }

  @override
  Widget build(BuildContext context) {
    final busca = CaloriasRepository.normalizar(_nome.text);
    final fonte = busca.isNotEmpty || _aba == 2 ? widget.catalogo : _aba == 0 ? widget.recentes : _favoritos;
    final opcoes = fonte.where((a) =>
        CaloriasRepository.normalizar(a.nome).contains(busca)).toList();
    final kcal = _novo ? _numero(_calorias.text) : _selecionado?.caloriasPor100g;
    final gramas = _numero(_gramas.text);
    final total = kcal != null && gramas != null && kcal.isFinite && gramas.isFinite
        ? kcal * gramas / 100 : null;
    return AlertDialog(
      scrollable: true,
      title: const Text('Adicionar alimento'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nome,
                decoration: const InputDecoration(labelText: 'Pesquisar alimento', prefixIcon: Icon(Icons.search), border: OutlineInputBorder()),
                onChanged: (_) => setState(() { _selecionado = null; _novo = false; }),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Informe o alimento.';
                  if (!_novo && _selecionado == null) return 'Selecione ou cadastre um alimento.';
                  return null;
                },
              ),
              if (_selecionado == null && !_novo) ...[
                const SizedBox(height: 8),
                Wrap(spacing: 6, children: List.generate(3, (i) => ChoiceChip(label: Text(['Recentes', 'Favoritos', 'Todos'][i]), selected: _aba == i, onSelected: (_) => setState(() { _aba = i; _nome.clear(); })))),
                if (opcoes.isEmpty) const Padding(padding: EdgeInsets.all(8), child: Text('Nenhum alimento nesta lista.')), 
                ...opcoes.take(busca.isEmpty ? 30 : 12).map((a) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(a.nome),
                  subtitle: Text('${a.caloriasPor100g} kcal/100 g'),
                  trailing: IconButton(tooltip: 'Favorito', onPressed: () => _alternarFavorito(a), icon: Icon(_favorito(a) ? Icons.star : Icons.star_border, color: Colors.amber)),
                  onTap: () => setState(() { _selecionado = a; _nome.text = a.nome; }),
                )),
                if (busca.isNotEmpty && !widget.catalogo.any((a) => CaloriasRepository.normalizar(a.nome) == busca))
                  TextButton.icon(onPressed: () => setState(() { _novo = true; _calorias.clear(); }), icon: const Icon(Icons.add), label: const Text('Cadastrar novo alimento')),
              ],
              if (_selecionado != null) Row(children: [Expanded(child: Text('${_selecionado!.caloriasPor100g} kcal por 100 g')), IconButton(tooltip: 'Favorito', onPressed: () => _alternarFavorito(_selecionado!), icon: Icon(_favorito(_selecionado!) ? Icons.star : Icons.star_border, color: Colors.amber))]),
              if (_novo) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _calorias,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Calorias por 100 g', suffixText: 'kcal', border: OutlineInputBorder()),
                  onChanged: (_) => setState(() {}),
                  validator: (v) { final n = _numero(v ?? ''); return n == null || !n.isFinite || n < 0 || n > 900 ? 'Informe de 0 a 900 kcal.' : null; },
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _gramas,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Quantidade consumida', suffixText: 'g', border: OutlineInputBorder()),
                onChanged: (_) => setState(() {}),
                validator: (v) { final n = _numero(v ?? ''); return n == null || !n.isFinite || n <= 0 || n > 5000 ? 'Informe uma quantidade válida.' : null; },
              ),
              if (total != null && total >= 0) Padding(padding: const EdgeInsets.only(top: 12), child: Text('Total: ${total.toStringAsFixed(1)} kcal')),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(onPressed: _salvar, child: const Text('Adicionar')),
      ],
    );
  }
}

class _DialogQuantidade extends StatefulWidget {
  const _DialogQuantidade({required this.alimento});
  final AlimentoSalvo alimento;
  @override
  State<_DialogQuantidade> createState() => _DialogQuantidadeState();
}
class _DialogQuantidadeState extends State<_DialogQuantidade> {
  final _form = GlobalKey<FormState>();
  late final _controller = TextEditingController(text: widget.alimento.gramas.toString());
  double? get _valor => double.tryParse(_controller.text.trim().replaceAll(',', '.'));
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AlertDialog(scrollable: true, title: Text(widget.alimento.nome), content: Form(key: _form, child: Column(mainAxisSize: MainAxisSize.min, children: [
    TextFormField(controller: _controller, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Quantidade', suffixText: 'g'), onChanged: (_) => setState(() {}), validator: (_) { final v = _valor; return v == null || !v.isFinite || v <= 0 || v > 5000 ? 'Informe de 0 a 5000 g (maior que zero).' : null; }),
    if (_valor != null && _valor!.isFinite && _valor! > 0) Text('${(_valor! * widget.alimento.caloriasPor100g / 100).toStringAsFixed(1)} kcal'),
  ])), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')), FilledButton(onPressed: () { if (_form.currentState!.validate()) { FocusScope.of(context).unfocus(); Navigator.pop(context, _valor); } }, child: const Text('Salvar'))]);
}
