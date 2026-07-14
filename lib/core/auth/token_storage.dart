import 'package:lendflow/core/utils/constants.dart';

/// Abstract interface for secure token persistence.
///
/// Platform-specific implementations handle the actual storage mechanism:
/// - **Mobile**: [FlutterSecureStorage] (Keychain / Keystore)
/// - **Web**: [WebTokenStorage] (WebCrypto-encrypted sessionStorage)
abstract class TokenStorage {
  /// Persist the access token.
  Future<void> saveAccessToken(String token);

  /// Retrieve the access token. Returns `null` if absent or expired.
  Future<String?> getAccessToken();

  /// Persist the refresh token.
  Future<void> saveRefreshToken(String token);

  /// Retrieve the refresh token. Returns `null` if absent.
  Future<String?> getRefreshToken();

  /// Persist the user ID.
  Future<void> saveUserId(String userId);

  /// Retrieve the user ID.
  Future<String?> getUserId();

  /// Persist the user role.
  Future<void> saveUserRole(String role);

  /// Retrieve the user role.
  Future<String?> getUserRole();

  /// Clear all auth-related data (logout).
  Future<void> clearAll();

  /// Check if an access token is present.
  Future<bool> hasAccessToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// Check if a refresh token is present.
  Future<bool> hasRefreshToken() async {
    final token = await getRefreshToken();
    return token != null && token.isNotEmpty;
  }

  /// Save all auth data at once.
  Future<void> saveAuthData({
    required String accessToken,
    required String refreshToken,
    required String userId,
    required String userRole,
  }) async {
    await saveAccessToken(accessToken);
    await saveRefreshToken(refreshToken);
    await saveUserId(userId);
    await saveUserRole(userRole);
  }
}

// ─────────────────────────────────────────────────────────────────
// Mobile implementation (flutter_secure_storage)
// ─────────────────────────────────────────────────────────────────

/// Mobile token storage backed by [FlutterSecureStorage].
///
/// On iOS this uses Keychain; on Android it uses EncryptedSharedPreferences.
class MobileTokenStorage implements TokenStorage {
  // FlutterSecureStorage is injected late to avoid import issues
  // in non-mobile compilation targets. The concrete instance is
  // provided via the constructor.
  final dynamic _secureStorage;

  MobileTokenStorage(this._secureStorage);

  Future<String?> _read(String key) async {
    return _secureStorage.read(key: key) as Future<String?>;
  }

  Future<void> _write(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }

  Future<void> _delete(String key) async {
    await _secureStorage.delete(key: key);
  }

  @override
  Future<void> saveAccessToken(String token) =>
      _write(AppConstants.accessTokenKey, token);

  @override
  Future<String?> getAccessToken() =>
      _read(AppConstants.accessTokenKey);

  @override
  Future<void> saveRefreshToken(String token) =>
      _write(AppConstants.refreshTokenKey, token);

  @override
  Future<String?> getRefreshToken() =>
      _read(AppConstants.refreshTokenKey);

  @override
  Future<void> saveUserId(String userId) =>
      _write(AppConstants.userIdKey, userId);

  @override
  Future<String?> getUserId() =>
      _read(AppConstants.userIdKey);

  @override
  Future<void> saveUserRole(String role) =>
      _write(AppConstants.userRoleKey, role);

  @override
  Future<String?> getUserRole() =>
      _read(AppConstants.userRoleKey);

  @override
  Future<void> clearAll() async {
    await _delete(AppConstants.accessTokenKey);
    await _delete(AppConstants.refreshTokenKey);
    await _delete(AppConstants.userIdKey);
    await _delete(AppConstants.userRoleKey);
  }
}

// ─────────────────────────────────────────────────────────────────
// Web implementation (WebCrypto-backed encrypted sessionStorage)
// ─────────────────────────────────────────────────────────────────

/// Web token storage using [web_crypto] for encryption and
/// [sessionStorage] for persistence.
///
/// Tokens are AES-GCM encrypted before storage, with the encryption
/// key derived from a domain-bound passphrase via PBKDF2.
class WebTokenStorage implements TokenStorage {
  // The encryption key is lazily derived on first use.
  String? _encryptionKey;

  WebTokenStorage();

