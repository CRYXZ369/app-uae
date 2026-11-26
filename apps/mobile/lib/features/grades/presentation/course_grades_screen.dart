import 'package:material_ui/material_ui.dart';

import '../domain/course_grade_summary.dart';

class CourseGradesScreen extends StatefulWidget {
  const CourseGradesScreen({this.loadCourses, this.courses, super.key})
    : assert(loadCourses != null || courses != null);

  final Future<List<CourseGradeSummary>> Function()? loadCourses;
  final List<CourseGradeSummary>? courses;

  @override
  State<CourseGradesScreen> createState() => _CourseGradesScreenState();
}

class _CourseGradesScreenState extends State<CourseGradesScreen> {
  late Future<List<CourseGradeSummary>> _courses;

  @override
  void initState() {
    super.initState();
    _courses = widget.loadCourses != null
        ? widget.loadCourses!()
        : Future.value(widget.courses!);
  }

  void _retry() => setState(() => _courses = widget.loadCourses!());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calificaciones')),
      body: SafeArea(
        child: FutureBuilder<List<CourseGradeSummary>>(
          future: _courses,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _MessageState(
                icon: Icons.cloud_off,
                title: 'No se pudieron cargar las calificaciones',
                message: 'Revisa tu conexión e inténtalo de nuevo.',
                action: _retry,
              );
            }
            final courses = snapshot.data ?? const <CourseGradeSummary>[];
            if (courses.isEmpty) {
              return const _MessageState(
                icon: Icons.school_outlined,
                title: 'Aún no hay calificaciones',
                message: 'Cuando tus materias tengan un plan de evaluación, aparecerán aquí.',
              );
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xffedf3fc),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: Color(0xff315d96),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Escala de 0 a 100. El promedio y el progreso son '
                          'estimaciones, no calificaciones oficiales.',
                          style: TextStyle(
                            color: Color(0xff344e6f),
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
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
            );
          },
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });
  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? action;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          if (action != null) ...[
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: action,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ],
      ),
    ),
  );
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
              minHeight: 7,
              borderRadius: BorderRadius.circular(8),
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
