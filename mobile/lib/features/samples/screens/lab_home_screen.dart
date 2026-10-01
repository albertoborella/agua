import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/models/lab_sample.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/lab_provider.dart';
import 'lab_samples_screen.dart';
import 'lab_analysis_entry_screen.dart';

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
      final provider = context.read<LabProvider>();
      provider.loadCounts();
      // Load pending samples by default for the home screen
      provider.loadSamples(estadoAnalisis: 'PENDIENTE');
    });
  }

  Future<void> _refresh() async {
    final provider = context.read<LabProvider>();
    await Future.wait([
      provider.loadCounts(),
      provider.loadSamples(estadoAnalisis: 'PENDIENTE'),
    ]);
  }

  Future<void> _logout(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    await auth.logout();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  void _navigateToAnalysis(BuildContext context, LabSample muestra) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LabAnalysisEntryScreen(sample: muestra),
      ),
    ).then((_) {
      // Refresh on return
      context.read<LabProvider>().loadSamples(estadoAnalisis: 'PENDIENTE');
      context.read<LabProvider>().loadCounts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final lab = context.watch<LabProvider>();
    final user = auth.user;
    final counts = lab.counts;
    final pendingSamples = lab.samples; // Already filtered to PENDIENTE by initState

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
        child: Column(
          children: [
            // Summary cards header
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hola, ${user?.username ?? 'Laboratorista'}',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Muestras pendientes de análisis',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          context,
                          title: 'Pendientes',
                          count: counts?.pendientesAnalisis ?? 0,
                          icon: Icons.pending_actions,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSummaryCard(
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
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            
            // Pending samples list
            Expanded(
              child: lab.isLoadingSamples
                  ? const Center(child: CircularProgressIndicator())
                  : lab.error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              const SizedBox(height: 16),
                              Text(lab.error!),
                              const SizedBox(height: 16),
                              FilledButton(
                                onPressed: _refresh,
                                child: const Text('Reintentar'),
                              ),
                            ],
                          ),
                        )
                      : pendingSamples.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.check_circle_outline,
                                      size: 64, color: Colors.green),
                                  const SizedBox(height: 16),
                                  const Text('¡No hay muestras pendientes de análisis!'),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Todas las muestras han sido analizadas.',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(8),
                              itemCount: pendingSamples.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final muestra = pendingSamples[index];
                                return _buildPendingSampleTile(context, muestra);
                              },
                            ),
            ),
          ],
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
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
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

  Widget _buildPendingSampleTile(BuildContext context, LabSample muestra) {
    final tipoColor = _getTipoColor(muestra.tipoAnalisisCodigo);
    final tipoIcon = _getTipoIcon(muestra.tipoAnalisisCodigo);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: tipoColor.withValues(alpha: 0.15),
        child: Icon(tipoIcon, color: tipoColor),
      ),
      title: Text(muestra.tipoAnalisisNombre),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(muestra.fuenteNombre),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'PENDIENTE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: tipoColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  muestra.fuenteTipo,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: tipoColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Operario: ${muestra.operarioUsername}',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Tomada: ${muestra.fecha} ${muestra.hora.substring(0, 5)}',
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
      trailing: FilledButton.icon(
        icon: Icon(
          muestra.isCloro ? Icons.water_drop : Icons.science,
          size: 18,
        ),
        label: Text(muestra.isCloro ? 'Cloro' : 'Analizar'),
        onPressed: () => _navigateToAnalysis(context, muestra),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
      onTap: () => _navigateToAnalysis(context, muestra),
    );
  }

  Color _getTipoColor(String codigo) {
    switch (codigo) {
      case 'CLORO':
        return Colors.blue;
      case 'FQ':
        return Colors.purple;
      case 'MB':
        return Colors.teal;
      case 'OTRO':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getTipoIcon(String codigo) {
    switch (codigo) {
      case 'CLORO':
        return Icons.water_drop;
      case 'FQ':
        return Icons.science;
      case 'MB':
        return Icons.biotech;
      case 'OTRO':
        return Icons.category;
      default:
        return Icons.help_outline;
    }
  }
}