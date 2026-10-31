# Integración del sprint 3 móvil

Revisión: 29 de octubre de 2026. Fuente: sección SPRINT 3, páginas impresas 288–295 del documento de avance (páginas PDF 301–308). La planificación inicial del documento contiene otro alcance; esta revisión usa la sección específica final del sprint.

Actualización: se revisó la nueva copia `C:/Users/PC/Downloads/SI2-Backend-sprint-3 (1)/SI2-Backend-sprint-3` y el frontend `C:/Users/PC/Downloads/SI2-Frontend-sprint-3/SI2-Frontend-sprint-3`. Esta revisión sustituye el diagnóstico inicial de APIs ausentes. La nueva copia agrega `operaciones.py`, lo registra en `main.py` y proporciona `docs/openapi.json`.

## Alcance móvil documentado

| Caso | Función | Situación en el código compartido |
| --- | --- | --- |
| CU-23 | Tasación IA | Implementado `POST /api/ia/tasaciones` con `id_propiedad`. Requiere Premium y al menos tres comparables de la misma empresa, zona, tipo y operación. Devuelve mínimo, estimado, máximo y explicación. |
| CU-26 | Recibo PDF y envío por SMTP | Implementados `GET /api/pagos/{pid}/recibo.pdf` y `POST /api/pagos/{pid}/enviar-recibo`. Acceso del titular o administrador de su empresa. Envío explícito al correo registrado del cliente. |
| CU-27 | Tokens FCM y avisos | Implementados PUT/GET `/api/notificaciones/tokens`, DELETE `/api/notificaciones/tokens/{ident}` y procesamiento de avisos de cuotas. Falta integrar SDK/configuración Firebase en Flutter. |
| CU-28 | Estado de cuenta | Implementados `GET /api/mi-cuenta` y `GET /api/contratos/{cid}/cuotas`, con contratos, cuotas, pagos y saldos del titular. |

CU-22 (planes), CU-24 (descripciones), CU-25 (promociones) y CU-29 (liquidación de comisiones) figuran como Web en la tabla final. No se presupone su traslado al móvil.

## Base reutilizable

- Flutter con Provider, Dio, GoRouter y almacenamiento seguro para tokens.
- Cliente Dio autenticado en `lib/main.dart` y cierre de sesión mediante interceptor.
- Consulta de catálogo en `/modulo_inmuebles/propiedades/catalogo`.
- Autenticación y perfil con identificadores de usuario y empresa suministrados por el servidor.
- Backend FastAPI con aislamiento por empresa y roles.
- Paquetes `pdf` y `printing` ya declarados para documentos locales.

## Condiciones de integración confirmadas

1. Usar la nueva copia del backend. Sus doce operaciones nuevas coinciden en método y ruta con el OpenAPI entregado.
2. La tasación parte de un inmueble existente de la empresa autenticada; no admite un formulario libre de atributos ni devuelve venta y alquiler simultáneamente. Usa Gemini sobre anuncios internos, no un modelo AVM entrenado con ventas históricas. El catálogo es global, por lo que una propiedad visible puede pertenecer a otra empresa y no admitir tasación para ese usuario.
3. Los nuevos contratos generan cuotas mensuales. Los anteriores pueden devolver `cronograma_disponible=false`. No hay recargos por mora en la respuesta. Los pagos históricos sin vínculo a cuota afectan el saldo del contrato, pero no el de cada cuota.
4. Los importes del OpenAPI son cadenas decimales. No hay campo de moneda ni conversión: no asumir bolivianos o dólares. El móvil debe ordenar los pagos para el historial porque el backend no impone orden explícito.
5. Los pagos nuevos son simulados y solo los registra un administrador con `confirma_simulacion=true`. El móvil del cliente consulta pagos registrados; no debe presentar su simulación local como un pago asentado. SMTP devuelve `aceptado_por_smtp`, no confirmación de entrega; actualmente no hay envío automático, cola asíncrona ni registro persistido del envío.
6. Se necesitan configuración Firebase de Android/iOS y credenciales de servidor. Registrar, actualizar y desvincular tokens al cambiar/cerrar sesión; contemplar permisos denegados y apertura de avisos. El backend implementa recordatorios de cuotas, no eventos de visitas, contratos o pagos. El planificador horario requiere `ENABLE_FCM_SCHEDULER=true` y un único worker.
7. Si se añade consulta financiera offline, separar la caché por usuario/empresa, mostrar la fecha de actualización y limpiar datos al cerrar sesión. La caché no debe confirmar pagos.

## Observaciones del móvil existente

- `pago_screen.dart` usa esperas artificiales para confirmar tarjeta y QR, sin petición al backend.
- `comprobante_screen.dart` genera una referencia aleatoria y afirma envío de correo sin ejecutarlo; no puede usarse como evidencia de CU-26.
- El comprobante vuelve a `/`, pero la ruta de catálogo configurada es `/catalogo`.
- La URL por defecto del servidor es una IP privada fija; existe soporte para `--dart-define=API_BASE_URL=...`.
- Se utilizó Flutter en `C:/src/flutter` para análisis, once pruebas automatizadas y compilación del APK de depuración. Quedan avisos heredados y tres sugerencias de estilo en pruebas, sin errores de análisis.

## Validación prevista

- Tasación: validación de entradas, carga, respuesta válida, falta de proveedor/cuota y errores de red.
- Finanzas: usuario sin contratos, múltiples contratos, pagos parciales, cuotas vencidas y aislamiento entre empresas/usuarios.
- Recibos: PDF correspondiente al pago, acceso denegado a recibos ajenos y estado real del envío SMTP.
- Push: token inicial/renovado, permisos denegados, primer y segundo plano, apertura desde notificación y cierre de sesión.
- Flutter: análisis estático, pruebas de modelos/servicios y recorrido en dispositivo conectado al backend.

## Frontend web y comprobaciones de esta revisión

- La copia Angular entregada tiene catálogo, inmuebles, planes, usuarios y reportes, pero no contiene llamadas a las nuevas rutas de operaciones ni pantallas de contratos/estado de cuenta/tasación. La afirmación de la documentación del backend de que la web permite procesar recordatorios no coincide con esta copia del frontend.
- Se analizaron sintácticamente los 56 archivos Python sin errores y se contrastaron las doce operaciones nuevas con el OpenAPI. Esto no equivale a pruebas de ejecución.
- Hay siete pruebas de operaciones con SQLite y servicios simulados. No se ejecutaron: el Python disponible carece de FastAPI, SQLAlchemy, Firebase Admin y otras dependencias; no se encontró entorno virtual adjunto.
- No se realizaron llamadas a Gemini, SMTP o FCM, ni se utilizó la clave compartida en el chat. Su proveedor no está identificado.

Actualización de implementación: se añadieron en Flutter Mi cuenta, descarga/envío de recibos, tasación desde el inmueble y gestión de notificaciones. El login recupera la empresa desde el perfil real y las rutas de pago ficticio redirigen a la cuenta. Ver `PRUEBAS_SPRINT_3.md` para ejecución y límites. Se ejecutaron once pruebas de modelos/servicios/sesión/widgets con respuestas simuladas. La entrega real de SMTP/FCM y la tasación real con Gemini siguen pendientes de configuración y prueba en el entorno del equipo.
