# Integración del frontend de NexAccess

## Obtener y ejecutar

Rama: `feature/nexaccess-frontend`.

```bash
git clone --branch feature/nexaccess-frontend https://github.com/juliobernal92/NexAccess_docs.git
cd NexAccess_docs/frontend
npm ci
npm run web
```

Usar Node.js LTS compatible con el proyecto (mínimo 22.13). El código actual usa Expo SDK 57, React Native 0.86.3 y React 19.2.3. Las versiones se conservan en `package-lock.json`.

Para paquetes Expo, utilizar `npx expo install <paquete>` y evitar cambiar versiones de React Native por separado.

Para probar en móvil, ejecutar `npx expo start --go` y escanear el QR con Expo Go compatible con SDK 57. El equipo y el teléfono deben compartir una red que permita la conexión. No se requiere un build personalizado para el alcance actual.

Cuenta de demostración: `admin` / `NexAccess2026!`. Son credenciales públicas del prototipo, no una cuenta real. La sesión y los cambios se reinician al cerrar sesión o recargar.

## Organización

- `src/app/login.tsx`: entrada pública sin registro.
- `src/app/(private)/`: los once módulos, con protección de navegación del cliente.
- `src/features/`: pantallas organizadas por funcionalidad.
- `src/state/SessionProvider.tsx`: sesión de demostración.
- `src/domain/auth.ts`: adaptador de credenciales ficticias.
- `src/state/UsersProvider.tsx`: operaciones de empleados y notificaciones.
- `src/state/useSystemState.ts`: tarjetas, áreas, lectores, permisos, alertas, auditoría y configuración compartida.
- `src/data/`: datos ficticios iniciales.
- `src/domain/`: contratos TypeScript, validación, proyecciones y reportes.
- `src/utils/export.ts`: descarga o preparación de archivos por plataforma.
- `src/theme.ts`: colores y estilos reutilizables.

La ruta `/` conserva el directorio de usuarios y `/dashboard` abre la vista general. Los demás módulos se abren desde el menú. En móvil hay un menú completo y accesos inferiores.

## Correspondencia con el esquema SQL

Los identificadores `EMP-*`, `AR-*`, `LE-*`, `CR-*` y `PE-*` pertenecen a la demostración. No deben convertirse directamente a claves de producción. La API deberá acordar si expone los UUID o los identificadores internos del esquema.

| Frontend | Referencia en SQL | Acuerdo pendiente |
| --- | --- | --- |
| Usuario del directorio (`Employee`) | `empleado` | Mantener la distinción respecto de una cuenta del portal. |
| Cédula, nombre, apellido, correo, teléfono, estado | Campos de `empleado` | Correo y teléfono opcionales; transformar valores vacíos según contrato. |
| Varios roles por persona | `rol` y `empleado_rol` | Mapear nombres visibles a códigos del backend. |
| Departamento / sector | No existe en el esquema inicial consultado | Confirmar el modelo con el equipo antes de enviar este campo a una API. |
| Credencial física / digital | `credencial` | Mapear `type` a `tipo` y `employeeId` al identificador real del empleado. |
| Bloqueada, extraviada, vencida o revocada | `activa`, `fecha_expiracion`, `revocada_at`, `motivo_revocacion` | Acordar un vocabulario de estados; los seis estados visuales no equivalen automáticamente a seis estados SQL. |
| Áreas y lectores | `area` y `dispositivo` | Confirmar los campos adicionales de ubicación, puerta, estado de conexión y horario. |
| Permisos por rol | `permiso_acceso` | Transformar días, horarios y relaciones a los campos reales. |
| Permisos individuales / vigencia temporal | No están representados de la misma forma en el esquema inicial | Requieren decisión del equipo; no asumir que el backend los soporta. |
| Historial de accesos | `evento_acceso` | Mantener eventos de solo lectura y diferenciar AUTORIZADO / RECHAZADO. |
| Marcaciones de asistencia | `marcacion` | Son un proceso diferente del intento de acceso; no tratarlos como el mismo evento. |
| Cuenta administrativa | `usuario` | Reemplazar el login de demostración con autenticación real. |
| Alertas, auditoría y configuración | Contratos todavía no definidos en este frontend | Acordar recursos, filtros, permisos y persistencia con el backend. |

## Sustituir los datos simulados

1. Acordar con el responsable de la API el contrato de autenticación, recursos, identificadores, paginación y errores. Este documento no define endpoints existentes.
2. Agregar una capa de servicios/adaptadores que transforme las respuestas del backend a los tipos de las pantallas.
3. Sustituir `authenticateDemo` y adaptar el proveedor de sesión al flujo asíncrono real. Definir expiración, renovación y cierre de sesión con el backend; no trasladar las credenciales de muestra a producción.
4. Reemplazar las operaciones locales de los proveedores por consultas y mutaciones de la API, manteniendo los estados vacíos, de carga, error y confirmación.
5. Conservar las relaciones entre empleados, credenciales, áreas, lectores y permisos. El perfil, los contadores y la matriz deben actualizarse después de una mutación confirmada por el servidor.
6. Mantener las fechas en ISO 8601, con zona horaria, y presentar los valores según la configuración. Las fechas sin hora (emisión y vencimiento) deben conservar su semántica de calendario.
7. Aplicar autenticación y autorización en el backend. Las rutas protegidas y los indicadores de permiso del cliente son presentación, no una medida de seguridad del servidor.
8. La auditoría real debe producirla y conservarla el servidor. Los eventos históricos no se modifican ni eliminan desde este prototipo.

No se incluyen secretos ni archivos `.env` reales. Si se necesita configurar una URL pública de API para Expo, debe tratarse como información visible en el cliente. No colocar claves privadas en variables incluidas en el paquete de la aplicación.

## Verificaciones

```bash
npm test
npm run typecheck
npm run lint
npx expo install --check
npx expo-doctor
npx expo export --platform all
```

La entrega cuenta con 24 pruebas de dominio aprobadas y paquetes web, Android e iOS generados. La evidencia detallada está en `VERIFICACION.md`. La ejecución en un teléfono y la exportación/compartición nativa siguen pendientes; generar un paquete no equivale a probarlo en un dispositivo.

## Revisar sin mezclar con main

Esta rama puede descargarse y ejecutarse de forma independiente. La integración con `main` se realiza después de la revisión del equipo. El frontend se agregó bajo `frontend/`; los documentos y el SQL existentes no se reemplazaron.
