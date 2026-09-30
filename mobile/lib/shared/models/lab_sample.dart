import 'package:flutter/material.dart';

/// Lab sample as returned by `GET /lab/samples`
/// Includes analysis status and results.
class LabSample {
  final String id;
  final String tenantId;
  final String fuenteId;
  final String fuenteNombre;
  final String fuenteTipo;
  final String tipoAnalisisId;
  final String tipoAnalisisNombre;
  final String tipoAnalisisCodigo;
  final String operarioId;
  final String operarioUsername;
  final String fecha;
  final String hora;
  final bool sincronizada;
  final String createdAt;
  final String estadoAnalisis; // "PENDIENTE" or "ANALIZADO"
  final String? analizadoPorId;
  final String? fechaAnalisis;
  final double? cloroNivel;
  final String? resultado; // "APTA" or "NO_APTA"
  final String? protocoloNumero;
  final String? descripcion;

  LabSample({
    required this.id,
    required this.tenantId,
    required this.fuenteId,
    required this.fuenteNombre,
    required this.fuenteTipo,
    required this.tipoAnalisisId,
    required this.tipoAnalisisNombre,
    required this.tipoAnalisisCodigo,
    required this.operarioId,
    required this.operarioUsername,
    required this.fecha,
    required this.hora,
    required this.sincronizada,
    required this.createdAt,
    required this.estadoAnalisis,
    this.analizadoPorId,
    this.fechaAnalisis,
    this.cloroNivel,
    this.resultado,
    this.protocoloNumero,
    this.descripcion,
  });

  factory LabSample.fromJson(Map<String, dynamic> json) => LabSample(
        id: json['id'],
        tenantId: json['tenant_id'],
        fuenteId: json['fuente_id'],
        fuenteNombre: json['fuente_nombre'],
        fuenteTipo: json['fuente_tipo'],
        tipoAnalisisId: json['tipo_analisis_id'],
        tipoAnalisisNombre: json['tipo_analisis_nombre'],
        tipoAnalisisCodigo: json['tipo_analisis_codigo'],
        operarioId: json['operario_id'],
        operarioUsername: json['operario_username'],
        fecha: json['fecha'],
        hora: json['hora'],
        sincronizada: json['sincronizada'],
        createdAt: json['created_at'],
        estadoAnalisis: json['estado_analisis'],
        analizadoPorId: json['analizado_por_id'],
        fechaAnalisis: json['fecha_analisis'],
        cloroNivel: json['cloro_nivel'] != null
            ? (json['cloro_nivel'] as num).toDouble()
            : null,
        resultado: json['resultado'],
        protocoloNumero: json['protocolo_numero'],
        descripcion: json['descripcion'],
      );

  bool get isCloro => tipoAnalisisCodigo == 'CLORO';
  bool get isAnalizado => estadoAnalisis == 'ANALIZADO';
  bool get isPendienteAnalisis => estadoAnalisis == 'PENDIENTE';

  /// Returns a human-readable analysis type label
  String get tipoAnalisisLabel {
    switch (tipoAnalisisCodigo) {
      case 'CLORO':
        return 'Cloro';
      case 'FQ':
        return 'Físico-Químico';
      case 'MB':
        return 'Microbiológico';
      case 'OTRO':
        return 'Otro';
      default:
        return tipoAnalisisNombre;
    }
  }

  /// Returns the result display text
  String? get resultadoTexto {
    if (!isAnalizado) return null;
    if (isCloro) {
      return cloroNivel != null ? '${cloroNivel!.toStringAsFixed(2)} mg/L' : '—';
    }
    if (resultado != null) {
      return '$resultado${protocoloNumero != null ? ' (Protocolo: $protocoloNumero)' : ''}';
    }
    return '—';
  }

  /// Returns the result color
  Color get resultadoColor {
    if (!isAnalizado) return Colors.grey;
    if (isCloro) return Colors.blue;
    if (resultado == 'APTA') return Colors.green;
    if (resultado == 'NO_APTA') return Colors.red;
    return Colors.grey;
  }
}

/// Lab sample counts for dashboard
class LabSampleCounts {
  final int pendientesAnalisis;
  final int analizadas;
  final int total;

  LabSampleCounts({
    required this.pendientesAnalisis,
    required this.analizadas,
    required this.total,
  });

  factory LabSampleCounts.fromJson(Map<String, dynamic> json) => LabSampleCounts(
        pendientesAnalisis: json['pendientes_analisis'] as int,
        analizadas: json['analizadas'] as int,
        total: json['total'] as int,
      );
}

/// Request to submit chlorine analysis
class CloroAnalysisRequest {
  final double cloroNivel;

  CloroAnalysisRequest({required this.cloroNivel});

  Map<String, dynamic> toJson() => {'cloro_nivel': cloroNivel};
}

/// Request to submit general (MB/FQ/OTRO) analysis
class GeneralAnalysisRequest {
  final String resultado; // "APTA" or "NO_APTA"
  final String protocoloNumero;
  final String? descripcion;

  GeneralAnalysisRequest({
    required this.resultado,
    required this.protocoloNumero,
    this.descripcion,
  });

  Map<String, dynamic> toJson() => {
        'resultado': resultado,
        'protocolo_numero': protocoloNumero,
        if (descripcion != null) 'descripcion': descripcion,
      };
}