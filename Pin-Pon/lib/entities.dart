import 'dart:math' as math;

class Pelota {
  double x;
  double y;
  int dx;
  int dy;
  double velocidad;

  Pelota({
    required this.x,
    required this.y,
    this.dx = 1,
    this.dy = 1,
    this.velocidad = 1.0,
  });

  int get xEntero => x.round();
  int get yEntero => y.round();

  int get velocidadVertical =>
      math.max(1, math.min(3, (velocidad * 0.5).round()));

  void mover() {
    x += dx * velocidad;
    y += dy * velocidadVertical;
  }

  void rebotarY() => dy = -dy;

  void rebotarX() => dx = -dx;

  void reiniciar(double centroX, double centroY) {
    x = centroX;
    y = centroY;
    dx = -dx;
  }
}

class Paleta {
  int y;
  final int x;
  final int alto;

  Paleta({required this.x, required this.y, required this.alto});

  void moverArriba({int pasos = 1}) {
    y = math.max(1, y - pasos);
  }

  void moverAbajo({int pasos = 1, required int limiteInferior}) {
    y = math.min(limiteInferior - 1 - alto, y + pasos);
  }
}