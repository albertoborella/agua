import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/models/models.dart';
import '../../../shared/models/sample.dart';
import '../../../shared/services/api_service.dart';
import '../../auth/providers/auth_provider.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  List<Alert> _alerts = [];
  List<Map<String, dynamic>> _sources = [];
  List<AnalysisType> _analysisTypes = [];
  String? _error;
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _busyAlertId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  ApiService get _api => context.read<AuthProvider>().api;

  List<Alert> _vencidas() =>
      _alerts.where((a) => a.isVencida).toList(growable: false);

  List<Alert> _pendientes() =>
      _alerts.where((a) => a.isPendiente).toList(growable: false);

  List<Alert> _programadas() =>
      _alerts.where((a) => a.isProgramada).toList(growable: false);

  // ── Data ────────────────────────────────────────────────────────────

  Future<void> _load() async {
    final api = _api;
    try {
      final results = await Future.wait([
        api.getPendingAlerts(),
        api.getSampleSources(),
        api.getAnalysisTypes(),
      ]);
      if (!mounted) return;
      setState(() {
        _alerts = results[0] as List<Alert>;
        _sources = results[1] as List<Map<String, dynamic>>;
        _analysisTypes = results[2] as List<AnalysisType>;
        _isLoading = false;
        _isRefreshing = false;
        _error = null;
      });
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _isRefreshing = true;
      _error = null;
    });
    await _load();
  }

  /// Tapping an alert marks it read; it is no longer pending, so it leaves
  /// the local list.
  Future<void> _markRead(Alert alert) async {
    if (_busyAlertId != null) return;
    setState(() {
      _busyAlertId = alert.id;
      _error = null;
    });

    try {
      await _api.markAlertRead(alert.id);
      if (!mounted) return;
      setState(() {
        _alerts = _alerts.where((a) => a.id != alert.id).toList();
        _busyAlertId = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alerta marcada como leída')),
      );
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() {
        _busyAlertId = null;
        _error = e.toString();
      });
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────

  String _sourceName(String id) {
    for (final source in _sources) {
      if (source['id'] == id) return '${source['nombre']}';
    }
    return id;
  }

  String _typeName(String id) {
    for (final type in _analysisTypes) {
      if (type.id == id) return type.nombre;
    }
    return id;
  }

  String _formatDate(String isoDate) {
    final parts = isoDate.split('-');
    if (parts.length != 3) return isoDate;
    return '${parts[2]}/${parts[1]}/${parts[0]}';
  }

  // ── UI ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alertas'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: _isRefreshing
                  ? const Center(child: CircularProgressIndicator())
                  : _buildList(),
            ),
    );
  }

  Widget _buildList() {
    if (_error != null && _alerts.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 32),
          _buildError(),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      );
    }

    if (_alerts.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 32),
          Text(
            'No tenés alertas pendientes',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        if (_error != null) ...[
          _buildError(),
          const SizedBox(height: 16),
        ],
        if (_vencidas().isNotEmpty) ...[
          _buildGroupHeader('Vencidas', Colors.red, _vencidas().length),
          ..._vencidas().map(_buildRow),
        ],
        if (_pendientes().isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildGroupHeader(
              'Pendientes', Colors.orange, _pendientes().length),
          ..._pendientes().map(_buildRow),
        ],
        if (_programadas().isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildGroupHeader(
              'Programadas', Colors.blue, _programadas().length),
          ..._programadas().map(_buildRow),
        ],
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildGroupHeader(String title, Color color, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          const SizedBox(width: 8),
          Text(
            count.toString(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(Alert alert) {
    final color = _stateColor(alert);
    final icon = _stateIcon(alert);
    final isBusy = _busyAlertId == alert.id;

    return Card(
      child: InkWell(
        onTap: _busyAlertId != null ? null : () => _markRead(alert),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _typeName(alert.tipoAnalisisId),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _sourceName(alert.fuenteId),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Fecha esperada: ${_formatDate(alert.fechaEsperada)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (isBusy)
                const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Text(
                  _stateLabel(alert),
                  style: TextStyle(color: color),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _stateColor(Alert alert) {
    if (alert.isVencida) return Colors.red;
    if (alert.isProgramada) return Colors.blue;
    return Colors.orange;
  }

  IconData _stateIcon(Alert alert) {
    if (alert.isVencida) return Icons.warning_amber;
    if (alert.isProgramada) return Icons.event;
    return Icons.pending_actions;
  }

  String _stateLabel(Alert alert) {
    if (alert.isVencida) return 'Vencida';
    if (alert.isProgramada) return 'Programada';
    return 'Pendiente';
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
