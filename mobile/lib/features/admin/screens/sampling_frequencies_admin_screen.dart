import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/models/models.dart';
import '../../auth/providers/auth_provider.dart';

class SamplingFrequenciesAdminScreen extends StatefulWidget {
  const SamplingFrequenciesAdminScreen({super.key});

  @override
  State<SamplingFrequenciesAdminScreen> createState() => _SamplingFrequenciesAdminScreenState();
}

class _SamplingFrequenciesAdminScreenState extends State<SamplingFrequenciesAdminScreen> {
  List<SamplingFrequency> _frequencies = [];
  List<AnalysisType> _analysisTypes = [];
  List<WaterSource> _sources = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final api = context.read<AuthProvider>().api;
      final results = await Future.wait([
        api.getFrequencies(),
        api.getAnalysisTypes(),
        api.getSources(),
      ]);
      if (!mounted) return;
      setState(() {
        _frequencies = results[0] as List<SamplingFrequency>;
        _analysisTypes = results[1] as List<AnalysisType>;
        _sources = results[2] as List<WaterSource>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _createOrEdit({SamplingFrequency? existing}) async {
    if (_sources.isEmpty || _analysisTypes.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Se requieren fuentes y tipos de análisis. Créelos primero.'),
        ),
      );
      return;
    }

    final String fuenteId = existing?.fuenteId ?? _sources.first.id;
    final String tipoAnalisisId = existing?.tipoAnalisisId ?? _analysisTypes.first.id;

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        String dialogFuenteId = fuenteId;
        String dialogTipoAnalisisId = tipoAnalisisId;
        final dialogFrecuenciaController = TextEditingController(text: existing?.frecuencia ?? '');
        final dialogDiasSemanaController = TextEditingController(text: existing?.diasSemana ?? '');
        final dialogHoraEsperadaController = TextEditingController(text: existing?.horaEsperada ?? '');

        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text(existing == null ? 'Nueva frecuencia de muestreo' : 'Editar frecuencia'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: dialogFuenteId,
                    decoration: const InputDecoration(
                      labelText: 'Fuente de agua',
                      prefixIcon: Icon(Icons.water_drop_outlined),
                    ),
                    items: _sources
                        .map((s) => DropdownMenuItem<String>(
                              value: s.id,
                              child: Text('${s.nombre} (${s.tipo})'),
                            ))
                        .toList(),
                    onChanged: (v) => setDialogState(() => dialogFuenteId = v!),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: dialogTipoAnalisisId,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de análisis',
                      prefixIcon: Icon(Icons.science_outlined),
                    ),
                    items: _analysisTypes
                        .map((t) => DropdownMenuItem<String>(
                              value: t.id,
                              child: Text(t.nombre),
                            ))
                        .toList(),
                    onChanged: (v) => setDialogState(() => dialogTipoAnalisisId = v!),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: dialogFrecuenciaController,
                    decoration: const InputDecoration(
                      labelText: 'Frecuencia *',
                      hintText: 'ej: daily, weekly, monthly, semiannual, annual, 7d, 30d',
                      prefixIcon: Icon(Icons.repeat),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: dialogDiasSemanaController,
                    decoration: const InputDecoration(
                      labelText: 'Días de la semana (opcional)',
                      hintText: 'ej: mon,wed,fri o 1,3,5',
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: dialogHoraEsperadaController,
                    decoration: const InputDecoration(
                      labelText: 'Hora esperada (opcional)',
                      hintText: 'HH:MM (24h)',
                      prefixIcon: Icon(Icons.access_time),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () {
                  if (dialogFrecuenciaController.text.trim().isEmpty) return;
                  Navigator.pop(context, {
                    'fuente_id': dialogFuenteId,
                    'tipo_analisis_id': dialogTipoAnalisisId,
                    'frecuencia': dialogFrecuenciaController.text.trim(),
                    'dias_semana': dialogDiasSemanaController.text.trim(),
                    'hora_esperada': dialogHoraEsperadaController.text.trim(),
                  });
                },
                child: Text(existing == null ? 'Crear' : 'Guardar'),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted) return;
    if (result != null) {
      await _saveFrequency(
        fuenteId: result['fuente_id']!,
        tipoAnalisisId: result['tipo_analisis_id']!,
        frecuencia: result['frecuencia']!,
        diasSemana: result['dias_semana']!.isEmpty ? null : result['dias_semana'],
        horaEsperada: result['hora_esperada']!.isEmpty ? null : result['hora_esperada'],
        existing: existing,
      );
    }
  }

  Future<void> _saveFrequency({
    required String fuenteId,
    required String tipoAnalisisId,
    required String frecuencia,
    String? diasSemana,
    String? horaEsperada,
    SamplingFrequency? existing,
  }) async {
    try {
      final api = context.read<AuthProvider>().api;

      if (existing == null) {
        await api.createFrequency(
          fuenteId: fuenteId,
          tipoAnalisisId: tipoAnalisisId,
          frecuencia: frecuencia,
          diasSemana: diasSemana,
          horaEsperada: horaEsperada,
        );
      } else {
        await api.updateFrequency(
          existing.id,
          frecuencia: frecuencia,
          diasSemana: diasSemana,
          horaEsperada: horaEsperada,
        );
      }
      if (!mounted) return;
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(existing == null
              ? 'Frecuencia creada'
              : 'Frecuencia actualizada'),
        ),
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

  Future<void> _delete(SamplingFrequency freq) async {
    final sourceName = _sources.firstWhere(
      (s) => s.id == freq.fuenteId,
      orElse: () => WaterSource(
        id: '',
        plantaId: '',
        tipo: '',
        nombre: 'Desconocida',
        activa: false,
        createdAt: '',
      ),
    ).nombre;

    final tipoName = _analysisTypes.firstWhere(
      (t) => t.id == freq.tipoAnalisisId,
      orElse: () => AnalysisType(
        id: '',
        codigo: '',
        nombre: 'Desconocido',
        requiereDescripcion: false,
      ),
    ).nombre;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar frecuencia de muestreo'),
        content: Text('¿Eliminar "$tipoName en $sourceName"? No se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      final api = context.read<AuthProvider>().api;
      await api.deleteFrequency(freq.id);
      if (!mounted) return;
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Frecuencia eliminada')),
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

  String _formatFrequency(String freq) {
    final lower = freq.toLowerCase();
    switch (lower) {
      case 'daily':
        return 'Diaria';
      case 'weekly':
        return 'Semanal';
      case 'monthly':
        return 'Mensual';
      case 'semiannual':
        return 'Semestral';
      case 'annual':
        return 'Anual';
      default:
        return freq;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Frecuencias de Muestreo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _createOrEdit(),
            tooltip: 'Nueva frecuencia',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
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
                      Text(_error!),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _load,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _frequencies.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.repeat_outlined,
                              size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text('No hay frecuencias de muestreo'),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Crear la primera'),
                            onPressed: () => _createOrEdit(),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: _frequencies.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final freq = _frequencies[index];
                        final source = _sources.firstWhere(
                          (s) => s.id == freq.fuenteId,
                          orElse: () => WaterSource(
                            id: '',
                            plantaId: '',
                            tipo: '',
                            nombre: 'Fuente eliminada',
                            activa: false,
                            createdAt: '',
                          ),
                        );
                        final tipo = _analysisTypes.firstWhere(
                          (t) => t.id == freq.tipoAnalisisId,
                          orElse: () => AnalysisType(
                            id: '',
                            codigo: '',
                            nombre: 'Tipo eliminado',
                            requiereDescripcion: false,
                          ),
                        );
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: freq.activa
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Theme.of(context).colorScheme.surfaceContainerHighest,
                            child: Icon(
                              Icons.repeat,
                              color: freq.activa
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          title: Text('${tipo.nombre} · ${source.nombre}'),
                          subtitle: Text(
                            '${_formatFrequency(freq.frecuencia)}${freq.diasSemana != null ? ' · ${freq.diasSemana}' : ''}${freq.horaEsperada != null ? ' · ${freq.horaEsperada}' : ''}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!freq.activa)
                                const Padding(
                                  padding: EdgeInsets.only(right: 8),
                                  child: Icon(Icons.pause_circle_outline, size: 20, color: Colors.grey),
                                ),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _createOrEdit(existing: freq),
                                tooltip: 'Editar',
                              ),
                              IconButton(
                                icon: Icon(Icons.delete,
                                    color: Theme.of(context).colorScheme.error),
                                onPressed: () => _delete(freq),
                                tooltip: 'Eliminar',
                              ),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}