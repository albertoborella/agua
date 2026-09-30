import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/models/models.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/samples_provider.dart';

class VencidasScreen extends StatefulWidget {
  const VencidasScreen({super.key});

  @override
  State<VencidasScreen> createState() => _VencidasScreenState();
}

class _VencidasScreenState extends State<VencidasScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SamplesProvider>().loadVencidas();
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

  IconData _getTipoIcon(String codigo) {
    if (codigo == 'CLORO') return Icons.water_drop;
    if (codigo == 'FQ') return Icons.science;
    if (codigo == 'MB') return Icons.biotech;
    return Icons.help_outline;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SamplesProvider>();
    final vencidas = provider.vencidas;
    final isLoading = provider.isLoadingVencidas;
    final error = provider.error;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Muestras Vencidas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: provider.loadVencidas,
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
                        onPressed: provider.loadVencidas,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : vencidas.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_outline,
                              size: 64, color: Colors.green),
                          const SizedBox(height: 16),
                          const Text('¡No hay muestras vencidas!'),
                          const SizedBox(height: 8),
                          const Text(
                            'Todas las muestras atrasadas han sido tomadas.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: provider.loadVencidas,
                      child: ListView.separated(
                        itemCount: vencidas.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final muestra = vencidas[index];
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
                                  title: const Text('Tomar muestra vencida'),
                                  content: Text(
                                    '¿Registrar la toma de "${muestra.tipoAnalisisNombre}" '
                                    'en ${muestra.fuenteNombre} ahora?\n\n'
                                    '(Estaba programada para ${muestra.fechaProgramada.day}/${muestra.fechaProgramada.month}/${muestra.fechaProgramada.year})',
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
                                backgroundColor: Colors.red.withValues(alpha: 0.15),
                                child: Icon(tipoIcon, color: Colors.red),
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
                                          color: Colors.red.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          muestra.estadoTexto,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.red,
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
                                  backgroundColor: Colors.red,
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