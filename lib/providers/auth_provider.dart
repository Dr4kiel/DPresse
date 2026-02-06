import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../services/http_client.dart';

class AuthState {
  final bool isLoggedIn;
  final bool isLoading;
  final String? domain;
  final String? error;

  const AuthState({
    this.isLoggedIn = false,
    this.isLoading = true,
    this.domain,
    this.error,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    bool? isLoading,
    String? domain,
    String? error,
  }) => AuthState(
    isLoggedIn: isLoggedIn ?? this.isLoggedIn,
    isLoading: isLoading ?? this.isLoading,
    domain: domain ?? this.domain,
    error: error,
  );
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  final AppHttpClient _httpClient;

  AuthNotifier(this._authService, this._httpClient) : super(const AuthState()) {
    _httpClient.onSessionExpired = _onSessionExpired;
    _tryRestoreSession();
  }

  void _onSessionExpired() {
    if (state.isLoggedIn) {
      _authService.clearAuth();
      state = const AuthState(isLoggedIn: false, isLoading: false);
    }
  }

  Future<void> _tryRestoreSession() async {
    try {
      final stored = await _authService.loadStoredSession();
      if (stored != null) {
        _httpClient.setBaseUrl(stored.domain);
        _httpClient.setRawCookies(stored.rawCookies);
        state = AuthState(
          isLoggedIn: true,
          isLoading: false,
          domain: stored.domain,
        );
      } else {
        state = const AuthState(isLoggedIn: false, isLoading: false);
      }
    } catch (e) {
      state = AuthState(isLoggedIn: false, isLoading: false, error: e.toString());
    }
  }

  Future<void> loginWithCookies({
    required String domain,
    required String rawCookies,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      await _authService.saveSession(domain: domain, rawCookies: rawCookies);
      _httpClient.setBaseUrl(domain);
      _httpClient.setRawCookies(rawCookies);
      state = AuthState(
        isLoggedIn: true,
        isLoading: false,
        domain: domain,
      );
    } catch (e) {
      state = AuthState(
        isLoggedIn: false,
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> logout() async {
    await _authService.clearAuth();
    state = const AuthState(isLoggedIn: false, isLoading: false);
  }

  Future<bool> checkAndRefreshSession() async {
    final expired = await _authService.areCookiesExpired();
    if (expired) {
      state = const AuthState(isLoggedIn: false, isLoading: false);
      return false;
    }
    return true;
  }
}

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final httpClientProvider = Provider<AppHttpClient>((ref) => AppHttpClient());

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.watch(authServiceProvider),
    ref.watch(httpClientProvider),
  );
});
