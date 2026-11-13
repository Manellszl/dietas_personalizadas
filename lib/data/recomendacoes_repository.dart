class SugestaoRefeicao {
  const SugestaoRefeicao({
    required this.nome,
    required this.categoria,
    required this.descricao,
  });

  final String nome;
  final String categoria;
  final String descricao;
}

class RecomendacoesRepository {
  static const int _quantidadePorDia = 4;
  static final DateTime _dataBase = DateTime.utc(2024, 1, 1);

  static List<SugestaoRefeicao> paraMeta(String meta) {
    return _sugestoesDoDia(meta);
  }

  static List<SugestaoRefeicao> _sugestoesDoDia(String meta) {
    final hoje = DateTime.now();
    final hojeUtc = DateTime.utc(hoje.year, hoje.month, hoje.day);
    final diasDesdeBase = hojeUtc.difference(_dataBase).inDays;

    final metaNormalizada = meta.trim().toLowerCase();
    final deslocamento = switch (metaNormalizada) {
      'ganhar massa muscular' => 0,
      'perder peso' => 5,
      'ganhar peso' => 10,
      'manter o peso' => 15,
      'melhorar hábitos alimentares' => 3,
      _ => 0,
    };

    final sugestoesDaMeta = switch (metaNormalizada) {
      'ganhar massa muscular' => _paraGanharMassa,
      'perder peso' => _paraPerderPeso,
      'ganhar peso' => _paraGanharPeso,
      'manter o peso' => _paraManterPeso,
      'melhorar hábitos alimentares' => _paraMelhorarHabitos,
      _ => const <SugestaoRefeicao>[],
    };

    final catalogoPorCategoria = <String, List<SugestaoRefeicao>>{
      'Café da manhã': [
        ..._cafesDaManha.map(
          (nome) => _criarSugestao(nome, 'Café da manhã'),
        ),
      ],
      'Almoço': [
        ..._almocos.map((nome) => _criarSugestao(nome, 'Almoço')),
      ],
      'Lanche': [
        ..._lanches.map((nome) => _criarSugestao(nome, 'Lanche')),
      ],
      'Jantar': [
        ..._jantares.map((nome) => _criarSugestao(nome, 'Jantar')),
      ],
    };

    for (final sugestao in [...sugestoesDaMeta, ..._sugestoesGerais]) {
      catalogoPorCategoria[sugestao.categoria]?.add(sugestao);
    }

    final categorias = catalogoPorCategoria.keys.toList();
    final sugestoesDoDia = <SugestaoRefeicao>[];

    for (var i = 0; i < _quantidadePorDia; i++) {
      final categoria = categorias[i];
      final opcoes = catalogoPorCategoria[categoria]!;
      final indice = (diasDesdeBase + deslocamento + i) % opcoes.length;
      sugestoesDoDia.add(opcoes[indice]);
    }

    return sugestoesDoDia;
  }

  static SugestaoRefeicao _criarSugestao(String nome, String categoria) {
    return SugestaoRefeicao(
      nome: nome,
      categoria: categoria,
      descricao:
          'Ideia para variar o cardápio. Ajuste ingredientes e porções '
          'às suas necessidades.',
    );
  }

  static const List<String> _cafesDaManha = [
    'Cuscuz com ovo e tomate',
    'Pão integral com queijo e mamão',
    'Aveia com banana e canela',
    'Tapioca com queijo e orégano',
    'Iogurte natural com fruta e aveia',
    'Omelete com tomate e cheiro-verde',
    'Pão com ovo mexido e uma fruta',
    'Mingau de aveia com maçã',
    'Cuscuz com queijo e banana',
    'Vitamina de banana com aveia',
    'Pão de queijo com fruta',
    'Crepioca com queijo',
    'Iogurte com mamão e granola',
    'Mandioca cozida com ovo',
    'Pão com ricota e tomate',
    'Panqueca de banana e aveia',
    'Milho cozido com queijo',
    'Ovos mexidos com pão e fruta',
    'Tapioca com frango desfiado',
    'Abacate amassado com pão',
  ];

