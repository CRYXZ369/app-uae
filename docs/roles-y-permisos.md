# Roles y permisos

Este documento consolida el levantamiento de la tarjeta F0-01. `CONFIRMADO` significa que puede usarse para el MVP; `POR_CONFIRMAR` significa que la universidad todavía debe validarlo.

| Código | Rol | Alcance inicial | Estado |
|---|---|---|---|
| `ESTUDIANTE` | Estudiante | Consulta su horario, tareas, progreso, transporte, pedidos, pagos, constancias, avisos y votaciones | Confirmado |
| `DOCENTE` | Docente | Consulta grupos y horarios; captura información académica cuando se autorice | Confirmado |
| `TRABAJADOR` | Personal general | Avisos y funciones operativas autorizadas | Por confirmar |
| `DIRECTIVO` | Dirección | Indicadores y avisos de su área | Por confirmar |
| `ADMIN_ESCOLAR` | Administración escolar | Estado de cuenta y constancias | Por confirmar |
| `GESTION_ACADEMICA` | Gestión académica | Carreras, grupos, materias, docentes y horarios | Por confirmar |
| `RECTORIA` | Rectoría | Comunicados institucionales y resúmenes globales | Por confirmar |
| `CCE` | Consejo/Comité Cultural Estudiantil | Votaciones y avisos estudiantiles | Confirmado |
| `CAFETERIA` | Personal de cafetería | Menús, disponibilidad y pedidos de su sucursal | Confirmado |
| `SOPORTE_TECNICO` | Soporte | Usuarios, roles, catálogos y errores | Confirmado para prototipo |

## Reglas obligatorias

- La API debe validar permisos; ocultar un botón en Flutter no es seguridad.
- Un estudiante solo puede consultar sus propios datos académicos, pagos y constancias.
- Un docente solo puede consultar grupos asignados.
- Un usuario puede tener más de un rol; por ejemplo, `ESTUDIANTE` + `CCE`.
- Nunca guardar tarjetas, contraseñas en texto plano ni datos bancarios.
- Las áreas y nombres que aparecen como “por confirmar” no deben tratarse como autorización final.

## Pendientes de validación institucional

1. Dominios de correo para personal externo.
2. Persona que actualizará la ubicación del transporte.
3. Nombres oficiales de las cafeterías.
4. Área que autoriza constancias y pagos.
5. Diferencias exactas entre directivos, gestión académica y rectoría.
6. Nombre oficial y visibilidad de resultados del CCE.
