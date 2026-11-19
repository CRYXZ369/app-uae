import 'dart:async';

import 'package:app_unificada_uae/app/app.dart';
import 'package:app_unificada_uae/core/widgets/app_error_screen.dart';
import 'package:app_unificada_uae/core/widgets/app_loading_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('muestra la pantalla inicial', (tester) async {
    await tester.pumpWidget(const AppUae());

    expect(find.text('App Unificada UAE'), findsOneWidget);
    expect(find.text('La aplicación está en desarrollo.'), findsOneWidget);
  });

  testWidgets('muestra una pantalla de carga con su mensaje', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AppLoadingScreen(message: 'Cargando datos')),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Cargando datos'), findsOneWidget);
  });

  testWidgets('muestra el error para rutas no registradas', (tester) async {
    await tester.pumpWidget(const AppUae());
    unawaited(
      tester.state<NavigatorState>(find.byType(Navigator)).pushNamed<void>(
        '/ruta-inexistente',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pantalla no encontrada'), findsOneWidget);
    expect(find.text('Volver al inicio'), findsOneWidget);
  });

  testWidgets('la acción de error regresa al inicio', (tester) async {
    await tester.pumpWidget(const AppUae());
    unawaited(
      tester.state<NavigatorState>(find.byType(Navigator)).pushNamed<void>(
        '/ruta-inexistente',
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Volver al inicio'));
    await tester.pumpAndSettle();

    expect(find.text('App Unificada UAE'), findsOneWidget);
  });

  testWidgets('la pantalla de error muestra el mensaje recibido', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AppErrorScreen(message: 'No fue posible completar la solicitud.'),
      ),
    );

    expect(find.text('Ocurrió un error'), findsOneWidget);
    expect(
      find.text('No fue posible completar la solicitud.'),
      findsOneWidget,
    );
  });
}
