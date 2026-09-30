import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/lab_provider.dart';

class LabHomeScreen extends StatefulWidget {
  const LabHomeScreen({super.key});

  @override
  State<LabHomeScreen> createState() => _LabHomeScreenState();
}

class _LabHomeScreenState extends State<LabHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LabProvider>().loadCounts();
    });
  }

  Future<void> _refresh() async {
    await context.read<LabProvider>().loadCounts();
  }

  Future<void> _logout(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    await auth.logout();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final lab = context.watch<LabProvider>();
    final user = auth.user;
    final counts = lab.counts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laboratorio'),
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
                    : 'L',
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
                      user?.username ?? 'Laboratorista',
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
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    if (user?.tenantId != null)
                      Text(
                        'Empresa: ${user!.tenantId}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).textTheme.bodySmall?.color,
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
        onRefresh: _refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Greeting
              Text(
                'Hola, ${user?.username ?? 'Laboratorista'}',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Gestión de análisis de muestras',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
              ),
              const SizedBox(height: 24),

              // Summary cards
              _buildSummaryCard(
                context,
                title: 'Pendientes de Análisis',
                count: counts?.pendientesAnalisis ?? 0,
                icon: Icons.pending_actions,
                color: Colors.orange,
                onTap: () => Navigator.pushNamed(context, '/lab/samples'),
              ),
              const SizedBox(height: 12),
              _buildSummaryCard(
                context,
                title: 'Analizadas',
                count: counts?.analizadas ?? 0,
                icon: Icons.check_circle_outline,
                color: Colors.green,
                onTap: () => Navigator.pushNamed(
                  context,
                  '/lab/samples',
                  arguments: {'estadoAnalisis': 'ANALIZADO'},
                ),
              ),
              const SizedBox(height: 12),
              _buildSummaryCard(
                context,
                title: 'Total Muestras',
                count: counts?.total ?? 0,
                icon: Icons.science,
                color: Colors.blue,
                onTap: () => Navigator.pushNamed(context, '/lab/samples'),
              ),
              const SizedBox(height: 32),

              // Quick actions
              Text(
                'Accesos rápidos',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              _buildActionButton(
                context,
                icon: Icons.water_drop,
                label: 'Solo Cloro',
                color: Colors.blue,
                onTap: () => Navigator.pushNamed(
                  context,
                  '/lab/samples',
                  arguments: {'tipoAnalisisCodigo': 'CLORO'},
                ),
              ),
              const SizedBox(height: 8),
              _buildActionButton(
                context,
                icon: Icons.science,
                label: 'Físico-Químico (FQ)',
                color: Colors.purple,
                onTap: () => Navigator.pushNamed(
                  context,
                  '/lab/samples',
                  arguments: {'tipoAnalisisCodigo': 'FQ'},
                ),
              ),
              const SizedBox(height: 8),
              _buildActionButton(
                context,
                icon: Icons.biotech,
                label: 'Microbiológico (MB)',
                color: Colors.teal,
                onTap: () => Navigator.pushNamed(
                  context,
                  '/lab/samples',
                  arguments: {'tipoAnalisisCodigo': 'MB'},
                ),
              ),
              const SizedBox(height: 8),
              _buildActionButton(
                context,
                icon: Icons.category,
                label: 'Otros Análisis',
                color: Colors.grey,
                onTap: () => Navigator.pushNamed(
                  context,
                  '/lab/samples',
                  arguments: {'tipoAnalisisCodigo': 'OTRO'},
                ),
              ),
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
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
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
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            Icon(Icons.chevron_right, color: color),
          ],
        ),
      ),
    );
  }
}