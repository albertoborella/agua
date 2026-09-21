class WaterSource {
  final String id;
  final String tenantId;
  final String? plantaId;
  final String nombre;
  final String tipo;
  final bool activa;
  final String createdAt;

  WaterSource({
    required this.id,
    required this.tenantId,
    this.plantaId,
    required this.nombre,
    required this.tipo,
    required this.activa,
    required this.createdAt,
  });

  factory WaterSource.fromJson(Map<String, dynamic> json) => WaterSource(
        id: json['id'],
        tenantId: json['tenant_id'],
        plantaId: json['planta_id'],
        nombre: json['nombre'],
        tipo: json['tipo'],
        activa: json['activa'],
        createdAt: json['created_at'],
      );
}

class AnalysisType {
  final String id;
  final String nombre;
  final String? descripcion;
  final bool activo;
  final String createdAt;

  AnalysisType({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.activo,
    required this.createdAt,
  });

  factory AnalysisType.fromJson(Map<String, dynamic> json) => AnalysisType(
        id: json['id'],
        nombre: json['nombre'],
        descripcion: json['descripcion'],
        activo: json['activo'],
        createdAt: json['created_at'],
      );
}

class SamplingFrequency {
  final String id;
  final String tenantId;
  final String fuenteId;
  final String tipoAnalisisId;
  final int intervaloHoras;
  final bool activa;
  final String createdAt;

  SamplingFrequency({
    required this.id,
    required this.tenantId,
    required this.fuenteId,
    required this.tipoAnalisisId,
    required this.intervaloHoras,
    required this.activa,
    required this.createdAt,
  });

  factory SamplingFrequency.fromJson(Map<String, dynamic> json) =>
      SamplingFrequency(
        id: json['id'],
        tenantId: json['tenant_id'],
        fuenteId: json['fuente_id'],
        tipoAnalisisId: json['tipo_analisis_id'],
        intervaloHoras: json['intervalo_horas'],
        activa: json['activa'],
        createdAt: json['created_at'],
      );
}
