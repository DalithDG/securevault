import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/unlock_screen.dart';
import '../../features/generator/presentation/screens/generator_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/vault/presentation/screens/client_pages_screen.dart';
import '../../features/vault/presentation/screens/vault_home_screen.dart';
import '../widgets/app_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authControllerProvider);
  return GoRouter(
    initialLocation: auth.isLoggedIn ? '/unlock' : '/login',
    redirect: (context, state) {
      final loggedIn = ref.read(authControllerProvider).isLoggedIn;
      final onAuth =
          state.matchedLocation == '/login' || state.matchedLocation == '/register';
      if (!loggedIn && !onAuth) return '/login';
      if (loggedIn && onAuth) return '/unlock';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
      GoRoute(path: '/unlock', builder: (_, _) => const UnlockScreen()),
      ShellRoute(
        builder: (context, state, child) => AppShell(
          location: state.matchedLocation,
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/vault',
            builder: (_, _) => const VaultHomeScreen(),
          ),
          GoRoute(
            path: '/vault/client/:clientId',
            builder: (_, state) => ClientPagesScreen(
              clientId: state.pathParameters['clientId']!,
            ),
          ),
          GoRoute(
            path: '/generator',
            builder: (_, _) => const GeneratorScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (_, _) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
});