  static const List<String> _almocos = [
    'Arroz, feijão, frango e salada',
    'Peixe assado com arroz e legumes',
    'Carne cozida com mandioca e couve',
    'Arroz, feijão, ovo e abóbora',
    'Frango grelhado com batata e salada',
    'Feijão tropeiro com couve e tomate',
    'Macarrão com carne moída e legumes',
    'Arroz, lentilha, frango e cenoura',
    'Carne moída com purê de batata e salada',
    'Peixe com purê de mandioca e legumes',
    'Arroz, feijão, carne e abobrinha',
    'Frango ensopado com milho e arroz',
    'Omelete com arroz, feijão e salada',
    'Sardinha com arroz, feijão e tomate',
    'Abóbora com carne e arroz',
    'Lombo assado com feijão e couve',
    'Arroz com legumes, feijão e ovo',
    'Frango desfiado com cuscuz e salada',
    'Carne de panela com batata e cenoura',
    'Arroz, feijão, peixe e vinagrete',
  ];

  static const List<String> _lanches = [
    'Banana com aveia',
    'Iogurte natural com fruta',
    'Pão com queijo e tomate',
    'Vitamina de mamão com leite',
    'Milho cozido',
    'Maçã com pasta de amendoim',
    'Cuscuz com queijo',
    'Tapioca com banana',
    'Pão com ovo cozido',
    'Mamão com aveia',
    'Queijo com goiabada e fruta',
    'Bolo caseiro de fubá com leite',
    'Mandioca cozida com queijo',
    'Iogurte com banana e granola',
    'Sanduíche de frango desfiado',
    'Pera com castanhas',
    'Crepioca simples',
    'Vitamina de abacate com leite',
    'Biscoito de polvilho com queijo',
    'Fruta da estação com iogurte',
  ];

  static const List<String> _jantares = [
    'Sopa de legumes com feijão',
    'Omelete com salada e mandioca',
    'Arroz, feijão, frango e legumes',
    'Peixe assado com batata e salada',
    'Canja de galinha com legumes',
    'Cuscuz com ovos e tomate',
    'Macarrão com legumes e frango',
    'Abóbora cozida com carne e feijão',
    'Sanduíche de queijo, tomate e folhas',
    'Arroz, feijão, ovo e couve',
    'Caldo de feijão com legumes',
    'Frango ensopado com batata',
    'Tapioca recheada com queijo e tomate',
    'Sardinha com purê de batata e salada',
    'Sopa de abóbora com frango',
    'Carne moída com legumes e arroz',
    'Mandioca com ovos e salada',
    'Feijão com arroz, couve e abóbora',
    'Panqueca de frango com salada',
    'Legumes refogados com ovos e arroz',
  ];

  static const List<SugestaoRefeicao> _paraGanharMassa = [
    SugestaoRefeicao(
      nome: 'Omelete com aveia e banana',
      categoria: 'Café da manhã',
      descricao: 'Ovos, aveia e banana em uma opção prática para começar o dia.',
    ),
    SugestaoRefeicao(
      nome: 'Arroz, feijão, frango e legumes',
      categoria: 'Almoço',
      descricao: 'Uma combinação de grãos, proteína e vegetais.',
    ),
    SugestaoRefeicao(
      nome: 'Iogurte natural com fruta e aveia',
      categoria: 'Lanche',
      descricao: 'Uma opção simples com fruta, cereal e iogurte.',
    ),
    SugestaoRefeicao(
      nome: 'Ovos, batata-doce e salada',
      categoria: 'Jantar',
      descricao: 'Refeição com ovos, tubérculo e vegetais.',
    ),
    SugestaoRefeicao(
      nome: 'Pão integral com ovos mexidos e mamão',
      categoria: 'Café da manhã',
      descricao: 'Uma combinação de pão, ovos e fruta.',
    ),
    SugestaoRefeicao(
      nome: 'Macarrão com carne moída e legumes',
      categoria: 'Almoço',
      descricao: 'Massa acompanhada de carne e vegetais.',
    ),
    SugestaoRefeicao(
      nome: 'Vitamina de leite, banana e aveia',
      categoria: 'Lanche',
      descricao: 'Uma bebida feita com leite, fruta e cereal.',
    ),
    SugestaoRefeicao(
      nome: 'Peixe, purê de mandioca e brócolis',
      categoria: 'Jantar',
      descricao: 'Peixe acompanhado de mandioca e vegetais.',
    ),
    SugestaoRefeicao(
      nome: 'Cuscuz com ovo e queijo',
      categoria: 'Café da manhã',
      descricao: 'Uma alternativa com cuscuz, ovo e queijo.',
    ),
    SugestaoRefeicao(
      nome: 'Arroz, feijão, carne e abóbora',
      categoria: 'Almoço',
      descricao: 'Uma refeição com grãos, carne e vegetal.',
    ),
    SugestaoRefeicao(
      nome: 'Sanduíche de frango com tomate',
      categoria: 'Lanche',
      descricao: 'Pão com frango e tomate para um lanche prático.',
    ),
    SugestaoRefeicao(
      nome: 'Panqueca de ovos com legumes',
      categoria: 'Jantar',
      descricao: 'Panqueca salgada acompanhada de vegetais.',
    ),
  ];

