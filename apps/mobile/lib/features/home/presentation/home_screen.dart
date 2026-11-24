import 'package:material_ui/material_ui.dart';

import '../../../core/session/session_store.dart';
import '../../grades/domain/course_grade_summary.dart';
import '../../grades/presentation/course_grades_screen.dart';
import '../../academic/presentation/academic_module_screen.dart';
import '../../academic/presentation/teacher_attendance_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    required this.onLogout,
    required this.email,
    required this.roles,
    required this.loadCourseGrades,
    required this.loadAcademicModule,
    required this.loadAttendanceRoster,
    required this.saveAttendance,
    super.key,
  });

  final Future<void> Function() onLogout;
  final String email;
  final List<String> roles;
  final Future<List<CourseGradeSummary>> Function() loadCourseGrades;
  final Future<List<Map<String, dynamic>>> Function(String module)
  loadAcademicModule;
  final AttendanceRosterLoader loadAttendanceRoster;
  final AttendanceSaver saveAttendance;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoggingOut = false;
  String? _errorMessage;
  int _tab = 0;

  Set<String> get _roleSet =>
      widget.roles.map((role) => role.toUpperCase()).toSet();
  bool get _isStudent => _roleSet.contains('ESTUDIANTE');
  String get _roleTitle {
    const names = {
      'ESTUDIANTE': 'Estudiante',
      'DOCENTE': 'Docente',
      'CAFETERIA': 'Cafetería',
      'CCE': 'Consejo Cultural Estudiantil',
      'ADMIN_ESCOLAR': 'Administración escolar',
      'GESTION_ACADEMICA': 'Gestión académica',
      'RECTORIA': 'Rectoría',
      'SOPORTE_TECNICO': 'Soporte técnico',
      'TRABAJADOR': 'Personal universitario',
      'DIRECTIVO': 'Directivo',
    };
    for (final role in widget.roles) {
      if (names.containsKey(role)) return names[role]!;
    }
    return 'Usuario UAE';
  }

  List<String> get _modules {
    final modules = <String>[];
    void add(List<String> values) {
      for (final value in values) {
        if (!modules.contains(value)) modules.add(value);
      }
    }

    if (_isStudent) {
      add(['Materias', 'Calificaciones', 'Horarios', 'Tareas', 'Asistencia']);
    }
    if (_roleSet.contains('DOCENTE')) {
      add(['Horarios', 'Materias', 'Tareas', 'Asistencia']);
    }
    if (_roleSet.contains('CAFETERIA')) {
      add(['Cafetería', 'Pedidos']);
    }
    if (_roleSet.contains('CCE')) {
      add(['Votaciones', 'Notificaciones']);
    }
    if (_roleSet.contains('ADMIN_ESCOLAR')) {
      add(['Pagos', 'Constancias', 'Perfil']);
    }
    if (_roleSet.contains('GESTION_ACADEMICA')) {
      add(['Materias', 'Horarios', 'Grupos']);
    }
    if (_roleSet.contains('RECTORIA') || _roleSet.contains('DIRECTIVO')) {
      add(['Avisos', 'Indicadores']);
    }
    if (_roleSet.contains('SOPORTE_TECNICO')) {
      add(['Usuarios', 'Roles', 'Incidencias']);
    }
    if (_roleSet.contains('TRABAJADOR')) {
      add(['Avisos']);
    }
    if (_roleSet.isEmpty) {
      add(['Materias', 'Calificaciones', 'Horarios', 'Tareas']);
    }
    if (!modules.contains('Notificaciones')) {
      add(['Notificaciones']);
    }
    if (!modules.contains('Perfil')) {
      add(['Perfil']);
    }
    return modules;
  }

  List<String> get _navigationModules {
    if (_isStudent) return ['Materias', 'Notificaciones', 'Perfil'];
    if (_roleSet.contains('DOCENTE')) {
      return ['Horarios', 'Asistencia', 'Perfil'];
    }
    if (_roleSet.contains('CAFETERIA')) {
      return ['Cafetería', 'Pedidos', 'Perfil'];
    }
    if (_roleSet.contains('CCE')) {
      return ['Votaciones', 'Notificaciones', 'Perfil'];
    }
    return _modules.take(3).toList();
  }

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
          _errorMessage = 'No se pudo cerrar la sesión en el servicio o en el dispositivo. Inténtalo de nuevo.';
        });
      }
    }
  }

  void _open(String title) {
    if (title == 'Asistencia' && _roleSet.contains('DOCENTE')) {
      Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => _moduleScreen(title)));
      return;
    }
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
      'Asistencia',
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
    'Grupos' => Icons.groups_outlined,
    'Cafetería' => Icons.restaurant,
    'Pedidos' => Icons.receipt_long,
    'Votaciones' => Icons.how_to_vote,
    'Pagos' => Icons.payments_outlined,
    'Constancias' => Icons.description_outlined,
    'Usuarios' => Icons.people_outline,
    'Roles' => Icons.admin_panel_settings_outlined,
    'Incidencias' => Icons.support_agent,
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
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          for (final module in _navigationModules)
            NavigationDestination(icon: Icon(_iconFor(module)), label: module),
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
                  TextButton.icon(
                    onPressed: _isLoggingOut ? null : _logout,
                    style: TextButton.styleFrom(foregroundColor: Colors.white),
                    icon: _isLoggingOut
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.logout, size: 18),
                    label: Text(
                      _isLoggingOut ? 'Cerrando...' : 'Cerrar sesión',
                    ),
                  ),
                ],
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.white),
                ),
              ],
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
                  title: Text(
                    _roleTitle,
                    style: TextStyle(fontSize: 12, color: Color(0xff2949b4)),
                  ),
                  subtitle: Text(
                    widget.email,
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
            _MetricCard(
              title: 'Sesión activa',
              value: _roleTitle,
              icon: Icons.dashboard_outlined,
            ),
            const SizedBox(height: 22),
            Text(
              _isStudent ? 'Tu universidad, a un toque' : 'Accesos de tu área',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xff24334f),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                for (final module in _modules.take(5))
                  Expanded(
                    child: _Shortcut(
                      label: module,
                      icon: _iconFor(module),
                      onTap: () => _open(module),
                    ),
                  ),
              ],
            ),
            if (_isStudent)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.calendar_month),
                  title: const Text('Consulta tus próximas clases'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _open('Horarios'),
                ),
              ),
          ],
        ),
      ),
    ],
  );

  Widget _otherTab(bool compact) {
    final title = _navigationModules[_tab - 1];
    if (title != 'Inicio') {
      return _moduleScreen(title);
    }
    return _ModulePage(
      title: title,
      icon: _iconFor(title),
      message: title == 'Perfil'
          ? widget.email
          : 'Aquí encontrarás tus $title.',
    );
  }

  Widget _moduleScreen(String title) {
    if (title == 'Asistencia' && _roleSet.contains('DOCENTE')) {
      return TeacherAttendanceScreen(
        loadSessions: () => widget.loadAcademicModule(title),
        loadRoster: widget.loadAttendanceRoster,
        saveAttendance: widget.saveAttendance,
      );
    }
    return AcademicModuleScreen(
      title: title,
      loadRows: () => widget.loadAcademicModule(title),
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
