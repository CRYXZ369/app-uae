import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:app_unificada_uae/features/academic/presentation/tasks_screen.dart';

void main() {
  final rows = [
    {
      'id_tarea': 1,
      'titulo': 'Práctica de laboratorio',
      'descripcion': 'Resolver la guía del laboratorio.',
      'materia': 'Bases de datos',
      'docente': 'Elena Vargas',
      'fecha_entrega': '2026-11-26T23:59:00Z',
      'prioridad': 'ALTA',
      'estado': 'PENDIENTE',
      'entrega_tardia': false,
    },
    {
      'id_tarea': 2,
      'titulo': 'Reporte de proyecto',
      'descripcion': 'Reporte final.',
      'materia': 'Gestión de proyectos',
      'docente': 'Carlos Ruiz',
      'fecha_entrega': '2026-11-20T18:00:00Z',
      'prioridad': 'MEDIA',
      'estado': 'ENTREGADA',
      'entrega_tardia': true,
    },
  ];

  testWidgets('muestra tareas, permite filtrar y consultar el detalle', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: TasksScreen(loadTasks: () async => rows)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Práctica de laboratorio'), findsOneWidget);
    expect(find.text('Reporte de proyecto'), findsOneWidget);
    expect(find.text('1 pendiente'), findsOneWidget);

    await tester.tap(find.text('Entregadas  1'));
    await tester.pumpAndSettle();
    expect(find.text('Reporte de proyecto'), findsOneWidget);
    expect(find.text('Práctica de laboratorio'), findsNothing);

    await tester.tap(find.text('Reporte de proyecto'));
    await tester.pumpAndSettle();
    expect(find.text('Reporte final.'), findsOneWidget);
    expect(find.text('Entrega tardía'), findsOneWidget);
  });

  testWidgets('presenta un estado vacío cuando no hay tareas', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: TasksScreen(loadTasks: () async => const [])),
    );
    await tester.pumpAndSettle();

    expect(find.text('Aún no tienes tareas'), findsOneWidget);
  });
}