  static const List<SugestaoRefeicao> _paraPerderPeso = [
    SugestaoRefeicao(
      nome: 'Iogurte natural com fruta',
      categoria: 'Café da manhã',
      descricao: 'Uma opção simples com fruta e iogurte.',
    ),
    SugestaoRefeicao(
      nome: 'Arroz, feijão, frango e salada',
      categoria: 'Almoço',
      descricao: 'Combine grãos, uma fonte de proteína e vegetais.',
    ),
    SugestaoRefeicao(
      nome: 'Fruta com aveia',
      categoria: 'Lanche',
      descricao: 'Uma combinação prática para o intervalo entre refeições.',
    ),
    SugestaoRefeicao(
      nome: 'Omelete com legumes',
      categoria: 'Jantar',
      descricao: 'Ovos preparados com vegetais de sua preferência.',
    ),
    SugestaoRefeicao(
      nome: 'Pão integral com ricota e tomate',
      categoria: 'Café da manhã',
      descricao: 'Uma alternativa de pão com queijo e tomate.',
    ),
    SugestaoRefeicao(
      nome: 'Peixe assado, arroz e legumes',
      categoria: 'Almoço',
      descricao: 'Peixe acompanhado de arroz e vegetais.',
    ),
    SugestaoRefeicao(
      nome: 'Maçã com iogurte natural',
      categoria: 'Lanche',
      descricao: 'Fruta e iogurte em uma combinação simples.',
    ),
    SugestaoRefeicao(
      nome: 'Sopa de legumes com feijão',
      categoria: 'Jantar',
      descricao: 'Uma sopa com vegetais e feijão.',
    ),
    SugestaoRefeicao(
      nome: 'Ovo cozido, fruta e pão',
      categoria: 'Café da manhã',
      descricao: 'Uma combinação de ovo, fruta e pão.',
    ),
    SugestaoRefeicao(
      nome: 'Feijão, abóbora, arroz e couve',
      categoria: 'Almoço',
      descricao: 'Uma refeição variada com grãos e vegetais.',
    ),
    SugestaoRefeicao(
      nome: 'Cenoura e pepino com homus',
      categoria: 'Lanche',
      descricao: 'Vegetais servidos com pasta de grão-de-bico.',
    ),
    SugestaoRefeicao(
      nome: 'Frango desfiado com legumes',
      categoria: 'Jantar',
      descricao: 'Frango acompanhado de legumes variados.',
    ),
  ];

