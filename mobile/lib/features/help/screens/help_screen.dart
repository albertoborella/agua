import 'package:flutter/material.dart';

/// In-app user manual, reached from the info icon on the home AppBar.
///
/// Written for an end user who wants to understand how to use Agua for
/// water quality control. No dev jargon, no setup instructions — just
/// the workflows the app actually supports.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manual de Usuario'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _QuickStartCard(),
          _Section(
            title: '1. ¿Qué es Agua?',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Bullet(
                  icon: Icons.water_drop_outlined,
                  text: 'Sistema de control de calidad de agua para empresas de saneamiento, cooperativas, municipios y laboratorios.',
                ),
                _Bullet(
                  icon: Icons.check_circle_outline,
                  text: 'Registra tomas de muestra en campo (operarios).',
                ),
                _Bullet(
                  icon: Icons.schedule_outlined,
                  text: 'Programa frecuencias de muestreo por fuente y tipo de análisis.',
                ),
                _Bullet(
                  icon: Icons.notifications_outlined,
                  text: 'Recibe alertas cuando una muestra está pendiente o vencida.',
                ),
                _Bullet(
                  icon: Icons.history_outlined,
                  text: 'Consulta historial completo con filtros.',
                ),
                _Bullet(
                  icon: Icons.admin_panel_settings_outlined,
                  text: 'Administra catálogos (tipos, fuentes, plantas, usuarios) — solo administradores.',
                ),
              ],
            ),
          ),
          _Section(
            title: '2. Primer acceso: ID de Empresa',
            subtitle: 'El "ID de Empresa" identifica a tu organización. No se pide en el login, se configura una vez en Configuración.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Step(
                  number: 1,
                  text: 'Tocá el ícono ⚙️ Configuración (arriba a la derecha).',
                ),
                _Step(
                  number: 2,
                  text: 'En "ID de Empresa" escribí el valor que te dio tu administrador.',
                ),
                _Step(
                  number: 3,
                  text: 'Tocá Guardar.',
                ),
                _Bullet(
                  icon: Icons.info_outline,
                  text: 'Para probar la app ahora mismo, usá: demo',
                ),
                _Bullet(
                  icon: Icons.business_outlined,
                  text: 'Cuando compres el sistema, tu admin te dará tu ID real (ej: cooperativa-agua-azul). Solo reemplazá "demo" por ese valor.',
                ),
              ],
            ),
          ),
          _Section(
            title: '3. Roles de usuario',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _RoleRow(
                  rol: 'ADMIN',
                  icon: Icons.admin_panel_settings_outlined,
                  color: Colors.red,
                  descripcion: 'Acceso total: catálogos, usuarios, todo el sistema',
                  usuarios: 'Gerentes, responsables de calidad, admin TI',
                ),
                _RoleRow(
                  rol: 'OPERARIO',
                  icon: Icons.engineering_outlined,
                  color: Colors.blue,
                  descripcion: 'Registra muestras, ve historial y alertas',
                  usuarios: 'Personal de campo que toma las muestras',
                ),
                _RoleRow(
                  rol: 'LABORATORISTA',
                  icon: Icons.science_outlined,
                  color: Colors.green,
                  descripcion: 'Consulta historial, resultados y alertas',
                  usuarios: 'Personal de laboratorio que analiza',
                ),
                _Bullet(
                  icon: Icons.lock_outline,
                  text: 'Solo el ADMIN ve la sección "Administración" en el Home.',
                ),
              ],
            ),
          ),
          _Section(
            title: '4. Flujo diario: Registrar una muestra (OPERARIO)',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Step(
                  number: 1,
                  text: 'En el Home, tocá "Nueva Muestra".',
                ),
                _Step(
                  number: 2,
                  text: 'Elegí el Tipo de Análisis (Cloro, FQ, MB, OTRO...).',
                ),
                _Step(
                  number: 3,
                  text: 'Elegí la Fuente de Agua.',
                ),
                _Step(
                  number: 4,
                  text: 'Tocá "Confirmar Toma".',
                ),
                _Step(
                  number: 5,
                  text: 'Verás la confirmación. Tocá "Volver al inicio".',
                ),
              ],
            ),
          ),
          _Section(
            title: '5. La regla del Cloro (importante)',
            subtitle: 'El tipo con código CLORO se comporta distinto al resto.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Bullet(
                  icon: Icons.casino_outlined,
                  text: 'Al elegir Cloro, el app te propone una fuente al azar (regla de aleatoriedad).',
                ),
                _Bullet(
                  icon: Icons.swap_horiz_outlined,
                  text: 'Si no es la correcta, tocá "Cambiar fuente" y elegí otra de la lista.',
                ),
                _Bullet(
                  icon: Icons.list_alt_outlined,
                  text: 'Para FQ, MB y OTRO se muestra el desplegable normal con todas las fuentes.',
                ),
                _Bullet(
                  icon: Icons.refresh_outlined,
                  text: 'Cada vez que volvés a elegir Cloro se sortea una fuente nueva.',
                ),
              ],
            ),
          ),
          _Section(
            title: '6. Consultar el Historial',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Bullet(
                  icon: Icons.history_outlined,
                  text: 'Desde el Home, tocá "Ver Historial".',
                ),
                _Bullet(
                  icon: Icons.filter_alt_outlined,
                  text: 'Filtrá por Fuente, Tipo de análisis y Rango de fechas.',
                ),
                _Bullet(
                  icon: Icons.filter_alt_off_outlined,
                  text: '"Limpiar filtros" quita los tres filtros de una.',
                ),
                _Bullet(
                  icon: Icons.list_alt_outlined,
                  text: 'Cada fila muestra: fecha/hora, fuente, tipo, operario.',
                ),
              ],
            ),
          ),
          _Section(
            title: '7. Alertas',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Bullet(
                  icon: Icons.notifications_outlined,
                  text: 'Desde el Home, tocá "Alertas".',
                ),
                _Bullet(
                  icon: Icons.category_outlined,
                  text: 'Agrupadas en: Vencidas, Pendientes, Programadas.',
                ),
                _Bullet(
                  icon: Icons.touch_app_outlined,
                  text: 'Tocá una alerta → se marca como leída y sale de la lista.',
                ),
                _Bullet(
                  icon: Icons.schedule_outlined,
                  text: 'Se generan automáticamente según las Frecuencias configuradas por el ADMIN.',
                ),
              ],
            ),
          ),
          _Section(
            title: '8. Administración (solo ADMIN)',
            subtitle: 'En el Home, sección "Administración".',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _AdminItem(
                  icon: Icons.people_outline,
                  titulo: 'Usuarios',
                  descripcion: 'Crear, editar (rol, email, activo), resetear contraseña, eliminar. No podés eliminarte a vos mismo.',
                ),
                _AdminItem(
                  icon: Icons.science_outlined,
                  titulo: 'Tipos de Análisis',
                  descripcion: 'Catálogo global. Código (CLORO, FQ, MB...), Nombre, Requiere descripción. Los de sistema no se borran.',
                ),
                _AdminItem(
                  icon: Icons.water_drop_outlined,
                  titulo: 'Fuentes de Agua',
                  descripcion: 'Grifos, pozos, ríos... asociados a una planta. Tipo define ícono. Activa/Inactiva para pausar sin borrar historial.',
                ),
                _AdminItem(
                  icon: Icons.repeat_outlined,
                  titulo: 'Frecuencias de Muestreo',
                  descripcion: 'Programan cuándo muestrear: fuente + tipo + frecuencia (diaria/semanal/mensual...) + día/hora opcionales. Alimentan las alertas.',
                ),
                _Bullet(
                  icon: Icons.info_outline,
                  text: 'Los cambios son inmediatos: al volver a "Nueva Muestra" el operario ya ve los nuevos catálogos.',
                ),
              ],
            ),
          ),
          _Section(
            title: '9. Gestión de sesión',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Bullet(
                  icon: Icons.save_outlined,
                  text: 'La sesión se guarda en el navegador: al cerrar y reabrir, seguís logueado (mientras el token no expire — 30 min).',
                ),
                _Bullet(
                  icon: Icons.logout_outlined,
                  text: 'Cerrar sesión: tocá tu avatar (arriba a la derecha) → "Cerrar sesión".',
                ),
                _Bullet(
                  icon: Icons.lock_reset_outlined,
                  text: 'Cambiar contraseña: Configuración → "Cambiar contraseña".',
                ),
              ],
            ),
          ),
          _Section(
            title: '10. Preguntas frecuentes',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _FAQ(
                  pregunta: '"Me dice: Primero configurá el ID de Empresa"',
                  respuesta: 'Andá a ⚙️ Configuración, poné el ID (ej: demo o el que te dio tu admin) y guardá.',
                ),
                _FAQ(
                  pregunta: '"No veo la sección Administración"',
                  respuesta: 'Solo el rol ADMIN la ve. Si sos Operario o Laboratorista, no tenés acceso.',
                ),
                _FAQ(
                  pregunta: '"Token inválido o expirado" al recargar',
                  respuesta: 'La sesión expiró (30 min sin actividad). Volvé a loguearte.',
                ),
                _FAQ(
                  pregunta: '"No veo mis muestras en el historial"',
                  respuesta: 'Verificá los filtros (fuente, tipo, fecha). Tocá "Limpiar filtros".',
                ),
                _FAQ(
                  pregunta: '"Quiero usar mi propia empresa, no demo"',
                  respuesta: '1. Cambiá el ID en Configuración por el que te asignaron. 2. Logueate como admin. 3. En Administración → Usuarios creá a tu equipo. 4. En Fuentes cargá tus plantas/fuentes. 5. En Frecuencias programá los muestreos.',
                ),
              ],
            ),
          ),
          _Section(
            title: '11. Datos de prueba (solo demo)',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _CredentialsRow(rol: 'ADMIN', usuario: 'admin', password: 'Admin123!'),
                _CredentialsRow(rol: 'OPERARIO', usuario: 'operario', password: 'Operario123!'),
                _CredentialsRow(rol: 'LABORATORISTA', usuario: 'lab', password: 'Lab123!'),
                const SizedBox(height: 12),
                _Bullet(
                  icon: Icons.business_outlined,
                  text: 'ID de Empresa: demo',
                ),
                _Bullet(
                  icon: Icons.restore_outlined,
                  text: 'Para resetear datos de demo (borra todo y vuelve al estado inicial):',
                ),
                _Command('podman exec -w /app agua-backend python scripts/seed_demo.py --reset'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ── Quick start card ───────────────────────────────────────────────────
class _QuickStartCard extends StatelessWidget {
  const _QuickStartCard();

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
                  'Acceso rápido',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const _FactRow(label: 'App', value: 'http://localhost:8080', icon: Icons.language),
            const _FactRow(label: 'ID Empresa (demo)', value: 'demo', icon: Icons.business),
            const _FactRow(label: 'Admin', value: 'admin / Admin123!', icon: Icons.admin_panel_settings_outlined),
            const _FactRow(label: 'Operario', value: 'operario / Operario123!', icon: Icons.engineering_outlined),
            const _FactRow(label: 'Laboratorista', value: 'lab / Lab123!', icon: Icons.science_outlined),
          ],
        ),
      ),
    );
  }
}

