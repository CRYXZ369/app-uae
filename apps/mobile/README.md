# Aplicación móvil Flutter

Esta carpeta contendrá la aplicación móvil Android/iOS de App Unificada UAE.

## Primer arranque

Cuando se inicialice el proyecto:

```sh
flutter create --org mx.edu.uae apps/mobile
cd apps/mobile
flutter pub get
flutter analyze
flutter test
```

La estructura recomendada será:

```text
lib/
  app/                 tema, rutas, sesión y configuración
  core/                HTTP, errores, almacenamiento y widgets comunes
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

No se deben crear pantallas directamente en `lib/` ni llamar a SQL desde Flutter. Cada feature debe separar modelos, repositorios, estado y widgets.
