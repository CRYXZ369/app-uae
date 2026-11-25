import 'package:material_ui/material_ui.dart';

class CafeteriaScreen extends StatefulWidget {
  const CafeteriaScreen({super.key, this.userRole = 'ESTUDIANTE'});

  final String userRole;

  @override
  State<CafeteriaScreen> createState() => _CafeteriaScreenState();
}

class _CafeteriaScreenState extends State<CafeteriaScreen> {
  static const _menuItems = <_CafeteriaItem>[
    _CafeteriaItem(
      id: 1,
      name: 'Chilaquiles verdes con pollo',
      price: 55,
      category: 'Desayuno',
      icon: Icons.ramen_dining_outlined,
    ),
    _CafeteriaItem(
      id: 2,
      name: 'Molletes tradicionales',
      price: 35,
      category: 'Desayuno',
      icon: Icons.bakery_dining_outlined,
    ),
    _CafeteriaItem(
      id: 3,
      name: 'Torta de milanesa',
      price: 45,
      category: 'Comida',
      icon: Icons.lunch_dining_outlined,
    ),
    _CafeteriaItem(
      id: 4,
      name: 'Café americano · 12 oz',
      price: 22,
      category: 'Bebidas',
      icon: Icons.coffee_outlined,
    ),
    _CafeteriaItem(
      id: 5,
      name: 'Agua fresca del día · 500 ml',
      price: 18,
      category: 'Bebidas',
      icon: Icons.local_drink_outlined,
    ),
  ];

  static const _locations = ['Cafetería Arriba', 'Cafetería Abajo'];
  static const _categories = ['Todas', 'Desayuno', 'Comida', 'Bebidas'];
  final Map<int, int> _cart = {};
  String _location = 'Cafetería Arriba';
  String _category = 'Todas';
  bool _demoOrderSent = false;

  bool get _isTeacher => widget.userRole.toUpperCase() == 'DOCENTE';
  List<_CafeteriaItem> get _visibleItems => _category == 'Todas'
      ? _menuItems
      : _menuItems.where((item) => item.category == _category).toList();

  double get _cartTotal => _menuItems.fold<double>(
    0,
    (total, item) => total + item.price * (_cart[item.id] ?? 0),
  );

  int get _cartCount => _cart.values.fold(0, (sum, count) => sum + count);

  void _add(_CafeteriaItem item) => setState(() {
    _cart[item.id] = (_cart[item.id] ?? 0) + 1;
    _demoOrderSent = false;
  });

  void _remove(_CafeteriaItem item) => setState(() {
    final quantity = _cart[item.id] ?? 0;
    if (quantity <= 1) {
      _cart.remove(item.id);
    } else {
      _cart[item.id] = quantity - 1;
    }
  });

  void _confirmDemoOrder() {
    if (_cart.isEmpty) return;
    setState(() {
      _demoOrderSent = true;
      _cart.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pedido demo registrado; no se envió a cocina.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Cafetería UAE'),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _isTeacher
                    ? const Color(0xfffff0cc)
                    : const Color(0xffe8f0fd),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _isTeacher ? 'Docente · demo' : 'Estudiante · demo',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _isTeacher
                      ? const Color(0xff825400)
                      : const Color(0xff315d96),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
    body: Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xffedf3fc),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                _isTeacher ? Icons.stars_rounded : Icons.info_outline_rounded,
                color: const Color(0xff315d96),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Menú y precios de demostración. Los pedidos no se envían a la cafetería.',
                  style: TextStyle(color: Color(0xff344e6f), height: 1.35),
                ),
              ),
            ],
          ),
        ),
        if (_demoOrderSent)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xffe8f5ed),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xffbde2ca)),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: Color(0xff27845a)),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Pedido de demostración registrado localmente.'),
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: SegmentedButton<String>(
            segments: [
              for (final location in _locations)
                ButtonSegment<String>(value: location, label: Text(location)),
            ],
            selected: {_location},
            onSelectionChanged: (value) =>
                setState(() => _location = value.first),
          ),
        ),
        SizedBox(
          height: 42,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              for (final category in _categories)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: _category == category,
                    onSelected: (_) => setState(() => _category = category),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            itemCount: _visibleItems.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = _visibleItems[index];
              final quantity = _cart[item.id] ?? 0;
              return Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xfff1f4f9),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(item.icon, color: const Color(0xff315d96)),
                    ),
                    title: Text(
                      item.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${item.category} · \$${item.price.toStringAsFixed(2)} MXN',
                      ),
                    ),
                    trailing: _QuantityControl(
                      quantity: quantity,
                      onDecrease: () => _remove(item),
                      onIncrease: () => _add(item),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xffe6ebf2))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Total · $_cartCount ${_cartCount == 1 ? 'producto' : 'productos'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xff718096),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '\$${_cartTotal.toStringAsFixed(2)} MXN',
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: Color(0xff243953),
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: _cart.isEmpty ? null : _confirmDemoOrder,
                  icon: const Icon(Icons.shopping_bag_outlined),
                  label: const Text('Pedir demo'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(140, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _CafeteriaItem {
  const _CafeteriaItem({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.icon,
  });

  final int id;
  final String name;
  final double price;
  final String category;
  final IconData icon;
}

class _QuantityControl extends StatelessWidget {
  const _QuantityControl({
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
  });

  final int quantity;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (quantity > 0) ...[
        IconButton(
          tooltip: 'Quitar una unidad',
          visualDensity: VisualDensity.compact,
          onPressed: onDecrease,
          icon: const Icon(Icons.remove_circle_outline),
        ),
        Text('$quantity', style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
      IconButton(
        tooltip: 'Agregar al pedido',
        visualDensity: VisualDensity.compact,
        onPressed: onIncrease,
        icon: const Icon(Icons.add_circle_outline, color: Color(0xff27845a)),
      ),
    ],
  );
}
