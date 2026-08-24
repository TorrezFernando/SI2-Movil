import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/secure_storage_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._repository, this._storage);

  final AuthRepository _repository;
  final SecureStorageService _storage;
  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  Future<void> restoreSession() async {
    final token = await _storage.readAccessToken();
    if (token == null || token.isEmpty) return;
    try {
      _user = await _repository.getMe();
    } on DioException {
      await signOut(notify: false);
    }
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final tokens = await _repository.login(email, password);
      await _storage.saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );
      _user = tokens.user;
      return true;
    } on DioException catch (error) {
      _errorMessage = _apiError(error, 'No se pudo iniciar sesión.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut({bool notify = true}) async {
    final refreshToken = await _storage.readRefreshToken();
    try {
      if (refreshToken != null) await _repository.logout(refreshToken);
    } catch (_) {
      // Local cleanup must happen even when the backend is unavailable.
    } finally {
      await _storage.clear();
      _user = null;
      if (notify) notifyListeners();
    }
  }

  String _apiError(DioException error, String fallback) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final detail = data['detail'] ?? data['message'];
      if (detail is String && detail.isNotEmpty) return detail;
    }
    return fallback;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}