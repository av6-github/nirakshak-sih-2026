import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme.dart';
import 'screens/citizen_home_screen.dart';
import 'screens/complaint_screen.dart';
import 'screens/compliance_result_screen.dart';
import 'screens/login_screen.dart';
import 'screens/officer_dashboard_screen.dart';
import 'screens/scan_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: NirikshakApp()));
}

final _router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const CitizenHomeScreen(),
    ),
    GoRoute(
      path: '/scan',
      builder: (context, state) => const ScanScreen(),
    ),
    GoRoute(
      path: '/result',
      builder: (context, state) {
        final result = (state.extra as Map<String, dynamic>?) ?? {};
        return ComplianceResultScreen(result: result);
      },
    ),
    GoRoute(
      path: '/officer',
      builder: (context, state) => const OfficerDashboardScreen(),
    ),
    GoRoute(
      path: '/complaint',
      builder: (context, state) => const ComplaintScreen(),
    ),
  ],
);

class NirikshakApp extends StatelessWidget {
  const NirikshakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'NIRIKSHAK AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: _router,
    );
  }
}
