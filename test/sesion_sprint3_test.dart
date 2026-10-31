import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inmobiliaria_mobile/data/repositories/auth_repository.dart';
import 'package:inmobiliaria_mobile/data/services/auth_service.dart';
import 'package:inmobiliaria_mobile/data/services/push_service.dart';
import 'package:inmobiliaria_mobile/data/services/secure_storage_service.dart';
import 'package:inmobiliaria_mobile/presentation/providers/auth_provider.dart';

import 'sprint3_test.dart' show FakeAdapter, jsonBody;

class MemoryStorage extends SecureStorageService {
  String? token;
  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    token = accessToken;
  }

  @override
  Future<String?> readAccessToken() async => token;
  @override
  Future<String?> readRefreshToken() async => '';
  @override
  Future<void> clear() async {
    token = null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Login obtiene identidad y empresa del perfil, y da de baja push antes de borrar token', () async {
    final storage = MemoryStorage();
    final events = <String>[];
    final dio = Dio();
    dio.httpClientAdapter = FakeAdapter((o) {
      events.add(o.path);
      if (o.path.endsWith('/login'))
        return jsonBody({'access_token': 'test-token'});
      if (o.path == '/auth/me')
        return jsonBody({
          'id': 9,
          'id_tenant': 2,
          'full_name': 'Cliente',
          'email': 'cliente@example.test',
          'is_active': true,
          'roles': [],
        });
      return jsonBody({'success': true});
    });
    final auth = AuthProvider(AuthRepository(AuthService(dio)), storage);
    auth.beforeSignOut = () async {
      expect(storage.token, 'test-token');
      events.add('baja-push');
    };
    expect(await auth.signIn('cliente@example.test', 'test'), isTrue);
    expect(auth.user!.idTenant, 2);
    expect(auth.user!.id, 9);
    await auth.signOut();
    expect(auth.isAuthenticated, isFalse);
    expect(storage.token, isNull);
    expect(
      events.indexOf('baja-push'),
      lessThan(events.indexOf('/auth/logout')),
    );
  });

  test(
    'No conserva una sesión parcial cuando falla la lectura del perfil',
    () async {
      final storage = MemoryStorage();
      final dio = Dio();
      dio.httpClientAdapter = FakeAdapter(
        (o) => o.path.endsWith('/login')
            ? jsonBody({'access_token': 'test-token'})
            : jsonBody({'detail': 'Sesión inválida'}, 401),
      );
      final auth = AuthProvider(AuthRepository(AuthService(dio)), storage);
      expect(await auth.signIn('cliente@example.test', 'test'), isFalse);
      expect(auth.user, isNull);
      expect(storage.token, isNull);
    },
  );

  test(
    'Sin Firebase se puede iniciar/cerrar sesión sin registrar tokens',
    () async {
      SharedPreferences.setMockInitialValues({});
      final dio = Dio();
      dio.httpClientAdapter = FakeAdapter(
        (_) => throw StateError('No debe llamar a la API'),
      );
      final push = PushService(dio);
      await push.initialize();
      await push.sessionChanged('1:9');
      await push.activate();
      expect(push.ready, isFalse);
      expect(push.enabled, isFalse);
      await push.disable();
      await push.sessionChanged(null);
      expect(push.enabled, isFalse);
      push.dispose();
    },
  );
}
