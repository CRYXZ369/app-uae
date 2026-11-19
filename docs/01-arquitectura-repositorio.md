# Arquitectura y reglas del repositorio

## Decisión actual

Se usará un monorepo con tres capas:

```text
Flutter móvil -> API REST Java -> PostgreSQL/Supabase
                         ├── notificaciones
                         ├── ubicación de transporte
                         └── archivos/comprobantes
```

`services/desktop-legacy/backend-java` es una referencia temporal. No es la API móvil y no debe recibir nuevas pantallas ni lógica de negocio.

## Responsabilidades por carpeta

| Carpeta | Contenido | Regla |
|---|---|---|
| `apps/mobile` | Flutter, navegación, estado, componentes y consumo HTTP | No guardar secretos ni reglas críticas de autorización |
| `services/api-java` | API, autenticación, permisos, casos de uso y validaciones | Toda entrada externa se valida aquí |
| `database` | Migraciones SQL y datos de desarrollo | Una migración nueva por cambio de esquema |
| `docs` | Decisiones, contratos, flujos y manuales | Actualizar cuando cambie el comportamiento |
| `hardware-bomba` | Prototipo físico separado | No mezclarlo con la app institucional |

## Capas de la API

Dentro de `services/api-java`, cada módulo deberá seguir:

```text
module/
  controller/       Endpoints HTTP y códigos de respuesta
  service/          Casos de uso y transacciones
  repository/       Acceso a datos
  model/            Entidades y DTO
  validation/       Validaciones reutilizables
```

Los controladores no deben consultar SQL directamente. Los repositorios no deben decidir permisos ni enviar respuestas HTTP.

## Módulos previstos

`identity`, `academic`, `tasks`, `transport`, `cafeteria`, `commerce`, `billing`, `documents`, `announcements`, `polls`, `notifications` y `admin`.

Cada módulo debe definir objetivo, actores, endpoints, tablas, estados, permisos, errores y pruebas. El detalle funcional se encuentra en `02-modulos-y-mvp.md`.

## Flujo de una funcionalidad

1. Crear o actualizar la tarjeta en `docs/kanban.md`.
2. Definir el flujo y criterios de aceptación.
3. Diseñar tablas y contrato de API.
4. Implementar backend y pruebas.
5. Implementar pantalla Flutter con estados de carga, vacío y error.
6. Probar con datos de desarrollo.
7. Abrir Pull Request con capturas, pruebas y migraciones.

## Convenciones

- Java: paquetes `mx.edu.uae.api.<modulo>`, clases en `PascalCase`, métodos en `camelCase`.
- Flutter: carpetas por módulo y archivos en `snake_case.dart`.
- SQL: migraciones numeradas (`03_...sql`) y nombres en `snake_case`; la sintaxis objetivo es PostgreSQL.
- API: rutas plurales (`/api/v1/announcements`), JSON camelCase y errores consistentes.
- Fechas: ISO 8601 con zona horaria; dinero en centavos o `BigDecimal`, nunca `double`.
- Roles y permisos se validan en backend; ocultar un botón no es autorización.
