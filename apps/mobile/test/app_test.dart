import 'package:app_unificada_uae/app/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('muestra la pantalla inicial', (tester) async {
    await tester.pumpWidget(const AppUae());

    expect(find.text('App Unificada UAE'), findsOneWidget);
    expect(find.text('La aplicación está en desarrollo.'), findsOneWidget);
  });
}
