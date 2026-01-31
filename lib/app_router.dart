import 'dart:async';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
// Correção dos imports para os caminhos corretos dos ficheiros
import 'screens/device_screen.dart';
import 'screens/admin_device_list_screen.dart';
import 'screens/admin/admin_screen.dart'; // Corrigido
import 'screens/chat/conversation_list_screen.dart'; // Corrigido
import 'screens/chat/chat_screen.dart';
import 'screens/groups/create_group_screen.dart';
import 'screens/groups/group_detail_screen.dart';
import 'screens/groups/group_list_screen.dart'; // Corrigido
import 'screens/home_screen.dart';
import 'screens/legal/legal_acceptance_screen.dart';
// import 'screens/legal/legal_details_screen.dart'; // Removido - ficheiro não existe
import 'screens/login_screen.dart';
import 'screens/onboarding/onboarding_screen.dart'; // Corrigido
import 'screens/register_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/settings_screen.dart';
import 'services/auth_service.dart';

// Classe auxiliar para converter um Stream num Listenable, necessário para o GoRouter
class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class AppRouter {
  final AuthService authService;
  final bool hasSeenOnboarding;

  AppRouter({required this.authService, required this.hasSeenOnboarding});

  late final GoRouter router = GoRouter(
    initialLocation: hasSeenOnboarding ? '/' : '/onboarding',
    refreshListenable: _GoRouterRefreshStream(
      authService.authStateChanges,
    ), // Corrigido
    observers: [
      FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
    ],
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) {
          return HomeScreen(isAdmin: true);
        },
        routes: <RouteBase>[
          GoRoute(
            path: 'device/:id',
            builder: (BuildContext context, GoRouterState state) {
              final id = state.pathParameters['id']!;
              return DeviceScreen(id: id);
            },
          ),
          GoRoute(
            path: 'admin-devices',
            builder: (BuildContext context, GoRouterState state) =>
                const AdminDeviceListScreen(),
          ),
          GoRoute(
            path: 'admin',
            builder: (BuildContext context, GoRouterState state) =>
                const AdminScreen(), // Corrigido
          ),
          GoRoute(
            path: 'chat',
            builder: (BuildContext context, GoRouterState state) =>
                const ConversationListScreen(), // Corrigido
            routes: [
              GoRoute(
                path: ':id',
                builder: (BuildContext context, GoRouterState state) =>
                    ChatScreen(conversationId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: 'groups',
            builder: (BuildContext context, GoRouterState state) =>
                const GroupListScreen(), // Corrigido
            routes: [
              GoRoute(
                path: 'create',
                builder: (BuildContext context, GoRouterState state) =>
                    const CreateGroupScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (BuildContext context, GoRouterState state) =>
                    GroupDetailScreen(groupId: state.pathParameters['id']!),
                routes: [
                  //  GoRoute(
                  //   path: 'manage-devices',
                  //   builder: (BuildContext context, GoRouterState state) => ManageDevicesScreen(groupId: state.pathParameters['id']!),
                  // ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: 'legal-acceptance',
            builder: (BuildContext context, GoRouterState state) =>
                const LegalAcceptanceScreen(),
          ),
          // Rota removida porque o ecrã não existe
          // GoRoute(
          //   path: 'legal/:docType',
          //   builder: (BuildContext context, GoRouterState state) => LegalDetailsScreen(docType: state.pathParameters['docType']!),
          // ),
          GoRoute(
            path: 'scan',
            builder: (BuildContext context, GoRouterState state) =>
                const ScanScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (BuildContext context, GoRouterState state) =>
                const SettingsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/onboarding',
        builder: (BuildContext context, GoRouterState state) {
          return const OnboardingScreen();
        },
      ),
      GoRoute(
        path: '/login',
        builder: (BuildContext context, GoRouterState state) {
          return const LoginScreen();
        },
      ),
      GoRoute(
        path: '/register',
        builder: (BuildContext context, GoRouterState state) {
          return const RegisterScreen();
        },
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      // Corrigido: Aceder ao utilizador atual através do getter público do AuthService
      final bool loggedIn = authService.currentUser != null;
      final bool isLoggingIn =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (!hasSeenOnboarding && state.matchedLocation != '/onboarding') {
        return '/onboarding';
      }

      if (loggedIn && isLoggingIn) {
        return '/';
      }

      if (!loggedIn && !isLoggingIn && state.matchedLocation != '/onboarding') {
        return '/login';
      }

      return null;
    },
  );
}
