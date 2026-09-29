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

  // Authenticated transport.
  //
  // Access tokens live 30 minutes, so a session that was healthy when the app
  // was opened dies while it is still open, and every subsequent call comes
  // back 401 with nothing in the app willing to recover. All authenticated
  // calls go through here so that recovery is one policy, not fifteen copies
  // of it, and so the per-call Spanish error messages stay where they are.
  Future<http.Response> _get(String path, {Map<String, String>? query}) =>
      _send(() {
        final uri = Uri.parse('$baseUrl$path');
        return http.get(
          query == null ? uri : uri.replace(queryParameters: query),
          headers: _headers,
        );
      });

  Future<http.Response> _post(String path, Object body) =>
      _send(() => http.post(Uri.parse('$baseUrl$path'),
          headers: _headers, body: body));

  Future<http.Response> _put(String path, [Object? body]) =>
      _send(() => http.put(Uri.parse('$baseUrl$path'),
          headers: _headers, body: body));

  Future<http.Response> _delete(String path) =>
      _send(() => http.delete(Uri.parse('$baseUrl$path'), headers: _headers));

  /// Runs [send], and on a 401 renews the session once and replays it.
  ///
  /// [send] is a closure rather than a built request on purpose: the replay
  /// re-reads `_headers`, so the second attempt necessarily goes out with the
  /// token the renewal produced instead of the one that just got rejected.
  ///
  /// Exactly one renewal, then one replay. A token the backend keeps refusing
  /// has not become acceptable by asking again, and retrying without a bound
  /// would turn a dead session into a request loop.
  Future<http.Response> _send(Future<http.Response> Function() send) async {
    final response = await send();
    if (response.statusCode != 401 || _refreshToken == null) return response;
    if (!await _renewOnce()) return response;
    return send();
  }

  /// Single-flight guard around [refreshToken].
  ///
  /// Screens fire several calls at once, so a burst of 401s would otherwise
  /// start one renewal per call, and every one of them calls `setTokens` -- the
  /// last writer wins. Today the backend is stateless and hands back an
  /// equivalent token each time, so the stampede is merely N redundant round
  /// trips on the slowest, most constrained path a mobile device has. It also
  /// makes the guard cheap insurance rather than a load-bearing assumption: the
  /// moment refresh tokens are revoked or rotated on use, one winner and N-1
  /// failures means the losers throw on a session that is still perfectly
  /// alive. Sharing the in-flight renewal means every caller waits on the same
  /// result and replays with the same fresh token either way.
  Future<bool>? _renewInFlight;

  Future<bool> _renewOnce() => _renewInFlight ??=
      _renew().whenComplete(() => _renewInFlight = null);

  /// Renewal as a boolean, because a failure here is a normal outcome: it means
  /// the session is over, and the caller should surface its own error rather
  /// than an exception about tokens.
  Future<bool> _renew() async {
    try {
      await refreshToken();
      return true;
    } catch (_) {
      return false;
    }
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
      throw Exception(_errorDetail(response) ?? 'Credenciales inválidas');
    }
  }

  /// The `detail` a failed request carries, or null when there is nothing
  /// presentable to show.
  ///
  /// The backend answers a rejected login with `{"detail": "..."}`, and that
  /// sentence is written for the user: a mistyped company id gets a 404 that
  /// names the id as the problem, and only a genuine wrong password gets a 401.
  /// Collapsing both into one hardcoded "Credenciales inválidas" points the
  /// user at the password, which is the half that was right. The client's job is
  /// to get out of the way and repeat the sentence.
  ///
  /// Null for every shape we cannot show, so the caller keeps its own message
  /// instead of surfacing our parsing:
  ///   * a body that is not JSON at all -- an HTML page from a proxy, an empty
  ///     body. [json.decode] would throw a FormatException about quoting and
  ///     colons, which tells the user nothing about their login.
  ///   * JSON that is not an object: a list, a bare string, a number, null.
  ///   * no `detail` key, or one that is not a string. The 422 for a missing
  ///     form field really does answer with `detail` as a LIST of validation
  ///     objects, and stringifying that would put framework internals on the
  ///     login screen.
  ///   * a `detail` that is only whitespace, which is a string that says
  ///     nothing.
  ///
  /// Returns the detail as sent, not trimmed: the sentence is the backend's
  /// copy and reformatting it here would only make the two drift apart.
  String? _errorDetail(http.Response response) {
    Object? decoded;
    try {
      decoded = json.decode(response.body);
    } on FormatException {
      return null;
    }
    if (decoded is! Map<String, dynamic>) return null;
    final detail = decoded['detail'];
    if (detail is! String) return null;
    return detail.trim().isEmpty ? null : detail;
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
    final response = await _post('/auth/change-password', json.encode({
      'current_password': currentPassword,
      'new_password': newPassword,
    }));

    if (response.statusCode != 200) {
      throw Exception('Error al cambiar contraseña');
    }
  }

  // Admin - Plants
  Future<List<Plant>> getPlants() async {
    final response = await _get('/admin/plants');

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((json) => Plant.fromJson(json)).toList();
    } else {
      throw Exception('Error al obtener plantas');
    }
  }

  Future<Plant> createPlant(String nombre, String? direccion) async {
    final response = await _post(
        '/admin/plants', json.encode({'nombre': nombre, 'direccion': direccion}));

    if (response.statusCode == 200) {
      return Plant.fromJson(json.decode(response.body));
    } else {
      throw Exception('Error al crear planta');
    }
  }

  // Admin - Water Sources
  Future<List<WaterSource>> getSources() async {
    final response = await _get('/admin/sources');

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((json) => WaterSource.fromJson(json)).toList();
    } else {
      throw Exception('Error al obtener fuentes');
    }
  }

  Future<WaterSource> createSource(String plantaId, String nombre, String tipo,
      {String? ubicacion}) async {
    final response = await _post('/admin/sources', json.encode({
      'planta_id': plantaId,
      'nombre': nombre,
      'tipo': tipo,
      'ubicacion': ubicacion,
    }));

    if (response.statusCode == 200) {
      return WaterSource.fromJson(json.decode(response.body));
    } else {
      throw Exception('Error al crear fuente');
    }
  }

  Future<WaterSource> updateSource(String sourceId, String nombre, String tipo,
      {String? ubicacion, bool? activa}) async {
    final body = <String, dynamic>{'nombre': nombre, 'tipo': tipo};
    if (ubicacion != null) body['ubicacion'] = ubicacion;
    if (activa != null) body['activa'] = activa;

    final response = await _put(
      '/admin/sources/$sourceId',
      json.encode(body),
    );

    if (response.statusCode == 200) {
      return WaterSource.fromJson(json.decode(response.body));
    } else {
      throw Exception('Error al actualizar fuente');
    }
  }

  Future<void> deleteSource(String sourceId) async {
    final response = await _delete('/admin/sources/$sourceId');

    if (response.statusCode != 200) {
      throw Exception('Error al eliminar fuente');
    }
  }

  // Catalog - analysis types
  // Reads the global catalog, which is open to any authenticated user (an
  // operario must be able to pick an analysis type). Writes stay ADMIN-only.
  Future<List<AnalysisType>> getAnalysisTypes() async {
    final response = await _get('/catalog/analysis-types');

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((json) => AnalysisType.fromJson(json)).toList();
    } else {
      throw Exception('Error al obtener tipos de análisis');
    }
  }

  Future<AnalysisType> createAnalysisType(String codigo, String nombre,
      {bool requiereDescripcion = false}) async {
    final response = await _post('/admin/analysis-types', json.encode({
      'codigo': codigo,
      'nombre': nombre,
      'requiere_descripcion': requiereDescripcion,
    }));

    if (response.statusCode == 200) {
      return AnalysisType.fromJson(json.decode(response.body));
    } else {
      throw Exception('Error al crear tipo de análisis');
    }
  }

  Future<AnalysisType> updateAnalysisType(
    String typeId,
    String nombre, {
    bool? requiereDescripcion,
  }) async {
    final body = <String, dynamic>{'nombre': nombre};
    if (requiereDescripcion != null) body['requiere_descripcion'] = requiereDescripcion;

    final response = await _put(
      '/admin/analysis-types/$typeId',
      json.encode(body),
    );

    if (response.statusCode == 200) {
      return AnalysisType.fromJson(json.decode(response.body));
    } else {
      throw Exception('Error al actualizar tipo de análisis');
    }
  }

  Future<void> deleteAnalysisType(String typeId) async {
    final response = await _delete('/admin/analysis-types/$typeId');

    if (response.statusCode != 200) {
      throw Exception('Error al eliminar tipo de análisis');
    }
  }

  // Admin - Frequencies
  Future<List<SamplingFrequency>> getFrequencies() async {
    final response = await _get('/admin/frequencies');

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((json) => SamplingFrequency.fromJson(json)).toList();
    } else {
      throw Exception('Error al obtener frecuencias');
    }
  }

  Future<SamplingFrequency> createFrequency({
    required String fuenteId,
    required String tipoAnalisisId,
    required String frecuencia,
    String? diasSemana,
    String? horaEsperada,
  }) async {
    final response = await _post('/admin/frequencies', json.encode({
      'fuente_id': fuenteId,
      'tipo_analisis_id': tipoAnalisisId,
      'frecuencia': frecuencia,
      if (diasSemana != null) 'dias_semana': diasSemana,
      if (horaEsperada != null) 'hora_esperada': horaEsperada,
    }));

    if (response.statusCode == 200) {
      return SamplingFrequency.fromJson(json.decode(response.body));
    } else {
      throw Exception('Error al crear frecuencia');
    }
  }

  Future<SamplingFrequency> updateFrequency(
    String frequencyId, {
    String? frecuencia,
    String? diasSemana,
    String? horaEsperada,
    bool? activa,
  }) async {
    final body = <String, dynamic>{};
    if (frecuencia != null) body['frecuencia'] = frecuencia;
    if (diasSemana != null) body['dias_semana'] = diasSemana;
    if (horaEsperada != null) body['hora_esperada'] = horaEsperada;
    if (activa != null) body['activa'] = activa;

    final response = await _put(
      '/admin/frequencies/$frequencyId',
      json.encode(body),
    );

    if (response.statusCode == 200) {
      return SamplingFrequency.fromJson(json.decode(response.body));
    } else {
      throw Exception('Error al actualizar frecuencia');
    }
  }

  Future<void> deleteFrequency(String frequencyId) async {
    final response = await _delete('/admin/frequencies/$frequencyId');

    if (response.statusCode != 200) {
      throw Exception('Error al eliminar frecuencia');
    }
  }

  // Admin - Users
  Future<List<User>> getUsers() async {
    final response = await _get('/admin/users');

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((json) => User.fromJson(json)).toList();
    } else {
      throw Exception('Error al obtener usuarios');
    }
  }

  Future<User> createUser(String username, String email, String password, String rol) async {
    final response = await _post('/admin/users', json.encode({
      'username': username,
      'email': email,
      'password': password,
      'rol': rol,
    }));

    if (response.statusCode == 200) {
      return User.fromJson(json.decode(response.body));
    } else {
      throw Exception('Error al crear usuario');
    }
  }

  Future<User> updateUser(String userId, {
    String? email,
    String? rol,
    bool? activo,
  }) async {
    final body = <String, dynamic>{};
    if (email != null) body['email'] = email;
    if (rol != null) body['rol'] = rol;
    if (activo != null) body['activo'] = activo;

    final response = await _put(
      '/admin/users/$userId',
      json.encode(body),
    );

    if (response.statusCode == 200) {
      return User.fromJson(json.decode(response.body));
    } else {
      throw Exception('Error al actualizar usuario');
    }
  }

  Future<void> deleteUser(String userId) async {
    final response = await _delete('/admin/users/$userId');

    if (response.statusCode != 200) {
      throw Exception('Error al eliminar usuario');
    }
  }

  Future<void> resetUserPassword(String userId, String newPassword) async {
    final response = await _post('/admin/users/$userId/reset-password', json.encode({
      'new_password': newPassword,
    }));

    if (response.statusCode != 200) {
      throw Exception('Error al restablecer contraseña');
    }
  }

  // Samples
  Future<List<Map<String, dynamic>>> getSampleSources() async {
    final response = await _get('/samples/sources');

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Error al obtener fuentes');
    }
  }

  Future<SampleRecord> createSample(String fuenteId, String tipoAnalisisId) async {
    final response = await _post('/samples', json.encode({
      'fuente_id': fuenteId,
      'tipo_analisis_id': tipoAnalisisId,
    }));

    if (response.statusCode == 200) {
      return SampleRecord.fromJson(json.decode(response.body));
    } else {
      throw Exception('Error al registrar muestra');
    }
  }

  Future<List<SampleRecord>> getTodaySamples() async {
    final response = await _get('/samples/today');

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

    final response = await _get('/samples/history', query: queryParams);

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((json) => SampleRecord.fromJson(json)).toList();
    } else {
      throw Exception('Error al obtener historial');
    }
  }

  Future<Map<String, int>> getSampleCounts() async {
    final response = await _get('/samples/counts');

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return {
        'realizadas': data['realizadas'] as int,
        'pendientes': data['pendientes'] as int,
        'vencidas': data['vencidas'] as int,
      };
    } else {
      throw Exception('Error al obtener conteos');
    }
  }

  // Alerts
  Future<List<Alert>> getPendingAlerts() async {
    final response = await _get('/alerts/pending');

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((json) => Alert.fromJson(json)).toList();
    } else {
      throw Exception('Error al obtener alertas');
    }
  }

  Future<Alert> markAlertRead(String alertId) async {
    final response = await _put('/alerts/$alertId/read');

    if (response.statusCode == 200) {
      return Alert.fromJson(json.decode(response.body));
    } else {
      throw Exception('Error al marcar alerta');
    }
  }
}
