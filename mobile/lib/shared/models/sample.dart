class SampleRecord {
  final String id;
  final String tenantId;
  final String fuenteId;
  final String tipoAnalisisId;
  final String operarioId;
  final String fecha;
  final String hora;
  final bool sincronizada;
  final String createdAt;

  SampleRecord({
    required this.id,
    required this.tenantId,
    required this.fuenteId,
    required this.tipoAnalisisId,
    required this.operarioId,
    required this.fecha,
    required this.hora,
    required this.sincronizada,
    required this.createdAt,
  });

  factory SampleRecord.fromJson(Map<String, dynamic> json) => SampleRecord(
        id: json['id'],
        tenantId: json['tenant_id'],
        fuenteId: json['fuente_id'],
        tipoAnalisisId: json['tipo_analisis_id'],
        operarioId: json['operario_id'],
        fecha: json['fecha'],
        hora: json['hora'],
        sincronizada: json['sincronizada'],
        createdAt: json['created_at'],
      );
}

class Alert {
  final String id;
  final String tenantId;
  final String usuarioId;
  final String tipo;
  final String fuenteId;
  final String tipoAnalisisId;
  final String fechaEsperada;
  final bool leida;
  final String createdAt;

  Alert({
    required this.id,
    required this.tenantId,
    required this.usuarioId,
    required this.tipo,
    required this.fuenteId,
    required this.tipoAnalisisId,
    required this.fechaEsperada,
    required this.leida,
    required this.createdAt,
  });

  factory Alert.fromJson(Map<String, dynamic> json) => Alert(
        id: json['id'],
        tenantId: json['tenant_id'],
        usuarioId: json['usuario_id'],
        tipo: json['tipo'],
        fuenteId: json['fuente_id'],
        tipoAnalisisId: json['tipo_analisis_id'],
        fechaEsperada: json['fecha_esperada'],
        leida: json['leida'],
        createdAt: json['created_at'],
      );

  bool get isPendiente => tipo == 'PENDIENTE';
  bool get isVencida => tipo == 'VENCIDA';
  bool get isProgramada => tipo == 'PROGRAMADA';
}
