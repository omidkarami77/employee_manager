import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'session_storage_contract.dart';

SessionStorage createSessionStorage(String key) => _SecureSessionStorage(key);

class _SecureSessionStorage implements SessionStorage {
  const _SecureSessionStorage(this.key);

  final String key;
  static const _storage = FlutterSecureStorage();

  @override
  Future<String?> read() => _storage.read(key: key);

  @override
  Future<void> write(String value) => _storage.write(key: key, value: value);

  @override
  Future<void> clear() => _storage.delete(key: key);
}
