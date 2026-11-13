import 'package:flutter_test/flutter_test.dart';
import 'package:dietas_personalizadas/models/perfil.dart';

void main() {
  test('Perfil antigo sem altura e sexo e marcado como incompleto', () {
    const perfil = Perfil(nome: 'Ana', idade: 30, peso: 60, meta: 'Perder peso');
    expect(perfil.incompleto, isTrue);
  });

  test('Perfil completo nao e incompleto e calcula o IMC', () {
    const perfil = Perfil(
      nome: 'Ana',
      idade: 30,
      peso: 80,
      meta: 'Manter o peso',
      sexo: 'Feminino',
      alturaCm: 200,
    );
    expect(perfil.incompleto, isFalse);
    expect(perfil.imc, closeTo(20.0, 0.01));
  });

  test('Ajuste calorico da meta', () {
    Perfil comMeta(String m) => Perfil(nome: 'A', idade: 30, peso: 70, meta: m);
    expect(comMeta('Perder peso').ajusteCaloricoMeta, -500);
    expect(comMeta('Ganhar massa muscular').ajusteCaloricoMeta, 300);
    expect(comMeta('Manter o peso').ajusteCaloricoMeta, 0);
  });

  test('Multiplicador de atividade por dias na semana', () {
    double mult(bool pratica, int dias) => Perfil(
          nome: 'A',
          idade: 30,
          peso: 70,
          meta: 'Manter o peso',
          praticaAtividade: pratica,
          diasAtividade: dias,
        ).multiplicadorAtividade;
    expect(mult(false, 0), 1.2);
    expect(mult(true, 2), 1.375);
    expect(mult(true, 4), 1.55);
    expect(mult(true, 6), 1.725);
    expect(mult(true, 7), 1.9);
  });
}
