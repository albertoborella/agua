import 'package:flutter/material.dart';
import '../../../shared/models/models.dart';
import '../../../shared/services/api_service.dart';

/// Shared provider for samples state.
/// Notifies listeners when a sample is taken so UI can refresh automatically.
class SamplesProvider extends ChangeNotifier {
  final ApiService _api;

  // Counts
  Map<String, int> _counts = {'realizadas': 0, 'pendientes': 0, 'vencidas': 0};
  Map<String, int> get counts => _counts;

  // Lists
  List<ScheduledSample> _pendientes = [];
  List<ScheduledSample> get pendientes => _pendientes;

  List<ScheduledSample> _vencidas = [];
  List<ScheduledSample> get vencidas => _vencidas;

  bool _isLoadingCounts = false;
  bool _isLoadingPendientes = false;
  bool _isLoadingVencidas = false;

  bool get isLoadingCounts => _isLoadingCounts;
  bool get isLoadingPendientes => _isLoadingPendientes;
  bool get isLoadingVencidas => _isLoadingVencidas;

  String? _error;
  String? get error => _error;

  SamplesProvider({required ApiService api}) : _api = api;

  Future<void> loadCounts() async {
    _isLoadingCounts = true;
    _error = null;
    notifyListeners();

    try {
      _counts = await _api.getSampleCounts();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoadingCounts = false;
      notifyListeners();
    }
  }

  Future<void> loadPendientes() async {
    _isLoadingPendientes = true;
    _error = null;
    notifyListeners();

    try {
      _pendientes = await _api.getPendingSamples();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoadingPendientes = false;
      notifyListeners();
    }
  }

  Future<void> loadVencidas() async {
    _isLoadingVencidas = true;
    _error = null;
    notifyListeners();

    try {
      _vencidas = await _api.getOverdueSamples();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoadingVencidas = false;
      notifyListeners();
    }
  }

  /// Call after taking a sample to refresh all data
  Future<void> onSampleTaken() async {
    await Future.wait([
      loadCounts(),
      loadPendientes(),
      loadVencidas(),
    ]);
  }
}