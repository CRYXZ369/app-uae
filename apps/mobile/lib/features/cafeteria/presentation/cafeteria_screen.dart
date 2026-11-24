import 'package:material_ui/material_ui.dart';

class CafeteriaScreen extends StatefulWidget {
  // Recibe el rol del usuario ('ESTUDIANTE' o 'DOCENTE')
  final String userRole;

  const CafeteriaScreen({super.key, this.userRole = 'ESTUDIANTE'});

  @override
  State<CafeteriaScreen> createState() => _CafeteriaScreenState();
}

class _CafeteriaScreenState extends State<CafeteriaScreen> {
  // Menú de ejemplo de la cafetería UAE
  final List> _menuItems = [
    {'id': 1, 'nombre': 'Chilaquiles Verdes c/ Pollo', 'precio': 55.0, 'categoria': 'Comida'},
    {'id': 2, 'nombre': 'Torta de Milanesa', 'precio': 45.0, 'categoria': 'Comida'},
    {'id': 3, 'nombre': 'Molletes Tradicionales (2 pzas)', 'precio': 35.0, 'categoria': 'Desayuno'},
    {'id': 4, 'nombre': 'Café Americano 12oz', 'precio': 22.0, 'categoria': 'Bebidas'},
    {'id': 5, 'nombre': 'Agua Fresca del Día 500ml', 'precio': 18.0, 'categoria': 'Bebidas'},
  ];

  // Carrito del usuario: {idProducto: cantidad}
  final Map<int, int> _carrito = {};
  bool _pedidoEnviado = false;

  double get _totalCarrito {
    double total = 0;
    _carrito.forEach((id, cantidad) {
      final item = _menuItems.firstWhere((e) => e['id'] == id);
      total += item['precio'] * cantidad;
    });
    return total;
  }

  void _agregarProducto(int id) {
    setState(() {
      _carrito[id] = (_carrito[id] ?? 0) + 1;
      _pedidoEnviado = false;
    });
  }

  void _quitarProducto(int id) {
    setState(() {
      if ((_carrito[id] ?? 0) > 1) {
        _carrito[id] = _carrito[id]! - 1;
      } else {
        _carrito.remove(id);
      }
    });
  }

  void _confirmarPedido() {
    if (_carrito.isEmpty) return;
    setState(() {
      _pedidoEnviado = true;
      _carrito.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.userRole == 'DOCENTE'
              ? 'Pedido prioritario de Docente enviado a cocina'
              : 'Pedido enviado. Pasa a recogerlo en 15 min',
        ),
        backgroundColor: Colors.green[700],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final esDocente = widget.userRole.toUpperCase() == 'DOCENTE';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cafetería UAE'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Chip(
              label: Text(
                esDocente ? 'Docente (Prioritario)' : 'Estudiante',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              backgroundColor: esDocente ? Colors.amber[200] : Colors.blue[100],
            ),
          )
        ],
      ),
      body: Column(
        children: [
          // Banner diferenciado por rol
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: esDocente ? Colors.amber[50] : Colors.blue[50],
            child: Row(
              children: [
                Icon(
                  esDocente ? Icons.star : Icons.info_outline,
                  color: esDocente ? Colors.amber[800] : Colors.blue[800],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    esDocente
                        ? 'Modo Docente: Tus pedidos tienen entrega rápida o envío a sala de maestros.'
                        : 'Ordena con anticipación para evitar filas en el receso.',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          if (_pedidoEnviado)
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                border: Border.all(color: Colors.green),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Expanded(child: Text('Tu orden está en preparación en cafetería.')),
                ],
              ),
            ),

          // Lista del menú
          Expanded(
            child: ListView.builder(
              itemCount: _menuItems.length,
              itemBuilder: (context, index) {
                final item = _menuItems[index];
                final cantidad = _carrito[item['id']] ?? 0;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text(item['nombre'], style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${item['categoria']} • \$${item['precio'].toStringAsFixed(2)} MXN'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (cantidad > 0) ...[
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                            onPressed: () => _quitarProducto(item['id']),
                          ),
                          Text('$cantidad', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                          onPressed: () => _agregarProducto(item['id']),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Barra inferior de resumen y botón de pedir
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total a pagar:', style: TextStyle(color: Colors.grey)),
                    Text(
                      '\$${_totalCarrito.toStringAsFixed(2)} MXN',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _carrito.isEmpty ? null : _confirmarPedido,
                  icon: const Icon(Icons.shopping_bag),
                  label: const Text('Hacer Pedido'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}