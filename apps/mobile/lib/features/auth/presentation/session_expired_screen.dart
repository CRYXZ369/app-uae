import 'package:material_ui/material_ui.dart';

import '../../../core/widgets/app_error_screen.dart';

class SessionExpiredScreen extends StatelessWidget {
  const SessionExpiredScreen({required this.onSignIn, super.key});

  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    return AppErrorScreen(
      title: 'Sesión expirada',
      message: 'Tu sesión terminó. Inicia sesión de nuevo para continuar.',
      actionLabel: 'Iniciar sesión',
      onAction: (_) => onSignIn(),
    );
  }
}
