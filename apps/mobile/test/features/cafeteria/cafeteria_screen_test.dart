import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:app_unificada_uae/features/cafeteria/presentation/cafeteria_screen.dart';

void main() {
  testWidgets('filtra menú demo y calcula el carrito', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: CafeteriaScreen()));

    expect(
      find.text(
        'Menú y precios de demostración. Los pedidos no se envían a la cafetería.',
      ),
      findsOneWidget,
    );
    expect(find.text('Cafetería Arriba'), findsOneWidget);
    expect(find.text('Cafetería Abajo'), findsOneWidget);
    await tester.tap(find.text('Cafetería Abajo'));
    await tester.pumpAndSettle();

    expect(find.text('Chilaquiles verdes con pollo'), findsOneWidget);
    expect(find.text('\$0.00 MXN'), findsOneWidget);

    await tester.tap(find.text('Bebidas'));
    await tester.pumpAndSettle();
    expect(find.text('Café americano · 12 oz'), findsOneWidget);
    expect(find.text('Chilaquiles verdes con pollo'), findsNothing);

    await tester.tap(find.byTooltip('Agregar al pedido').first);
    await tester.pumpAndSettle();
    expect(find.text('\$22.00 MXN'), findsOneWidget);
    await tester.tap(find.text('Pedir demo'));
    await tester.pumpAndSettle();
    expect(
      find.text('Pedido demo registrado; no se envió a cocina.'),
      findsOneWidget,
    );
  });

  testWidgets('indica la modalidad docente como demostración', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: CafeteriaScreen(userRole: 'DOCENTE')),
    );
    expect(find.text('Docente · demo'), findsOneWidget);
  });
}
