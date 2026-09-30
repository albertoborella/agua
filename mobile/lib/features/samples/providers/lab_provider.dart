import 'package:flutter/material.dart';
import '../../../shared/models/lab_sample.dart';
import '../../../shared/services/api_service.dart';

/// Shared provider for lab samples state.
/// Notifies listeners when analysis is submitted so UI can refresh automatically.
class LabProvider extends ChangeNotifier {
  final ApiService _api;

  // Counts
  LabSampleCounts? _counts;
  LabSampleCounts? get counts => _counts;

  // Lists
  List<LabSample> _samples = [];
  List<LabSample> get samples => _samples;

  bool _isLoadingCounts = false;
  bool _isLoadingSamples = false;
  bool _isSubmitting = false;

  bool get isLoadingCounts => _isLoadingCounts;
  bool get isLoadingSamples => _isLoadingSamples;
  bool get isSubmitting => _isSubmitting;

  String? _error;
  String? get error => _error;

  LabProvider({required ApiService api}) : _api = api;

  Future<void> loadCounts() async {
    _isLoadingCounts = true;
    _error = null;
    notifyListeners();

    try {
      _counts = await _api.getLabCounts();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoadingCounts = false;
      notifyListeners();
    }
  }

  Future<void> loadSamples({
    String? estadoAnalisis,
    String? tipoAnalisisCodigo,
  }) async {
    _isLoadingSamples = true;
    _error = null;
    notifyListeners();

    try {
      _samples = await _api.getLabSamples(
        estadoAnalisis: estadoAnalisis,
        tipoAnalisisCodigo: tipoAnalisisCodigo,
      );
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoadingSamples = false;
      notifyListeners();
    }
  }

  /// Call after submitting analysis to refresh all data
  Future<void> onAnalysisSubmitted() async {
    await Future.wait([
      loadCounts(),
      loadSamples(),
    ]);
  }

  /// Submit chlorine analysis
  Future<LabSample> submitCloroAnalysis(String sampleId, double cloroNivel) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _api.submitCloroAnalysis(sampleId, cloroNivel);
      return result;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      rethrow;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Submit general analysis (MB/FQ/OTRO)
  Future<LabSample> submitGeneralAnalysis({
    required String sampleId,
    required String resultado,
    required String protocoloNumero,
    String? descripcion,
  }) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _api.submitGeneralAnalysis(
        sampleId,
        resultado: resultado,
        protocoloNumero: protocoloNumero,
        descripcion: descripcion,
      );
      return result;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      rethrow;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}