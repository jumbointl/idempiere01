# Documentación del Pedido: Aplicación Flutter para Consumo de API REST iDempiere

## Descripción General

El objetivo es desarrollar una aplicación en Flutter que consuma datos de la API REST de iDempiere. La documentación oficial de la API se encuentra en: [iDempiere REST Web Services](https://wiki.idempiere.org/en/REST_Web_Services).

### Funcionalidades Principales Solicitadas

1. **Módulo de Login:**
   - Permitir al usuario autenticarse utilizando las credenciales proporcionadas.
   - Implementar la conexión con los endpoints de autenticación de la API de iDempiere.

2. **Selección de Roles:**
   - Una vez autenticado, el usuario podrá seleccionar uno de los roles asociados a su cuenta.
   - Mostrar una lista de roles disponibles obtenidos desde la API.

3. **Menú Principal Dinámico:**
   - Mostrar un menú de opciones en la pantalla principal basado en el rol seleccionado del usuario.
   - Las opciones del menú serán obtenidas dinámicamente desde la API.

4. **Menú Lateral de Navegación:**
   - Implementar un menú lateral (drawer) que contenga:
     - Opciones de navegación de la aplicación.
     - Botones para cambiar el rol del usuario.
     - Opción para cerrar sesión.

## Estructura del Proyecto

La carpeta `lib` del proyecto se organiza de la siguiente manera:

- **`main.dart`:**
  - Contiene el punto de entrada de la aplicación.
  - Configura el entorno inicial usando `Environment.initEnvironment()`.
  - Utiliza `Riverpod` para la gestión del estado.
  - Configura el tema con `AppTheme` y la navegación con `AppRouter`.

- **`config/`:**
  - Contiene configuraciones generales de la aplicación, como:
    - `Environment`: Manejo de variables de entorno.
    - `http/`: Configuración de clientes HTTP mediante `Dio` para consumir la API de iDempiere.
    - `router/`: Configuración del enrutador principal de la aplicación.
    - `theme/`: Configuración del tema visual de la aplicación.
    - `menu/`: Definición de elementos del menú principal y lateral.

- **`features/`:**
  - Módulos principales de la aplicación organizados por funcionalidad, incluyendo:
    - `auth/`: Módulo de autenticación y manejo de roles.
    - `home/`: Pantalla principal y componentes relacionados con el menú dinámico.

## Detalles Específicos

### Módulo de Login
- **Vista y Funcionalidad:**
  - Pantalla de inicio de sesión con campos para usuario y contraseña.
  - Validación local de datos y manejo de errores.
- **Integración API:**
  - Conexión con el endpoint de autenticación para validar credenciales.
  - Almacén seguro de tokens (JWT).

### Selección de Roles
- **Vista:**
  - Pantalla que muestra los roles del usuario en una lista o dropdown.
- **Integración API:**
  - Consumo del endpoint para obtener roles asociados al usuario autenticado.

### Menú Principal
- **Vista y Funcionalidad:**
  - Pantalla inicial con opciones dinámicas basadas en el rol del usuario.
  - Navegación hacia otras secciones de la aplicación.
- **Integración API:**
  - Consumo de datos para configurar dinámicamente el menú.

### Menú Lateral
- **Vista y Funcionalidad:**
  - Drawer con:
    - Opciones de navegación interna.
    - Botones para cambiar roles y cerrar sesión.

## Próximos Pasos

- Detallar la implementación de cada módulo con ejemplos de código.
- Documentar cómo se conecta cada componente con la API de iDempiere.
- Incluir diagramas de flujo y arquitectura de la aplicación.
