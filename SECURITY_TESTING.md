# Pruebas de seguridad y compatibilidad

## Seguridad
- Verificar que no se almacenan contraseñas en texto plano (solo blob cifrado).
- Verificar que la contraseña maestra nunca se envía al backend.
- Verificar cifrado AES-256-GCM y derivación Argon2id.
- Verificar que no se imprimen credenciales en logs.
- Verificar bloqueo automático y sesiones revocables (pendiente).

## Compatibilidad
- Flutter: Android, iOS, Windows, Linux, macOS (ejecutar `flutter run` en cada plataforma).
- Extensión: Chrome, Edge, Firefox (cargar en modo desarrollador).

## Análisis estático
- `flutter analyze` sin errores.
- Revisar dependencias con `flutter pub outdated`.