import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mukamal_pakistan_admin/features/alerts/%20services/alert_service.dart';

import 'package:mukamal_pakistan_admin/theme.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final AlertService _service = AlertService();

  final titleCtrl = TextEditingController();
  final msgCtrl = TextEditingController();

  List<String> selectedRoles = ['member'];
  bool loading = false;

  void clear() {
    titleCtrl.clear();
    msgCtrl.clear();
    selectedRoles = ['member'];
  }

  Future<void> createAlertDialog() async {
    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Create Alert"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: "Title"),
                  ),
                  TextField(
                    controller: msgCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: "Message"),
                  ),
                  const SizedBox(height: 10),

                  Wrap(
                    spacing: 8,
                    children: ['member', 'vc', 'admin'].map((role) {
                      final selected = selectedRoles.contains(role);

                      return FilterChip(
                        label: Text(role.toUpperCase()),
                        selected: selected,
                        selectedColor: AppTheme.primaryGreen.withOpacity(0.3),
                        onSelected: (val) {
                          setStateDialog(() {
                            if (val) {
                              selectedRoles.add(role);
                            } else {
                              selectedRoles.remove(role);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (titleCtrl.text.isEmpty || msgCtrl.text.isEmpty) return;

                    await _service.createAlert(
                      title: titleCtrl.text,
                      message: msgCtrl.text,
                      visibleTo: selectedRoles,
                      adminId: "admin_uid_here",
                    );

                    clear();
                    Navigator.pop(context);
                  },
                  child: const Text("Publish"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget buildCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final active = data['active'] ?? true;

    return Card(
      child: ListTile(
        leading: Icon(
          Icons.campaign,
          color: active ? Colors.green : Colors.grey,
        ),
        title: Text(data['title'] ?? ''),
        subtitle: Text(data['message'] ?? ''),
        trailing: PopupMenuButton(
          onSelected: (value) async {
            if (value == 'toggle') {
              await _service.toggleAlert(doc.id, !active);
            }
            if (value == 'delete') {
              await _service.deleteAlert(doc.id);
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'toggle',
              child: Text(active ? "Deactivate" : "Activate"),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Text("Delete"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Alerts Management"),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: createAlertDialog,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _service.getAlerts(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          return ListView(
            padding: const EdgeInsets.all(12),
            children: docs.map(buildCard).toList(),
          );
        },
      ),
    );
  }
}