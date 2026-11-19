import 'package:material_ui/material_ui.dart';

class AppUae extends StatelessWidget {
  const AppUae({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Unificada UAE',
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
      home: const Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'App Unificada UAE',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'La aplicación está en desarrollo.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
