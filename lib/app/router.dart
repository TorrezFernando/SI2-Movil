import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../presentation/providers/auth_provider.dart';
import '../presentation/screens/login_screen.dart';
import '../presentation/screens/profile_screen.dart';
import '../presentation/screens/catalogo_screen.dart';
import '../presentation/screens/main_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorCatKey = GlobalKey<NavigatorState>(debugLabel: 'catalogo');
final _shellNavigatorProfKey = GlobalKey<NavigatorState>(debugLabel: 'perfil');

GoRouter createRouter(AuthProvider auth) => GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/catalogo',
      refreshListenable: auth,
      redirect: (context, state) {
        final onLogin = state.matchedLocation == '/login';
        if (!auth.isAuthenticated && !onLogin) return '/login';
        if (auth.isAuthenticated && onLogin) return '/catalogo';
        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (_, _) => const LoginScreen(),
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