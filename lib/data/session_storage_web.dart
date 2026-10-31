import 'package:web/web.dart' as web;

import 'session_storage_contract.dart';

/// WebCrypto requires HTTPS away from localhost. For this intranet HTTP site,
/// keep the authenticated session in the browser's local storage instead.
SessionStorage createSessionStorage(String key) => _WebSessionStorage(key);

class _WebSessionStorage implements SessionStorage {
  const _WebSessionStorage(this.key);

  final String key;
  static final _memoryFallback = <String, String>{};

  @override
  Future<String?> read() async {
    try {
      return web.window.localStorage.getItem(key) ?? _memoryFallback[key];
    } catch (_) {
      return _memoryFallback[key];
    }
  }

  @override
  Future<void> write(String value) async {
    _memoryFallback[key] = value;
    try {
      web.window.localStorage.setItem(key, value);
    } catch (_) {
      // Some locked-down browsers disable local storage on intranet HTTP
      // origins. Keep the session until this tab is closed in that case.
    }
  }

  @override
  Future<void> clear() async {
    _memoryFallback.remove(key);
    try {
      web.window.localStorage.removeItem(key);
    } catch (_) {
      // Nothing else to clear when local storage is unavailable.
    }
  }
}
