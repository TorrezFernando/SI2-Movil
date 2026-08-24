import 'package:go_router/go_router.dart';
import '../presentation/providers/auth_provider.dart';
import '../presentation/screens/login_screen.dart';
import '../presentation/screens/profile_screen.dart';

GoRouter createRouter(AuthProvider auth) => GoRouter(
      initialLocation: '/profile',
      refreshListenable: auth,
      redirect: (context, state) {
        final onLogin = state.matchedLocation == '/login';
        if (!auth.isAuthenticated && !onLogin) return '/login';
        if (auth.isAuthenticated && onLogin) return '/profile';
        return null;
      },
      routes: [
        GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
        GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
      ],
    );