// Tests del historial de récords (persistencia con shared_preferences).

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pin_pon_app/juego/records.dart';

void main() {
  // shared_preferences necesita un binding y valores iniciales simulados.
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('el historial empieza vacío', () async {
    final almacen = AlmacenRecords();
    expect(await almacen.cargar(), isEmpty);
  });

  test('agregar guarda un registro y se puede recuperar', () async {
    final almacen = AlmacenRecords();
    await almacen.agregar(
      const RegistroPartida(
        modo: 'Dos jugadores',
        j1: 'Ana',
        j2: 'Luis',
        puntosJ1: 5,
        puntosJ2: 3,
        duracionMs: 45000,
        fecha: '2026-01-01T00:00:00.000',
      ),
    );

    final registros = await almacen.cargar();
    expect(registros, hasLength(1));
    expect(registros.first.j1, 'Ana');
    expect(registros.first.puntaje, 5);
    expect(registros.first.duracionSegundos, 45);
    expect(registros.first.marcador, '5 - 3');
  });

  test('limpiar borra todo el historial', () async {
    final almacen = AlmacenRecords();
    await almacen.agregar(
      const RegistroPartida(
        modo: 'Contra la IA',
        j1: 'Ana',
        j2: 'IA',
        puntosJ1: 1,
        puntosJ2: 2,
        duracionMs: 10000,
        fecha: '2026-01-01T00:00:00.000',
      ),
    );
    expect(await almacen.cargar(), hasLength(1));

    await almacen.limpiar();
    expect(await almacen.cargar(), isEmpty);
  });

  test('se conservan como máximo 50 partidas', () async {
    final almacen = AlmacenRecords();
    for (var i = 0; i < 55; i++) {
      await almacen.agregar(
        RegistroPartida(
          modo: 'Reto',
          j1: 'A',
          j2: 'B',
          puntosJ1: i,
          puntosJ2: 0,
          duracionMs: i * 1000,
          fecha: '2026-01-01T00:00:00.000',
        ),
      );
    }
    final registros = await almacen.cargar();
    expect(registros, hasLength(50));
    // El primero guardado (puntosJ1=0) se descartó: quedan del 5 al 54.
    expect(registros.first.puntosJ1, 5);
    expect(registros.last.puntosJ1, 54);
  });
}