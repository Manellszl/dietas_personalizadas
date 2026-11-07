class Perfil {
  const Perfil({
    required this.nome,
    required this.idade,
    required this.peso,
    required this.meta,
  });

  final String nome;
  final int idade;
  final double peso;
  final String meta;

  // Converte o registro do SQLite para um objeto usado pelo aplicativo.
  factory Perfil.fromMap(Map<String, Object?> map) {
    return Perfil(
      nome: map['nome'] as String,
      idade: map['idade'] as int,
      peso: (map['peso'] as num).toDouble(),
      meta: map['meta'] as String,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'nome': nome,
      'idade': idade,
      'peso': peso,
      'meta': meta,
    };
  }
}