# BankOs — App de clientes (Flutter)

App móvil **exclusiva para clientes** de la plataforma bancaria multi-tenant BankOS. Consume la API Laravel existente y replica todas las funciones del cliente de la app web, con una interfaz móvil llamativa basada en los colores de marca del logo (azul → morado → verde).

> ⚠️ Esta app es **solo para clientes**. Si un usuario administrador intenta iniciar sesión, la app lo rechaza automáticamente.

---

## ✨ Funcionalidades

| # | Función | Cómo funciona |
|---|---------|---------------|
| 1 | **Login + clave dinámica** | Validas correo y contraseña contra la API. Luego la app genera una **clave de un solo uso (OTP) de 6 dígitos válida 10 minutos** y la "envía" a tu correo. Solo con esa clave entras al panel. *(La lógica del OTP de acceso vive en Flutter.)* |
| 2 | **Dashboard** | Muestra tus cuentas activas con saldos, accesos rápidos y movimientos recientes. |
| 3 | **Operaciones del cliente** | Depósitos, retiros y transferencias, con notificación por correo al cambiar tu cuenta/perfil. |
| 4 | **Generar QR** | Genera un QR de cobro de tu cuenta. **No se almacena**: se genera al momento. |
| 5 | **Escanear QR** | Escanea el QR de otra persona con la cámara y **autollena** el número de cuenta y banco en la transferencia. |
| 6 | **Descargar certificado** | Genera un certificado PDF de tu cuenta; se descarga y "llega a tu correo". |
| 7 | **Solicitar certificado (seguro)** | Antes de emitir el certificado, **reconfirmas tu contraseña** (reautenticación contra la API). |
| 8 | **Chatbot** | Asistente con OpenAI acotado **solo a tu cuenta y al uso de la app**. |
| 9 | **PQRS** | Peticiones, quejas, reclamos y sugerencias. El **backend** envía correos a ti y al administrador, y ves su respuesta cuando llega. |
| + | **Política de privacidad** | Incluida en la app (login, registro y perfil). |

---

## 🎨 Identidad visual

La paleta se extrajo directamente del logo:

- **Azules:** `#000060`, `#001878`, `#0078F0`, `#0090F0`
- **Morados:** `#7800F0`, `#9000F0`, `#A800F0`
- **Verdes/cian:** `#00A8A8`, `#00A890`, `#00C078`

Tema oscuro, tipografía Poppins, tarjetas con gradiente y animaciones sutiles.

---

## 📋 Requisitos previos