  static const List<SugestaoRefeicao> _paraGanharPeso = [
    SugestaoRefeicao(
      nome: 'Vitamina de banana com aveia',
      categoria: 'Café da manhã',
      descricao: 'Uma bebida com fruta e cereal.',
    ),
    SugestaoRefeicao(
      nome: 'Arroz, feijão, carne e legumes',
      categoria: 'Almoço',
      descricao: 'Uma refeição com grãos, carne e vegetais.',
    ),
    SugestaoRefeicao(
      nome: 'Pão com queijo e fruta',
      categoria: 'Lanche',
      descricao: 'Uma opção fácil de combinar e levar.',
    ),
    SugestaoRefeicao(
      nome: 'Macarrão com frango e vegetais',
      categoria: 'Jantar',
      descricao: 'Massa servida com frango e vegetais.',
    ),
    SugestaoRefeicao(
      nome: 'Cuscuz com ovos e queijo',
      categoria: 'Café da manhã',
      descricao: 'Cuscuz acompanhado de ovos e queijo.',
    ),
    SugestaoRefeicao(
      nome: 'Purê de batata, feijão e carne',
      categoria: 'Almoço',
      descricao: 'Uma combinação de tubérculo, feijão e carne.',
    ),
    SugestaoRefeicao(
      nome: 'Iogurte com granola e banana',
      categoria: 'Lanche',
      descricao: 'Iogurte servido com granola e fruta.',
    ),
    SugestaoRefeicao(
      nome: 'Arroz, lentilha e frango',
      categoria: 'Jantar',
      descricao: 'Uma refeição com arroz, lentilha e frango.',
    ),
    SugestaoRefeicao(
      nome: 'Pão com pasta de amendoim e banana',
      categoria: 'Café da manhã',
      descricao: 'Pão com pasta de amendoim e fruta.',
    ),
    SugestaoRefeicao(
      nome: 'Escondidinho de mandioca com carne',
      categoria: 'Almoço',
      descricao: 'Mandioca com carne em uma refeição caseira.',
    ),
    SugestaoRefeicao(
      nome: 'Abacate com iogurte',
      categoria: 'Lanche',
      descricao: 'Uma combinação simples de fruta e iogurte.',
    ),
    SugestaoRefeicao(
      nome: 'Omelete com batata e salada',
      categoria: 'Jantar',
      descricao: 'Omelete servida com batata e vegetais.',
    ),
  ];

  static const List<SugestaoRefeicao> _paraManterPeso = [
    SugestaoRefeicao(
      nome: 'Pão integral com ovo e fruta',
      categoria: 'Café da manhã',
      descricao: 'Uma combinação variada para iniciar o dia.',
    ),
    SugestaoRefeicao(
      nome: 'Arroz, feijão, peixe e salada',
      categoria: 'Almoço',
      descricao: 'Inclui grãos, proteína e vegetais.',
    ),
    SugestaoRefeicao(
      nome: 'Fruta com iogurte natural',
      categoria: 'Lanche',
      descricao: 'Uma opção simples para diferentes horários.',
    ),
    SugestaoRefeicao(
      nome: 'Sopa de legumes com frango',
      categoria: 'Jantar',
      descricao: 'Uma refeição com vegetais e frango.',
    ),
    SugestaoRefeicao(
      nome: 'Tapioca com queijo e tomate',
      categoria: 'Café da manhã',
      descricao: 'Tapioca recheada com queijo e tomate.',
    ),
    SugestaoRefeicao(
      nome: 'Carne, arroz, feijão e abobrinha',
      categoria: 'Almoço',
      descricao: 'Uma combinação de grãos, carne e vegetais.',
    ),
    SugestaoRefeicao(
      nome: 'Banana com aveia',
      categoria: 'Lanche',
      descricao: 'Fruta com cereal em um lanche rápido.',
    ),
    SugestaoRefeicao(
      nome: 'Omelete com salada e mandioca',
      categoria: 'Jantar',
      descricao: 'Ovos servidos com vegetais e mandioca.',
    ),
    SugestaoRefeicao(
      nome: 'Mingau de aveia com maçã',
      categoria: 'Café da manhã',
      descricao: 'Aveia preparada com maçã.',
    ),
    SugestaoRefeicao(
      nome: 'Frango, purê de abóbora e feijão',
      categoria: 'Almoço',
      descricao: 'Frango acompanhado de abóbora e feijão.',
    ),
    SugestaoRefeicao(
      nome: 'Queijo com goiaba',
      categoria: 'Lanche',
      descricao: 'Uma combinação simples de queijo e fruta.',
    ),
    SugestaoRefeicao(
      nome: 'Peixe com batata e legumes',
      categoria: 'Jantar',
      descricao: 'Peixe acompanhado de batata e vegetais.',
    ),
  ];

