import 'package:flutter/material.dart';

/// In-app user manual, reached from the info icon on the home AppBar.
///
/// It walks a first-time user from an empty browser tab to a registered sample.
/// Everything above the last section describes behaviour that exists today; the
/// last section states what does not exist yet, so nobody burns an hour
/// looking for a feature that was never built.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Instructivo'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _AtajoCard(),
          _Section(
            title: '1. Levantá el sistema',
            subtitle: 'Sin esto no hay nada para ver.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Step(
                  number: 1,
                  text: 'Desde la raíz del repositorio corré '
                      'podman-compose up -d.',
                ),
                _Step(
                  number: 2,
                  text: 'Abrí http://localhost:8080 en el navegador. '
                      'El frontend NO está en el 5173.',
                ),
                _Step(
                  number: 3,
                  text: 'La API responde en http://localhost:8000. '
                      'No hace falta abrirla en otra pestaña.',
                ),
              ],
            ),
          ),
          _Section(
            title: '2. Configurá el ID de Empresa',
            subtitle: 'El "ID de Empresa" es el identificador de tu empresa '
                '(el tenant). No se pide en el login: se carga acá, en '
                'Configuración.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Bullet(
                  icon: Icons.badge_outlined,
                  text: 'El campo se llama "ID de Empresa" y su ayuda dice '
                      '"ej: empresa-abc".',
                ),
                _Bullet(
                  icon: Icons.science_outlined,
                  text: 'Con los datos de prueba el valor es demo.',
                ),
                _Bullet(
                  icon: Icons.info_outline,
                  text: 'Si falta, el login te avisa "Primero configurá el ID '
                      'de empresa" y te deja tocar "Ir a Configuración".',
                ),
              ],
            ),
          ),
          _Section(
            title: '3. Entrá con un usuario',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Step(
                  number: 1,
                  text: 'En el login escribí tu usuario y tu contraseña, y '
                      'tocá "Ingresar".',
                ),
                _Step(
                  number: 2,
                  text: 'Si el ID de Empresa no está cargado, los campos '
                      'quedan deshabilitados hasta que lo configures.',
                ),
                _Step(
                  number: 3,
                  text: 'Entrás directo al Home. La sesión queda guardada en el '
                      'navegador, así que al recargar la página volvés al '
                      'Home sin loguearte de nuevo (mientras el token siga '
                      'vigente).',
                ),
              ],
            ),
          ),
          _Section(
            title: '4. Usuarios de prueba',
            subtitle: 'Los tres existen con el ID de Empresa demo.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Credentials(),
                SizedBox(height: 12),
                _Bullet(
                  icon: Icons.admin_panel_settings_outlined,
                  text: 'Solo el ADMIN ve la sección "Administración" en el '
                      'Home.',
                ),
                _Bullet(
                  icon: Icons.science_outlined,
                  text: 'El OPERARIO registra muestras y consulta el historial '
                      'y las alertas.',
                ),
              ],
            ),
          ),
          _Section(
            title: '5. Administrá catálogos (solo ADMIN)',
            subtitle: 'En el Home, sección "Administración", tenés tres botones '
                'para configurar lo que usan los operarios al registrar muestras.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Bullet(
                  icon: Icons.science,
                  text: '"Tipos de Análisis": creá, editá o eliminá los tipos '
                      'que el operario elige (Cloro, FQ, MB, etc.). Los de '
                      'sistema (CLORO, FQ, MB, OTRO) no se pueden borrar.',
                ),
                _Bullet(
                  icon: Icons.water_drop,
                  text: '"Fuentes de Agua": cargá grifos, pozos u otras fuentes '
                      'asociadas a una planta. El tipo (GRIFO/POZO/RIO/...) '
                      'define el icono y si aplica la regla de aleatoriedad.',
                ),
                _Bullet(
                  icon: Icons.repeat,
                  text: '"Frecuencias de Muestreo": definí cada cuánto se debe '
                      'muestrear cada fuente para cada tipo de análisis '
                      '(diaria, semanal, mensual, etc.), con día y hora '
                      'esperada opcionales. Esto alimenta las alertas.',
                ),
                _Bullet(
                  icon: Icons.info_outline,
                  text: 'Los cambios son inmediatos: al volver a "Nueva Muestra" '
                      'el operario ya ve los nuevos tipos y fuentes.',
                ),
              ],
            ),
          ),
          _Section(
            title: '6. Registrá tu primera muestra',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Step(
                  number: 1,
                  text: 'En el Home tocá "Nueva Muestra".',
                ),
                _Step(
                  number: 2,
                  text: 'Elegí el "Tipo de Análisis".',
                ),
                _Step(
                  number: 3,
                  text: 'Elegí la fuente. Con cloro el sistema te propone una '
                      'al azar; con los demás tipos la elegís del desplegable.',
                ),
                _Step(
                  number: 4,
                  text: 'Tocá "Confirmar Toma".',
                ),
                _Step(
                  number: 5,
                  text: 'Te aparece "Muestra registrada" con el resumen, y '
                      'volvés al Home con "Volver al inicio".',
                ),
                _Step(
                  number: 6,
                  text: 'La muestra ya aparece en "Ver Historial".',
                ),
              ],
            ),
          ),
          _Section(
            title: '7. La regla del cloro',
            subtitle: 'El tipo de análisis con código CLORO se comporta '
                'distinto al resto.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Bullet(
                  icon: Icons.casino_outlined,
                  text: 'Al elegir Cloro, el app te propone una fuente al azar '
                      'sin que tengas que buscar nada.',
                ),
                _Bullet(
                  icon: Icons.swap_horiz,
                  text: 'Si no es la correcta, tocá "Cambiar fuente" y elegí '
                      'otra de la lista.',
                ),
                _Bullet(
                  icon: Icons.list_alt_outlined,
                  text: 'Para FQ, MB y OTRO se muestra el desplegable normal '
                      'con todas las fuentes.',
                ),
                _Bullet(
                  icon: Icons.refresh,
                  text: 'Cada vez que volvés a elegir un tipo de cloro se '
                      'sortea una fuente nueva: si ya habías tocado "Cambiar '
                      'fuente", esa elección se pierde al cambiar de tipo.',
                ),
              ],
            ),
          ),
          _Section(
            title: '8. Consultá el historial',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Bullet(
                  icon: Icons.history,
                  text: 'Desde el Home, "Ver Historial".',
                ),
                _Bullet(
                  icon: Icons.filter_alt_outlined,
                  text: 'Podés filtrar por fuente, por tipo de análisis y por '
                      'rango de fechas.',
                ),
                _Bullet(
                  icon: Icons.filter_alt_off_outlined,
                  text: '"Limpiar filtros" saca los tres filtros de una.',
                ),
                _Bullet(
                  icon: Icons.list_alt_outlined,
                  text: 'Cada fila muestra fecha y hora, fuente, tipo de '
                      'análisis y el operario que la tomó.',
                ),
              ],
            ),
          ),
          _Section(
            title: '9. Revisá las alertas',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Bullet(
                  icon: Icons.notifications_outlined,
                  text: 'Desde el Home, "Alertas".',
                ),
                _Bullet(
                  icon: Icons.category_outlined,
                  text: 'Vienen agrupadas en Vencidas, Pendientes y '
                      'Programadas.',
                ),
                _Bullet(
                  icon: Icons.touch_app_outlined,
                  text: 'Tocás una alerta y queda marcada como leída: sale de '
                      'la lista.',
                ),
                _Bullet(
                  icon: Icons.warning_amber,
                  text: 'No hay ninguna que se genere sola: las que ves las '
                      'cargó el script de datos de prueba (sección 10).',
                ),
              ],
            ),
          ),
          _Section(
            title: '10. Volvé a los datos de prueba',
            subtitle: 'Si ensuciaste los datos probando, este comando los '
                'deja como estaban al principio:',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Command(
                  'podman exec -w /app agua-backend '
                  'python scripts/seed_demo.py --reset',
                ),
                SizedBox(height: 12),
                _Bullet(
                  icon: Icons.restore,
                  text: 'Deja el tenant con 74 muestras y 5 alertas, borra '
                      'todo lo que hayas creado y vuelve a crear los usuarios '
                      'de prueba.',
                ),
              ],
            ),
          ),
          _Section(
            title: 'Limitaciones conocidas',
            subtitle: 'Lo que todavía NO está implementado, para que no lo '
                'busques.',
            child: _Callout(
              icon: Icons.report_gmailerrorred_outlined,
              tint: Colors.orange,
              children: [
                _Bullet(
                  icon: Icons.notification_important_outlined,
                  text: 'Nada genera alertas automáticamente. Las alertas de '
                      'demo las inserta el script de seed; lo único que '
                      'existe es leerlas y marcarlas como leídas.',
                ),
                _Bullet(
                  icon: Icons.token_outlined,
                  text: 'No hay refresco automático de token. Una sesión '
                      'guardada con el token vencido da 401 y tenés que volver '
                      'a loguearte.',
                ),
                _Bullet(
                  icon: Icons.format_list_numbered,
                  text: 'El historial no tiene paginación: se cargan todas '
                      'las muestras del tenant de una.',
                ),
                _Bullet(
                  icon: Icons.person_off,
                  text: 'El botón "Usuarios" en Administración apunta a una '
                      'ruta que todavía no está registrada, así que no abre. '
                      'El menú de persona (avatar) SÍ tiene "Cerrar sesión" '
                      'y funciona.',
                ),
                _Bullet(
                  icon: Icons.dashboard_customize_outlined,
                  text: 'Las tarjetas de resumen del Home (Pendientes, '
                      'Realizadas, Vencidas) muestran 0 fijo: todavía no se '
                      'calculan.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Atajo ─────────────────────────────────────────────────────────────

/// The three things you need to get in, on screen before you read anything
/// else.
class _AtajoCard extends StatelessWidget {
  const _AtajoCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.bolt, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Atajo',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const _Fact(
              icon: Icons.language,
              label: 'App',
              value: 'http://localhost:8080',
            ),
            const _Fact(
              icon: Icons.business,
              label: 'ID de Empresa',
              value: 'demo',
            ),
            const _Fact(
              icon: Icons.admin_panel_settings_outlined,
              label: 'Admin',
              value: 'admin / Admin123!',
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────

/// Titled block. The manual is one long scroll, so each block needs a stable
/// anchor to skim by.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.subtitle});

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

/// Numbered step, for the ordered paths where the order carries meaning.
class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$number',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Unordered point. The icon is what tells a "this is how it works" line apart
/// from a "this does not exist" line, so it is not decorative.
class _Bullet extends StatelessWidget {
  const _Bullet({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

/// Icon + label + value row. Values get a monospace face because the whole
/// point of the Atajo card is that you copy them somewhere else.
class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Seeded users, one block per role. A table would squeeze the long role name
/// on a phone, and the role matters as much as the credentials.
class _Credentials extends StatelessWidget {
  const _Credentials();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const [
            _User(
              rol: 'ADMIN',
              usuario: 'admin',
              password: 'Admin123!',
            ),
            Divider(height: 24),
            _User(
              rol: 'OPERARIO',
              usuario: 'operario',
              password: 'Operario123!',
            ),
            Divider(height: 24),
            _User(
              rol: 'LABORATORISTA',
              usuario: 'lab',
              password: 'Lab123!',
            ),
          ],
        ),
      ),
    );
  }
}

class _User extends StatelessWidget {
  const _User({
    required this.rol,
    required this.usuario,
    required this.password,
  });

  final String rol;
  final String usuario;
  final String password;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          rol,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          '$usuario  /  $password',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontFamily: 'monospace',
              ),
        ),
      ],
    );
  }
}

/// Shell command, kept on one line and monospaced so it can be pasted as-is.
class _Command extends StatelessWidget {
  const _Command(this.command);

  final String command;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Text(
        command,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}

/// Tinted box for what is NOT implemented, so the limitation list never reads
/// like a feature list.
class _Callout extends StatelessWidget {
  const _Callout({
    required this.icon,
    required this.tint,
    required this.children,
  });

  final IconData icon;
  final Color tint;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tint.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tint.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: tint),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'No está implementado',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: tint,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}
