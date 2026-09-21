import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/models/user.dart';
import '../../../shared/services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService api;

  User? _user;
  bool _isLoading = false;
  String? _error;

  AuthProvider({required this.api});

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  bool get isAdmin => _user?.isAdmin ?? false;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');
    final refreshToken = prefs.getString('refresh_token');
    final tenantId = prefs.getString('tenant_id');
    final userJson = prefs.getString('user_json');

    if (accessToken != null &&
        refreshToken != null &&
        tenantId != null &&
        userJson != null) {
      try {
        api.setTokens(accessToken, refreshToken, tenantId);
        final userData = json.decode(userJson) as Map<String, dynamic>;
        _user = User.fromJson(userData);
        notifyListeners();
      } catch (e) {
        clearTokens();
      }
    }
  }

  Future<bool> login(String username, String password, String tenantId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await api.login(username, password, tenantId);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', data['access_token']);
      await prefs.setString('refresh_token', data['refresh_token']);
      await prefs.setString('tenant_id', tenantId);

      // Decode JWT to get user info
      final payload = _decodeJwt(data['access_token']);
      if (payload != null) {
        _user = User(
          id: payload['sub'] ?? '',
          tenantId: payload['tenant'] ?? tenantId,
          username: username,
          email: '',
          rol: payload['rol'] ?? 'OPERARIO',
          activo: true,
          createdAt: DateTime.now().toIso8601String(),
        );
        await prefs.setString('user_json', json.encode({
          'id': _user!.id,
          'tenant_id': _user!.tenantId,
          'username': _user!.username,
          'email': _user!.email,
          'rol': _user!.rol,
          'activo': _user!.activo,
          'created_at': _user!.createdAt,
        }));
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    clearTokens();
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('tenant_id');
    await prefs.remove('user_json');
    notifyListeners();
  }

  void clearTokens() {
    api.clearTokens();
  }

  Map<String, dynamic>? _decodeJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      return json.decode(decoded) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }
}
