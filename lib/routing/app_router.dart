import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Importar os novos ecrãs de admin
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/admin_user_management_screen.dart';
import '../screens/admin/admin_device_management_screen.dart';
import '../screens/admin/admin_device_detail_screen.dart';
import '../screens/admin/admin_reports_screen.dart';
import '../screens/admin/admin_device_map_screen.dart';
import '../screens/admin/admin_gateway_management_screen.dart';
import '../screens/admin/admin_uplink_feed_screen.dart';
import '../screens/admin/admin_group_management_screen.dart';
import '../screens/admin/admin_create_group_screen.dart';
import '../screens/admin/admin_group_detail_screen.dart';

// Outros imports
import '../screens/device_screen.dart';
import '../screens/chat/conversation_list_screen.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/groups/create_group_screen.dart';
import '../screens/group/group_details_screen.dart';
import '../screens/group/add_members_screen.dart'; // ROTA NOVA
import '../screens/groups/group_list_screen.dart';
import '../screens/home_screen.dart';
import '../screens/legal/legal_acceptance_screen.dart';
import '../screens/login_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/register_screen.dart';
import '../screens/scan_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/faq_screen.dart';

import '../services/auth_service.dart';

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
    refreshListenable: _GoRouterRefreshStream(authService.authStateChanges),
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) {
          return HomeScreen(isAdmin: false);
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
            path: 'admin',
            builder: (BuildContext context, GoRouterState state) =>
                const AdminDashboardScreen(),
            routes: [
              GoRoute(
                path: 'users',
                builder: (BuildContext context, GoRouterState state) =>
                    const AdminUserManagementScreen(),
              ),
              GoRoute(
                path: 'devices',
                builder: (BuildContext context, GoRouterState state) =>
                    const AdminDeviceManagementScreen(),
                routes: [
                  GoRoute(
                    path: ':deviceId',
                    builder: (BuildContext context, GoRouterState state) {
                      final deviceId = state.pathParameters['deviceId']!;
                      return AdminDeviceDetailScreen(deviceId: deviceId);
                    },
                  ),
                ],
              ),
              GoRoute(
                path: 'gateways',
                builder: (BuildContext context, GoRouterState state) =>
                    const AdminGatewayManagementScreen(),
              ),
              GoRoute(
                path: 'reports',
                builder: (BuildContext context, GoRouterState state) =>
                    const AdminReportsScreen(),
              ),
              GoRoute(
                path: 'map',
                builder: (BuildContext context, GoRouterState state) =>
                    const AdminDeviceMapScreen(),
              ),
              GoRoute(
                path: 'uplink-feed',
                builder: (BuildContext context, GoRouterState state) =>
                    const AdminUplinkFeedScreen(),
              ),
              GoRoute(
                path: 'groups',
                builder: (BuildContext context, GoRouterState state) =>
                    const AdminGroupManagementScreen(),
                routes: [
                  GoRoute(
                    path: 'create',
                    builder: (BuildContext context, GoRouterState state) =>
                        const AdminCreateGroupScreen(),
                  ),
                  GoRoute(
                    path: ':groupId',
                    builder: (BuildContext context, GoRouterState state) {
                      final groupId = state.pathParameters['groupId']!;
                      return AdminGroupDetailScreen(groupId: groupId);
                    },
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: 'chat',
            builder: (BuildContext context, GoRouterState state) =>
                const ConversationListScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (BuildContext context, GoRouterState state) =>
                    ChatScreen(conversationId: state.pathParameters['id']!),
                routes: [
                  GoRoute(
                    path: 'details',
                    builder: (BuildContext context, GoRouterState state) =>
                        GroupDetailsScreen(
                          groupId: state.pathParameters['id']!,
                        ),
                    routes: [
                      GoRoute(
                        path: 'add-members',
                        builder: (BuildContext context, GoRouterState state) =>
                            AddMembersScreen(
                              groupId: state.pathParameters['id']!,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: 'groups',
            builder: (BuildContext context, GoRouterState state) =>
                const GroupListScreen(),
            routes: [
              GoRoute(
                path: 'create',
                builder: (BuildContext context, GoRouterState state) =>
                    const CreateGroupScreen(),
              ),
            ],
          ),
          GoRoute(
            path: 'legal-acceptance',
            builder: (BuildContext context, GoRouterState state) =>
                const LegalAcceptanceScreen(),
          ),
          GoRoute(
            path: 'scan',
            builder: (BuildContext context, GoRouterState state) =>
                const ScanScreen(),
          ),
          GoRoute(
            path: 'settings',
            builder: (BuildContext context, GoRouterState state) =>
                const SettingsScreen(),
          ),
          GoRoute(
            path: 'faq',
            builder: (BuildContext context, GoRouterState state) =>
                const FaqScreen(),
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
