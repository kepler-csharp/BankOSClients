# Configuración de plataformas (LÉEME antes de compilar)

Este proyecto incluye **todo el código de la app** (`lib/`), las dependencias (`pubspec.yaml`), los assets, y la configuración de plataforma **personalizada** (permisos, íconos, tema de arranque). 

Sin embargo, los proyectos nativos de Android e iOS tienen archivos generados automáticamente por Flutter (como el `Runner.xcodeproj` de iOS o el `gradle-wrapper.jar` de Android) que **no se pueden crear a mano de forma fiable**. La forma correcta y oficial de generarlos es con un solo comando.

## ✅ Paso único de preparación

Desde la carpeta del proyecto, ejecuta:

```bash
flutter create .
```

Esto **completa** la estructura nativa sin tocar tu código:

- ✔️ **NO** sobrescribe `lib/` (todo el código de la app)
- ✔️ **NO** sobrescribe `pubspec.yaml` ni `assets/`
- ✔️ **Conserva** el `ios/Runner/Info.plist` ya personalizado (con el permiso de cámara)
- ✔️ **Conserva** el `AndroidManifest.xml`, `build.gradle` e íconos ya personalizados
- ✔️ Genera los archivos nativos que faltan (Xcode project, Gradle wrapper, etc.)

> El comando solo **rellena lo que falta**. Tus archivos personalizados se mantienen.

Luego:

```bash
flutter pub get
flutter run   # (o con los --dart-define del README)
```

## ¿Qué ya está personalizado y se conservará?

| Archivo | Personalización |
|---------|-----------------|
| `android/app/src/main/AndroidManifest.xml` | Permisos de **cámara** e **internet**, nombre "BankOs" |
| `android/app/build.gradle` | `minSdk 21` (requerido por mobile_scanner), namespace `com.bankos.app` |
| `android/app/src/main/res/mipmap-*/ic_launcher.png` | Íconos generados desde el logo |
| `ios/Runner/Info.plist` | **NSCameraUsageDescription** (permiso de cámara), nombre "BankOs", soporte es/en |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/` | Ícono de la app (1024px) |

## Verificación rápida tras `flutter create .`

Asegúrate de que estas personalizaciones sigan presentes (Flutter las respeta, pero por si acaso):

```bash
grep "CAMERA" android/app/src/main/AndroidManifest.xml      # debe aparecer
grep "minSdk = 21" android/app/build.gradle                 # debe aparecer
grep "NSCameraUsageDescription" ios/Runner/Info.plist       # debe aparecer
```

Si alguna se perdió (poco probable), vuelve a aplicarla con los valores indicados arriba.

---

Después de este paso único, todos los comandos del `README.md` (ejecutar, generar APK, desplegar) funcionan normalmente.
