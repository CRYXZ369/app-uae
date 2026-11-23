import 'package:material_ui/material_ui.dart';

import '../domain/course_grade_summary.dart';

class CourseGradesScreen extends StatelessWidget {
  const CourseGradesScreen({required this.courses, super.key});

  final List<CourseGradeSummary> courses;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calificaciones')),
      body: SafeArea(
        child: courses.isEmpty
            ? const Center(child: Text('Todavía no hay materias para mostrar.'))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Escala de 0 a 100. El promedio y el progreso son '
                        'estimaciones, no calificaciones oficiales.',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final course in courses) ...[
                    _CourseGradeCard(course: course),
                    const SizedBox(height: 12),
                  ],
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Solo el docente asignado puede registrar o actualizar '
                      'calificaciones.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _CourseGradeCard extends StatelessWidget {
  const _CourseGradeCard({required this.course});

  final CourseGradeSummary course;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final estimatedAverage = course.estimatedAverage;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(course.courseName, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              estimatedAverage == null
                  ? course.hasCompletePlan
                        ? 'Promedio estimado: sin calificaciones'
                        : 'Promedio estimado: falta completar las ponderaciones'
                  : 'Promedio estimado: '
                        '${estimatedAverage.toStringAsFixed(2)} / 100',
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: course.courseProgress / CourseGradeSummary.scaleMaximum,
            ),
            const SizedBox(height: 4),
            Text(
              'Progreso del curso: '
              '${course.courseProgress.toStringAsFixed(2)}% ponderado calificado',
            ),
            const Divider(height: 24),
            for (final assessment in course.assessments)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(assessment.name),
                subtitle: Text(
                  'Ponderación: '
                  '${assessment.weightPercentage.toStringAsFixed(2)}%',
                ),
                trailing: Text(
                  assessment.grade == null
                      ? 'Sin calificar'
                      : '${assessment.grade!.toStringAsFixed(2)} / 100',
                ),
              ),
          ],
        ),
      ),
    );
  }
}
