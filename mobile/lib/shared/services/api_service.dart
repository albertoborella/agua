import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/plant.dart';
import '../models/models.dart';
import '../models/sample.dart';

class ApiService {
  final String baseUrl;

  ApiService({required this.baseUrl});

  String? _accessToken;
  String? _refreshToken;
  String? _tenantId;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
      };

  void setTokens(String accessToken, String refreshToken, String tenantId) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _tenantId = tenantId;
  }

  void clearTokens() {
    _accessToken = null;
    _refreshToken = null;
    _tenantId = null;
  }

  // Auth
  Future<Map<String, dynamic>> login(
      String username, String password, String tenantId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'username': username,
        'password': password,
        'client_id': tenantId,
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      final accessToken = data['access_token'] as String?;
      final refreshToken = data['refresh_token'] as String?;
      if (accessToken == null || refreshToken == null) {
        throw Exception('La respuesta del login no incluye los tokens');
      }
      setTokens(accessToken, refreshToken, tenantId);
      return data;
    } else {
      throw Exception('Credenciales inválidas');
    }
  }

  Future<Map<String, dynamic>> refreshToken() async {
    final tenantId = _tenantId;
    final currentRefreshToken = _refreshToken;
    if (tenantId == null || currentRefreshToken == null) {
      throw Exception('No hay sesión activa para renovar el token');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/auth/refresh'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'refresh_token': currentRefreshToken}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      final accessToken = data['access_token'] as String?;
      final newRefreshToken = data['refresh_token'] as String?;
      if (accessToken == null || newRefreshToken == null) {
        throw Exception('La respuesta del refresh no incluye los tokens');
      }
      setTokens(accessToken, newRefreshToken, tenantId);
      return data;
    } else {
      throw Exception('Token inválido');
    }
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/change-password'),
      headers: _headers,
      body: json.encode({
        'current_password': currentPassword,
        'new_password': newPassword,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al cambiar contraseña');
    }
  }

  // Admin - Plants
  Future<List<Plant>> getPlants() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/plants'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((json) => Plant.fromJson(json)).toList();
    } else {
      throw Exception('Error al obtener plantas');
    }
  }

  Future<Plant> createPlant(String nombre, String? direccion) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/plants'),
      headers: _headers,
      body: json.encode({'nombre': nombre, 'direccion': direccion}),
    );

    if (response.statusCode == 200) {
      return Plant.fromJson(json.decode(response.body));
    } else {
      throw Exception('Error al crear planta');
    }
  }

  // Admin - Water Sources
  Future<List<WaterSource>> getSources() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/sources'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((json) => WaterSource.fromJson(json)).toList();
    } else {
      throw Exception('Error al obtener fuentes');
    }
  }

  Future<WaterSource> createSource(String plantaId, String nombre, String tipo,
      {String? ubicacion}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/sources'),
      headers: _headers,
      body: json.encode({
        'planta_id': plantaId,
        'nombre': nombre,
        'tipo': tipo,
        'ubicacion': ubicacion,
      }),
    );

    if (response.statusCode == 200) {
      return WaterSource.fromJson(json.decode(response.body));
    } else {
      throw Exception('Error al crear fuente');
    }
  }

  // Catalog - analysis types
  // Reads the global catalog, which is open to any authenticated user (an
  // operario must be able to pick an analysis type). Writes stay ADMIN-only.
  Future<List<AnalysisType>> getAnalysisTypes() async {
    final response = await http.get(
      Uri.parse('$baseUrl/catalog/analysis-types'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((json) => AnalysisType.fromJson(json)).toList();
    } else {
      throw Exception('Error al obtener tipos de análisis');
    }
  }

  Future<AnalysisType> createAnalysisType(String codigo, String nombre,
      {bool requiereDescripcion = false}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/analysis-types'),
      headers: _headers,
      body: json.encode({
        'codigo': codigo,
        'nombre': nombre,
        'requiere_descripcion': requiereDescripcion,
      }),
    );

    if (response.statusCode == 200) {
      return AnalysisType.fromJson(json.decode(response.body));
    } else {
      throw Exception('Error al crear tipo de análisis');
    }
  }

  // Admin - Frequencies
  Future<List<SamplingFrequency>> getFrequencies() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/frequencies'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((json) => SamplingFrequency.fromJson(json)).toList();
    } else {
      throw Exception('Error al obtener frecuencias');
    }
  }

  // Admin - Users
  Future<List<User>> getUsers() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/users'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((json) => User.fromJson(json)).toList();
    } else {
      throw Exception('Error al obtener usuarios');
    }
  }

  Future<User> createUser(String username, String email, String password, String rol) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/users'),
      headers: _headers,
      body: json.encode({
        'username': username,
        'email': email,
        'password': password,
        'rol': rol,
      }),
    );

    if (response.statusCode == 200) {
      return User.fromJson(json.decode(response.body));
    } else {
      throw Exception('Error al crear usuario');
    }
  }

  // Samples
  Future<List<Map<String, dynamic>>> getSampleSources() async {
    final response = await http.get(
      Uri.parse('$baseUrl/samples/sources'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Error al obtener fuentes');
    }
  }

  Future<SampleRecord> createSample(String fuenteId, String tipoAnalisisId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/samples'),
      headers: _headers,
      body: json.encode({
        'fuente_id': fuenteId,
        'tipo_analisis_id': tipoAnalisisId,
      }),
    );

    if (response.statusCode == 200) {
      return SampleRecord.fromJson(json.decode(response.body));
    } else {
      throw Exception('Error al registrar muestra');
    }
  }

  Future<List<SampleRecord>> getTodaySamples() async {
    final response = await http.get(
      Uri.parse('$baseUrl/samples/today'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((json) => SampleRecord.fromJson(json)).toList();
    } else {
      throw Exception('Error al obtener muestras de hoy');
    }
  }

  Future<List<SampleRecord>> getHistory({
    String? fuenteId,
    String? tipoAnalisisId,
    String? fechaDesde,
    String? fechaHasta,
  }) async {
    final queryParams = <String, String>{};
    if (fuenteId != null) queryParams['fuente_id'] = fuenteId;
    if (tipoAnalisisId != null) queryParams['tipo_analisis_id'] = tipoAnalisisId;
    if (fechaDesde != null) queryParams['fecha_desde'] = fechaDesde;
    if (fechaHasta != null) queryParams['fecha_hasta'] = fechaHasta;

    final uri = Uri.parse('$baseUrl/samples/history')
        .replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((json) => SampleRecord.fromJson(json)).toList();
    } else {
      throw Exception('Error al obtener historial');
    }
  }

  // Alerts
  Future<List<Alert>> getPendingAlerts() async {
    final response = await http.get(
      Uri.parse('$baseUrl/alerts/pending'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((json) => Alert.fromJson(json)).toList();
    } else {
      throw Exception('Error al obtener alertas');
    }
  }

  Future<Alert> markAlertRead(String alertId) async {
    final response = await http.put(
      Uri.parse('$baseUrl/alerts/$alertId/read'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return Alert.fromJson(json.decode(response.body));
    } else {
      throw Exception('Error al marcar alerta');
    }
  }
}
