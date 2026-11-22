# Aplicación móvil Flutter

Esta carpeta contiene la aplicación Flutter para Android/iOS de App Unificada UAE,
una aplicación universitaria institucional. El inicio de sesión ya cuenta con
formulario y estados de interfaz; la autenticación todavía requiere conectar la API.

## Primer arranque

Instala el [SDK de Flutter](https://docs.flutter.dev/install) y la extensión
Flutter de VS Code, que también instala la extensión de Dart. Después, desde
la raíz del repositorio:

```sh
cd apps/mobile
flutter doctor
flutter pub get
flutter analyze
flutter test
```

El proyecto se creó con Flutter stable 3.50.0. Cada integrante necesita su
propio SDK; este no se comparte en Git. La primera descarga de dependencias
requiere conexión a internet.

Para una vista previa rápida sin Android, ejecuta `flutter run -d web-server`
y abre la dirección indicada en un navegador. La depuración con este modo es
limitada; Chrome o Edge permiten depuración web desde VS Code. Para Android
necesitas configurar el Android SDK y conectar un teléfono o iniciar un
emulador. Para compilar y probar iOS se requiere macOS con Xcode.

En VS Code, abre este repositorio, abre `apps/mobile/lib/main.dart`, selecciona
un dispositivo en la barra inferior y presiona F5. Si Flutter no aparece,
reinicia VS Code después de instalarlo y revisa `flutter doctor`.

## Trabajo en equipo

Cada integrante clona el repositorio, instala Flutter y ejecuta `flutter pub get`.
Trabajen en ramas separadas y compartan cambios mediante pull requests; consulten
la [guía del equipo](../../docs/03-guia-del-equipo.md). VS Code Live Share es
opcional para editar juntos en tiempo real, pero no sustituye Git ni GitHub.

## Organización

La estructura inicial implementada se resume al final en «Estado actual»;
la lista siguiente muestra módulos previstos para fases posteriores:

```text
lib/
  app/                 tema, rutas, sesión y configuración
  core/                sesión segura, HTTP, errores y widgets comunes
  features/
    academic/
    announcements/
    auth/
    cafeteria/
    commerce/
    documents/
    home/
    polls/
    profile/
    transport/
```

Actualmente `lib/main.dart` arranca la aplicación y el inicio muestra el
formulario de sesión de `features/auth/`. Incluye validación de campos y del
formato general del correo, mostrar u ocultar contraseña, carga y errores de
credenciales. La validación no restringe el dominio: falta confirmar cuál es
el dominio institucional permitido.

La sesión se guarda mediante `flutter_secure_storage` usando almacenamiento
cifrado del sistema (Android Keystore e iOS Keychain). Solo se persisten los
tokens, correo y vencimiento obligatorio que entregue la API; nunca la contraseña. Al
iniciar, se restaura una sesión vigente y se descarta una sesión vencida. El
inicio ofrece cerrar sesión y elimina el registro seguro local.

La autenticación contra el servicio universitario todavía no está conectada:
el envío muestra un aviso explícito hasta definir el endpoint y su respuesta
(token, refresh token y vencimiento del access token). Tampoco hay endpoint de revocación; cerrar
sesión borra la copia del dispositivo. No se debe llamar a SQL desde Flutter.
Cada feature debe separar modelos, repositorios, estado y widgets.

## Estado actual

La estructura inicial implementada incluye `app/` (entrada y control de sesión),
`core/session/` (contrato y almacenamiento seguro), `core/widgets/` (estados
reutilizables) y `features/auth/` y `features/home/`. Las demás features se
crearán conforme se definan sus funciones; no es necesario crear módulos vacíos
por adelantado.
