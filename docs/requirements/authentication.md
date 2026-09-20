# Autenticacion y Autorizacion

## 1. Modelo de Usuarios

| Rol | Quien lo tiene | Permisos principales |
| ---- | -------------- | -------------------- |
| **Administrador** | Primer usuario creado por script; otros admins creados por este | Configurar planta (grifos, pozos, frecuencias), gestionar usuarios, ver todas las muestras. |
| **Operario** | Empleados que toman muestras | Registrar tomas de muestra, ver historial propio, ver alertas del dia. |
| **Laboratorista** | Empleados del laboratorio (futuro) | Ingresar resultados de analisis (futuro). |

## 2. Registro del Primer Administrador

El primer administrador se crea mediante un script de inicializacion:

```bash
python manage.py createsuperadmin
```

El script solicita:
- Nombre de usuario
- Correo electronico
- Contrasena (con confirmacion)

Este usuario tiene permisos de administrador total y es el unico que puede
crear otros usuarios desde la interfaz.

## 3. Gestion de Usuarios

El administrador puede:
- **Crear** un nuevo usuario asignando: nombre de usuario, contrasena
  inicial y rol.
- **Editar** nombre, correo y rol de un usuario existente.
- **Desactivar** un usuario sin eliminarlo (preserva historial).
- **Restablecer** la contrasena de un usuario.

## 4. Cambio de Contrasena

- El usuario recibe un link para cambiar su contrasena (generado por el
  sistema o enviado por el administrador).
- La contrasena debe cumplir Politica Minima de Seguridad:
  - Minimo 8 caracteres.
  - Al menos una mayuscula, una minuscula y un numero.
  - No puede ser identica a las ultimas 3 contrasenas usadas.
- La sesion expira tras un periodo configurable de inactividad (default: 30
  minutos).

## 5. Sesion

- Cada usuario tiene una unica sesion activa por dispositivo.
- Al cerrar sesion o expirar, se invalida el token de sesion.
- El operario puede trabajar offline; la autenticacion se valida al
  sincronizar.
