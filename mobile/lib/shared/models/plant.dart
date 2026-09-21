class Plant {
  final String id;
  final String tenantId;
  final String nombre;
  final String? direccion;
  final bool activa;
  final String createdAt;

  Plant({
    required this.id,
    required this.tenantId,
    required this.nombre,
    this.direccion,
    required this.activa,
    required this.createdAt,
  });

  factory Plant.fromJson(Map<String, dynamic> json) => Plant(
        id: json['id'],
        tenantId: json['tenant_id'],
        nombre: json['nombre'],
        direccion: json['direccion'],
        activa: json['activa'],
        createdAt: json['created_at'],
      );
}
