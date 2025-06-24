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

## Requisitos Técnicos

- **Framework:** Flutter (versión actualizada).
- **Backend:** Conexión con la API REST de iDempiere.
- **Autenticación:**
  - Implementar manejo de tokens (JWT o sesión según lo definido en la API).
  - Almacenar de forma segura las credenciales y tokens.

## Detalles Específicos

### Módulo de Login
- **Entrada de Datos:**
  - Campos para usuario y contraseña.
  - Botón de inicio de sesión.
- **Validación:**
  - Validar los campos localmente antes de enviar los datos al servidor.
  - Mostrar mensajes de error en caso de credenciales incorrectas.
- **Conexión API:**
  - Endpoint de autenticación de iDempiere.
  - Manejo de errores de conexión o respuestas no exitosas.

### Selección de Roles
- **Vista:**
  - Pantalla con una lista desplegable o botones que muestren los roles del usuario.
- **Conexión API:**
  - Endpoint para obtener roles según el usuario autenticado.
  - Guardar el rol seleccionado para modificar dinámicamente las opciones del menú principal.

### Menú Principal
- **Vista:**
  - Pantalla principal con un diseño limpio y adaptable.
  - Opciones dinámicas basadas en el rol del usuario.
- **Conexión API:**
  - Endpoint para obtener las opciones de menú.
  - Manejo dinámico del contenido según las respuestas del servidor.

### Menú Lateral
- **Vista:**
  - Drawer con las siguientes opciones:
    - Navegación principal de la aplicación.
    - Botón "Cambiar Rol" que redirige a la pantalla de selección de roles.
    - Botón "Cerrar Sesión" para salir del sistema y redirigir al login.

## Entregables

- Código funcional con las características descritas.
- Documentación técnica del desarrollo (posterior a la finalización de la aplicación).
- Manual de usuario (opcional, si es requerido por el cliente).

---

### Notas
Este documento se actualizará en caso de recibir más detalles o cambios en los requerimientos del proyecto.
