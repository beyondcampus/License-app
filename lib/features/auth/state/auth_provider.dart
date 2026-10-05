import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/content_source.dart';
import '../../../core/services/content_cache.dart';
import '../data/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(
    this._repository, {
    this._contentCache,
    this._contentSource,
    this._onContentInvalidated,
  }) {
    _user = _repository.currentUser;
    _subscription = _repository.authStateChanges.listen((state) {
      _user = state.session?.user;
      if (state.event == AuthChangeEvent.signedIn ||
          state.event == AuthChangeEvent.signedOut) {
        _clearCache(state.event == AuthChangeEvent.signedIn);
      }
      notifyListeners();
    });
  }

  final AuthRepository _repository;
  final ContentCache? _contentCache;
  final ContentSource? _contentSource;
  final Future<void> Function(bool signedIn)? _onContentInvalidated;
  late final StreamSubscription<AuthState> _subscription;
  User? _user;
  bool _busy = false;
  String? _error;

  User? get user => _user;
  bool get isSignedIn => _user != null;
  bool get isBusy => _busy;
  String? get error => _error;

  Future<void> signIn(String email, String password) async {
    await _run(() => _repository.signIn(email: email, password: password));
  }

  Future<AuthResponse?> signUp(
      String email, String password, String fullName, String phone) async {
    AuthResponse? response;
    await _run(() async {
      response = await _repository.signUp(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
      );
    });
    return response;
  }

  Future<void> resetPassword(String email) async {
    await _run(() => _repository.resetPassword(email));
  }

  Future<void> signOut() => _run(_repository.signOut);

  Future<void> _clearCache(bool signedIn) async {
    try {
      _contentSource?.clearMemoryCache();
      await _contentCache?.invalidate();
      await _onContentInvalidated?.call(signedIn);
    } catch (_) {
      // Cache cleanup must never block authentication state changes.
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await action();
    } on AuthException catch (error) {
      _error = error.message;
    } catch (_) {
      _error = 'Something went wrong. Please try again.';
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
