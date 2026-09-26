import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/models/models.dart';
import '../../../shared/models/sample.dart';
import '../../../shared/models/user.dart';
import '../../../shared/services/api_service.dart';
import '../../auth/providers/auth_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _sources = [];
  List<AnalysisType> _analysisTypes = [];
  List<SampleRecord> _samples = [];
  User? _operario;
  String? _selectedSourceId;
  String? _selectedTypeId;
  DateTimeRange? _dateRange;
  String? _error;
  bool _isLoading = true;
  bool _isFiltering = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  ApiService get _api => context.read<AuthProvider>().api;

  bool get _hasFilters =>
      _selectedSourceId != null || _selectedTypeId != null || _dateRange != null;

  // ── Data ────────────────────────────────────────────────────────────

  Future<void> _load() async {
    final api = _api;
    _operario = context.read<AuthProvider>().user;
    try {
      final results = await Future.wait([
        api.getSampleSources(),
        api.getAnalysisTypes(),
        api.getHistory(
          fuenteId: _selectedSourceId,
          tipoAnalisisId: _selectedTypeId,
          fechaDesde: _dateRange == null ? null : _toApiDate(_dateRange!.start),
          fechaHasta: _dateRange == null ? null : _toApiDate(_dateRange!.end),
        ),
      ]);
      if (!mounted) return;
      setState(() {
        _sources = results[0] as List<Map<String, dynamic>>;
        _analysisTypes = results[1] as List<AnalysisType>;
        _samples = results[2] as List<SampleRecord>;
        _isLoading = false;
        _isFiltering = false;
        _error = null;
      });
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isFiltering = false;
        _error = e.toString();
      });
    }
  }

  /// Re-runs the query after a filter change, keeping the filters on screen.
  Future<void> _reload() async {
    setState(() {
      _isFiltering = true;
      _error = null;
    });
    await _load();
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      initialDateRange: _dateRange,
      helpText: 'Elegí el rango de fechas',
    );
    if (!mounted) return;
    if (picked == null) return;
    setState(() => _dateRange = picked);
    await _reload();
  }

  Future<void> _clearFilters() async {
    setState(() {
      _selectedSourceId = null;
      _selectedTypeId = null;
      _dateRange = null;
    });
    await _reload();
  }

  // ── Helpers ─────────────────────────────────────────────────────────

  String _sourceName(String id) {
    for (final source in _sources) {
      if (source['id'] == id) return '${source['nombre']}';
    }
    return id;
  }

  String _sourceType(String id) {
    for (final source in _sources) {
      if (source['id'] == id) return '${source['tipo']}';
    }
    return '';
  }

  String _typeName(String id) {
    for (final type in _analysisTypes) {
      if (type.id == id) return type.nombre;
    }
    return id;
  }

  /// The history endpoint only returns `operario_id`. Resolving usernames for
  /// other operarios would need `GET /admin/users`, which is ADMIN-only, so
  /// the signed-in operario is named and everyone else falls back to an id.
  String _operarioName(String id) {
    if (_operario != null && _operario!.id == id) return _operario!.username;
    final short = id.length > 8 ? id.substring(0, 8) : id;
    return 'Operario $short';
  }

  String _formatDate(String isoDate) {
    final parts = isoDate.split('-');
    if (parts.length != 3) return isoDate;
    return '${parts[2]}/${parts[1]}/${parts[0]}';
  }

  String _formatTime(String isoTime) =>
      isoTime.length > 5 ? isoTime.substring(0, 5) : isoTime;

  String _toApiDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  // ── UI ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildFilters(),
                const Divider(height: 1),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _reload,
                    child: _isFiltering
                        ? const Center(child: CircularProgressIndicator())
                        : _buildResults(),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilters() {
    final dateLabel = _dateRange == null
        ? 'Sin rango de fechas'
        : '${_formatDate(_toApiDate(_dateRange!.start))} - '
            '${_formatDate(_toApiDate(_dateRange!.end))}';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Filtros',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Dejá los filtros vacíos para ver todas las muestras.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            // Keyed by the current value: a DropdownButtonFormField pushes a
            // changed `initialValue` back through `onChanged`, which would
            // double-fire the reload.
            key: ValueKey(_selectedSourceId),
            initialValue: _selectedSourceId,
            decoration: const InputDecoration(
              labelText: 'Fuente',
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
            onChanged: (value) {
              setState(() => _selectedSourceId = value);
              _reload();
            },
          ),
          const SizedBox(height: 24),

          DropdownButtonFormField<String>(
            key: ValueKey(_selectedTypeId),
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
                    child: Text(type.nombre, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() => _selectedTypeId = value);
              _reload();
            },
          ),
          const SizedBox(height: 24),

          OutlinedButton.icon(
            onPressed: _isFiltering ? null : _pickDateRange,
            icon: const Icon(Icons.date_range),
            label: Text(dateLabel),
          ),
          const SizedBox(height: 12),

          OutlinedButton.icon(
            onPressed: !_hasFilters || _isFiltering ? null : _clearFilters,
            icon: const Icon(Icons.filter_alt_off),
            label: const Text('Limpiar filtros'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          _buildError(),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      );
    }

    if (_samples.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 32),
          Text(
            'No hay muestras para los filtros seleccionados',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _samples.length,
      itemBuilder: (context, index) => _buildRow(_samples[index]),
    );
  }

  Widget _buildRow(SampleRecord sample) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_formatDate(sample.fecha)} ${_formatTime(sample.hora)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_sourceName(sample.fuenteId)} (${_sourceType(sample.fuenteId)})',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              _typeName(sample.tipoAnalisisId),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _operarioName(sample.operarioId),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ),
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
        ],
      ),
    );
  }
}
