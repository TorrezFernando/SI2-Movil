import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'operaciones_service.dart';

class PushService extends ChangeNotifier {
  PushService(this._dio);
  final Dio _dio;
  final messages = StreamController<RemoteMessage>.broadcast();
  final opened = StreamController<void>.broadcast();
  StreamSubscription<String>? _refresh;
  StreamSubscription<RemoteMessage>? _foreground, _opened;
  FirebaseMessaging? _messaging;
  int? _registration;
  String? _session;
  String? _device;
  int _generation = 0;
  Future<void> _pending = Future.value();
  Future<void> _activation = Future.value();
  bool enabled = false;
  bool busy = false;
  bool ready = false;
  bool pendingOpen = false;
  bool _disabling = false;
  String status =
      'Notificaciones sin configurar. El resto de la app está disponible.';

  Future<void> initialize() async {
    if (kIsWeb ||
        ![
          TargetPlatform.android,
          TargetPlatform.iOS,
        ].contains(defaultTargetPlatform)) {
      status = 'Las notificaciones de esta versión están disponibles en Android/iOS.';
      return;
    }
    const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
    const appId = String.fromEnvironment('FIREBASE_APP_ID');
    const sender = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
    const project = String.fromEnvironment('FIREBASE_PROJECT_ID');
    const useNativeConfig = bool.fromEnvironment('ENABLE_FIREBASE');
    final hasOptions = [
      apiKey,
      appId,
      sender,
      project,
    ].every((v) => v.isNotEmpty);
    if (!useNativeConfig && !hasOptions) return;
    try {
      await Firebase.initializeApp(
        options: hasOptions
            ? const FirebaseOptions(
                apiKey: apiKey,
                appId: appId,
                messagingSenderId: sender,
                projectId: project,
                iosBundleId: String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID'),
              )
            : null,
      );
      _messaging = FirebaseMessaging.instance;
      // No registrar un dispositivo antes de que el usuario lo active.
      await _messaging!.setAutoInitEnabled(false);
      // El backend usa registration tokens con Firebase Admin, no FID.
      // ignore: deprecated_member_use
      _refresh = _messaging!.onTokenRefresh.listen((token) {
        if (enabled && _session != null) _queueRegister(token);
      });
      _foreground = FirebaseMessaging.onMessage.listen((message) {
        if (enabled && _session != null) messages.add(message);
      });
      _opened = FirebaseMessaging.onMessageOpenedApp.listen((_) {
        pendingOpen = true;
        opened.add(null);
      });
      pendingOpen = await _messaging!.getInitialMessage() != null;
      ready = true;
      status =
          'Puedes activar los recordatorios de cuotas en este dispositivo.';
    } catch (_) {
      status =
          'No se pudo iniciar Firebase. Revisa la configuración de esta app.';
    }
  }

  Future<void> sessionChanged(String? identity) async {
    if (_session == identity) return;
    _generation++;
    _session = identity;
    enabled = false;
    _registration = null;
    if (identity != null && ready) {
      final prefs = await SharedPreferences.getInstance();
      if (_session == identity && prefs.getBool('push:$identity') == true) {
        await activate();
      }
    }
    notifyListeners();
  }

  Future<String> _deviceId() async {
    if (_device != null) return _device!;
    final prefs = await SharedPreferences.getInstance();
    _device = prefs.getString('push_device');
    if (_device == null) {
      _device = List.generate(
        24,
        (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'),
      ).join();
      await prefs.setString('push_device', _device!);
    }
    return _device!;
  }

  Future<void> activate() {
    if (busy || _disabling) return _activation;
    return _activation = _activate();
  }

  Future<void> _activate() async {
    if (!ready || _session == null || busy) return;
    busy = true;
    notifyListeners();
    final generation = _generation;
    try {
      final settings = await _messaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (generation != _generation) return;
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        status =
            'Permiso denegado. Puedes habilitarlo en los ajustes del teléfono.';
        return;
      }
      await _messaging!.setAutoInitEnabled(true);
      // Compatibilidad con messaging.Message(token=...) del backend.
      // ignore: deprecated_member_use
      final token = await _messaging!.getToken();
      if (generation != _generation) return;
      if (token == null) {
        status =
            'El dispositivo aún no tiene token. Intenta activar nuevamente.';
        return;
      }
      enabled = true;
      await _queueRegister(token);
      if (generation == _generation && _registration != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('push:$_session', true);
      }
    } catch (e) {
      status = mensajeOperacion(e);
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> _queueRegister(String token) {
    final generation = _generation;
    _pending = _pending.then((_) async {
      if (generation != _generation || !enabled) return;
      try {
        final device = await _deviceId();
        if (generation != _generation) return;
        final response = await _dio.put<Map<String, dynamic>>(
          '/api/notificaciones/tokens',
          data: {
            'dispositivo': device,
            'token': token,
            'plataforma': defaultTargetPlatform == TargetPlatform.iOS
                ? 'ios'
                : 'android',
          },
          options: Options(extra: {'skipUnauthorizedLogout': true}),
        );
        // disable() espera esta cola antes de dar de baja el registro.
        _registration = response.data!['id'] as int;
        if (generation == _generation) {
          status = 'Recordatorios activados en este dispositivo.';
        }
      } catch (e) {
        if (generation == _generation) {
          enabled = false;
          status = mensajeOperacion(e);
        }
      }
      notifyListeners();
    });
    return _pending;
  }

  Future<void> disable() async {
    if (!ready) return;
    _disabling = true;
    final identity = _session;
    _generation++;
    enabled = false;
    busy = true;
    notifyListeners();
    bool failed = false;
    try {
      await _activation;
      await _pending;
      // Recuperar el registro tras reiniciar la app, incluso si no se activó.
      if (_registration == null && identity != null && ready) {
        try {
          final device = await _deviceId();
          final response = await _dio.get<List<dynamic>>(
            '/api/notificaciones/tokens',
            options: Options(extra: {'skipUnauthorizedLogout': true}),
          );
          for (final row in response.data!) {
            if (row['dispositivo'] == device) _registration = row['id'] as int;
          }
        } catch (_) {
          failed = true;
        }
      }
      if (_registration != null) {
        try {
          await _dio.delete(
            '/api/notificaciones/tokens/$_registration',
            options: Options(extra: {'skipUnauthorizedLogout': true}),
          );
          _registration = null;
        } catch (_) {
          failed = true;
        }
      }
      if (_messaging != null) {
        await _messaging!.setAutoInitEnabled(false);
        // Revocar el registration token usado por esta versión del backend.
        // ignore: deprecated_member_use
        await _messaging!.deleteToken();
      }
    } catch (_) {
      failed = true;
    } finally {
      if (identity != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('push:$identity');
      }
      pendingOpen = false;
      busy = false;
      _disabling = false;
      status = failed
          ? 'No se pudo completar la baja. Revisa la conexión; puedes desactivar el permiso en los ajustes del teléfono.'
          : 'Notificaciones desactivadas.';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _refresh?.cancel();
    _foreground?.cancel();
    _opened?.cancel();
    messages.close();
    opened.close();
    super.dispose();
  }
}
