import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/models/models.dart';
import '../../../shared/services/api_service.dart';
import '../../auth/providers/auth_provider.dart';

class SamplingFrequenciesAdminScreen extends StatefulWidget {
  const SamplingFrequenciesAdminScreen({super.key});

  @override
  State<SamplingFrequenciesAdminScreen> createState() => _SamplingFrequenciesAdminScreenState();
}

class _SamplingFrequenciesAdminScreenState extends State<SamplingFrequenciesAdminScreen> {
  List<Map<String, dynamic>> _frequencies = [];
  List<AnalysisType> _analysisTypes = [];
  List<Map<String, dynamic>> _sources = [];
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
        _frequencies = List<Map<String, dynamic>>.from(results[0]);
        _analysisTypes = results[1] as List<AnalysisType>;
        _sources = List<Map<String, dynamic>>.from(results[2]);
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

  Future<void> _showFrequencyDialog({Map<String, dynamic>? existing}) async {
    final frecuenciaController = TextEditingController(text: existing?['frecuencia'] ?? '');
    final diasSemanaController = TextEditingController(text: existing?['dias_semana'] ?? '');
    final horaEsperadaController = TextEditingController(text: existing?['hora_esperada'] ?? '');
    String fuenteId = existing?['fuente_id'] ?? (_sources.isNotEmpty ? _sources.first['id'] : '');
    String tipoAnalisisId = existing?['tipo_analisis_id'] ?? (_analysisTypes.isNotEmpty ? _analysisTypes.first.id : '');

    await showDialog<void>(
      context: context,
      builder: (context) {
        String localFuenteId = fuenteId;
        String localTipoAnalisisId = tipoAnalisisId;
        return AlertDialog(
          title: Text(existing == null ? 'Nueva frecuencia de muestreo' : 'Editar frecuencia'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: localFuenteId,
                  decoration: const InputDecoration(
                    labelText: 'Fuente de agua',
                    prefixIcon: Icon(Icons.water_drop_outlined),
                  ),
                  items: _sources
                      .map((s) => DropdownMenuItem(value: s['id'], child: Text('${s['nombre']} (${s['tipo']})')))
                      .toList(),
                  onChanged: (v) => localFuenteId = v!,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: localTipoAnalisisId,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de análisis',
                    prefixIcon: Icon(Icons.science_outlined),
                  ),
                  items: _analysisTypes
                      .map((t) => DropdownMenuItem(value: t.id, child: Text(t.nombre)))
                      .toList(),
                  onChanged: (v) => localTipoAnalisisId = v!,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: TextEditingController(text: existing?['frecuencia'] ?? ''),
                  decoration: const InputDecoration(
                    labelText: 'Frecuencia',
                    hintText: 'ej: daily, weekly, monthly, semiannual, annual, 7d, 30d',
                    prefixIcon: Icon(Icons.repeat),
                  ),
                  onChanged: (v) {},
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: TextEditingController(text: existing?['dias_semana'] ?? ''),
                  decoration: const InputDecoration(
                    labelText: 'Días de la semana (opcional)',
                    hintText: 'ej: mon,wed,fri o 1,3,5',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  onChanged: (v) {},
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: TextEditingController(text: existing?['hora_esperada'] ?? ''),
                  decoration: const InputDecoration(
                    labelText: 'Hora esperada (opcional)',
                    hintText: 'HH:MM (24h)',
                    prefixIcon: Icon(Icons.access_time),
                  ),
                  onChanged: (v) {},
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
                Navigator.pop(context, 'guardar');
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Frecuencias de Muestreo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showFrequencyDialog(),
            tooltip: 'Nueva frecuencia',
          ),
        ],
      ),
      body: Center(child: Text('Pantalla en construcción')),
    );
  }
}