import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:alu_startup_connect/core/theme/app_theme.dart';
import 'package:alu_startup_connect/features/onboarding/splash_screen.dart';
import 'package:alu_startup_connect/features/onboarding/onboarding_screen.dart';
import 'package:alu_startup_connect/features/onboarding/auth_screen.dart';
import 'package:alu_startup_connect/features/home/main_shell.dart';
import 'package:alu_startup_connect/features/profile/company_profile_screen.dart';
import 'package:alu_startup_connect/features/notifications/notifications_screen.dart';
import 'package:alu_startup_connect/features/onboarding/startup_pending_screen.dart';
import 'package:alu_startup_connect/features/admin/admin_dashboard.dart';

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (_, __) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (_, __) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/auth',
      builder: (_, __) => const AuthScreen(),
    ),
    GoRoute(
      path: '/main',
      builder: (_, __) => const MainShell(),
    ),
    GoRoute(
      path: '/company/:id',
      builder: (_, state) => CompanyProfileScreen(
        companyId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/notifications',
      builder: (_, __) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/pending',
      builder: (_, __) => const StartupDashboardScreen(),
    ),
    GoRoute(
      path: '/admin',
      builder: (_, __) => const AdminDashboard(),
    ),
  ],
);

class AluStartupConnectApp extends StatelessWidget {
  const AluStartupConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ALU Startup Connect',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: _router,
    );
  }
}