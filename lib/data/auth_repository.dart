import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pocketbase/pocketbase.dart';

import '../config/pocketbase_config.dart';
import '../models/app_user.dart';

class AuthRepositoryException implements Exception {
  const AuthRepositoryException(this.message);
  final String message;
  @override
  String toString() => message;
}

abstract class SessionStorage {
  Future<String?> read();
  Future<void> write(String value);
  Future<void> clear();
}

class SecureSessionStorage implements SessionStorage {
  const SecureSessionStorage(this.key);
  final String key;
  static const _storage = FlutterSecureStorage();
  @override
  Future<String?> read() => _storage.read(key: key);
  @override
  Future<void> write(String value) => _storage.write(key: key, value: value);
  @override
  Future<void> clear() => _storage.delete(key: key);
}

class AuthRepository {
  AuthRepository(this.client, {SessionStorage? storage})
    : storage =
          storage ??
          SecureSessionStorage(
            'employee_manager.auth.${Uri.encodeComponent(client.baseURL)}',
          );
  final PocketBase client;
  final SessionStorage storage;
  bool logoutPending = false;
  Stream<AuthStoreEvent> get changes => client.authStore.onChange;

  AppUser? get currentUser {
    try {
      return client.authStore.isValid
          ? AppUser.fromRecord(client.authStore.record)
          : null;
    } catch (_) {
      return null;
    }
  }

  Future<AppUser?> restore() async {
    if (logoutPending) {
      await logout();
      return null;
    }
    String? saved;
    try {
      saved = await storage.read();
    } catch (_) {
      throw const AuthRepositoryException(
        'خواندن نشست ذخیره‌شده ممکن نیست. دوباره تلاش کنید.',
      );
    }
    if (saved == null || saved.isEmpty) {
      client.authStore.clear();
      return null;
    }
    try {
      final json = jsonDecode(saved) as Map<String, dynamic>;
      client.authStore.save(
        json['token'] as String,
        RecordModel.fromJson(json['record'] as Map<String, dynamic>),
      );
    } catch (_) {
      await logout();
      return null;
    }
    if (currentUser == null) {
      await logout();
      return null;
    }
    return refresh();
  }

  Future<AppUser> login(String email, String password) async {
    if (logoutPending) await logout();
    try {
      await client
          .collection(PocketBaseConfig.authCollection)
          .authWithPassword(email.trim(), password);
      return await _acceptSession();
    } on ClientException catch (error) {
      client.authStore.clear();
      throw _translate(error);
    }
  }

  Future<AppUser?> refresh() async {
    try {
      await client.collection(PocketBaseConfig.authCollection).authRefresh();
      return await _acceptSession();
    } on ClientException catch (error) {
      if ([400, 401, 403, 404].contains(error.statusCode)) {
        await logout();
        return null;
      }
      // Do not admit an offline cached identity, but keep its token for retry.
      throw _translate(error);
    }
  }

  Future<AppUser> _acceptSession() async {
    final user = currentUser;
    if (user == null) {
      await logout();
      throw const AuthRepositoryException(
        'نقش کاربری معتبر نیست. با مدیر سیستم تماس بگیرید.',
      );
    }
    try {
      await storage.write(
        jsonEncode({
          'token': client.authStore.token,
          'record': client.authStore.record!.toJson(),
        }),
      );
    } catch (_) {
      client.authStore.clear();
      throw const AuthRepositoryException(
        'ذخیره امن نشست ممکن نیست. دوباره تلاش کنید.',
      );
    }
    return user;
  }

  Future<void> logout() async {
    logoutPending = true;
    client.authStore.clear();
    try {
      await storage.clear();
      logoutPending = false;
    } catch (_) {
      throw const AuthRepositoryException(
        'پاک‌کردن نشست ذخیره‌شده ممکن نیست. خروج را دوباره انجام دهید.',
      );
    }
  }

  AuthRepositoryException _translate(ClientException error) =>
      AuthRepositoryException(switch (error.statusCode) {
        0 =>
          'ارتباط با سرور برقرار نشد. اتصال را بررسی کنید و دوباره تلاش کنید.',
        400 || 401 => 'ایمیل یا رمز عبور نادرست است.',
        403 => 'ورود به این حساب مجاز نیست.',
        404 => 'تنظیمات ورود در سرور یافت نشد. با مدیر سیستم تماس بگیرید.',
        429 => 'تعداد تلاش‌های ورود زیاد است. کمی بعد دوباره تلاش کنید.',
        _ => 'ورود انجام نشد. دوباره تلاش کنید.',
      });
}
