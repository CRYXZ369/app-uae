# Cafetería: prototipo de pedidos

## Implementado

- `apps/mobile/lib/features/cafeteria/presentation/cafeteria_screen.dart`:
  menú de demostración, filtros por categoría, carrito local y total.
- El acceso aparece para estudiantes y docentes. La etiqueta de rol es
  informativa; no implica prioridad real de servicio.
- Confirmar el carrito muestra un resultado local de demostración. No crea un
  pedido en base de datos ni lo envía a cocina.
- Los productos y precios son datos ilustrativos, no el menú oficial.

## Pendiente para el MVP

- Validar los menús, precios, disponibilidad y las cafeterías Arriba/Abajo con
  las personas responsables.
- Implementar API y persistencia para catálogo, carrito y pedidos.
- Definir el flujo real de preparación, entrega y cambios de estado.
- Crear la vista de operación para el rol de cafetería y protegerla en API.
- Confirmar si los docentes tienen atención prioritaria antes de habilitar ese
  comportamiento.

La pantalla no procesa pagos. Cualquier cobro debe seguir simulado y no se
deben almacenar datos de tarjetas.
