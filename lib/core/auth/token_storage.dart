// lib/core/auth/token_storage.dart
import 'package:jireta_loan/core/utils/constants.dart';

abstract class TokenStorage {
  Future<void> saveAccessToken(String token);

  Future<String?> getAccessToken();

  Future<void> saveRefreshToken(String token);

  Future<String?> getRefreshToken();

  Future<void> saveUserId(String userId);

  Future<String?> getUserId();

  Future<void> saveUserRole(String role);

  Future<String?> getUserRole();

  Future<void> clearAll();

  Future<bool> hasAccessToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<bool> hasRefreshToken() async {
    final token = await getRefreshToken();
    return token != null && token.isNotEmpty;
  }

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


class MobileTokenStorage extends TokenStorage {
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


class WebTokenStorage extends TokenStorage {
  String? _encryptionKey;

  WebTokenStorage();

  Future<String> _getEncryptionKey() async {
    if (_encryptionKey != null) return _encryptionKey!;

    const keyStorageKey = '_lf_ek';
    try {
      final existing = _webSessionGet(keyStorageKey);
      if (existing != null) {
        _encryptionKey = existing;
        return _encryptionKey!;
      }
    } catch (_) {
    }

    final now = DateTime.now().microsecondsSinceEpoch.toString();
    _encryptionKey = 'lf_${now.hashCode.toRadixString(36)}';
    try {
      _webSessionSet(keyStorageKey, _encryptionKey!);
    } catch (_) {
    }
    return _encryptionKey!;
  }

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

  String? _webSessionGet(String key) {
    return _inMemoryStore[key];
  }

  void _webSessionSet(String key, String value) {
    _inMemoryStore[key] = value;
  }

  void _webSessionRemove(String key) {
    _inMemoryStore.remove(key);
  }

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
