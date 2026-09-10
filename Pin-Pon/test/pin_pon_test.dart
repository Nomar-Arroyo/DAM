import 'package:pin_pon/entities.dart';
import 'package:pin_pon/game_config.dart';
import 'package:pin_pon/pin_pon.dart';
import 'package:test/test.dart';

void main() {
  test('calculate', () {
    expect(calculate(), 42);
  });

  test('la pelota avanza segun su velocidad', () {
    final pelota = Pelota(x: 10, y: 10, velocidad: 2);
    pelota.mover();
    expect(pelota.xEntero, 12);
    expect(pelota.yEntero, 11);
  });

  test('la velocidad vertical se escala progresivamente', () {
    expect(Pelota(x: 0, y: 0, velocidad: 1).velocidadVertical, 1);
    expect(Pelota(x: 0, y: 0, velocidad: 4).velocidadVertical, 2);
    expect(Pelota(x: 0, y: 0, velocidad: 6).velocidadVertical, 3);
  });

  test('los rebotes invierten la direccion', () {
    final pelota = Pelota(x: 10, y: 10);
    pelota.rebotarX();
    pelota.rebotarY();
    expect(pelota.dx, -1);
    expect(pelota.dy, -1);
  });

  test('la paleta no sale de los limites', () {
    final paleta = Paleta(x: 2, y: 1, alto: 4);
    paleta.moverArriba();
    expect(paleta.y, 1);

    paleta.moverAbajo(pasos: 20, limiteInferior: GameConfig.alto);
    expect(paleta.y, GameConfig.alto - 1 - paleta.alto);
  });

  test('la velocidad progresiva crece hasta el maximo', () {
    final cfg = GameConfig.dificultades[Dificultad.medio]!;
    double velocidad(int puntos) {
      final base =
          cfg.velocidadInicial + puntos * GameConfig.incrementoVelocidadPorPunto;
      return base.clamp(cfg.velocidadInicial, cfg.velocidadMaxima).toDouble();
    }

    expect(velocidad(0), cfg.velocidadInicial);
    expect(velocidad(30), cfg.velocidadMaxima);
  });

  test('existen retos configurables', () {
    expect(GameConfig.retos, isNotEmpty);
    expect(GameConfig.retos.first.objetivo, greaterThan(0));
    expect(GameConfig.retos.any((r) => r.tiempoSegundos > 0), isTrue);
  });
}