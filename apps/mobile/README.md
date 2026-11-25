# Aplicación móvil Flutter

Esta carpeta contiene la aplicación Flutter para Android/iOS de App Unificada UAE,
una aplicación universitaria institucional. El inicio de sesión ya cuenta con
formulario y estados de interfaz; la autenticación usa la API local cuando se configura.

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

Para probar el login en navegador con la API local configurada y en ejecución, abre **dos terminales** y ejecuta cada comando completo en una sola línea:

1. **Terminal 1 (API Java):**

```sh
cd /home/CRYXZ/app-uae && set -a && source services/api-java/.env && set +a && export DEV_WEB_ORIGINS=http://127.0.0.1:8081,http://localhost:8081 && cd services/api-java && mvn spring-boot:run
```

Espera a ver `Started ApiApplication` (puerto `8080`). No cierres esta terminal.

2. **Terminal 2 (Flutter Web):**

```sh
cd /home/CRYXZ/app-uae/apps/mobile && flutter run -d web-server --web-hostname=127.0.0.1 --web-port=8081 --dart-define=API_BASE_URL=http://127.0.0.1:8080
```

3. **Abrir en el navegador:** entra a `http://127.0.0.1:8081` (para vista de teléfono en Chrome/Opera/Firefox, presiona `F12` y luego `Ctrl + Shift + M`).

La API debe estar preparada con una base y cuentas ficticias de desarrollo.
La vista web no sustituye las pruebas de almacenamiento seguro en dispositivos.

## Probar en teléfonos de la misma red local

`127.0.0.1` siempre apunta al dispositivo que lo abre. Para compartir la demo,
conecta laptop y teléfonos al mismo Wi-Fi y usa la IP de la laptop, no esa
dirección de loopback. En la laptop, revisa la IP con `hostname -I`; en esta
configuración de ejemplo es `192.168.8.46`. Reemplázala si cambia.

En una terminal, inicia la API y permite solo el origen web de la laptop:

```sh
cd /home/CRYXZ/app-uae
set -a
source services/api-java/.env
set +a
export SERVER_ADDRESS=192.168.8.46
export DEV_WEB_ORIGINS=http://192.168.8.46:8081,http://127.0.0.1:8081
cd services/api-java
mvn spring-boot:run
```

En otra terminal, sirve Flutter en la interfaz Wi-Fi y configura la misma IP
para las llamadas a la API:

```sh
cd /home/CRYXZ/app-uae/apps/mobile
flutter run -d web-server --web-hostname=192.168.8.46 --web-port=8081 \
  --dart-define=API_BASE_URL=http://192.168.8.46:8080 \
  --dart-define=LAN_DEMO_MODE=true
```

Los teléfonos abren `http://192.168.8.46:8081`. El modo LAN de demo permite
HTTP únicamente hacia IP privadas y guarda la sesión en memoria: al recargar o
cerrar la pestaña hay que iniciar sesión de nuevo. No uses esta configuración
fuera de una red de desarrollo. Cada persona debería usar una cuenta de prueba
propia. El carrito de cafetería y el GPS simulado son locales a cada navegador;
las tareas sí comparten la base de datos.

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

La autenticación puede conectarse a la API de desarrollo mediante
`--dart-define=API_BASE_URL=http://127.0.0.1:8080`. Sin esa configuración o
si el servicio no responde, se muestra un error. En la configuración normal,
HTTP solo se permite para localhost; una API remota requiere HTTPS. El modo
`LAN_DEMO_MODE` habilita HTTP hacia IP privadas solo para pruebas de navegador
en la red local y usa una sesión volátil en memoria. Las sesiones normales se
verifican al restaurarse y se revocan en el servidor al cerrar sesión. Para el
contrato y preparación consulta la
[guía de la API](../../services/api-java/README.md). No se debe llamar a SQL
desde Flutter.

## Estado actual

La estructura inicial implementada incluye `app/` (entrada y control de sesión),
`core/session/` (contrato y almacenamiento seguro), `core/widgets/` (estados
reutilizables) y `features/auth/` y `features/home/`. Las demás features se
crearán conforme se definan sus funciones; no es necesario crear módulos vacíos
por adelantado.

En Android se desactivó la copia de seguridad automática para evitar restaurar
datos cifrados sin sus claves. Consulta el [estado de F2-01](../../docs/modules/f2-01-sesion.md).
