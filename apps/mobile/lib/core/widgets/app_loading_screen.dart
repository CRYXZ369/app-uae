import 'package:material_ui/material_ui.dart';

class AppLoadingScreen extends StatelessWidget {
  const AppLoadingScreen({
    super.key,
    this.message = 'Cargando...',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(message),
            ],
          ),
        ),
      ),
    );
  }
}
