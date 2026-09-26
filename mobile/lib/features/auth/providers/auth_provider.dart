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
  String? _tenantId;
  bool _isInitialized = false;

  AuthProvider({required this.api});

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  bool get isAdmin => _user?.isAdmin ?? false;
  String? get tenantId => _tenantId;

  /// False until the stored session has been rehydrated from disk.
  ///
  /// `init()` is async, so the app must not build its MaterialApp before this
  /// flips: `initialRoute` is only read when the Navigator is first created, so
  /// a restored session would otherwise be dropped back to the login screen.
  bool get isInitialized => _isInitialized;

  Future<void> init() async {
    // Nothing in here may prevent the app from rendering: `main.dart` blocks
    // the MaterialApp behind `isInitialized`, so any throw that escapes here
    // would leave the user staring at the splash forever. Session restore is a
    // best-effort optimisation -- failing to restore must degrade to the login
    // screen, never to a blank page.
    try {
      final prefs = await SharedPreferences.getInstance();
      // Read into a local final: the `tenantId` getter is public, so Dart
      // cannot promote it to non-nullable and the null check below would not
      // compile.
      final storedTenantId = prefs.getString('tenant_id');
      _tenantId = storedTenantId;
      final accessToken = prefs.getString('access_token');
      final refreshToken = prefs.getString('refresh_token');
      final userJson = prefs.getString('user_json');

      if (accessToken != null &&
          refreshToken != null &&
          storedTenantId != null &&
          userJson != null) {
        try {
          api.setTokens(accessToken, refreshToken, storedTenantId);
          final userData = json.decode(userJson) as Map<String, dynamic>;
          _user = User.fromJson(userData);
          notifyListeners();
        } catch (e) {
          // Corrupt or stale session: drop it and fall back to login.
          clearTokens();
        }
      }
    } catch (e) {
      // Unreadable storage, for example. Keep the app usable.
      _user = null;
      _error = 'No se pudo restaurar la sesion guardada';
      clearTokens();
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<bool> login(String username, String password) async {
    if (_tenantId == null || _tenantId!.isEmpty) {
      _error = 'Configurá el ID de empresa en Configuración';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await api.login(username, password, _tenantId!);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', data['access_token']);
      await prefs.setString('refresh_token', data['refresh_token']);

      // Decode JWT to get user info
      final payload = _decodeJwt(data['access_token']);
      if (payload != null) {
        _user = User(
          id: payload['sub'] ?? '',
          tenantId: payload['tenant'] ?? _tenantId,
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
    await prefs.remove('user_json');
    // NOTE: tenant_id is NOT removed — it's a persistent setting.
    // The user changes it from the Settings screen.
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
