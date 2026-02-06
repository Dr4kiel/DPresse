import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants.dart';

class StoredSession {
  final String domain;
  final String rawCookies;

  const StoredSession({required this.domain, required this.rawCookies});
}

class AuthService {
  final FlutterSecureStorage _secureStorage;

  AuthService({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// Save raw cookie string and domain to secure storage
  Future<void> saveSession({
    required String domain,
    required String rawCookies,
  }) async {
    await _secureStorage.write(
      key: AppConstants.cookieStorageKey,
      value: rawCookies,
    );
    await _secureStorage.write(
      key: AppConstants.cookieDomainKey,
      value: domain,
    );
    await _secureStorage.write(
      key: AppConstants.cookieTimestampKey,
      value: DateTime.now().toIso8601String(),
    );
  }

  /// Load session from secure storage
  Future<StoredSession?> loadStoredSession() async {
    final rawCookies = await _secureStorage.read(
      key: AppConstants.cookieStorageKey,
    );
    final domain = await _secureStorage.read(
      key: AppConstants.cookieDomainKey,
    );

    if (rawCookies == null || domain == null) return null;
    if (await areCookiesExpired()) return null;

    return StoredSession(domain: domain, rawCookies: rawCookies);
  }

  /// Check if stored cookies are expired (older than 30 min)
  Future<bool> areCookiesExpired() async {
    final timestampStr = await _secureStorage.read(
      key: AppConstants.cookieTimestampKey,
    );
    if (timestampStr == null) return true;

    final timestamp = DateTime.parse(timestampStr);
    final elapsed = DateTime.now().difference(timestamp);
    return elapsed > AppConstants.cookieValidDuration;
  }

  /// Clear all stored auth data
  Future<void> clearAuth() async {
    await _secureStorage.delete(key: AppConstants.cookieStorageKey);
    await _secureStorage.delete(key: AppConstants.cookieDomainKey);
    await _secureStorage.delete(key: AppConstants.cookieTimestampKey);
  }
}
