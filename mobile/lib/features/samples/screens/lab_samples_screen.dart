import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/models/lab_sample.dart';
import '../../../shared/models/models.dart';
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
  // Filter state for history view
  DateTime? _fechaDesde;
  DateTime? _fechaHasta;
  String? _selectedTipoAnalisisCodigo;
  String? _selectedFuenteId;
  List<WaterSource> _fuentes = [];
  List<AnalysisType> _tiposAnalisis = [];
  bool _isLoadingFilters = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFilterData();
      context.read<LabProvider>().loadSamples(
        estadoAnalisis: widget.estadoAnalisis,
        tipoAnalisisCodigo: widget.tipoAnalisisCodigo,
      );
    });
  }

  Future<void> _loadFilterData() async {
    setState(() => _isLoadingFilters = true);
    try {
      final api = context.read<AuthProvider>().api;
      final fuentes = await api.getSources();
      final tipos = await api.getAnalysisTypes();
      if (mounted) {
        setState(() {
          _fuentes = fuentes;
          _tiposAnalisis = tipos;
          _isLoadingFilters = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingFilters = false);
    }
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
      return 'Historial de Muestras Analizadas';
    }
    return 'Muestras Pendientes de Análisis';
  }

  bool get _isHistoryView => widget.estadoAnalisis == 'ANALIZADO';

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

  Future<void> _applyFilters() async {
    context.read<LabProvider>().loadSamples(
      estadoAnalisis: widget.estadoAnalisis,
      tipoAnalisisCodigo: _selectedTipoAnalisisCodigo,
      fuenteId: _selectedFuenteId,
      fechaDesde: _fechaDesde?.toIso8601String().split('T').first,
      fechaHasta: _fechaHasta?.toIso8601String().split('T').first,
    );
    if (mounted) Navigator.pop(context);
  }

  Future<void> _clearFilters() async {
    setState(() {
      _fechaDesde = null;
      _fechaHasta = null;
      _selectedTipoAnalisisCodigo = null;
      _selectedFuenteId = null;
    });
    await _applyFilters();
  }

  Future<void> _pickDate(BuildContext context, bool isDesde) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isDesde ? (_fechaDesde ?? DateTime.now()) : (_fechaHasta ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() {
        if (isDesde) {
          _fechaDesde = picked;
        } else {
          _fechaHasta = picked;
        }
      });
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
          if (_isHistoryView) ...[
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilterDialog,
              tooltip: 'Filtros',
            ),
            if (_hasActiveFilters())
              IconButton(
                icon: const Icon(Icons.clear_all),
                onPressed: _clearFilters,
                tooltip: 'Limpiar filtros',
              ),
          ],
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _reloadSamples(),
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
                        onPressed: _reloadSamples,
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
                      onRefresh: _reloadSamples,
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

  void _reloadSamples() {
    context.read<LabProvider>().loadSamples(
      estadoAnalisis: widget.estadoAnalisis,
      tipoAnalisisCodigo: _selectedTipoAnalisisCodigo ?? widget.tipoAnalisisCodigo,
      fuenteId: _selectedFuenteId,
      fechaDesde: _fechaDesde?.toIso8601String().split('T').first,
      fechaHasta: _fechaHasta?.toIso8601String().split('T').first,
    );
  }

  bool _hasActiveFilters() {
    return _fechaDesde != null ||
        _fechaHasta != null ||
        _selectedTipoAnalisisCodigo != null ||
        _selectedFuenteId != null;
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Filtros de Historial'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fecha desde
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text(_fechaDesde != null
                      ? 'Desde: ${_fechaDesde!.day}/${_fechaDesde!.month}/${_fechaDesde!.year}'
                      : 'Fecha desde'),
                  onTap: () => _pickDate(context, true).then((_) => setDialogState(() {})),
                ),
                // Fecha hasta
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text(_fechaHasta != null
                      ? 'Hasta: ${_fechaHasta!.day}/${_fechaHasta!.month}/${_fechaHasta!.year}'
                      : 'Fecha hasta'),
                  onTap: () => _pickDate(context, false).then((_) => setDialogState(() {})),
                ),
                const Divider(),
                // Tipo de análisis
                DropdownButtonFormField<String>(
                  value: _selectedTipoAnalisisCodigo,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de análisis',
                    prefixIcon: Icon(Icons.science),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Todos')),
                    ..._tiposAnalisis.map((t) => DropdownMenuItem(
                          value: t.codigo,
                          child: Text('${t.codigo} - ${t.nombre}'),
                        )),
                  ],
                  onChanged: (value) => setDialogState(() => _selectedTipoAnalisisCodigo = value),
                ),
                const SizedBox(height: 16),
                // Fuente
                DropdownButtonFormField<String>(
                  value: _selectedFuenteId,
                  decoration: const InputDecoration(
                    labelText: 'Fuente de agua',
                    prefixIcon: Icon(Icons.water_drop),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Todas')),
                    ..._fuentes.map((f) => DropdownMenuItem(
                          value: f.id,
                          child: Text('${f.nombre} (${f.tipo})'),
                        )),
                  ],
                  onChanged: (value) => setDialogState(() => _selectedFuenteId = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            if (_hasActiveFilters())
              TextButton(
                onPressed: () {
                  _clearFilters();
                  Navigator.pop(context);
                },
                child: const Text('Limpiar'),
              ),
            FilledButton(
              onPressed: _applyFilters,
              child: const Text('Aplicar'),
            ),
          ],
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
      _reloadSamples();
    });
  }
}