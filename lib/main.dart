import 'dart:async';

import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/router.dart';
import 'core/config/api_constants.dart';
import 'data/network/auth_interceptor.dart';
import 'data/repositories/auth_repository.dart';
import 'data/services/auth_service.dart';
import 'data/services/propiedades_service.dart';
import 'data/repositories/propiedades_repository.dart';
import 'data/services/secure_storage_service.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/propiedades_provider.dart';
import 'data/services/operaciones_service.dart';
import 'data/services/push_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = SecureStorageService();
  late AuthProvider auth;
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ),
  );
  final authService = AuthService(dio);
  final propiedadesService = PropiedadesService(dio);
  auth = AuthProvider(AuthRepository(authService), storage);
  final propiedadesProvider = PropiedadesProvider(
    PropiedadesRepository(propiedadesService),
  );
  dio.interceptors.add(AuthInterceptor(storage, auth.signOut));
  final push = PushService(dio);
  await push.initialize();
  auth.beforeSignOut = push.disable;
  await auth.restoreSession();
  runApp(
    InmobiliariaApp(
      auth: auth,
      propiedadesProvider: propiedadesProvider,
      operaciones: OperacionesService(dio),
      push: push,
    ),
  );
}

class InmobiliariaApp extends StatefulWidget {
  const InmobiliariaApp({
    required this.auth,
    required this.propiedadesProvider,
    required this.operaciones,
    required this.push,
    super.key,
  });

  final AuthProvider auth;
  final PropiedadesProvider propiedadesProvider;
  final OperacionesService operaciones;
  final PushService push;

  @override
  State<InmobiliariaApp> createState() => _InmobiliariaAppState();
}

class _InmobiliariaAppState extends State<InmobiliariaApp> {
  late final GoRouter _router;
  final _messenger = GlobalKey<ScaffoldMessengerState>();
  StreamSubscription? _messages, _opened;
  String? _identity;

  @override
  void initState() {
    super.initState();
    _router = createRouter(widget.auth);
    widget.auth.addListener(_sessionChanged);
    _messages = widget.push.messages.stream.listen((message) {
      if (!widget.auth.isAuthenticated) return;
      _messenger.currentState?.showSnackBar(
        SnackBar(
          content: Text(
            '${message.notification?.title ?? 'Recordatorio'}\n${message.notification?.body ?? 'Revisa tu estado de cuenta.'}',
          ),
          action: SnackBarAction(
            label: 'Ver cuenta',
            onPressed: () => _router.go('/cuenta'),
          ),
        ),
      );
    });
    _opened = widget.push.opened.stream.listen((_) => _openNotification());
    _sessionChanged();
  }

  void _sessionChanged() {
    final user = widget.auth.user;
    final identity = user == null ? null : '${user.idTenant}:${user.id}';
    if (_identity != identity) {
      _identity = identity;
      _messenger.currentState?.clearSnackBars();
      unawaited(widget.push.sessionChanged(identity));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _openNotification();
    });
  }

  void _openNotification() {
    if (widget.auth.isAuthenticated && widget.push.pendingOpen) {
      widget.push.pendingOpen = false;
      _router.go('/cuenta');
    }
  }

  @override
  void dispose() {
    widget.auth.removeListener(_sessionChanged);
    _messages?.cancel();
    _opened?.cancel();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: widget.auth),
      ChangeNotifierProvider.value(value: widget.propiedadesProvider),
      Provider.value(value: widget.operaciones),
      ChangeNotifierProvider.value(value: widget.push),
    ],
    child: MaterialApp.router(
      title: 'Inmobiliaria',
      scaffoldMessengerKey: _messenger,
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
      routerConfig: _router,
    ),
  );
}