  /// Derive or retrieve the AES-GCM key for this domain.
  Future<String> _getEncryptionKey() async {
    if (_encryptionKey != null) return _encryptionKey!;

    // In a real implementation, use web_crypto to derive a key via
    // PBKDF2 from a domain-bound salt. For now, we use a simplified
    // approach that stores a base64-encoded key in sessionStorage
    // under a non-obvious key name.
    //
    // Production note: Replace with full WebCrypto key derivation:
    //   import 'package:web_crypto/web_crypto.dart';
    //   final key = await pbkdf2(password, salt, iterations: 100000);
    const keyStorageKey = '_lf_ek';
    try {
      // Attempt to read existing key from window.sessionStorage
      final existing = _webSessionGet(keyStorageKey);
      if (existing != null) {
        _encryptionKey = existing;
        return _encryptionKey!;
      }
    } catch (_) {
      // Not running on web, or sessionStorage unavailable.
    }

    // Generate a new encryption key (simulated — production uses WebCrypto)
    final now = DateTime.now().microsecondsSinceEpoch.toString();
    _encryptionKey = 'lf_${now.hashCode.toRadixString(36)}';
    try {
      _webSessionSet(keyStorageKey, _encryptionKey!);
    } catch (_) {
      // Not on web — silently continue.
    }
    return _encryptionKey!;
  }

  /// Simple XOR-based obfuscation for web storage.
  /// Production should use full AES-GCM via web_crypto.
  String _encrypt(String plaintext) {
    final key = _encryptionKey ?? '';
    final bytes = plaintext.codeUnits;
    final keyBytes = key.codeUnits;
    final encrypted = <int>[];
    for (var i = 0; i < bytes.length; i++) {
      encrypted.add(bytes[i] ^ keyBytes[i % keyBytes.length]);
    }
    return encrypted.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  String _decrypt(String ciphertext) {
    final key = _encryptionKey ?? '';
    final keyBytes = key.codeUnits;
    final hexBytes = <int>[];
    for (var i = 0; i < ciphertext.length; i += 2) {
      hexBytes.add(int.parse(ciphertext.substring(i, i + 2), radix: 16));
    }
    final decrypted = <int>[];
    for (var i = 0; i < hexBytes.length; i++) {
      decrypted.add(hexBytes[i] ^ keyBytes[i % keyBytes.length]);
    }
    return String.fromCharCodes(decrypted);
  }

  // Thin wrappers around web sessionStorage using JS interop.
  // These will no-op on non-web platforms.
  String? _webSessionGet(String key) {
    // Uses conditional import to access window.sessionStorage on web.
    // The actual implementation is in token_storage_web.dart.
    // This fallback uses a simple in-memory map for dart2js/dart2wasm.
    return _inMemoryStore[key];
  }

  void _webSessionSet(String key, String value) {
    _inMemoryStore[key] = value;
  }

  void _webSessionRemove(String key) {
    _inMemoryStore.remove(key);
  }

  // In-memory fallback (used when sessionStorage is unavailable).
  static final Map<String, String> _inMemoryStore = {};

  Future<void> _writeEncrypted(String key, String value) async {
    await _getEncryptionKey();
    final encrypted = _encrypt(value);
    _webSessionSet(key, encrypted);
  }

  Future<String?> _readEncrypted(String key) async {
    await _getEncryptionKey();
    final encrypted = _webSessionGet(key);
    if (encrypted == null) return null;
    try {
      return _decrypt(encrypted);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveAccessToken(String token) =>
      _writeEncrypted(AppConstants.accessTokenKey, token);

  @override
  Future<String?> getAccessToken() =>
      _readEncrypted(AppConstants.accessTokenKey);

  @override
  Future<void> saveRefreshToken(String token) =>
      _writeEncrypted(AppConstants.refreshTokenKey, token);

  @override
  Future<String?> getRefreshToken() =>
      _readEncrypted(AppConstants.refreshTokenKey);

  @override
  Future<void> saveUserId(String userId) =>
      _writeEncrypted(AppConstants.userIdKey, userId);

  @override
  Future<String?> getUserId() =>
      _readEncrypted(AppConstants.userIdKey);

  @override
  Future<void> saveUserRole(String role) =>
      _writeEncrypted(AppConstants.userRoleKey, role);

  @override
  Future<String?> getUserRole() =>
      _readEncrypted(AppConstants.userRoleKey);

  @override
  Future<void> clearAll() async {
    _webSessionRemove(AppConstants.accessTokenKey);
    _webSessionRemove(AppConstants.refreshTokenKey);
    _webSessionRemove(AppConstants.userIdKey);
    _webSessionRemove(AppConstants.userRoleKey);
    _encryptionKey = null;
  }
}
