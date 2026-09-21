class User {
  final String id;
  final String tenantId;
  final String username;
  final String email;
  final String rol;
  final bool activo;
  final String createdAt;

  User({
    required this.id,
    required this.tenantId,
    required this.username,
    required this.email,
    required this.rol,
    required this.activo,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'],
        tenantId: json['tenant_id'],
        username: json['username'],
        email: json['email'],
        rol: json['rol'],
        activo: json['activo'],
        createdAt: json['created_at'],
      );

  bool get isAdmin => rol == 'ADMIN';
  bool get isOperario => rol == 'OPERARIO';
  bool get isLaboratorista => rol == 'LABORATORISTA';
}
