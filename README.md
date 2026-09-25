# Mi Presupuesto — Flutter conectado a la API real

Las 5 pantallas base (Inicio, Ingresos, Presupuesto, Ahorro, Ajustes) ya
están conectadas a tu backend de Laravel — ya no usan `mock_data.dart`
(el archivo se deja ahí solo como referencia, no se importa desde ninguna
pantalla).

## Concepto visual

Paleta y tipografía tipo "libro mayor / plano de construcción": azul tinta
como color principal, fondo gris-azulado pálido, bronce para ahorro/progreso
y óxido para descuentos/alertas. Cifras grandes en una serif (Source Serif 4),
el resto de la interfaz en una sans geométrica (Manrope). Todo definido en
`lib/theme/app_theme.dart`.

## Qué se agregó en esta vuelta

- `lib/services/api_client.dart` — cliente HTTP, guarda el token con
  `flutter_secure_storage` y arma la URL base.
- `lib/services/auth_service.dart` — login, registro, logout reales.
- `lib/services/data_repository.dart` — todas las llamadas a
  `/pay-periods`, `/budget-categories`, `/budget-expenses`,
  `/savings-goals` y `/savings-goals/{id}/contributions`.
- `lib/state/app_state.dart` + `app_state_scope.dart` — guarda los datos
  ya cargados en memoria y los comparte entre las 5 pantallas sin repetir
  peticiones al cambiar de tab.
- `lib/screens/login_screen.dart` — pantalla nueva de login/registro.
- Todos los modelos (`lib/models/*.dart`) ahora tienen `fromJson()` que
  mapea exactamente los campos que devuelve tu `PayPeriodResource`,
  `BudgetCategoryResource` y `SavingsGoalResource`.

### Qué es real ahora mismo

- Login y registro contra `/api/login` y `/api/register`.
- Cerrar sesión (Ajustes → Cerrar sesión) revoca el token en el backend.
- Inicio, Ingresos, Presupuesto y Ahorro muestran datos reales de tu
  usuario, con pull-to-refresh.
- "Guardar gasto" en Presupuesto crea un gasto real (`POST /budget-expenses`)
  y refresca el presupuesto al instante.
- "Agregar aporte" en el detalle de una meta crea un aporte real
  (`POST /savings-goals/{id}/contributions`) y actualiza el progreso.
- Crear una planilla nueva desde Ingresos (`POST /pay-periods`), eligiendo
  ingresos desde tus fuentes guardadas o escribiéndolos a mano, y
  descuentos desde tus reglas configuradas.
- Crear una meta de ahorro nueva desde Ahorro (`POST /savings-goals`).
- Editar una meta existente (nombre, monto meta, fecha) desde su pantalla
  de detalle (`PUT /savings-goals/{id}`).
- Fuentes de ingreso y reglas de descuento en Ajustes: ver, agregar y
  eliminar (`/income-sources`, `/deduction-rules`).
- Categorías de presupuesto: crear, editar el monto mensual y eliminar,
  desde el ícono junto al título "Presupuesto" (`/budget-categories`).

### Qué sigue como placeholder ("próximamente")

- Calendario de pago (Ajustes).
- Sincronización en la nube ya es real de fondo (todo vive en tu base de
  datos), pero falta indicarlo visualmente en Ajustes.
- Editar/eliminar una planilla.

## Configurar la URL de tu API

Antes de correr la app, edita `lib/services/api_client.dart` si tu
backend no corre en el puerto/host por defecto. La clase `ApiConfig`
ya trae los tres casos más comunes:

- **Android (emulador):** `http://10.0.2.2:8000/api` (así ve el emulador
  a "localhost" de tu PC) — es el valor por defecto.
- **Web / Chrome / PWA:** `http://127.0.0.1:8000/api` — se usa
  automáticamente cuando corres `flutter run -d chrome`.
- **Celular físico en la misma red Wi-Fi que tu PC:**
  `http://TU_IP_LOCAL:8000/api` (ej. `http://192.168.1.50:8000/api`).
  Corre el backend con `php artisan serve --host=0.0.0.0` para que
  escuche en toda la red, no solo en `127.0.0.1`, y edita
  `ApiConfig.baseUrl` con tu IP.

Cuando despliegues el backend (Railway, Render, VPS), cambia
`ApiConfig.baseUrl` por la URL pública (ej.
`https://presupuesto-api.tuapp.com/api`).

## Cómo correrlo

1. Instala las dependencias nuevas:
   ```
   flutter pub get
   ```
2. Asegúrate de que tu backend Laravel esté corriendo
   (`php artisan serve`) y que hayas corrido `migrate --seed`.
3. Corre la app:
   ```
   flutter run
   ```
4. En la pantalla de login ya viene precargado el usuario demo del
   seeder (`diego@example.com` / `password`) — solo dale "Entrar", o
   crea una cuenta nueva con "¿No tienes cuenta? Créala".

## Probarlo en tu iPhone (PWA, sin cuenta de Apple Developer)

```
flutter build web
```
Sube `build/web` a un hosting gratuito (Cloudflare Pages, Vercel,
Firebase Hosting) — necesitas que tu backend también sea accesible por
HTTPS desde internet (Railway/Render), porque Safari en iOS bloquea
peticiones HTTP simples desde una PWA en HTTPS. Abre la URL en Safari
y usa "Agregar a pantalla de inicio".

## Qué falta en general

- Formularios para crear planillas y metas de ahorro nuevas.
- Editar/eliminar categorías, planillas y metas.
- Sincronización en la nube ya es real de fondo (todo vive en tu base
  de datos), pero falta indicarlo visualmente en Ajustes.
