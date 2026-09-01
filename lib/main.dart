import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:mukammal_pakistan_admin/Website/website_dashboard_screen.dart';
import 'package:mukammal_pakistan_admin/widgets/auth%20guard.dart';
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
        // Login stays unguarded — it's the one screen that's meant to be
        // reachable without a session.
        AppRoutes.login: (_) => const AdminLoginScreen(),

        // Every other route is wrapped in AuthGuard. Even if someone
        // pastes this route's URL directly into a browser with no
        // session, AuthGuard shows the login screen instead of the
        // real content.
        AppRoutes.dashboard: (_) =>
        const AuthGuard(child: DashboardScreen()),
        AppRoutes.users: (_) => const AuthGuard(child: UsersScreen()),
        AppRoutes.membershipApplications: (_) =>
        const AuthGuard(child: MembershipApplicationsScreen()),
        AppRoutes.roles: (_) => const AuthGuard(child: RolesScreen()),
        AppRoutes.banners: (_) => const AuthGuard(child: BannersScreen()),
        AppRoutes.manageWebsite: (_) =>
        const AuthGuard(child: WebsiteDashboardScreen()),
      },
    );
  }
}