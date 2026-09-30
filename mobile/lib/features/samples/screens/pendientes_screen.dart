import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/models/models.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/samples_provider.dart';

class PendientesScreen extends StatefulWidget {
  const PendientesScreen({super.key});

  @override
  State<PendientesScreen> createState() => _PendientesScreenState();
}

class _PendientesScreenState extends State<PendientesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SamplesProvider>().loadPendientes();
    });
  }

  Future<void> _tomarMuestra(ScheduledSample muestra) async {
    try {
      final api = context.read<AuthProvider>().api;
      await api.takeScheduledSample(
        frecuenciaId: muestra.frecuenciaId,
        fuenteId: muestra.fuenteId,
        tipoAnalisisId: muestra.tipoAnalisisId,
      );
      if (!mounted) return;
      // Refresh all data in provider (will notify all listeners)
      await context.read<SamplesProvider>().onSampleTaken();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Muestra de ${muestra.fuenteNombre} tomada correctamente')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Color _getEstadoColor(ScheduledSample muestra) {
    if (muestra.diasDesdeProgramada < 0) {
      return Colors.blue; // future
    } else if (muestra.diasDesdeProgramada == 0) {
      return Colors.orange; // today
    } else {
      return Colors.red; // overdue
    }
  }

  IconData _getTipoIcon(String codigo) {
    if (codigo == 'CLORO') return Icons.water_drop;
    if (codigo == 'FQ') return Icons.science;
    if (codigo == 'MB') return Icons.biotech;
    return Icons.help_outline;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SamplesProvider>();
    final pendientes = provider.pendientes;
    final isLoading = provider.isLoadingPendientes;
    final error = provider.error;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Muestras Pendientes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: provider.loadPendientes,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
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
                      Text(error!),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: provider.loadPendientes,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : pendientes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_outline,
                              size: 64, color: Colors.green),
                          const SizedBox(height: 16),
                          const Text('¡No hay muestras pendientes!'),
                          const SizedBox(height: 8),
                          const Text(
                            'Todas las muestras programadas están al día.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: provider.loadPendientes,
                      child: ListView.separated(
                        itemCount: pendientes.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final muestra = pendientes[index];
                          final estadoColor = _getEstadoColor(muestra);
                          final tipoIcon = _getTipoIcon(muestra.tipoAnalisisCodigo);

                          return Dismissible(
                            key: Key(muestra.frecuenciaId),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              color: Colors.green,
                              child: const Icon(Icons.check, color: Colors.white),
                            ),
                            confirmDismiss: (direction) async {
                              return await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Tomar muestra'),
                                  content: Text(
                                    '¿Registrar la toma de "${muestra.tipoAnalisisNombre}" '
                                    'en ${muestra.fuenteNombre} ahora?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text('Cancelar'),
                                    ),
                                    FilledButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      child: const Text('Tomar ahora'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            onDismissed: (_) => _tomarMuestra(muestra),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: estadoColor.withValues(alpha: 0.15),
                                child: Icon(tipoIcon, color: estadoColor),
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
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: estadoColor.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          muestra.estadoTexto,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: estadoColor,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.primaryContainer,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          muestra.fuenteTipo,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: FilledButton.icon(
                                icon: const Icon(Icons.check, size: 18),
                                label: const Text('Tomar'),
                                onPressed: () => _tomarMuestra(muestra),
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}