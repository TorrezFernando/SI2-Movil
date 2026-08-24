import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/router.dart';
import 'core/config/api_constants.dart';
import 'data/network/auth_interceptor.dart';
import 'data/repositories/auth_repository.dart';
import 'data/services/auth_service.dart';
import 'data/services/secure_storage_service.dart';
import 'presentation/providers/auth_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = SecureStorageService();
  late AuthProvider auth;
  final dio = Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    headers: {'Content-Type': 'application/json'},
  ));
  final service = AuthService(dio);
  auth = AuthProvider(AuthRepository(service), storage);
  dio.interceptors.add(AuthInterceptor(storage, auth.signOut));
  await auth.restoreSession();
  runApp(InmobiliariaApp(auth: auth));
}

class InmobiliariaApp extends StatelessWidget {
  const InmobiliariaApp({required this.auth, super.key});

  final AuthProvider auth;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider.value(
        value: auth,
        child: MaterialApp.router(
          title: 'Inmobiliaria',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xff0e7490),
              brightness: Brightness.light,
            ),
            useMaterial3: true,
            inputDecorationTheme: const InputDecorationTheme(
              border: OutlineInputBorder(),
            ),
          ),
          routerConfig: createRouter(auth),
        ),
      );
}
