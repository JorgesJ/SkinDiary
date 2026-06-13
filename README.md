# SkinDiary

App movil (Flutter) para **documentar y comparar fotografias de tu piel** a lo
largo del tiempo (lunares, manchas, pecas, etc.) organizadas por zona del cuerpo.

> **Aviso:** uso **informativo**, sin validez medica. No diagnostica ni sustituye
> a un profesional. Para un resultado verificado, acude a tu especialista.

Un unico codigo para **Android e iOS**. Empezamos por Android (ya tienes Play
Console); iOS se activa mas adelante con el mismo proyecto, sin reescribir nada.

---

## Que hace (MVP - Fase 1)

- Pantalla de **consentimiento** obligatoria al primer inicio (se guarda la aceptacion).
- **Zonas del cuerpo** (brazo izq/der, antebrazos, espalda...) con su ultima foto.
- **Captura con camara** + marco guia y **"fantasma"** de la foto anterior
  superpuesto (con control de opacidad) para encuadrar igual cada vez.
- **Almacenamiento local**: las fotos quedan en el dispositivo (no se suben a ningun sitio).
- **Comparacion** de 2 fotos de la misma zona: lado a lado o con deslizador, con
  el numero de dias transcurridos.
- Nota opcional por foto y borrado de fotos.

---

## Requisitos

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.4 o superior).
- Android Studio con los plugins **Flutter** y **Dart** instalados.
- Un dispositivo Android real (recomendado para probar la camara).

---

## Puesta en marcha (Android Studio)

Este repositorio contiene la logica de la app (`lib/`) y el `pubspec.yaml`. Las
carpetas de plataforma (`android/`, `ios/`) se generan en tu maquina con un comando.

1. **Genera las carpetas de plataforma** (desde la raiz del proyecto):

   ```bash
   flutter create .
   ```

   Esto crea `android/`, `ios/`, etc. sin tocar el codigo de `lib/`.

2. **Instala las dependencias:**

   ```bash
   flutter pub get
   ```

3. **Configura los permisos** (ver seccion siguiente).

4. **Ejecuta en tu dispositivo:**

   ```bash
   flutter run
   ```

   O abre la carpeta en Android Studio y pulsa *Run*.

---

## Permisos de camara

### Android

Edita `android/app/src/main/AndroidManifest.xml` y anade dentro de `<manifest>`
(antes de `<application>`):

```xml
<uses-permission android:name="android.permission.CAMERA" />
```

El plugin `camera` requiere `minSdkVersion 21`. En `android/app/build.gradle`
(o `build.gradle.kts`), asegurate de:

```gradle
android {
    defaultConfig {
        minSdkVersion 21
    }
}
```

### iOS (cuando tengas un Mac)

En `ios/Runner/Info.plist` anade:

```xml
<key>NSCameraUsageDescription</key>
<string>La app usa la camara para fotografiar zonas de tu piel.</string>
```

---

## Estructura del codigo

```
lib/
  main.dart                 # Arranque: camaras + BD + consentimiento
  app_theme.dart            # Tema visual
  data/body_zones.dart      # Zonas del cuerpo sugeridas
  models/scan_record.dart   # Modelo de foto + resumen de zona
  services/
    storage_service.dart    # SQLite (metadatos) + ficheros (imagenes)
    consent_service.dart    # Aceptacion del aviso
  screens/
    consent_screen.dart     # Aviso inicial
    home_screen.dart        # Lista de zonas
    zone_detail_screen.dart # Fotos de una zona + comparar
    capture_screen.dart     # Camara + guia fantasma
    photo_view_screen.dart  # Visor a pantalla completa
    compare_screen.dart     # Comparacion (lado a lado / deslizador)
  widgets/
    camera_overlay.dart     # Marco guia sobre la camara
```

---

## Privacidad

Todas las imagenes y datos se guardan **solo en el dispositivo** (carpeta de
documentos de la app + base de datos SQLite local). Nada se envia a internet.

---

## Siguientes fases (ideas)

- **Fase 2:** recordatorios periodicos, exportar a PDF/zip para llevar al
  dermatologo, etiquetas por foto, copia de seguridad cifrada.
- **Fase 3:** deteccion/medicion automatica de lunares y resaltado de diferencias
  entre sesiones (vision por computador).
