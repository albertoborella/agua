/// Water source as returned by `GET /admin/sources`
/// (`WaterSourceResponse`: id, planta_id, tipo, nombre, ubicacion, activa,
/// created_at).
///
/// The model has no `tenant_id` on purpose: tenant scoping runs through
/// `planta_id` -> `plants.tenant_id`, so the API never sends it. An earlier
/// version required `tenant_id` and crashed on every response.
class WaterSource {
  final String id;
  final String plantaId;
  final String tipo;
  final String nombre;
  final String? ubicacion;
  final bool activa;
  final String createdAt;

  WaterSource({
    required this.id,
    required this.plantaId,
    required this.tipo,
    required this.nombre,
    this.ubicacion,
    required this.activa,
    required this.createdAt,
  });

  factory WaterSource.fromJson(Map<String, dynamic> json) => WaterSource(
        id: json['id'],
        plantaId: json['planta_id'],
        tipo: json['tipo'],
        nombre: json['nombre'],
        ubicacion: json['ubicacion'],
        activa: json['activa'],
        createdAt: json['created_at'],
      );

  bool get isGrifo => tipo == 'GRIFO';
  bool get isPozo => tipo == 'POZO';
}

/// Analysis type as returned by `GET /catalog/analysis-types`
/// (`AnalysisTypeResponse`: id, codigo, nombre, requiere_descripcion).
///
/// `codigo` is what identifies a chlorine analysis — the model has no boolean
/// flag, so the random-source business rule keys off this exact string.
class AnalysisType {
  final String id;
  final String codigo;
  final String nombre;
  final bool requiereDescripcion;

  AnalysisType({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.requiereDescripcion,
  });

  factory AnalysisType.fromJson(Map<String, dynamic> json) => AnalysisType(
        id: json['id'],
        codigo: json['codigo'],
        nombre: json['nombre'],
        requiereDescripcion: json['requiere_descripcion'] ?? false,
      );

  static const String cloroCodigo = 'CLORO';

  bool get isCloro => codigo == cloroCodigo;
}

/// Sampling frequency as returned by `GET /admin/frequencies`
/// (`SamplingFrequencyResponse`: id, fuente_id, tipo_analisis_id, frecuencia,
/// dias_semana, hora_esperada, activa, created_at).
class SamplingFrequency {
  final String id;
  final String fuenteId;
  final String tipoAnalisisId;
  final String frecuencia;
  final String? diasSemana;
  final String? horaEsperada;
  final bool activa;
  final String createdAt;

  SamplingFrequency({
    required this.id,
    required this.fuenteId,
    required this.tipoAnalisisId,
    required this.frecuencia,
    this.diasSemana,
    this.horaEsperada,
    required this.activa,
    required this.createdAt,
  });

  factory SamplingFrequency.fromJson(Map<String, dynamic> json) =>
      SamplingFrequency(
        id: json['id'],
        fuenteId: json['fuente_id'],
        tipoAnalisisId: json['tipo_analisis_id'],
        frecuencia: json['frecuencia'],
        diasSemana: json['dias_semana'],
        horaEsperada: json['hora_esperada'],
        activa: json['activa'],
        createdAt: json['created_at'],
      );
}

/// A scheduled sample that is pending or overdue.
/// Returned by `GET /samples/pending` and `GET /samples/overdue`.
class ScheduledSample {
  final String frecuenciaId;
  final String fuenteId;
  final String fuenteNombre;
  final String fuenteTipo;
  final String tipoAnalisisId;
  final String tipoAnalisisNombre;
  final String tipoAnalisisCodigo;
  final DateTime fechaProgramada;
  final int diasDesdeProgramada; // negative = days until due, positive = days overdue
  final String estado; // "PENDIENTE" or "VENCIDA"

  ScheduledSample({
    required this.frecuenciaId,
    required this.fuenteId,
    required this.fuenteNombre,
    required this.fuenteTipo,
    required this.tipoAnalisisId,
    required this.tipoAnalisisNombre,
    required this.tipoAnalisisCodigo,
    required this.fechaProgramada,
    required this.diasDesdeProgramada,
    required this.estado,
  });

  factory ScheduledSample.fromJson(Map<String, dynamic> json) => ScheduledSample(
        frecuenciaId: json['frecuencia_id'],
        fuenteId: json['fuente_id'],
        fuenteNombre: json['fuente_nombre'],
        fuenteTipo: json['fuente_tipo'],
        tipoAnalisisId: json['tipo_analisis_id'],
        tipoAnalisisNombre: json['tipo_analisis_nombre'],
        tipoAnalisisCodigo: json['tipo_analisis_codigo'],
        fechaProgramada: DateTime.parse(json['fecha_programada']),
        diasDesdeProgramada: json['dias_desde_programada'] as int,
        estado: json['estado'],
      );

  bool get isPendiente => estado == 'PENDIENTE';
  bool get isVencida => estado == 'VENCIDA';
  bool get isCloro => tipoAnalisisCodigo == 'CLORO';

  /// Returns a human-readable string for the due status
  String get estadoTexto {
    if (diasDesdeProgramada < 0) {
      return 'En ${-diasDesdeProgramada} día${-diasDesdeProgramada != 1 ? 's' : ''}';
    } else if (diasDesdeProgramada == 0) {
      return 'Hoy';
    } else {
      return 'Hace $diasDesdeProgramada día${diasDesdeProgramada != 1 ? 's' : ''}';
    }
  }
}