/// ── Section wrapper ────────────────────────────────────────────────────
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

/// ── Numbered step ──────────────────────────────────────────────────────
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
              child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
            ),
          ),
        ],
      ),
    );
  }
}

/// ── Bullet point ───────────────────────────────────────────────────────
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
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

/// ── Role row ───────────────────────────────────────────────────────────
class _RoleRow extends StatelessWidget {
  const _RoleRow({
    required this.rol,
    required this.icon,
    required this.color,
    required this.descripcion,
    required this.usuarios,
  });

  final String rol;
  final IconData icon;
  final Color color;
  final String descripcion;
  final String usuarios;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withAlpha(30),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  rol,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(descripcion, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text(
              'Usuarios típicos: $usuarios',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

/// ── Admin item ─────────────────────────────────────────────────────────
class _AdminItem extends StatelessWidget {
  const _AdminItem({
    required this.icon,
    required this.titulo,
    required this.descripcion,
  });

  final IconData icon;
  final String titulo;
  final String descripcion;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 12),
                  Text(
                    titulo,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(descripcion, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}

/// ── FAQ item ───────────────────────────────────────────────────────────
class _FAQ extends StatelessWidget {
  const _FAQ({required this.pregunta, required this.respuesta});

  final String pregunta;
  final String respuesta;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              pregunta,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(respuesta, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

/// ── Credentials row ────────────────────────────────────────────────────
class _CredentialsRow extends StatelessWidget {
  const _CredentialsRow({
    required this.rol,
    required this.usuario,
    required this.password,
  });

  final String rol;
  final String usuario;
  final String password;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              rol,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$usuario  /  $password',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ── Fact row (key/value) ───────────────────────────────────────────────
class _FactRow extends StatelessWidget {
  const _FactRow({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

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

/// ── Command block ──────────────────────────────────────────────────────
class _Command extends StatelessWidget {
  const _Command(this.command);

  final String command;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
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