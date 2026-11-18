# Guía de trabajo del equipo

## Integrantes y responsabilidad inicial

| Integrante | Responsabilidad principal | Entregables iniciales |
|---|---|---|
| CRYXZ | Coordinación técnica, backend, base de datos e integración | Arquitectura, migraciones, autenticación, contratos de API y revisiones |
| Kike | Backend/API y transporte | Endpoints de transporte, rutas, paradas, confirmación de salida y pruebas |
| Donovan | Flutter y académico | Navegación, inicio, horarios, materias, tareas y estados de pantalla |
| Camila | Flutter/UI y comunidad | Sistema visual, avisos, votaciones, notificaciones y accesibilidad |
| Carlos | QA, documentación y apoyo operativo | Casos de prueba, datos de prueba, manuales, capturas y validación de flujos |

La distribución es inicial, no una barrera: cualquier integrante puede pedir revisión o apoyo. Carlos debe recibir tareas pequeñas, acotadas y con criterios de aceptación claros antes de tomar módulos críticos.

## Preparación de cada integrante

Todos deben instalar Git, JDK 17, Maven, Flutter stable, Android Studio o dispositivo de prueba, MySQL/MariaDB y un cliente REST. Cada persona debe poder clonar, crear rama, ejecutar el proyecto y abrir un Pull Request.

## Flujo de ramas

```text
main                  código revisado
feature/<modulo>-<tarea>
fix/<modulo>-<problema>
docs/<tema>
```

No trabajar directamente sobre `main`. Una rama corresponde a una tarea concreta. Antes de abrir PR:

1. Actualizar la tarjeta del Kanban.
2. Probar el cambio y anotar el comando ejecutado.
3. Actualizar documentación o migración relacionada.
4. Revisar que no existan secretos, datos reales ni archivos generados.
5. Solicitar al menos una revisión.

## Plantilla de Pull Request

```md
## Qué cambia

## Tarjeta relacionada

## Cómo probarlo

## Evidencia

## Migraciones o configuración

## Riesgos y pendientes
```

## Definition of Done

Una tarjeta solo pasa a Done cuando funciona el flujo feliz, se manejan carga/vacío/error, se validan permisos, existe prueba o evidencia, la documentación está actualizada y otro integrante revisó el PR.

## Reunión y coordinación

- Reunión breve: qué hice, qué haré, bloqueo.
- Nadie debe permanecer bloqueado más de un día sin avisar.
- Las decisiones se escriben en `docs/decisions/`.
- Si un dato institucional no está confirmado, marcarlo como `POR_CONFIRMAR`.
