# Justificación del proyecto, explicada fácil

Este documento explica **por qué** tomamos cada decisión. La idea es que cualquier integrante, aunque todavía esté aprendiendo, pueda entender qué estamos construyendo y por qué.

## ¿Por qué hacer una sola aplicación?

Hoy la información puede estar repartida entre mensajes, hojas de cálculo, carteles y diferentes personas. Eso hace que un alumno pierda tiempo buscando horarios, tareas, transporte, pagos o avisos.

La aplicación será como una **mochila digital de la universidad**: cada persona tendrá en un solo lugar las herramientas que sí necesita. No todos verán lo mismo. Un alumno verá sus materias; un docente verá sus grupos; cafetería verá sus pedidos; administración verá sus trámites.

## ¿Por qué Flutter?

Elegimos Flutter porque permite construir la aplicación para **Android y iOS usando una misma base de código**. Esto es importante porque en la UAE hay personas con teléfonos Android y también con iPhone.

Si hiciéramos una aplicación diferente para cada sistema, tendríamos que programar lo mismo dos veces. Eso tomaría más tiempo y aumentaría los errores. Con Flutter aprendemos una tecnología y podemos entregar ambas versiones.

Flutter tampoco significa que todos deban saberlo desde el primer día. Por eso el proyecto separa tareas: una persona puede trabajar en pantallas, otra en datos y otra en pruebas.

## ¿Por qué una API REST Java?

La aplicación móvil no debe conectarse directamente a la base de datos. Sería como entregar las llaves de toda la universidad a cada teléfono.

La API es un **recepcionista de seguridad**: recibe la solicitud, verifica quién la hace, revisa si tiene permiso y devuelve únicamente la información necesaria. Java se eligió porque el repositorio ya tiene una base Java y el equipo puede reutilizar conocimientos y código.

La API también permite que, en el futuro, exista una página web o un panel administrativo sin duplicar las reglas importantes.

## ¿Por qué conservar el Java Swing como legado?

El programa Swing actual representa trabajo ya realizado. Moverlo a una carpeta de legado evita borrarlo y permite consultar sus modelos, conexión y ejemplos.

No se agregan nuevas pantallas allí porque el objetivo cambió: ahora el producto principal será móvil. Mantenerlo separado evita que el equipo confunda el prototipo anterior con la API nueva.

## ¿Por qué separar el repositorio en carpetas?

Cada carpeta tiene una responsabilidad, como los salones de una escuela:

- `apps/mobile`: donde se construyen las pantallas del teléfono.
- `services/api-java`: donde se protegen y procesan los datos.
- `database`: donde se define cómo se guardan los datos.
- `docs`: donde se explican decisiones y tareas.
- `hardware-bomba`: proyecto físico independiente.

Separar las áreas permite que varias personas trabajen al mismo tiempo sin pisarse el trabajo.

## ¿Por qué organizar por módulos?

La aplicación tiene muchas funciones. Si todo se programa como una sola pieza, cambiar una parte puede romper otra.

Por eso existen módulos como académico, transporte, cafetería, pagos, avisos y votaciones. Cada módulo tiene sus propias reglas, pruebas y responsables. Es parecido a una escuela: cada materia tiene un profesor, pero todas forman parte de la misma institución.

## ¿Por qué comenzar con un MVP?

MVP significa **producto mínimo viable**: la versión más pequeña que ya demuestra la idea.

No intentaremos construir el sistema perfecto en un día. Primero probaremos login, inicio, horarios, tareas, avisos y transporte. Después agregaremos cafeterías, descuentos, pagos y documentos.

Esto permite detectar errores temprano, recibir opiniones reales y presentar avances aunque todavía falten funciones.

## ¿Por qué los datos de transporte son configurables?

Las rutas, paradas y horarios pueden cambiar. Además, todavía falta confirmar una de las cuatro rutas.

Si escribimos las rutas directamente dentro de la aplicación, cada cambio obligaría a publicar una nueva versión. Si las guardamos en la base de datos, una persona autorizada puede actualizarlas sin reconstruir todo el teléfono. La ruta desconocida se marca como `POR_CONFIRMAR`; nunca se inventa información.

## ¿Por qué la salida del mediodía necesita confirmación?

La salida de las **12:00 p. m. (mediodía)** puede no realizarse si casi nadie la utiliza. La confirmación permite saber cuántas personas realmente necesitan el transporte antes de decidir.

El sistema debe mostrar el plazo para confirmar, contar respuestas y publicar el resultado. No debe prometer que el transporte saldrá hasta que la regla institucional lo determine.

## ¿Por qué comenzar los pagos como simulación?

Los pagos reales necesitan una institución autorizada, seguridad, comprobantes y reglas legales. Guardar números de tarjeta en nuestro proyecto escolar sería peligroso.

Por eso primero simularemos el flujo: elegir servicio, confirmar, mostrar estado y generar comprobante de prueba. La integración real será una fase posterior, con un proveedor autorizado.

## ¿Por qué existen roles y permisos?

No toda persona debe ver o cambiar todo. Un alumno no debe modificar una calificación; un pedido de Cafetería Arriba no debe aparecer en la cuenta de Cafetería Abajo; un aviso de rectoría debe tener autor autorizado.

Los permisos se revisan en el backend. Ocultar un botón no basta, porque alguien podría intentar llamar directamente a la API.

## ¿Por qué existe un Kanban?

El Kanban hace visible quién está haciendo qué, qué sigue y qué está bloqueado. Evita que dos personas hagan el mismo trabajo o que una tarea importante se olvide.

Una tarjeta no se considera terminada solo porque el código existe. También debe tener pruebas, documentación, permisos revisados y una segunda persona que la revise.

## ¿Por qué se repartieron así las responsabilidades?

CRYXZ coordina backend, base de datos e integración porque esas áreas conectan todo el sistema. Kike toma transporte y API; Donovan, Flutter y académico; Camila, diseño y comunidad; Carlos, pruebas y documentación con tareas pequeñas y claras.

La distribución es una ayuda inicial, no una etiqueta permanente. Todos pueden aprender y apoyar a otros. La dificultad de una tarea se ajusta para que cada integrante pueda entregar algo útil y comprobable.

## Carpeta compartida de documentación

La documentación complementaria se compartirá en Google Drive:

[Proyecto Integrador 5to ITI - UAE](https://drive.google.com/drive/folders/1JWi4O-No4db1N4jgEwp1JrdOCgdOGl7k?usp=sharing)

GitHub conserva la documentación técnica versionada. Drive puede conservar presentaciones, entrevistas, capturas, videos y archivos pesados. No subir contraseñas, datos reales ni documentos personales.
