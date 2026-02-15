import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:myapp/core/app_theme.dart';
import 'package:myapp/providers/analytics_provider.dart';
import 'package:myapp/services/battery_level_history/battery_level.dart';
import 'package:myapp/services/user_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/admin_service.dart';
import 'services/firebase_service.dart';
import 'services/group_service.dart';
import 'services/uplink_processing_service.dart';
import 'routing/app_router.dart';
import 'providers/theme_provider.dart';
import 'providers/device_provider.dart';
import 'providers/group_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/user_provider.dart';
import 'providers/search_provider.dart';
import 'providers/settings_provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  BatteryLevelService.start();
  await EasyLocalization.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
    name: 'Pager1',
  );
  BatteryTracker.startTracking();
  final prefs = await SharedPreferences.getInstance();
  final bool hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
  final authService = AuthService();
  await authService.initGoogle();

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en'),
        Locale('ur'),
        Locale('ar'),
        Locale('pt'),
        Locale('zh'),
        Locale('ru'),
        Locale('es'),
        Locale('fr'),
        Locale('de'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: MyApp(hasSeenOnboarding: hasSeenOnboarding),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool hasSeenOnboarding;

  const MyApp({super.key, required this.hasSeenOnboarding});

  @override
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Serviços de Baixo Nível (sem dependências na UI)
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<FirebaseService>(create: (_) => FirebaseService()),
        // Serviço de background para processar uplinks
        Provider<UplinkProcessingService>(
          create: (_) => UplinkProcessingService(),
          lazy: false, // Ensure that the service is created immediately.
        ),
        // Serviços de Dados e Lógica de Negócios
        ChangeNotifierProvider<AdminService>(create: (_) => AdminService()),
        Provider(create: (_) => UserService()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        // Providers de Estado da UI
        ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
        ChangeNotifierProvider<SettingsProvider>(
          create: (_) => SettingsProvider(),
        ),
        ChangeNotifierProvider<DeviceProvider>(create: (_) => DeviceProvider()),
        ChangeNotifierProvider<GroupProvider>(create: (_) => GroupProvider()),
        ChangeNotifierProvider<UserProvider>(create: (_) => UserProvider()),
        ChangeNotifierProvider<SearchProvider>(create: (_) => SearchProvider()),
        ChangeNotifierProvider(
          create: (_) => AnalyticsProvider()..listenAnalytics(),
        ),
        // Providers com Dependências (ProxyProviders)
        StreamProvider<User?>(
          create: (context) => context.read<AuthService>().authStateChanges,
          initialData: null,
        ),
        ChangeNotifierProxyProvider2<AuthService, AdminService, GroupService>(
          create: (context) => GroupService(
            context.read<AuthService>(),
            context.read<AdminService>(),
          ),
          update: (context, authService, adminService, previous) =>
              previous ?? GroupService(authService, adminService),
        ),
        ChangeNotifierProxyProvider3<
          UserProvider,
          SettingsProvider,
          AdminService,
          ChatProvider
        >(
          create: (context) => ChatProvider(
            context.read<UserProvider>(),
            context.read<SettingsProvider>(),
            context.read<AdminService>(),
          ),
          update:
              (
                context,
                userProvider,
                settingsProvider,
                adminService,
                previous,
              ) =>
                  previous ??
                  ChatProvider(userProvider, settingsProvider, adminService),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          final appRouter = AppRouter(
            authService: context.read<AuthService>(),
            hasSeenOnboarding: hasSeenOnboarding,
          );

          return ScreenUtilInit(
            designSize: const Size(375, 812),
            minTextAdapt: true,
            splitScreenMode: true,
            builder: (context, child) {
              return MaterialApp.router(
                title: 'My App',
                theme: lightTheme,
                darkTheme: darkTheme,
                locale: context.locale,
                supportedLocales: context.supportedLocales,
                localizationsDelegates: context.localizationDelegates,
                themeMode: themeProvider.themeMode,
                debugShowCheckedModeBanner: false,
                routerConfig: appRouter.router,
              );
            },
          );
        },
      ),
    );
  }
}