1. **Flutter SDK** 3.19 o superior → [Guía oficial de instalación](https://docs.flutter.dev/get-started/install)
   ```bash
   flutter --version   # verifica que esté instalado
   flutter doctor      # revisa que no falte nada
   ```
2. **Backend BankOS corriendo** (la API Laravel multi-tenant). Por defecto la app apunta a `http://10.0.2.2:8080/api/v1` (que es `localhost:8080` visto desde el emulador de Android).
3. *(Opcional)* Una **API key de OpenAI** para el chatbot con IA. Sin ella, el chatbot funciona en "modo básico" con respuestas predefinidas.

---

## 🚀 Cómo ejecutar (paso a paso)

### 1. Instala las dependencias
```bash
cd bankos_app
flutter pub get
```

### 2. Asegúrate de que el backend esté accesible

| Dónde corres la app | URL que debes usar |
|---------------------|--------------------|
| Emulador Android | `http://10.0.2.2:8080/api/v1` (valor por defecto) |
| Simulador iOS | `http://localhost:8080/api/v1` |
| Dispositivo físico | `http://IP-DE-TU-PC:8080/api/v1` (misma red Wi-Fi) |
| Backend desplegado | `https://tu-dominio.com/api/v1` |

### 3. Ejecuta la app

**Opción simple** (usa la URL por defecto, chatbot en modo básico):
```bash
flutter run
```

**Opción completa** (URL personalizada + chatbot con IA):
```bash
flutter run \
  --dart-define=API_BASE_URL=http://10.0.2.2:8080/api/v1 \
  --dart-define=OPENAI_API_KEY=sk-tu-clave-de-openai
```

> 🔐 **Nunca** escribas tu API key directamente en el código. Siempre pásala con `--dart-define`.

---

## 📦 Generar el APK (Android)

```bash
# APK de depuración (rápido, para probar):
flutter build apk --debug

# APK de producción:
flutter build apk --release \
  --dart-define=API_BASE_URL=https://tu-dominio.com/api/v1 \
  --dart-define=OPENAI_API_KEY=sk-tu-clave
```

El APK queda en:
```
build/app/outputs/flutter-apk/app-release.apk
```
Puedes compartir ese archivo e instalarlo en cualquier Android (habilitando "instalar de orígenes desconocidos").

---

## ☁️ Despliegue GRATIS (paso a paso)

Tienes varias opciones sin costo para distribuir la app:

### Opción A — APK directo (lo más simple, $0)
1. Genera el APK release (comando de arriba).
2. Súbelo a Google Drive, Dropbox o tu web.
3. Comparte el enlace. Los usuarios lo descargan e instalan.

> Ideal para pruebas internas o un grupo pequeño de clientes.

### Opción B — Firebase App Distribution (gratis)
Distribuye el APK a testers por correo, con instalación guiada.
1. Crea un proyecto en [Firebase Console](https://console.firebase.google.com) (plan Spark, gratis).
2. Instala las herramientas:
   ```bash
   npm install -g firebase-tools
   firebase login
   ```
3. Sube el APK:
   ```bash
   firebase appdistribution:distribute \
     build/app/outputs/flutter-apk/app-release.apk \
     --app TU_APP_ID_DE_FIREBASE \
     --groups "testers"
   ```
4. Los testers reciben un correo con el enlace de instalación.

### Opción C — Codemagic (CI/CD gratis con cuota mensual)
Compila en la nube sin tener Android Studio.
1. Conecta tu repositorio en [codemagic.io](https://codemagic.io) (500 min/mes gratis).
2. Selecciona el proyecto Flutter.
3. Configura las variables `API_BASE_URL` y `OPENAI_API_KEY` en el panel de Codemagic (como variables de entorno cifradas).
4. Codemagic genera el APK/IPA automáticamente en cada push.

### Opción D — GitHub Actions (gratis para repos públicos)
Crea `.github/workflows/build.yml`:
```yaml
name: Build APK
on: [push]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'
      - run: flutter pub get
      - run: flutter build apk --release --dart-define=API_BASE_URL=${{ secrets.API_BASE_URL }} --dart-define=OPENAI_API_KEY=${{ secrets.OPENAI_API_KEY }}
      - uses: actions/upload-artifact@v4
        with:
          name: app-release
          path: build/app/outputs/flutter-apk/app-release.apk
```
Guarda `API_BASE_URL` y `OPENAI_API_KEY` en **Settings → Secrets** del repo. Cada push genera el APK como artefacto descargable.

> 📱 Para publicar en **Google Play** necesitas una cuenta de desarrollador (pago único de USD $25). Para **App Store** se requiere la cuenta de Apple Developer (USD $99/año). Las opciones A–D de arriba son 100% gratuitas.

---

## 🏗️ Arquitectura del proyecto

```
lib/
├── main.dart                      # Entrada; enruta por fase de autenticación
├── core/
│   ├── constants/app_config.dart  # URLs y claves (vía --dart-define)
│   ├── network/                   # Cliente Dio + manejo de errores
│   ├── theme/                     # Colores de marca y tema oscuro
│   └── utils/                     # Formato de moneda y fechas
├── data/
│   ├── models/                    # Bank, Account, TxModel, PqrsModel, etc.
│   ├── repositories/              # Auth + Banking (envuelven la API)
│   └── services/                  # OTP, correo simulado, chatbot, certificado
├── providers/                     # Estado con Provider (auth, banking, pqrs)
├── screens/                       # UI por funcionalidad
└── widgets/                       # Componentes reutilizables
```

**Patrón:** Repositorios (API) → Providers (estado) → Screens (UI). El cliente HTTP inyecta automáticamente los headers `X-Tenant-ID`, `Authorization: Bearer`, `X-Correlation-ID` e `Idempotency-Key`.

---

## ⚙️ Notas sobre la integración con el backend

La app consume estos endpoints reales de la API BankOS:

- `GET /banks` — selector de banco (público)
- `POST /auth/login`, `POST /auth/register`, `GET /auth/me`, `POST /auth/logout`, `PATCH /auth/me/password`
- `GET /config` — límites y comisiones del banco
- `GET /accounts`, `GET /accounts/{id}`, `GET /accounts/{id}/qr`
- `GET /transactions`, `POST /transactions/deposit`, `POST /transactions/transfer`
- `POST /withdrawal/request-code`, `POST /withdrawal/confirm` — retiro con OTP del backend
- `GET /pqrs`, `POST /pqrs` — el backend notifica por correo

### 🔧 Endpoints sugeridos para producción

Algunas funciones se **simulan localmente** porque la API actual no las cubre. Para una versión de producción real, te recomiendo agregar estos endpoints en el backend y reemplazar la simulación:

1. **Correo al hacer depósito/transferencia.** Hoy la API no envía correo en estas operaciones (solo en retiro y PQRS). La app lo simula con `MailService`. → *Sugerencia:* disparar el correo desde `TransactionService` tras un depósito/transferencia exitosos.

2. **Certificado bancario.** No existe endpoint; el PDF se genera en el dispositivo. → *Sugerencia:* crear `POST /accounts/{id}/certificate` que genere el PDF en el servidor, lo firme y lo envíe por correo.

3. **Resolución de QR cross-tenant.** `TransferRequest` valida el destino como `uuid|exists`, por lo que no acepta transferencias por **número de cuenta** hacia **otro banco**. La app detecta este caso y avisa al usuario. → *Sugerencia:* permitir resolver destino por `account_number` + `tenant_id` para transferencias entre bancos.

Mientras tanto, **todo funciona de extremo a extremo** dentro del mismo banco, y los flujos simulados están claramente marcados (incluida una bandeja de "Notificaciones" en el perfil que muestra los correos simulados).

---

## 🔒 Seguridad

- Token JWT y sesión guardados con `flutter_secure_storage` (cifrado).
- Clave dinámica de acceso (OTP) de un solo uso, válida 10 minutos, **no persistida** en disco.
- Reautenticación obligatoria antes de emitir certificados.
- Retiros con doble verificación (OTP del backend).
- La API key de OpenAI nunca se incluye en el binario (se pasa por `--dart-define`).

---

## 🧰 Solución de problemas

| Problema | Solución |
|----------|----------|
| "No se pudo cargar la lista de bancos" | Verifica que el backend esté corriendo y que `API_BASE_URL` sea correcta para tu entorno (emulador usa `10.0.2.2`). |
| La cámara no abre al escanear | Acepta el permiso de cámara. En Android, revisa Ajustes → Apps → BankOs → Permisos. |
| El chatbot responde "modo básico" | No pasaste `OPENAI_API_KEY`. Reejecuta con el `--dart-define` correspondiente. |
| Error de conexión en dispositivo físico | Usa la IP de tu PC (no `localhost`) y verifica que estén en la misma red Wi-Fi. |
| `cleartext traffic not permitted` | Para HTTP en producción, usa HTTPS. El manifest ya permite cleartext para desarrollo. |

---

## 📄 Licencia

Proyecto generado para integrarse con la plataforma BankOS. Ajusta la licencia según tus necesidades.

---

**BankOs** · Una plataforma, todos los bancos. 🏦
