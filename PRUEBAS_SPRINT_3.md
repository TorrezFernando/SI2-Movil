# Sprint 3 móvil: ejecución y pruebas

## Qué se implementó

- Pestaña **Mi cuenta**: contratos propios, saldos, cuotas ordenadas por vencimiento, historial de pagos y estados vacíos/error/reintento.
- Recibos: descargar/compartir el PDF del servidor y solicitar el envío al correo del titular. Solo se muestra aceptación cuando SMTP la confirma.
- **Estimar valor con IA** en el detalle de inmuebles de la empresa del usuario: estimación y rango para la operación registrada, explicación y errores de plan/comparables/proveedor.
- **Perfil > Notificaciones**: activación, permiso, registro/rotación de token, desactivación y baja antes de cerrar sesión. Abrir un aviso lleva a Mi cuenta; en primer plano se muestra un aviso dentro de la app.
- El login consulta el perfil real para recuperar usuario y empresa. Ya no usa la identidad provisional del token para habilitar funciones.
- Las rutas antiguas de pago y comprobante redirigen a Mi cuenta. El botón del inmueble lleva a Mis contratos. Los archivos de simulación antiguos se conservan, pero no están conectados a la navegación.

Los importes se manejan en centavos exactos y no se presupone moneda. No se suman saldos de diferentes contratos. No se escriben cuotas ni pagos desde la app del cliente.

## Ejecutar con el backend nuevo

Usar `C:/Users/PC/Downloads/SI2-Backend-sprint-3 (1)/SI2-Backend-sprint-3`, no la copia anterior. Iniciar su servidor con sus dependencias y configuración habituales, escuchando en `0.0.0.0:8000` para pruebas desde teléfono.

Desde la raíz del proyecto móvil, en PowerShell:

```powershell
& C:/src/flutter/bin/flutter.bat pub get
& C:/src/flutter/bin/flutter.bat run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

`10.0.2.2` corresponde al emulador Android estándar. En teléfono físico, reemplazar por la IP LAN de la PC y conectar ambos a la misma red. El valor por defecto heredado sigue siendo `http://192.168.100.4:8000`; el APK sin parámetro usa esa dirección. La URL se fija al compilar: reconstruir con `--dart-define` si cambia.

## Recorrido manual

1. Iniciar sesión con un cliente que tenga contrato asociado en el backend. Ir a Mi cuenta y contrastar cuotas/saldos con `/api/mi-cuenta`.
2. Probar un cliente sin contratos: debe aparecer una explicación, no datos ficticios.
3. Crear contrato y abono simulado con un administrador mediante Swagger (`/docs`). La API exige `confirma_simulacion=true` y una clave de idempotencia; el cliente no tiene permiso para registrar pagos.
4. Actualizar Mi cuenta, descargar un recibo y verificar referencia, importe y contrato. Probar compartir/guardar usando el diálogo del sistema.
5. Enviar un recibo: con SMTP configurado debe confirmar aceptación del servidor; sin SMTP debe informar el error. No debe afirmar que llegó al buzón.
6. Cortar la conexión y actualizar: comprobar error y reintento. Si ya había datos, se identifican como consulta anterior. No hay persistencia financiera offline en esta entrega.
7. Cerrar sesión e iniciar con otro cliente: no deben mostrarse los contratos anteriores.
8. En un inmueble de la empresa propia, abrir Estimar valor con IA. Normal/Pro deben informar la restricción; Premium necesita al menos tres comparables de igual zona, tipo y operación, además de Gemini configurado en el servidor.
9. La tasación debe mostrar rango, explicación y la operación correcta; no cambia el precio publicado. Si el catálogo muestra otra empresa, no se ofrece el botón de tasación.

## Firebase (pendiente de configuración del equipo)

La app funciona sin Firebase y no intenta registrar tokens cuando falta la configuración. La clave compartida en el chat no se ha incorporado.

Configuración nativa recomendada:

1. Crear el proyecto Firebase y registrar Android con paquete `com.inmobiliaria.inmobiliaria_mobile`.
2. Descargar `google-services.json` en `android/app/`. El proyecto aplica el plugin de Google Services únicamente cuando ese archivo existe.
3. Compilar con `--dart-define=ENABLE_FIREBASE=true` además de `API_BASE_URL`.
4. En iOS, añadir `GoogleService-Info.plist` al target Runner desde Xcode, habilitar Push Notifications y Background Modes > Remote notifications, y configurar APNs en Firebase. Requiere macOS/Xcode para compilar y probar.
5. Configurar en el backend `GOOGLE_APPLICATION_CREDENTIALS` con su credencial de servidor; esa credencial no pertenece al móvil. Activar `ENABLE_FCM_SCHEDULER=true` en un único worker, o disparar `/api/notificaciones/procesar` como administrador.
6. Abrir Perfil > Notificaciones y activar con una cuenta que tenga cuotas pendientes o próximas a vencer. Comprobar primer plano, segundo plano, apertura del aviso, desactivación y cierre de sesión. Una cuota/dispositivo solo recibe un aviso por día según el backend.

También se aceptan opciones explícitas de inicialización mediante `FIREBASE_API_KEY`, `FIREBASE_APP_ID`, `FIREBASE_MESSAGING_SENDER_ID`, `FIREBASE_PROJECT_ID` y, para iOS, `FIREBASE_IOS_BUNDLE_ID`, usando `--dart-define`. Mantener los archivos nativos de configuración para la recepción cuando el sistema inicia la app en segundo plano.

El backend usa registration tokens con Firebase Admin; el cliente conserva las APIs de tokens compatibles, aunque Firebase Messaging 17 las marca como obsoletas frente a su API de FID. No sustituir tokens por FID sin migrar también el servidor.

Fuentes de configuración: [Flutter FCM](https://firebase.google.com/docs/cloud-messaging/flutter/get-started) y [Google Services Android](https://firebase.google.com/docs/android/google-services-plugin-and-file).

## Verificación automatizada

```powershell
& C:/src/flutter/bin/flutter.bat test
& C:/src/flutter/bin/flutter.bat analyze --no-fatal-infos --no-fatal-warnings
& C:/src/flutter/bin/flutter.bat build apk --debug
```

Las pruebas usan respuestas simuladas: validan importes, contratos, orden, rutas/body HTTP, PDF, aceptación SMTP, errores, reintento, pantalla vacía, sesión y ejecución sin Firebase. No prueban entregas externas ni conexión a la base de datos real.

El análisis conserva advertencias heredadas del proyecto. Las pruebas reales de Gemini, SMTP y FCM y la compilación iOS quedan pendientes de su configuración y del dispositivo correspondiente.

Resultado verificado el 29/10/2026: **11 pruebas aprobadas**, análisis sin errores (con advertencias previas y sugerencias de estilo), y **APK debug compilado** en `build/app/outputs/flutter-apk/app-debug.apk`. Se compiló sin Firebase y con la URL por defecto heredada `http://192.168.100.4:8000`. No se instaló en un teléfono ni se ejecutó contra el servidor real.
