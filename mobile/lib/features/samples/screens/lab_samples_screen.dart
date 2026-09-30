import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/models/lab_sample.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/lab_provider.dart';
import 'lab_analysis_entry_screen.dart';

class LabSamplesScreen extends StatefulWidget {
  final String? estadoAnalisis;
  final String? tipoAnalisisCodigo;

  const LabSamplesScreen({
    super.key,
    this.estadoAnalisis,
    this.tipoAnalisisCodigo,
  });

  @override
  State<LabSamplesScreen> createState() => _LabSamplesScreenState();
}

class _LabSamplesScreenState extends State<LabSamplesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LabProvider>().loadSamples(
        estadoAnalisis: widget.estadoAnalisis,
        tipoAnalisisCodigo: widget.tipoAnalisisCodigo,
      );
    });
  }

  String _getTitle() {
    if (widget.tipoAnalisisCodigo != null) {
      switch (widget.tipoAnalisisCodigo) {
        case 'CLORO':
          return 'Muestras de Cloro';
        case 'FQ':
          return 'Muestras Físico-Químico';
        case 'MB':
          return 'Muestras Microbiológico';
        case 'OTRO':
          return 'Otros Análisis';
        default:
          return 'Muestras';
      }
    }
    if (widget.estadoAnalisis == 'ANALIZADO') {
      return 'Muestras Analizadas';
    }
    return 'Muestras Pendientes de Análisis';
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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LabProvider>();
    final samples = provider.samples;
    final isLoading = provider.isLoadingSamples;
    final error = provider.error;

    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<LabProvider>().loadSamples(
              estadoAnalisis: widget.estadoAnalisis,
              tipoAnalisisCodigo: widget.tipoAnalisisCodigo,
            ),
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
                        onPressed: () => context.read<LabProvider>().loadSamples(
                          estadoAnalisis: widget.estadoAnalisis,
                          tipoAnalisisCodigo: widget.tipoAnalisisCodigo,
                        ),
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : samples.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_outline,
                              size: 64, color: Colors.green),
                          const SizedBox(height: 16),
                          Text(
                            widget.estadoAnalisis == 'ANALIZADO'
                                ? 'No hay muestras analizadas'
                                : '¡No hay muestras pendientes de análisis!',
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.estadoAnalisis == 'ANALIZADO'
                                ? 'Todas las muestras analizadas se muestran aquí.'
                                : 'Todas las muestras han sido analizadas.',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => context.read<LabProvider>().loadSamples(
                        estadoAnalisis: widget.estadoAnalisis,
                        tipoAnalisisCodigo: widget.tipoAnalisisCodigo,
                      ),
                      child: ListView.separated(
                        itemCount: samples.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final muestra = samples[index];
                          final tipoColor = _getTipoColor(muestra.tipoAnalisisCodigo);
                          final tipoIcon = _getTipoIcon(muestra.tipoAnalisisCodigo);

                          return _buildSampleTile(context, muestra, tipoColor, tipoIcon);
                        },
                      ),
                    ),
    );
  }

  Widget _buildSampleTile(
    BuildContext context,
    LabSample muestra,
    Color tipoColor,
    IconData tipoIcon,
  ) {
    final isAnalyzed = muestra.isAnalizado;

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
                  color: isAnalyzed ? Colors.green.withValues(alpha: 0.15) : Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isAnalyzed ? 'ANALIZADA' : 'PENDIENTE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isAnalyzed ? Colors.green : Colors.orange,
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
          if (isAnalyzed) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  size: 14,
                  color: muestra.resultadoColor,
                ),
                const SizedBox(width: 4),
                Text(
                  muestra.resultadoTexto ?? '—',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: muestra.resultadoColor,
                  ),
                ),
                if (muestra.fechaAnalisis != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    'Analizada: ${muestra.fechaAnalisis}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
      trailing: isAnalyzed
          ? Icon(Icons.check_circle, color: Colors.green, size: 28)
          : FilledButton.icon(
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
      onTap: isAnalyzed ? null : () => _navigateToAnalysis(context, muestra),
    );
  }

  void _navigateToAnalysis(BuildContext context, LabSample muestra) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LabAnalysisEntryScreen(sample: muestra),
      ),
    ).then((_) {
      // Refresh on return
      context.read<LabProvider>().loadSamples(
        estadoAnalisis: widget.estadoAnalisis,
        tipoAnalisisCodigo: widget.tipoAnalisisCodigo,
      );
    });
  }
}