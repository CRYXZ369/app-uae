import 'package:material_ui/material_ui.dart';

import '../state/session_controller.dart';

class SignOutButton extends StatelessWidget {
  const SignOutButton({
    required this.controller,
    required this.onSignedOut,
    super.key,
  });

  final SessionController controller;
  final VoidCallback onSignedOut;

  Future<void> _signOut(BuildContext context) async {
    try {
      await controller.signOut();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo cerrar la sesión. Inténtalo de nuevo.'),
          ),
        );
      }
      return;
    }
    if (context.mounted) onSignedOut();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => TextButton(
        onPressed:
            controller.status == SessionStatus.authenticated ||
                controller.status == SessionStatus.error
            ? () => _signOut(context)
            : null,
        child: const Text('Cerrar sesión'),
      ),
    );
  }
}
