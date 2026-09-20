# Caso de Uso: Autenticacion

## UC-AUTH-001: Iniciar Sesion

**Actor**: Cualquier usuario (Admin, Operario, Laboratorista).

**Precondicion**: El usuario tiene usuario y contrasena asignados por el
administrador.

**Flujo principal**:

1. El usuario abre la app movil.
2. El sistema muestra la pantalla de login con campos usuario y contrasena.
3. El usuario ingresa sus credenciales y presiona "Ingresar".
4. El sistema valida las credenciales contra la base de datos.
5. El sistema genera un access token y un refresh token.
6. El sistema redirige al usuario a la pantalla principal segun su rol.

**Flujos alternativos**:

- **4a. Credenciales invalidas**: el sistema muestra "Usuario o contrasena
  incorrectos" y permanece en la pantalla de login.
- **4b. Usuario desactivado**: el sistema muestra "Su cuenta esta
  desactivada. Contacte al administrador."
- **4c. Limite de intentos**: despues de 5 intentos fallidos, el sistema
  bloquea el login por 15 minutos y muestra "Demasiados intentos. Espere
  X minutos."

**Postcondicion**: El usuario esta autenticado y puede usar la app.

---

## UC-AUTH-002: Cambiar Contrasena (Propia)

**Actor**: Cualquier usuario logueado.

**Precondicion**: El usuario esta autenticado.

**Flujo principal**:

1. El usuario accede a "Mi cuenta" > "Cambiar contrasena".
2. El sistema muestra campos: contrasena actual, nueva contrasena,
  confirmar contrasena.
3. El usuario completa los campos y presiona "Guardar".
4. El sistema valida:
   - La contrasena actual es correcta.
   - La nueva contrasena cumple politica (min 8 chars, mayuscula, minuscula,
     numero).
   - Las dos nuevas contrasenas coinciden.
   - No es igual a las ultimas 3 contrasenas.
5. El sistema actualiza la contrasena y muestra "Contrasena actualizada".

**Flujos alternativos**:

- **4a. Contrasena actual incorrecta**: "La contrasena actual es
  incorrecta."
- **4b. No cumple politica**: "La contrasena debe tener minimo 8
  caracteres, una mayuscula, una minuscula y un numero."
- **4c. No coinciden**: "Las contrasena no coinciden."
- **4d. Reutilizada**: "No puede usar una contrasena recientemente
  utilizada."

**Postcondicion**: La contrasena esta actualizada. Las sesiones activas
en otros dispositivos se invalidan.

---

## UC-AUTH-003: Restablecer Contrasena (Admin)

**Actor**: Administrador.

**Precondicion**: El administrador esta logueado.

**Flujo principal**:

1. El administrador accede a "Usuarios" > selecciona un usuario >
   "Restablecer contrasena".
2. El sistema muestra un formulario para ingresar la nueva contrasena.
3. El administrador ingresa la nueva contrasena y confirma.
4. El sistema actualiza la contrasena del usuario seleccionado.
5. El usuario afectado debe usar la nueva contrasena en su proximo login.

**Postcondicion**: La contrasena del usuario seleccionado esta actualizada.
