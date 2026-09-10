// ui.dart
import 'dart:io';

import 'game_config.dart';
import 'render.dart';

void pintarInicio() {
  Renderer.limpiarPantalla();
  final sb = StringBuffer();
  sb.writeln(Renderer.titulo('=== PIN-PON ===  1.1.0'));
  sb.writeln();
  sb.writeln('${Renderer.gris('  1.')} Jugar contra otra persona');
  sb.writeln('${Renderer.gris('  2.')} Jugar contra la IA');
  sb.writeln('${Renderer.gris('  3.')} Retos');
  sb.writeln('${Renderer.gris('  4.')} Salir');
  sb.writeln();
  sb.writeln(Renderer.gris('  Presiona el numero de tu eleccion.'));
  stdout.write(sb.toString());
}

void pintarDificultad(String modoTexto) {
  Renderer.limpiarPantalla();
  final sb = StringBuffer();
  sb.writeln(Renderer.titulo('=== ELIGE DIFICULTAD ==='));
  sb.writeln();
  sb.writeln('  Modo: ${Renderer.resaltar(modoTexto)}');
  sb.writeln();
  sb.writeln('${Renderer.gris('  1.')} Facil   - paleta grande y pelota lenta');
  sb.writeln('${Renderer.gris('  2.')} Medio   - velocidad progresiva');
  sb.writeln('${Renderer.gris('  3.')} Dificil - pelota rapida y paleta pequeña');
  sb.writeln();
  sb.writeln('${Renderer.gris('  R.')} Volver   ${Renderer.gris('Q.')} Salir');
  stdout.write(sb.toString());
}

void pintarRetos(List<Reto> retos, Set<int> completados) {
  Renderer.limpiarPantalla();
  final sb = StringBuffer();
  sb.writeln(Renderer.titulo('=== RETOS ==='));
  sb.writeln();
  for (int i = 0; i < retos.length; i++) {
    final reto = retos[i];
    final marca = completados.contains(reto.id)
        ? Renderer.verde('[X]')
        : Renderer.gris('[ ]');
    final nombre = Renderer.resaltar(reto.nombre);
    sb.writeln('  ${i + 1}. $marca $nombre - ${reto.descripcion}');
  }
  sb.writeln();
  sb.writeln('${Renderer.gris('  R.')} Volver   ${Renderer.gris('Q.')} Salir');
  stdout.write(sb.toString());
}

void pintarFin(String mensaje) {
  Renderer.limpiarPantalla();
  final sb = StringBuffer();
  sb.writeln(Renderer.titulo('=== FIN DE LA PARTIDA ==='));
  sb.writeln();
  sb.writeln('  $mensaje');
  sb.writeln();
  sb.writeln(Renderer.gris('  Presiona cualquier tecla para volver.'));
  stdout.write(sb.toString());
}

String descripcionModo(ModoJuego modo, [Reto? reto]) {
  if (modo == ModoJuego.reto) {
    return 'Reto: ${reto?.nombre ?? ''}';
  }
  if (modo == ModoJuego.dosJugadores) {
    return '2 Jugadores';
  }
  return 'Vs IA';
}