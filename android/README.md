# 📱 SkinDiary para Android

App Android nativa (Kotlin) que envuelve la app web de SkinDiary en un `WebView`.
Reutiliza al 100% el HTML/CSS/JS que vive en la raíz del repositorio, así que solo
mantienes una base de código y la app móvil se actualiza sola al recompilar.

## ✅ Cómo funciona

- La pantalla principal (`MainActivity`) muestra un `WebView` a pantalla completa.
- Los archivos web se sirven **localmente** mediante `WebViewAssetLoader` desde
  `https://appassets.androidplatform.net/assets/web/index.html`. Usar un host virtual
  (en vez de `file://`) garantiza un *origen seguro* estable, necesario para que
  `localStorage` y otras APIs web funcionen de forma fiable.
- Antes de compilar, la tarea Gradle **`copyWebAssets`** copia automáticamente
  `index.html`, `styles/` y `js/` desde la raíz del repo a
  `app/src/main/assets/web/`. Por eso esa carpeta está en `.gitignore`: es generada.
- Está soportado el selector de fotos (`<input type="file">`) y el botón **atrás**
  navega por el historial del WebView.

## 🧰 Requisitos

- **Android Studio** (Ladybug o posterior recomendado).
- **JDK 17** (Android Studio incluye uno embebido; no necesitas instalarlo aparte).
- Android SDK con **API 34** (lo instala Android Studio al abrir el proyecto).
- `minSdk = 26` (Android 8.0) · `targetSdk = 34`.

## 🚀 Pasos para compilar y probar en tu móvil

1. **Abre el proyecto**: en Android Studio, *File → Open* y selecciona la carpeta
   `android/` de este repositorio (no la raíz del repo, sino la subcarpeta `android`).
2. **Sincroniza Gradle**: Android Studio descargará Gradle 8.9, el Android Gradle
   Plugin 8.6.1 y las dependencias. Acepta instalar el SDK/API 34 si lo pide.
3. **Conecta tu teléfono** por USB:
   - Activa *Opciones de desarrollador* (toca 7 veces *Número de compilación* en
     *Ajustes → Información del teléfono*).
   - Activa *Depuración por USB*.
   - Acepta el diálogo de confianza al conectar el cable.
4. **Ejecuta**: pulsa el botón ▶ *Run 'app'* y elige tu dispositivo. Android Studio
   compilará e instalará la app en el móvil.

### Alternativa: generar un APK e instalarlo a mano

```bash
# Desde la carpeta android/
./gradlew assembleDebug
# APK resultante:
#   app/build/outputs/apk/debug/app-debug.apk
```

Copia ese APK al teléfono e instálalo (debes permitir "instalar apps de orígenes
desconocidos"). También puedes instalarlo con ADB:

```bash
adb install -r app/build/outputs/apk/debug/app-debug.apk
```

## 🗂️ Estructura

```
android/
├── settings.gradle.kts
├── build.gradle.kts            # config raíz
├── gradle/libs.versions.toml   # catálogo de versiones (AGP, Kotlin, libs)
├── gradle.properties
├── gradlew / gradlew.bat       # Gradle wrapper (8.9)
└── app/
    ├── build.gradle.kts        # módulo app + tarea copyWebAssets
    ├── proguard-rules.pro
    └── src/main/
        ├── AndroidManifest.xml
        ├── java/com/skindiary/app/MainActivity.kt
        ├── res/                # tema, colores, strings, iconos adaptativos
        └── assets/web/         # (generado) copia de la web; NO se versiona
```

## 🔧 Notas y solución de problemas

- **No edites** `app/src/main/assets/web/`: es una copia generada. Edita la web en la
  raíz del repositorio (`/index.html`, `/styles`, `/js`) y vuelve a compilar.
- Si cambias la web y no ves los cambios, ejecuta *Build → Clean Project* y vuelve a
  ejecutar (la tarea `copyWebAssets` corre antes de `preBuild`).
- Los datos del diario se guardan en el `localStorage` del WebView, dentro del
  almacenamiento privado de la app. Se mantienen entre ejecuciones y se incluyen en el
  backup de la app; se borran si desinstalas o borras los datos de la app.

> Nota: este proyecto no se pudo compilar en el entorno donde se generó (sin Android
> SDK y con red restringida). La compilación está pensada para hacerse en tu Android
> Studio, que descargará el SDK y las dependencias automáticamente.
