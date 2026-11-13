import '../models/perfil.dart';

class AlimentoInfo {
  const AlimentoInfo({required this.nome, required this.caloriasPor100g});

  final String nome;
  final double caloriasPor100g;

  double caloriasNaPorcao(double gramas) {
    return caloriasPor100g * gramas / 100;
  }
}

class CaloriasRepository {
  static String normalizar(String texto) {
    var resultado = texto.trim().toLowerCase();
    const grupos = ['áàâãä', 'éèêë', 'íìîï', 'óòôõö', 'úùûü', 'ç'];
    const letras = ['a', 'e', 'i', 'o', 'u', 'c'];
    for (var i = 0; i < grupos.length; i++) {
      for (final letra in grupos[i].split('')) {
        resultado = resultado.replaceAll(letra, letras[i]);
      }
    }
    return resultado.replaceAll(RegExp(r'\s+'), ' ');
  }

  static const List<AlimentoInfo> alimentos = [
    AlimentoInfo(nome: 'Arroz branco cozido', caloriasPor100g: 128),
    AlimentoInfo(nome: 'Arroz integral cozido', caloriasPor100g: 124),
    AlimentoInfo(nome: 'Feijão cozido', caloriasPor100g: 76),
    AlimentoInfo(nome: 'Frango grelhado', caloriasPor100g: 159),
    AlimentoInfo(nome: 'Carne bovina cozida', caloriasPor100g: 250),
    AlimentoInfo(nome: 'Peixe assado', caloriasPor100g: 160),
    AlimentoInfo(nome: 'Ovo cozido', caloriasPor100g: 155),
    AlimentoInfo(nome: 'Batata cozida', caloriasPor100g: 87),
    AlimentoInfo(nome: 'Mandioca cozida', caloriasPor100g: 125),
    AlimentoInfo(nome: 'Macarrão cozido', caloriasPor100g: 157),
    AlimentoInfo(nome: 'Pão francês', caloriasPor100g: 300),
    AlimentoInfo(nome: 'Banana', caloriasPor100g: 89),
    AlimentoInfo(nome: 'Maçã', caloriasPor100g: 52),
    AlimentoInfo(nome: 'Tomate', caloriasPor100g: 18),
    AlimentoInfo(nome: 'Alface', caloriasPor100g: 15),
    AlimentoInfo(nome: 'Abóbora cozida', caloriasPor100g: 48),
    AlimentoInfo(nome: 'Queijo muçarela', caloriasPor100g: 300),
    AlimentoInfo(nome: 'Iogurte natural', caloriasPor100g: 61),
    AlimentoInfo(nome: 'Aveia', caloriasPor100g: 394),
  ];

  static double? metabolismoBasal(Perfil perfil) {
    final altura = perfil.alturaCm;
    final sexo = perfil.sexo?.trim().toLowerCase();

    if (altura == null || altura <= 0) return null;

    final ajusteSexo = switch (sexo) {
      'masculino' => 5,
      'feminino' => -161,
      _ => null,
    };

    if (ajusteSexo == null) return null;

    return (10 * perfil.peso) +
        (6.25 * altura) -
        (5 * perfil.idade) +
        ajusteSexo;
  }

  static int? metaCaloricaDiaria(Perfil perfil) {
    final basal = metabolismoBasal(perfil);
    if (basal == null) return null;

    final total =
        (basal * perfil.multiplicadorAtividade) + perfil.ajusteCaloricoMeta;

    return total.round();
  }
}
