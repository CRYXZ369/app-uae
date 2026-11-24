import 'package:app_unificada_uae/features/grades/domain/course_grade_summary.dart';
import 'package:app_unificada_uae/features/grades/presentation/course_grades_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  const evaluations = [
    CourseGradeAssessment(name: 'Parcial 1', weightPercentage: 30),
    CourseGradeAssessment(name: 'Proyecto integrador', weightPercentage: 30),
    CourseGradeAssessment(name: 'Evaluación final', weightPercentage: 40),
  ];

  test('materia sin calificaciones muestra progreso cero y sin promedio', () {
    final summary = CourseGradeSummary.fromAssessments(
      courseName: 'Programación I',
      assessments: evaluations,
    );

    expect(summary.estimatedAverage, isNull);
    expect(summary.courseProgress, 0);
    expect(summary.hasCompletePlan, isTrue);
    expect(summary.isEstimate, isFalse);
  });

  test('calcula promedio ponderado estimado y progreso calificado', () {
    final summary = CourseGradeSummary.fromAssessments(
      courseName: 'Programación I',
      assessments: [
        const CourseGradeAssessment(
          name: 'Parcial 1',
          weightPercentage: 30,
          grade: 90,
        ),
        ...evaluations.skip(1),
      ],
    );

    expect(summary.estimatedAverage, 90);
    expect(summary.courseProgress, 30);
    expect(summary.isEstimate, isTrue);
  });

  test('no estima si el plan no suma cien por ciento', () {
    final summary = CourseGradeSummary.fromAssessments(
      courseName: 'Programación I',
      assessments: const [
        CourseGradeAssessment(
          name: 'Parcial 1',
          weightPercentage: 30,
          grade: 80,
        ),
      ],
    );

    expect(summary.estimatedAverage, isNull);
    expect(summary.hasCompletePlan, isFalse);
    expect(summary.courseProgress, 30);
  });

  test('rechaza calificaciones y ponderaciones fuera de escala', () {
    expect(
      () => CourseGradeSummary.fromAssessments(
        courseName: 'Programación I',
        assessments: const [
          CourseGradeAssessment(
            name: 'Parcial',
            weightPercentage: 100,
            grade: 101,
          ),
        ],
      ),
      throwsArgumentError,
    );
    expect(
      () => CourseGradeSummary.fromAssessments(
        courseName: 'Programación I',
        assessments: const [
          CourseGradeAssessment(name: 'Parcial', weightPercentage: 60),
          CourseGradeAssessment(name: 'Final', weightPercentage: 50),
        ],
      ),
      throwsArgumentError,
    );
  });

  testWidgets('muestra materia sin notas en modo de solo lectura', (
    tester,
  ) async {
    final summary = CourseGradeSummary.fromAssessments(
      courseName: 'Programación I',
      assessments: evaluations,
    );

    await tester.pumpWidget(
      MaterialApp(home: CourseGradesScreen(courses: [summary])),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Escala de 0 a 100. El promedio y el progreso son estimaciones, '
        'no calificaciones oficiales.',
      ),
      findsOneWidget,
    );
    expect(find.text('Programación I'), findsOneWidget);
    expect(find.text('Promedio estimado: sin calificaciones'), findsOneWidget);
    expect(
      find.text('Progreso del curso: 0.00% ponderado calificado'),
      findsOneWidget,
    );
    expect(find.text('Sin calificar'), findsNWidgets(3));
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(EditableText), findsNothing);
  });
}
