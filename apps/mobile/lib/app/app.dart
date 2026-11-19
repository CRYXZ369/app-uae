import 'package:material_ui/material_ui.dart';

import '../core/widgets/app_error_screen.dart';
import '../features/home/presentation/home_screen.dart';
import 'app_routes.dart';

class AppUae extends StatelessWidget {
  const AppUae({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Unificada UAE',
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
      initialRoute: AppRoutes.home,
      routes: {
        AppRoutes.home: (_) => const HomeScreen(),
      },
      onUnknownRoute: (_) => MaterialPageRoute<void>(
        builder: (_) => AppErrorScreen(
          title: 'Pantalla no encontrada',
          message: 'No se encontró la pantalla solicitada.',
          actionLabel: 'Volver al inicio',
          onAction: (context) => Navigator.of(context)
              .pushNamedAndRemoveUntil(AppRoutes.home, (_) => false),
        ),
      ),
    );
  }
}
