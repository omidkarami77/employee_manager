import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/auth_repository.dart';
import '../models/app_user.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  const AuthState(this.status, {this.user, this.message});
  final AuthStatus status;
  final AppUser? user;
  final String? message;
}

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this.repository) : super(const AuthState(AuthStatus.initial)) {
    _subscription = repository.changes.listen((event) {
      if (!_busy &&
          state.status == AuthStatus.authenticated &&
          repository.currentUser == null) {
        unawaited(logout());
      }
    });
    _timer = Timer.periodic(const Duration(minutes: 5), (_) => refresh());
  }
  final AuthRepository repository;
  late final StreamSubscription<dynamic> _subscription;
  late final Timer _timer;
  bool _busy = false;

  bool get canManageEmployees =>
      state.status == AuthStatus.authenticated &&
      state.user?.isAdmin == true &&
      repository.currentUser?.isAdmin == true;

  Future<void> restore() => _authenticate(repository.restore);
  Future<void> login(String email, String password) =>
      _authenticate(() => repository.login(email, password));

  Future<void> _authenticate(Future<AppUser?> Function() operation) async {
    if (_busy || isClosed) return;
    _busy = true;
    emit(const AuthState(AuthStatus.loading));
    try {
      final user = await operation();
      if (!isClosed) {
        emit(
          AuthState(
            user == null
                ? AuthStatus.unauthenticated
                : AuthStatus.authenticated,
            user: user,
          ),
        );
      }
    } on AuthRepositoryException catch (error) {
      if (!isClosed) emit(AuthState(AuthStatus.error, message: error.message));
    } catch (_) {
      if (!isClosed) {
        emit(
          const AuthState(
            AuthStatus.error,
            message: 'ورود انجام نشد. دوباره تلاش کنید.',
          ),
        );
      }
    } finally {
      _busy = false;
    }
  }

  Future<void> refresh() async {
    if (_busy || isClosed || state.status != AuthStatus.authenticated) return;
    // A refresh can change the user's role; never trust a role cached at startup.
    _busy = true;
    try {
      final user = await repository.refresh();
      if (!isClosed) {
        emit(
          AuthState(
            user == null
                ? AuthStatus.unauthenticated
                : AuthStatus.authenticated,
            user: user,
          ),
        );
      }
    } catch (_) {
      if (!isClosed) {
        emit(
          const AuthState(
            AuthStatus.error,
            message: 'اعتبارسنجی نشست انجام نشد. دوباره تلاش کنید.',
          ),
        );
      }
    } finally {
      _busy = false;
    }
  }

  Future<void> logout() async {
    if (_busy || isClosed) return;
    _busy = true;
    emit(const AuthState(AuthStatus.loading));
    try {
      await repository.logout();
      if (!isClosed) emit(const AuthState(AuthStatus.unauthenticated));
    } on AuthRepositoryException catch (error) {
      if (!isClosed) emit(AuthState(AuthStatus.error, message: error.message));
    } finally {
      _busy = false;
    }
  }

  @override
  Future<void> close() async {
    _timer.cancel();
    await _subscription.cancel();
    return super.close();
  }
}
