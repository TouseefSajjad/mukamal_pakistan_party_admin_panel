import 'package:flutter/material.dart';
import 'package:mukamal_pakistan_admin/Settings/settings_screen.dart';
import 'package:mukamal_pakistan_admin/dashboard/dashboard_screen.dart';
import 'package:mukamal_pakistan_admin/features/alerts/screens/alerts_screen.dart';
import 'package:mukamal_pakistan_admin/features/applications/screens/applications_list_screen.dart';
import 'package:mukamal_pakistan_admin/features/members/screens/members_screen.dart';
import 'package:mukamal_pakistan_admin/layout/sidebar.dart';
import 'package:mukamal_pakistan_admin/layout/topbar.dart';

class AdminScaffold extends StatefulWidget {
  const AdminScaffold({super.key});

  @override
  State<AdminScaffold> createState() => _AdminScaffoldState();
}

class _AdminScaffoldState extends State<AdminScaffold> {
  int selectedIndex = 0;

  final List<Widget> screens = [
    DashboardScreen(),
    MembersScreen(),
    ApplicationsListScreen(),
    AlertsScreen(),
    SettingsScreen(),
  ];

  void onItemSelected(int index) {
    setState(() => selectedIndex = index);
  }

  String getTitle() {
    switch (selectedIndex) {
      case 0:
        return "Dashboard";
      case 1:
        return "Members";
      case 2:
        return "Applications";
      case 3:
        return "Alerts";
      case 4:
        return "Settings";
      default:
        return "Admin Panel";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Sidebar(
            selectedIndex: selectedIndex,
            onItemSelected: onItemSelected,
          ),
          Expanded(
            child: Column(
              children: [
                Topbar(title: getTitle()),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    color: Colors.grey.shade100,
                    child: screens[selectedIndex],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}