import '../models/token_response_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthRepository {
  const AuthRepository(this._service);

  final AuthService _service;

  Future<TokenResponseModel> login(String email, String password) =>
      _service.login(email, password);
  
  Future<void> register({
    required String ci,
    required String nombre,
    required String correo,
    required String telefono,
    required String password,
  }) => _service.register(
    ci: ci, 
    nombre: nombre, 
    correo: correo, 
    telefono: telefono, 
    password: password
  );
  Future<UserModel> getMe() => _service.getMe();
  Future<void> logout(String refreshToken) => _service.logout(refreshToken);
  Future<String> forgotPassword(String email) => _service.forgotPassword(email);
  Future<void> resetPassword(String token, String password) =>
      _service.resetPassword(token, password);
  Future<void> changePassword(String current, String next) =>
      _service.changePassword(current, next);
}