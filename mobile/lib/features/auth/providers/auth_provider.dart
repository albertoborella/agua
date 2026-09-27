import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/models/user.dart';
import '../../../shared/services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService api;

  /// The cold start renewal deadline this instance enforces; [renewalTimeout]
  /// unless a caller passes a shorter one.
  ///
  /// Overridable so a test can prove the deadline in milliseconds instead of
  /// waiting the production ten seconds out. Nothing in the app sets it.
  final Duration _renewalTimeout;

  User? _user;
  bool _isLoading = false;
  String? _error;
  String? _tenantId;
  bool _isInitialized = false;

  AuthProvider({required this.api, Duration? renewalTimeout})
      : _renewalTimeout = renewalTimeout ?? AuthProvider.renewalTimeout;

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
          // After the user payload, not before: this is the only part of the
          // restore that touches the network, and corrupt storage must not pay
          // for a round trip it cannot use.
          await _renewExpiredSession(prefs, accessToken);
          notifyListeners();
        } catch (e) {
          // Unrenewable or corrupt session: drop it and fall back to login.
          // The stored tokens go as well, otherwise the next cold start walks
          // the same dead end and the user has no way out but a fresh login
          // that never appears to be needed.
          clearTokens();
          _user = null;
          await _forgetStoredSession(prefs);
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
      final accessToken = data['access_token'] as String;
      final refreshToken = data['refresh_token'] as String;

      // The in-memory ApiService must hold the token as well. Persisting it is
      // not enough: only init() re-reads storage, so without this call every
      // authenticated request goes out without an Authorization header and the
      // backend answers 401. The symptom is misleading because login itself
      // succeeds -- it is the first screen that needs data that fails, which
      // only went away after reloading the page to trigger init().
      api.setTokens(accessToken, refreshToken, _tenantId!);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', accessToken);
      await prefs.setString('refresh_token', refreshToken);

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
    await _forgetStoredSession(prefs);
    notifyListeners();
  }

  /// Drops the persisted session.
  ///
  /// NOTE: tenant_id is NOT removed — it's a persistent setting. The user
  /// changes it from the Settings screen, and a session that cannot be revived
  /// must not take it down with it.
  Future<void> _forgetStoredSession(SharedPreferences prefs) async {
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('user_json');
  }

  /// Renews the stored access token if it is no longer usable, and persists
  /// whatever the renewal returned.
  ///
  /// A stored access token carries a 30 minute lifetime, so most sessions found
  /// on a cold start are already dead by the time the app is reopened.
  /// Restoring one as-is is the bug itself: the app reports "logged in" while
  /// every request it makes answers 401, and nothing in the app tries to fix
  /// that. A session that can still be renewed must not cost the user a login.
  ///
  /// Throws when the session cannot be revived -- a rejected, revoked or
  /// missing refresh token -- which is the caller's signal to fall back to the
  /// login screen. A renewal that never answers does NOT throw: see
  /// [renewalTimeout].
  Future<void> _renewExpiredSession(
      SharedPreferences prefs, String accessToken) async {
    if (!_isExpired(accessToken)) return;

    // Bounded, because `main.dart` holds the first frame behind this await. An
    // unbounded renewal is not a slow start, it is a blank screen that never
    // resolves, and that is strictly worse than the 401 it was added to fix.
    Map<String, dynamic>? renewed;
    try {
      // `ApiService.refreshToken()` swaps the in-memory tokens itself on
      // success, so the rest of the app picks up the new session from here on.
      renewed = await api.refreshToken().timeout(_renewalTimeout);
    } on TimeoutException {
      // The deadline gives the wait up; it does not give the session up.
      // Restoring optimistically is not a compromise, for two reasons:
      //   * `ApiService._send()` already recovers from a 401 -- it renews once
      //     and replays the request -- so a session restored with a stale
      //     access token heals itself on its first request, and no login
      //     screen ever appears. Falling back to login here would sign the user
      //     out every time the network hiccuped during startup.
      //   * A timeout is evidence about the network and not about the refresh
      //     token, which is good for days. Throwing would make the caller
      //     discard a perfectly valid token because a captive portal ate a
      //     packet, and the user would have to log in again over nothing.
      // So: nothing is written, nothing is cleared, the stored session stands.
      // A renewal that actually ANSWERS is still believed -- only silence is
      // treated as inconclusive, and silence has more than one shape.
      return;
    } on http.ClientException {
      // Connection refused, DNS failure, TLS error: the request never reached a
      // server that could judge the token. That is the same inconclusive
      // silence a timeout is, so it gets the same outcome -- keep a session
      // that is good for days instead of signing the user out because the
      // backend happened not to be up yet. Only an answer FROM the server, like
      // `Exception('Token inválido')`, is proof the session is over.
      return;
    }

    final renewedAccessToken = renewed['access_token'] as String;

    await prefs.setString('access_token', renewedAccessToken);
    // Only overwrite the refresh token when the response actually carried one.
    // `ApiService.refreshToken()` already refuses a response without both, but
    // writing a good token away on a surprise would break the next renewal.
    final renewedRefreshToken = renewed['refresh_token'] as String?;
    if (renewedRefreshToken != null) {
      await prefs.setString('refresh_token', renewedRefreshToken);
    }
  }

  /// How long the cold start renewal may wait on the network before the app
  /// stops waiting and renders with the session it already has.
  ///
  /// Ten seconds, chosen against the thing this protects rather than the thing
  /// it waits for: `main.dart` does not call `runApp` until `init()` returns,
  /// so every second spent inside the renewal is a second of blank screen. A
  /// healthy renewal is one small POST that a mediocre mobile connection
  /// answers in well under two, so ten is generous enough not to fire on a slow
  /// network or a cold backend, and short enough that a captive portal costs a
  /// moment of patience instead of a minute of it. Leaning late is the safe
  /// direction: a premature deadline only restores a session whose first
  /// request heals itself through the 401 path, while a late one keeps the user
  /// staring at nothing.
  static const Duration renewalTimeout = Duration(seconds: 10);

  /// How far ahead of its `exp` an access token already counts as expired.
  ///
  /// A token that dies between the check and the response is a 401 the app has
  /// to recover from, and recovery costs a round trip. Renewing a few seconds
  /// early is cheaper than paying for it.
  static const Duration _clockSkew = Duration(seconds: 45);

  /// Whether [token] is past its `exp` claim.
  ///
  /// A token whose `exp` cannot be read is NOT treated as expired. `exp` is
  /// optional in JWT (RFC 7519 4.1.4), so a missing one is no evidence that the
  /// token died, and rejecting on that guess would sign out every session
  /// stored before this check existed. A token we cannot judge is left alone
  /// and the 401 handling in `ApiService` remains the backstop for it.
  bool _isExpired(String token) {
    final exp = _decodeJwt(token)?['exp'];
    if (exp is! num) return false;
    final expiresAt =
        DateTime.fromMillisecondsSinceEpoch((exp * 1000).round());
    return !expiresAt.isAfter(DateTime.now().add(_clockSkew));
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
