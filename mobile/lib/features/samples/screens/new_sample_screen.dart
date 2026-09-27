import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/models/models.dart';
import '../../../shared/services/api_service.dart';
import '../../auth/providers/auth_provider.dart';

class NewSampleScreen extends StatefulWidget {
  const NewSampleScreen({super.key});

  @override
  State<NewSampleScreen> createState() => _NewSampleScreenState();
}

class _NewSampleScreenState extends State<NewSampleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _random = Random();

  List<AnalysisType> _analysisTypes = [];
  List<Map<String, dynamic>> _sources = [];
  String? _selectedTypeId;
  String? _selectedSourceId;
  String? _error;
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  ApiService get _api => context.read<AuthProvider>().api;

  AnalysisType? get _selectedType =>
      _findById(_analysisTypes, _selectedTypeId, (AnalysisType t) => t.id);

  bool get _isCloro => _selectedType?.isCloro ?? false;

  /// Confirm stays disabled when there is nothing to confirm: still loading,
  /// a failed catalog load, an empty analysis-type catalog, or no active
  /// sources.
  bool get _canConfirm =>
      !_isLoading &&
      !_isSubmitting &&
      _error == null &&
      _analysisTypes.isNotEmpty &&
      _sources.isNotEmpty;

  // ── Catalog ──────────────────────────────────────────────────────────

  Future<void> _loadCatalog() async {
    final api = _api;
    try {
      final results = await Future.wait([
        api.getAnalysisTypes(),
        api.getSampleSources(),
      ]);
      if (!mounted) return;
      setState(() {
        _analysisTypes = results[0] as List<AnalysisType>;
        _sources = results[1] as List<Map<String, dynamic>>;
        _isLoading = false;
        _error = null;
      });
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  // ── Selection ───────────────────────────────────────────────────────

  void _onTypeChanged(String? typeId) {
    final type = _findById(_analysisTypes, typeId, (AnalysisType t) => t.id);
    setState(() {
      _selectedTypeId = typeId;
      _error = null;
      // Chlorine gets a random suggestion every time it is picked; every
      // other type starts with no source so the operario chooses one.
      _selectedSourceId =
          (type != null && type.isCloro) ? _pickRandomSourceId() : null;
    });
    // If OTRO is selected, prompt to create a custom analysis type.
    if (typeId != null) {
      final selectedType = _findById(_analysisTypes, typeId,
          (AnalysisType t) => t.id);
      if (selectedType?.codigo == 'OTRO') {
        _promptCustomAnalysisType();
      }
    }
  }

  Future<void> _promptCustomAnalysisType() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Crear análisis personalizado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'El análisis "Otro" requiere una descripción. '
              'Ingresá el nombre del nuevo tipo de análisis:',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Nombre del análisis',
                hintText: 'ej: Análisis de pH, Metales pesados, etc.',
                prefixIcon: Icon(Icons.science_outlined),
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.words,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Crear'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (result != null && result.isNotEmpty) {
      await _createCustomAnalysisType(result);
    }
  }

  Future<void> _createCustomAnalysisType(String nombre) async {
    try {
      // Auto-generate code from name: uppercase, first 10 chars, only alnum
      final codigo = nombre
          .toUpperCase()
          .replaceAll(RegExp(r'[^A-Z0-9]'), '')
          .substring(0, min(10, nombre.length));
      final newType =
          await _api.createAnalysisType(codigo, nombre, requiereDescripcion: true);
      setState(() {
        _analysisTypes.add(newType);
        _selectedTypeId = newType.id;
      });
      // Chlorine rule: if the new type has codigo CLORO, trigger random source
      if (newType.isCloro) {
        setState(() {
          _selectedSourceId = _pickRandomSourceId();
        });
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Análisis "$nombre" creado')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al crear análisis: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _onSourceChanged(String? sourceId) {
    setState(() {
      _selectedSourceId = sourceId;
      _error = null;
    });
  }

  String? _pickRandomSourceId() {
    if (_sources.isEmpty) return null;
    return _sources[_random.nextInt(_sources.length)]['id'] as String?;
  }

  /// Lets the operario override the chlorine suggestion.
  Future<void> _changeSource() async {
    final picked = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Cambiar fuente'),
        children: _sources
            .map(
              (source) => SimpleDialogOption(
                onPressed: () => Navigator.pop(context, source['id'] as String?),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(_sourceIcon(source)),
                  title: Text('${source['nombre']}'),
                  subtitle: Text('${source['tipo']}'),
                ),
              ),
            )
            .toList(),
      ),
    );
    if (!mounted) return;
    if (picked == null) return;
    setState(() {
      _selectedSourceId = picked;
      _error = null;
    });
  }

  // ── Submit ──────────────────────────────────────────────────────────

  Future<void> _confirm() async {
    if (!_formKey.currentState!.validate()) return;

    final type = _selectedType;
    final fuenteId = _selectedSourceId;
    if (type == null || fuenteId == null) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      await _api.createSample(fuenteId, type.id);
      if (!mounted) return;
      setState(() => _isSubmitting = false);

      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: Colors.green, size: 40),
          title: const Text('Muestra registrada'),
          content: Text(
            '${type.nombre}\n${_sourceName(fuenteId)}',
            textAlign: TextAlign.center,
          ),
          actions: [
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.home),
              label: const Text('Volver al inicio'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      Navigator.pop(context);
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _error = e.toString();
      });
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────

  T? _findById<T>(List<T> items, String? id, String Function(T item) idOf) {
    if (id == null) return null;
    for (final item in items) {
      if (idOf(item) == id) return item;
    }
    return null;
  }

  String _sourceName(String id) {
    for (final source in _sources) {
      if (source['id'] == id) return '${source['nombre']}';
    }
    return id;
  }

  IconData _sourceIcon(Map<String, dynamic> source) =>
      source['tipo'] == 'GRIFO' ? Icons.water_drop : Icons.water;

  // ── UI ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Muestra'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_error != null) ...[
                      _buildError(),
                      const SizedBox(height: 24),
                    ],

                    if (_analysisTypes.isEmpty)
                      _buildEmptyState(
                        icon: Icons.science_outlined,
                        message: 'No hay tipos de análisis configurados',
                      )
                    else if (_sources.isEmpty)
                      _buildEmptyState(
                        icon: Icons.water_drop_outlined,
                        message: 'No hay fuentes de agua activas',
                      )
                    else ...[
                      // Section: analysis type
                      Text(
                        'Tipo de análisis',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Elegí el análisis que vas a tomar en esta muestra.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        // Keyed by the current value so every pick builds a
                        // fresh FormField: a DropdownButtonFormField pushes a
                        // changed `initialValue` back through `onChanged`,
                        // which would re-run the chlorine random pick.
                        //
                        // The 'analysis-type' prefix is required, not decoration.
                        // Both dropdowns are siblings in the same Column and both
                        // start as null, so a bare ValueKey(_selectedTypeId) and
                        // ValueKey(_selectedSourceId) would still collide on the
                        // first render and trip Flutter's "Duplicate keys found"
                        // assert. Namespacing makes the two keys distinct even
                        // when the values are equal or both null.
                        key: ValueKey('analysis-type-${_selectedTypeId ?? ''}'),
                        initialValue: _selectedTypeId,
                        decoration: const InputDecoration(
                          labelText: 'Tipo de análisis',
                          prefixIcon: Icon(Icons.science),
                        ),
                        isExpanded: true,
                        items: _analysisTypes
                            .map(
                              (type) => DropdownMenuItem<String>(
                                value: type.id,
                                child: Text(type.nombre),
                              ),
                            )
                            .toList(),
                        onChanged: _isSubmitting ? null : _onTypeChanged,
                        validator: (value) => value == null
                            ? 'Elegí el tipo de análisis'
                            : null,
                      ),
                      const SizedBox(height: 24),

                      // Section: water source
                      Text(
                        'Fuente de agua',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isCloro
                            ? 'Cloro: el sistema sugiere una fuente al azar. '
                                'Podés cambiarla si conocés la correcta.'
                            : 'Elegí la fuente de la que tomás la muestra.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      const SizedBox(height: 16),
                      if (_isCloro)
                        _buildSuggestedSource()
                      else
                        DropdownButtonFormField<String>(
                          // Same reason as the type dropdown above, and
                          // namespaced for the same duplicate-key reason.
                          key: ValueKey('water-source-${_selectedSourceId ?? ''}'),
                          initialValue: _selectedSourceId,
                          decoration: const InputDecoration(
                            labelText: 'Fuente de agua',
                            prefixIcon: Icon(Icons.water_drop),
                          ),
                          isExpanded: true,
                          items: _sources
                              .map(
                                (source) => DropdownMenuItem<String>(
                                  value: source['id'] as String?,
                                  child: Text(
                                    '${source['nombre']} (${source['tipo']})',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: _isSubmitting ? null : _onSourceChanged,
                          validator: (value) => value == null
                              ? 'Elegí la fuente de agua'
                              : null,
                        ),
                      const SizedBox(height: 24),
                    ],

                    // Confirm
                    ElevatedButton.icon(
                      onPressed: _canConfirm ? _confirm : null,
                      icon: const Icon(Icons.check),
                      label: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Confirmar Toma'),
                    ),
                    const SizedBox(height: 12),

                    // Cancel
                    OutlinedButton.icon(
                      onPressed:
                          _isSubmitting ? null : () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      label: const Text('Cancelar'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSuggestedSource() {
    final sourceId = _selectedSourceId;
    final source = _findById(_sources, sourceId, (Map<String, dynamic> s) => '${s['id']}');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(_sourceIcon(source ?? {}), size: 32, color: Colors.blue),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    source == null
                        ? 'Sin fuente sugerida'
                        : '${source['nombre']} (${source['tipo']})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _isSubmitting ? null : _changeSource,
          icon: const Icon(Icons.swap_horiz),
          label: const Text('Cambiar fuente'),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isSubmitting ? null : _loadCatalog,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 32, color: Colors.grey),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
