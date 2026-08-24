import 'package:dio/dio.dart';

import '../models/token_response_model.dart';
import '../models/user_model.dart';

class AuthService {
  const AuthService(this._dio);

  final Dio _dio;

  Future<TokenResponseModel> login(String email, String password) async {
    final response = await _dio.post('/login', data: {
      'correo': email,
      'password': password,
    });
    return TokenResponseModel.fromJson(
      response.data as Map<String, dynamic>,
      fallbackEmail: email,
    );
  }

  Future<UserModel> getMe() async {
    final response = await _dio.get('/auth/me');
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> logout(String refreshToken) async {
    await _dio.post('/auth/logout', data: {'refresh_token': refreshToken});
  }

  Future<String> forgotPassword(String email) async {
    final response = await _dio.post('/auth/forgot-password', data: {'email': email});
    return (response.data as Map<String, dynamic>)['message'] as String? ?? '';
  }

  Future<void> resetPassword(String token, String newPassword) async {
    await _dio.post('/auth/reset-password', data: {
      'token': token,
      'new_password': newPassword,
    });
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    await _dio.post('/auth/change-password', data: {
      'current_password': currentPassword,
      'new_password': newPassword,
    });
  }
}