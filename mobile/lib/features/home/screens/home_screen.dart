import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agua'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Instructivo',
            onPressed: () => Navigator.pushNamed(context, '/help'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
          PopupMenuButton<String>(
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                user != null && user.username.isNotEmpty
                    ? user.username[0].toUpperCase()
                    : 'O',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            onSelected: (value) {
              if (value == 'logout') {
                _logout(context);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                enabled: false,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.username ?? 'Operario',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    if (user?.rol != null)
                      Text(
                        user!.rol,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.color,
                        ),
                      ),
                    if (user?.tenantId != null)
                      Text(
                        'Empresa: ${user!.tenantId}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.color,
                        ),
                      ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'logout',
                child: ListTile(
                  leading: const Icon(Icons.logout, size: 20),
                  title: const Text('Cerrar sesión'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // TODO: refresh data
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Greeting
              Text(
                'Hola, ${user?.username ?? 'Operario'}',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 24),

              // Summary cards
              _buildSummaryCard(
                context,
                title: 'Pendientes',
                count: 0,
                icon: Icons.pending_actions,
                color: Colors.orange,
              ),
              const SizedBox(height: 12),
              _buildSummaryCard(
                context,
                title: 'Realizadas',
                count: 0,
                icon: Icons.check_circle_outline,
                color: Colors.green,
              ),
              const SizedBox(height: 12),
              _buildSummaryCard(
                context,
                title: 'Vencidas',
                count: 0,
                icon: Icons.warning_amber,
                color: Colors.red,
              ),
              const SizedBox(height: 32),

              // Action buttons
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/new-sample'),
                icon: const Icon(Icons.add),
                label: const Text('Nueva Muestra'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/history'),
                icon: const Icon(Icons.history),
                label: const Text('Ver Historial'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/alerts'),
                icon: const Icon(Icons.notifications),
                label: const Text('Alertas'),
              ),

              // Admin section
              if (auth.isAdmin) ...[
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  'Administración',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/settings'),
                  icon: const Icon(Icons.settings),
                  label: const Text('Configuración'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/admin/users'),
                  icon: const Icon(Icons.people),
                  label: const Text('Usuarios'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required String title,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Text(
              count.toString(),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    await auth.logout();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }
}
