class Perfil {
  const Perfil({
    required this.nome,
    required this.idade,
    required this.peso,
    required this.meta,
    this.sexo,
    this.alturaCm,
    this.praticaAtividade = false,
    this.diasAtividade = 0,
  });

  final String nome;
  final int idade;
  final double peso;
  final String meta;

  // campos novos (vazios em quem já tinha cadastro)
  final String? sexo; // 'Masculino' ou 'Feminino'
  final int? alturaCm;
  final bool praticaAtividade;
  final int diasAtividade; // 0 a 7 dias por semana

  static const sexos = ['Masculino', 'Feminino'];

  static const metas = [
    'Ganhar massa muscular',
    'Perder peso',
    'Ganhar peso',
    'Manter o peso',
    'Melhorar hábitos alimentares',
  ];

  // perfil antigo não tem altura nem sexo
  bool get incompleto => sexo == null || alturaCm == null;

  // ajuste de calorias da meta
  // perder -500, ganhar +300, o resto 0
  int get ajusteCaloricoMeta {
    switch (meta) {
      case 'Perder peso':
        return -500;
      case 'Ganhar massa muscular':
      case 'Ganhar peso':
        return 300;
      default:
        return 0;
    }
  }

  // multiplicador pelos dias de atividade
  double get multiplicadorAtividade {
    if (!praticaAtividade || diasAtividade <= 0) return 1.2;
    if (diasAtividade <= 2) return 1.375;
    if (diasAtividade <= 4) return 1.55;
    if (diasAtividade <= 6) return 1.725;
    return 1.9;
  }

  // IMC (só se tiver altura)
  double? get imc {
    final h = alturaCm;
    if (h == null || h <= 0) return null;
    final m = h / 100;
    return peso / (m * m);
  }

  // Converte o registro do SQLite para um objeto usado pelo aplicativo.
  factory Perfil.fromMap(Map<String, Object?> map) {
    return Perfil(
      nome: map['nome'] as String,
      idade: map['idade'] as int,
      peso: (map['peso'] as num).toDouble(),
      meta: map['meta'] as String,
      sexo: map['sexo'] as String?,
      alturaCm: map['altura'] as int?,
      praticaAtividade: ((map['pratica_atividade'] as int?) ?? 0) == 1,
      diasAtividade: (map['dias_atividade'] as int?) ?? 0,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'nome': nome,
      'idade': idade,
      'peso': peso,
      'meta': meta,
      'sexo': sexo,
      'altura': alturaCm,
      'pratica_atividade': praticaAtividade ? 1 : 0,
      'dias_atividade': diasAtividade,
    };
  }
}
