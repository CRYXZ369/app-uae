import 'package:material_ui/material_ui.dart';

import '../../../core/session/session_store.dart';
import '../../grades/domain/course_grade_summary.dart';
import '../../grades/presentation/course_grades_screen.dart';
import '../../academic/presentation/academic_module_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    required this.onLogout,
    required this.email,
    required this.loadCourseGrades,
    required this.loadAcademicModule,
    super.key,
  });

  final Future<void> Function() onLogout;
  final String email;
  final Future<List<CourseGradeSummary>> Function() loadCourseGrades;
  final Future<List<Map<String, dynamic>>> Function(String module)
  loadAcademicModule;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoggingOut = false;
  String? _errorMessage;
  int _tab = 0;

  String get _firstName {
    final local = widget.email.split('@').first.split('.').first;
    if (local.isEmpty) return 'Estudiante';
    return '${local[0].toUpperCase()}${local.substring(1)}';
  }

  Future<void> _logout() async {
    if (_isLoggingOut) return;
    setState(() {
      _isLoggingOut = true;
      _errorMessage = null;
    });
    try {
      await widget.onLogout();
    } on SessionStorageException {
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
          _errorMessage = 'No se pudo cerrar sesión. Inténtalo de nuevo.';
        });
      }
    }
  }

  void _open(String title) {
    if (title == 'Calificaciones') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              CourseGradesScreen(loadCourses: widget.loadCourseGrades),
        ),
      );
      return;
    }
    if (const {
      'Materias',
      'Horarios',
      'Tareas',
      'Notificaciones',
      'Perfil',
    }.contains(title)) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => AcademicModuleScreen(
            title: title,
            loadRows: () => widget.loadAcademicModule(title),
          ),
        ),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _ModulePage(
          title: title,
          icon: _iconFor(title),
          message: 'Este módulo está contemplado para la aplicación. Su contenido estará disponible próximamente.',
        ),
      ),
    );
  }

  IconData _iconFor(String label) => switch (label) {
    'Materias' => Icons.menu_book,
    'Horarios' => Icons.calendar_month,
    'Tareas' => Icons.assignment,
    'Asistencia' => Icons.check_circle_outline,
    'Notificaciones' => Icons.notifications_none,
    _ => Icons.person_outline,
  };

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 600;
    return Scaffold(
      backgroundColor: const Color(0xfff1f3f6),
      body: SafeArea(child: _tab == 0 ? _home(compact) : _otherTab(compact)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            label: 'Materias',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_none),
            label: 'Notificaciones',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  Widget _home(bool compact) => CustomScrollView(
    slivers: [
      SliverToBoxAdapter(
        child: Container(
          color: const Color(0xff2949b4),
          padding: EdgeInsets.fromLTRB(
            compact ? 20 : 36,
            18,
            compact ? 20 : 36,
            22,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'MI CAMPUS',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => _open('Notificaciones'),
                    color: Colors.white,
                    icon: const Icon(Icons.notifications_none),
                  ),
                  PopupMenuButton<String>(
                    iconColor: Colors.white,
                    onSelected: (_) => _logout(),
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'logout',
                        child: Text('Cerrar sesión'),
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                '¡Hola, $_firstName!',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Todo listo para un gran día.',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 18),
              Card(
                color: Colors.white,
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xffe3edff),
                    child: Icon(Icons.person, color: Color(0xff2949b4)),
                  ),
                  title: const Text(
                    'Estudiante',
                    style: TextStyle(fontSize: 12, color: Color(0xff2949b4)),
                  ),
                  subtitle: const Text(
                    'Ingeniería en Sistemas\nCuarto semestre',
                    style: TextStyle(fontWeight: FontWeight.w600, height: 1.5),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _open('Perfil'),
                ),
              ),
            ],
          ),
        ),
      ),
      SliverPadding(
        padding: EdgeInsets.fromLTRB(
          compact ? 16 : 36,
          16,
          compact ? 16 : 36,
          24,
        ),
        sliver: SliverList.list(
          children: [
            Row(
              children: const [
                Expanded(
                  child: _MetricCard(
                    title: 'Promedio general',
                    value: '9.2',
                    icon: Icons.bar_chart,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    title: 'Asistencia',
                    value: '95 %',
                    icon: Icons.check_circle_outline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            const Text(
              'Tu universidad, a un toque',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xff24334f),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                for (final item in [
                  ('Materias', Icons.menu_book),
                  ('Calificaciones', Icons.bar_chart),
                  ('Horarios', Icons.calendar_month),
                  ('Tareas', Icons.assignment),
                  ('Asistencia', Icons.check_circle_outline),
                ])
                  Expanded(
                    child: _Shortcut(
                      label: item.$1,
                      icon: item.$2,
                      onTap: () => _open(item.$1),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 25),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Próximas clases',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff24334f),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => _open('Horarios'),
                  child: const Text('Ver horario'),
                ),
              ],
            ),
            Text(
              'HOY · MIÉRCOLES, 18 NOV',
              style: TextStyle(
                color: Colors.blueGrey.shade500,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            const _ClassCard(
              time: '09:00',
              end: '10:30',
              name: 'Programación orientada a objetos',
              place: 'Aula B-204',
              badge: 'En 30 min',
            ),
            const SizedBox(height: 10),
            const _ClassCard(
              time: '11:00',
              end: '12:30',
              name: 'Base de datos II',
              place: 'Laboratorio 3',
            ),
            const SizedBox(height: 20),
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
    ],
  );

  Widget _otherTab(bool compact) {
    final title = ['Inicio', 'Materias', 'Notificaciones', 'Perfil'][_tab];
    if (title != 'Inicio') {
      return AcademicModuleScreen(
        title: title,
        loadRows: () => widget.loadAcademicModule(title),
      );
    }
    return _ModulePage(
      title: title,
      icon: _iconFor(title),
      message: title == 'Perfil'
          ? widget.email
          : 'Aquí encontrarás tus $title.',
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
  });
  final String title, value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 7),
          Row(
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Icon(icon, color: const Color(0xff3159c8)),
            ],
          ),
        ],
      ),
    ),
  );
}

class _Shortcut extends StatelessWidget {
  const _Shortcut({
    required this.label,
    required this.icon,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xff3159c8),
            child: Icon(icon, size: 21),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 9),
          ),
        ],
      ),
    ),
  );
}

class _ClassCard extends StatelessWidget {
  const _ClassCard({
    required this.time,
    required this.end,
    required this.name,
    required this.place,
    this.badge,
  });
  final String time, end, name, place;
  final String? badge;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Column(
            children: [
              Text(
                time,
                style: const TextStyle(
                  color: Color(0xff3159c8),
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                end,
                style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
              ),
            ],
          ),
          const SizedBox(width: 14),
          const SizedBox(
            height: 38,
            child: VerticalDivider(
              width: 1,
              thickness: 2,
              color: Color(0xff5b82e8),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14),
                    Text(place, style: const TextStyle(fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          if (badge != null)
            Chip(label: Text(badge!, style: const TextStyle(fontSize: 10))),
        ],
      ),
    ),
  );
}

class _ModulePage extends StatelessWidget {
  const _ModulePage({
    required this.title,
    required this.icon,
    required this.message,
  });
  final String title, message;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: const Color(0xff3159c8)),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Volver al inicio'),
            ),
          ],
        ),
      ),
    ),
  );
}
