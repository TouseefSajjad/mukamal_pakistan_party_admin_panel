import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:mukammal_pakistan_admin/screens/LOGIN.dart';
import 'config/app_routes.dart';
import 'config/app_theme.dart';
import 'firebase_options.dart';
import 'screens/banners_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/membership_applications_screen.dart';
import 'screens/roles_screen.dart';
import 'screens/users_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MukammalPakistanAdminApp());
}

class MukammalPakistanAdminApp extends StatelessWidget {
  const MukammalPakistanAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MPP Admin Panel',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.login,
      routes: {
        AppRoutes.login: (_) => const AdminLoginScreen(),
        AppRoutes.dashboard: (_) => const DashboardScreen(),
        AppRoutes.users: (_) => const UsersScreen(),
        AppRoutes.membershipApplications: (_) =>
        const MembershipApplicationsScreen(),
        AppRoutes.roles: (_) => const RolesScreen(),
        AppRoutes.banners: (_) => const BannersScreen(),
      },
    );
  }
}