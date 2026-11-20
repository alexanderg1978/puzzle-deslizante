# Puzzle deslizante

Juego de puzzle deslizante en Flutter, solo Android. Todo el desarrollo, la
compilación y la publicación ocurren en la nube: no se depende de ningún PC.

## Flujo de trabajo

1. Editar en una sesión de Claude Code en la nube, en la rama que indique la sesión.
2. Antes de subir, ejecutar siempre (deben pasar los dos, igual que en la CI):
   ```
   flutter analyze
   flutter test
   ```
3. Subir la rama. Nada se publica hasta unir a `main`.
4. Cada push a `main` lanza `.github/workflows/build-apk.yml`: compila el APK
   firmado, lo publica como pre-release `v1.0.N` (N = número de ejecución) y la
   app instalada lo detecta y se actualiza sola (OTA). Tarda unos 6 minutos.

Para probar una rama en el teléfono sin publicarla: lanzar el workflow a mano
(`workflow_dispatch`) sobre esa rama. Publica un APK firmado con tag
`prueba-N`, que se instala encima de la app desde el enlace del release y que
la actualización automática ignora. Solo se conserva el último.

Unir a `main` equivale a publicar a los teléfonos: hacerlo solo cuando el
usuario lo pida. Los cambios que no tocan la app (documentación, CI) conviene
unirlos junto con el siguiente cambio real, para no publicar versiones vacías.

## Entorno

- Flutter 3.47.7 estable, la misma versión que fija la CI. Si se cambia en un
  sitio, cambiarla en el otro (workflow y script de arranque del entorno
  `puzzle-deslizante`).
- El entorno de la nube instala Flutter en `/opt/flutter` y ejecuta
  `flutter pub get`. No tiene el SDK de Android: el APK solo se compila en la CI.
- La clave de firma está en los secretos de GitHub (`KEYSTORE_BASE64`,
  `KEYSTORE_PASSWORD`, `KEY_ALIAS`). Sin ella un APK no puede actualizar al
  instalado, así que los APK de PR no sirven para instalar encima; los de prueba sí.

## Estructura

- `lib/models/`: lógica pura (puzzle, niveles y mundos, misiones, insignias, elogios).
- `lib/services/`: progreso (`shared_preferences`, local por jugador), catálogo
  de imágenes, inicio de sesión con Google y actualizaciones OTA.
- `lib/screens/`: pantallas; `game_screen.dart` es la más grande.
- `catalog/`: imágenes que la app descarga desde `raw.githubusercontent.com`
  en `main`. Ver `catalog/README.md` para añadir una. Solo dominio público o CC0.
- `tools/fetch_images.py`: descarga imágenes candidatas de Wikimedia Commons
  o del Met a una carpeta para revisarlas (`--help` muestra el uso).

## Convenciones

- Código, comentarios, textos de la app y mensajes de commit en español.
- Mensajes de commit de una línea que describen el cambio visible para el jugador.
- Los tests desactivan la comprobación de actualizaciones con
  `UpdateService.autoCheck = false`.
