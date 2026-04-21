import 'package:flutter/material.dart';
import 'package:mukamal_pakistan_admin/dashboard_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardService _service = DashboardService();

  int totalMembers = 0;
  int pendingApplications = 0;
  int approvedToday = 0;
  int activeChats = 0;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    totalMembers = await _service.getTotalMembers();
    pendingApplications = await _service.getPendingApplications();
    approvedToday = await _service.getApprovedToday();
    activeChats = await _service.getActiveChats();

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Overview",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),

        const SizedBox(height: 20),

        Row(
          children: [
            _card("Members", totalMembers, Icons.people),
            _card("Pending", pendingApplications, Icons.assignment),
            _card("Approved Today", approvedToday, Icons.check),
            _card("Chats", activeChats, Icons.chat),
          ],
        ),
      ],
    );
  }

  Widget _card(String title, int value, IconData icon) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 30, color: Colors.green),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title),
                Text("$value",
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            )
          ],
        ),
      ),
    );
  }
}