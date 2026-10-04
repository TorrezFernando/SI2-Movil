import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/models/propiedad_model.dart';
import '../presentation/providers/auth_provider.dart';
import '../presentation/screens/login_screen.dart';
import '../presentation/screens/register_screen.dart';
import '../presentation/screens/forgot_password_screen.dart';
import '../presentation/screens/profile_screen.dart';
import '../presentation/screens/catalogo_screen.dart';
import '../presentation/screens/main_screen.dart';
import '../presentation/screens/map_screen.dart';
import '../presentation/screens/propiedad_detalle_screen.dart';
import '../presentation/screens/agendar_visita_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorCatKey = GlobalKey<NavigatorState>(debugLabel: 'catalogo');
final _shellNavigatorMapKey = GlobalKey<NavigatorState>(debugLabel: 'mapa');
final _shellNavigatorProfKey = GlobalKey<NavigatorState>(debugLabel: 'perfil');

GoRouter createRouter(AuthProvider auth) => GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/catalogo',
      refreshListenable: auth,
      redirect: (context, state) {
        final onLoginOrRegister = state.matchedLocation == '/login' || state.matchedLocation == '/register' || state.matchedLocation == '/forgot-password';
        if (!auth.isAuthenticated && !onLoginOrRegister) return '/login';
        if (auth.isAuthenticated && onLoginOrRegister) return '/catalogo';
        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (_, _) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (_, _) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (_, _) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: '/propiedad-detalle',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            final prop = state.extra as PropiedadModel;
            return PropiedadDetalleScreen(propiedad: prop);
          },
        ),
        GoRoute(
          path: '/agendar-visita',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            final prop = state.extra as PropiedadModel;
            return AgendarVisitaScreen(propiedad: prop);
          },
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return MainScreen(navigationShell: navigationShell);
          },
          branches: [
            StatefulShellBranch(
              navigatorKey: _shellNavigatorCatKey,
              routes: [
                GoRoute(
                  path: '/catalogo',
                  builder: (context, state) => const CatalogoScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              navigatorKey: _shellNavigatorMapKey,
              routes: [
                GoRoute(
                  path: '/mapa',
                  builder: (context, state) => const MapScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              navigatorKey: _shellNavigatorProfKey,
              routes: [
                GoRoute(
                  path: '/profile',
                  builder: (context, state) => const ProfileScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    );