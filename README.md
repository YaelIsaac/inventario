# PizzaStock

App Flutter + Firebase para que **negocios** lleven su inventario y le pidan a sus **proveedores**, y para que los proveedores tengan en orden a sus clientes, pedidos y cobros.

| Rol | Qué hace |
|---|---|
| **Proveedor** | Catálogo con todos los productos que surte · registra negocios por correo o recibe solicitudes con su código · recibe y avanza pedidos · estado de cuenta (saldo y abonos) por cliente · cuenta para transferencias · reportes. |
| **Negocio** | Inventario propio (entradas/salidas, mínimos y alertas) · varios proveedores · pedidos a cada proveedor según su catálogo · al recibir un pedido se suma solo al inventario · saldo por proveedor y comprobantes de pago. |
| **Administrador** | Ve todas las cuentas, verifica proveedores, suspende cuentas, asciende/desciende administradores y ve estadísticas de la plataforma. |

## Cómo se conectan proveedor y negocio
1. **Por código:** el negocio escribe el código del proveedor (o lo busca en el directorio) y el proveedor aprueba la solicitud.
2. **Por correo:** el proveedor registra al negocio con su correo; en cuanto ese negocio crea su cuenta (o si ya la tiene) quedan vinculados solos.

## Puesta en marcha
1. **Correo del administrador inicial** (2 lugares, idénticos):
   - `lib/config.dart` → `kAdminInicial`
   - `firestore.rules` → función `adminInicial()`
   Crea esa cuenta primero (Crear cuenta con ese correo) y quedará como administrador.
2. Firebase → **Authentication → Método de acceso**: activa **Correo electrónico/contraseña**. (El acceso anónimo ya no se usa.)
3. Firebase → **Firestore → Reglas**: pega `firestore.rules` y **Publica**.
4. `android/app/google-services.json` en su lugar.
5. **Borra los datos de prueba anteriores** en Firestore (colecciones `productos`, `movimientos`, `menu`, `pedidos`, `users`, `config`, `comprobantes`) y las cuentas viejas en Authentication: la estructura cambió.
6. `flutter pub get` y `flutter run`.

## Notas
- Comprobantes: la foto se comprime y se guarda en Firestore (Firebase Storage exige plan de pago).
- Notificaciones **locales**: llegan con la app abierta o en segundo plano. Con la app cerrada del todo harían falta FCM + Cloud Functions (plan de pago).
- El saldo cuenta los pedidos **entregados** menos los abonos que registra el proveedor.
- El correo no se verifica por email al registrarse; si compartes la app, crea primero la cuenta del administrador.