  static const List<SugestaoRefeicao> _paraMelhorarHabitos = [
    SugestaoRefeicao(
      nome: 'Fruta, aveia e iogurte natural',
      categoria: 'Café da manhã',
      descricao: 'Uma forma prática de incluir fruta e cereal na rotina.',
    ),
    SugestaoRefeicao(
      nome: 'Arroz, feijão, ovo e salada',
      categoria: 'Almoço',
      descricao: 'Uma combinação simples com grãos, proteína e vegetais.',
    ),
    SugestaoRefeicao(
      nome: 'Fruta da estação',
      categoria: 'Lanche',
      descricao: 'Escolha uma fruta disponível e de sua preferência.',
    ),
    SugestaoRefeicao(
      nome: 'Legumes, arroz e frango',
      categoria: 'Jantar',
      descricao: 'Uma opção com vegetais, grãos e proteína.',
    ),
    SugestaoRefeicao(
      nome: 'Pão com queijo branco e mamão',
      categoria: 'Café da manhã',
      descricao: 'Pão, queijo e fruta em uma opção simples.',
    ),
    SugestaoRefeicao(
      nome: 'Feijão tropeiro com couve e tomate',
      categoria: 'Almoço',
      descricao: 'Uma refeição com feijão e vegetais.',
    ),
    SugestaoRefeicao(
      nome: 'Milho cozido',
      categoria: 'Lanche',
      descricao: 'Uma opção simples feita com milho.',
    ),
    SugestaoRefeicao(
      nome: 'Abóbora, lentilha e ovo',
      categoria: 'Jantar',
      descricao: 'Uma combinação de legume, leguminosa e ovo.',
    ),
    SugestaoRefeicao(
      nome: 'Cuscuz com banana',
      categoria: 'Café da manhã',
      descricao: 'Cuscuz servido com fruta.',
    ),
    SugestaoRefeicao(
      nome: 'Arroz, feijão, sardinha e salada',
      categoria: 'Almoço',
      descricao: 'Grãos e sardinha acompanhados de salada.',
    ),
    SugestaoRefeicao(
      nome: 'Iogurte natural com mamão',
      categoria: 'Lanche',
      descricao: 'Iogurte acompanhado de mamão.',
    ),
    SugestaoRefeicao(
      nome: 'Mandioca, feijão e legumes',
      categoria: 'Jantar',
      descricao: 'Uma refeição com mandioca, feijão e vegetais.',
    ),
  ];

  static const List<SugestaoRefeicao> _sugestoesGerais = [
    SugestaoRefeicao(
      nome: 'Arroz integral com feijão',
      categoria: 'Almoço',
      descricao: 'Uma combinação tradicional que pode fazer parte de uma alimentação variada.',
    ),
    SugestaoRefeicao(
      nome: 'Fruta com iogurte natural',
      categoria: 'Lanche',
      descricao: 'Uma opção simples para incluir fruta na rotina.',
    ),
    SugestaoRefeicao(
      nome: 'Omelete com legumes',
      categoria: 'Jantar',
      descricao: 'Uma refeição prática com ovos e vegetais.',
    ),
    SugestaoRefeicao(
      nome: 'Pão com ovo e tomate',
      categoria: 'Café da manhã',
      descricao: 'Uma opção simples com pão, ovo e tomate.',
    ),
    SugestaoRefeicao(
      nome: 'Peixe com arroz e salada',
      categoria: 'Almoço',
      descricao: 'Peixe servido com arroz e vegetais.',
    ),
    SugestaoRefeicao(
      nome: 'Banana com aveia',
      categoria: 'Lanche',
      descricao: 'Fruta e cereal em uma combinação rápida.',
    ),
    SugestaoRefeicao(
      nome: 'Sopa de legumes',
      categoria: 'Jantar',
      descricao: 'Sopa preparada com vegetais disponíveis.',
    ),
    SugestaoRefeicao(
      nome: 'Cuscuz com queijo',
      categoria: 'Café da manhã',
      descricao: 'Cuscuz servido com queijo.',
    ),
  ];
}
