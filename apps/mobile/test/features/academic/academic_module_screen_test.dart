import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:app_unificada_uae/features/academic/presentation/academic_module_screen.dart';

void main() {
  testWidgets('renderiza materias y horarios con formato moderno', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AcademicModuleScreen(
          title: 'Materias',
          loadRows: () async => const [
            {
              'codigo': 'ITI-501',
              'materia': 'Diseño y Usabilidad',
              'grupo': '5ro A',
              'semestre': 5,
              'docente': 'Mtra. Ruth Marcela Romero',
            },
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ITI-501'), findsOneWidget);
    expect(find.text('Diseño y Usabilidad'), findsOneWidget);
    expect(find.text('Mtra. Ruth Marcela Romero'), findsOneWidget);
  });

  testWidgets('calcula resumen en asistencia estudiantil', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AcademicModuleScreen(
          title: 'Asistencia',
          loadRows: () async => const [
            {
              'actividad': 'Arquitectura Web',
              'estado': 'PRESENTE',
              'fecha_clase': '2026-11-24',
              'dia': 'Martes',
              'hora_inicio': '08:00:00',
            },
            {
              'actividad': 'Base de Datos',
              'estado': 'FALTA',
              'fecha_clase': '2026-11-23',
              'dia': 'Lunes',
              'hora_inicio': '10:00:00',
            },
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('50% de asistencia'), findsOneWidget);
    expect(find.text('Presente'), findsOneWidget);
    expect(find.text('Falta'), findsOneWidget);
  });
}
