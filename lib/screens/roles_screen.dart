import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// THEME
// ─────────────────────────────────────────────────────────────────────────────

const _kGreen = Color(0xFF1B6B3A);
const _kGreenDark = Color(0xFF145229);
const _kBg = Color(0xFFF7F9F7);
const _kSurface = Colors.white;
const _kTextPrimary = Color(0xFF111827);
const _kTextSecondary = Color(0xFF6B7280);
const _kBorder = Color(0xFFE5E7EB);
const _kShadow = Color(0x0D000000);
const _kHover = Color(0xFFF0FAF4);

// ─────────────────────────────────────────────────────────────────────────────
// MODEL
// ─────────────────────────────────────────────────────────────────────────────

class RoleModel {
  final String id;
  final Map<String, dynamic> permissions;

  const RoleModel({
    required this.id,
    required this.permissions,
  });

  factory RoleModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return RoleModel(
      id: doc.id,
      permissions: Map<String, dynamic>.from(
        data['permissions'] ?? {},
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class RolesScreen extends StatefulWidget {
  const RolesScreen({super.key});

  @override
  State<RolesScreen> createState() => _RolesScreenState();
}

class _RolesScreenState extends State<RolesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ───────────────────────────────────────────────────────────────────────────
  // FETCH ROLES
  // ───────────────────────────────────────────────────────────────────────────

  Stream<List<RoleModel>> _streamRoles() {
    return _firestore.collection('roles').snapshots().map(
          (snapshot) {
        return snapshot.docs
            .map((doc) => RoleModel.fromDoc(doc))
            .toList();
      },
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // ADD ROLE
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> _showAddRoleDialog() async {
    final controller = TextEditingController();

    bool canApproveMembership = false;
    bool canChat = false;
    bool canPostAlerts = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: const Text(
                'Add Role',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: controller,
                        decoration: InputDecoration(
                          hintText: 'Role name',
                          filled: true,
                          fillColor: const Color(0xFFF9FAFB),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                            const BorderSide(color: _kBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                            const BorderSide(color: _kBorder),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      CheckboxListTile(
                        value: canApproveMembership,
                        activeColor: _kGreen,
                        title:
                        const Text('Can Approve Membership'),
                        onChanged: (v) {
                          setModalState(() {
                            canApproveMembership = v ?? false;
                          });
                        },
                      ),

                      CheckboxListTile(
                        value: canChat,
                        activeColor: _kGreen,
                        title: const Text('Can Chat'),
                        onChanged: (v) {
                          setModalState(() {
                            canChat = v ?? false;
                          });
                        },
                      ),

                      CheckboxListTile(
                        value: canPostAlerts,
                        activeColor: _kGreen,
                        title: const Text('Can Post Alerts'),
                        onChanged: (v) {
                          setModalState(() {
                            canPostAlerts = v ?? false;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: _kTextSecondary),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kGreen,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    final roleName =
                    controller.text.trim().toLowerCase();

                    if (roleName.isEmpty) return;

                    await _firestore
                        .collection('roles')
                        .doc(roleName)
                        .set({
                      'permissions': {
                        'can_approve_membership':
                        canApproveMembership,
                        'can_chat': canChat,
                        'can_post_alerts': canPostAlerts,
                      },
                    });

                    if (mounted) {
                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Role added successfully'),
                        ),
                      );
                    }
                  },
                  child: const Text('Add Role'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // DELETE ROLE
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> _deleteRole(RoleModel role) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text('Delete Role'),
          content: Text(
            'Are you sure you want to delete "${role.id}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    ) ??
        false;

    if (!confirmed) return;

    await _firestore.collection('roles').doc(role.id).delete();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Role deleted successfully'),
        ),
      );
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // UI
  // ───────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,

      appBar: AppBar(
        backgroundColor: _kSurface,
        elevation: 0,
        title: const Text(
          'Roles Management',
          style: TextStyle(
            color: _kTextPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _kGreen,
        foregroundColor: Colors.white,
        onPressed: _showAddRoleDialog,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Role'),
      ),

      body: StreamBuilder<List<RoleModel>>(
        stream: _streamRoles(),
        builder: (context, snapshot) {
          // Loading
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: _kGreen,
              ),
            );
          }

          // Error
          if (snapshot.hasError) {
            return Center(
              child: Text(
                snapshot.error.toString(),
                style: const TextStyle(
                  color: Colors.red,
                ),
              ),
            );
          }

          final roles = snapshot.data ?? [];

          // Empty
          if (roles.isEmpty) {
            return const Center(
              child: Text(
                'No roles found',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _kTextSecondary,
                ),
              ),
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final gridCount = constraints.maxWidth > 1200
                  ? 4
                  : constraints.maxWidth > 900
                  ? 3
                  : constraints.maxWidth > 600
                  ? 2
                  : 1;

              return GridView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: roles.length,
                gridDelegate:
                SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: gridCount,
                  crossAxisSpacing: 18,
                  mainAxisSpacing: 18,
                  childAspectRatio: 1.15,
                ),
                itemBuilder: (_, index) {
                  final role = roles[index];

                  return _RoleCard(
                    role: role,
                    onDelete: () => _deleteRole(role),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ROLE CARD
// ─────────────────────────────────────────────────────────────────────────────

class _RoleCard extends StatefulWidget {
  final RoleModel role;
  final VoidCallback onDelete;

  const _RoleCard({
    required this.role,
    required this.onDelete,
  });

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final role = widget.role;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),

      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),

        padding: const EdgeInsets.all(22),

        decoration: BoxDecoration(
          color: _hovered ? _kHover : _kSurface,
          borderRadius: BorderRadius.circular(20),

          border: Border.all(
            color: _hovered
                ? _kGreen.withOpacity(0.30)
                : _kBorder,
          ),

          boxShadow: [
            BoxShadow(
              color: _hovered
                  ? _kGreen.withOpacity(0.08)
                  : _kShadow,
              blurRadius: _hovered ? 12 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _kGreen.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.security_rounded,
                    color: _kGreen,
                    size: 28,
                  ),
                ),

                const Spacer(),

                IconButton(
                  onPressed: widget.onDelete,
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.red,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            Text(
              role.id.toUpperCase(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: _kTextPrimary,
                letterSpacing: -0.4,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'Role Permissions',
              style: TextStyle(
                fontSize: 13,
                color: _kTextSecondary,
              ),
            ),

            const SizedBox(height: 18),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: role.permissions.entries.map((e) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _PermissionTile(
                        title: e.key,
                        enabled: e.value == true,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PERMISSION TILE
// ─────────────────────────────────────────────────────────────────────────────

class _PermissionTile extends StatelessWidget {
  final String title;
  final bool enabled;

  const _PermissionTile({
    required this.title,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: enabled
            ? _kGreen.withOpacity(0.08)
            : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: enabled
              ? _kGreen.withOpacity(0.18)
              : _kBorder,
        ),
      ),
      child: Row(
        children: [
          Icon(
            enabled
                ? Icons.check_circle_rounded
                : Icons.cancel_rounded,
            size: 18,
            color: enabled ? _kGreen : Colors.red,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              title.replaceAll('_', ' ').toUpperCase(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _kTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}