import 'package:flutter/material.dart';
import 'package:mukammal_pakistan_admin/models/services/user_service.dart';
import '../models/app_user.dart';


// ── Theme ─────────────────────────────────────────────────────────────────────
const _kGreen = Color(0xFF1B6B3A);
const _kGreenDark = Color(0xFF145229);
const _kBg = Color(0xFFF7F9F7);
const _kSurface = Colors.white;
const _kTextPrimary = Color(0xFF111827);
const _kTextSecondary = Color(0xFF6B7280);
const _kBorder = Color(0xFFE5E7EB);
const _kShadow = Color(0x0D000000);
const _kHover = Color(0xFFF0FAF4);

// ── Filter options ────────────────────────────────────────────────────────────
enum _Filter {
  all,
  members,
  admins,
  moderators,
  approved,
  pending,
  rejected,
  online,
}

extension _FilterLabel on _Filter {
  String get label {
    switch (this) {
      case _Filter.all:        return 'All';
      case _Filter.members:    return 'Members';
      case _Filter.admins:     return 'Admins';
      case _Filter.moderators: return 'Moderators';
      case _Filter.approved:   return 'Approved';
      case _Filter.pending:    return 'Pending';
      case _Filter.rejected:   return 'Rejected';
      case _Filter.online:     return 'Online';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  _Filter _filter = _Filter.all;
  String _search = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Client-side filtering ─────────────────────────────────────────────────
  List<AppUser> _apply(List<AppUser> all) {
    List<AppUser> list = all;

    // Role / status / online filter
    switch (_filter) {
      case _Filter.members:
        list = list.where((u) => u.role == 'member').toList();
        break;
      case _Filter.admins:
        list = list.where((u) => u.role == 'admin').toList();
        break;
      case _Filter.moderators:
        list = list.where((u) => u.role == 'moderator').toList();
        break;
      case _Filter.approved:
        list = list.where((u) => u.membershipStatus == 'approved').toList();
        break;
      case _Filter.pending:
        list = list.where((u) => u.membershipStatus == 'pending').toList();
        break;
      case _Filter.rejected:
        list = list.where((u) => u.membershipStatus == 'rejected').toList();
        break;
      case _Filter.online:
        list = list.where((u) => u.isOnline).toList();
        break;
      case _Filter.all:
        break;
    }

    // Search filter
    final q = _search.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((u) {
        return u.name.toLowerCase().contains(q) ||
            u.email.toLowerCase().contains(q) ||
            u.phone.toLowerCase().contains(q);
      }).toList();
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: _buildAppBar(),
      body: StreamBuilder<List<AppUser>>(
        stream: UserService.instance.streamUsers(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const _LoadingState();
          }
          if (snap.hasError) {
            return _ErrorState(error: snap.error.toString());
          }
          final all = snap.data ?? [];
          final filtered = _apply(all);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats
              _StatsSection(users: all),
              // Search + Filters
              _SearchFilterBar(
                controller: _searchCtrl,
                currentFilter: _filter,
                onSearch: (v) => setState(() => _search = v),
                onFilter: (f) => setState(() => _filter = f),
              ),
              // List
              Expanded(
                child: filtered.isEmpty
                    ? const _EmptyState()
                    : _UsersList(
                  users: filtered,
                  onDelete: (u) => _confirmDelete(u),
                  onToggleBlock: (u) => _confirmBlock(u),
                  onRoleChange: (u, role) => _changeRole(u, role),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(64),
      child: Container(
        decoration: const BoxDecoration(
          color: _kSurface,
          border: Border(bottom: BorderSide(color: _kBorder)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _kGreen,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text('MP',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'User Management',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _kTextPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: _kGreen.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _kGreen.withOpacity(0.18)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.shield_outlined, color: _kGreen, size: 15),
                      SizedBox(width: 5),
                      Text('Admin',
                          style: TextStyle(
                              color: _kGreen,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Actions ───────────────────────────────────────────────────────────────
  void _confirmDelete(AppUser user) {
    showDialog(
      context: context,
      builder: (ctx) => _ConfirmDialog(
        title: 'Delete User',
        message:
        'Are you sure you want to permanently delete ${user.name.isEmpty ? "this user" : user.name}? This cannot be undone.',
        confirmLabel: 'Delete',
        confirmColor: const Color(0xFFEF4444),
        onConfirm: () async {
          Navigator.of(ctx).pop();
          try {
            await UserService.instance.deleteUser(user.uid);
            _snack('User deleted successfully', const Color(0xFF10B981));
          } catch (e) {
            _snack('Error: $e', const Color(0xFFEF4444));
          }
        },
      ),
    );
  }

  void _confirmBlock(AppUser user) {
    final blocking = !user.blocked;
    showDialog(
      context: context,
      builder: (ctx) => _ConfirmDialog(
        title: blocking ? 'Block User' : 'Unblock User',
        message: blocking
            ? 'Block ${user.name.isEmpty ? "this user" : user.name}? They will not be able to access the app.'
            : 'Unblock ${user.name.isEmpty ? "this user" : user.name}?',
        confirmLabel: blocking ? 'Block' : 'Unblock',
        confirmColor:
        blocking ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
        onConfirm: () async {
          Navigator.of(ctx).pop();
          try {
            await UserService.instance
                .setBlocked(user.uid, blocked: blocking);
            _snack(
              blocking
                  ? 'User blocked successfully'
                  : 'User unblocked successfully',
              blocking
                  ? const Color(0xFFF59E0B)
                  : const Color(0xFF10B981),
            );
          } catch (e) {
            _snack('Error: $e', const Color(0xFFEF4444));
          }
        },
      ),
    );
  }

  Future<void> _changeRole(AppUser user, String role) async {
    try {
      await UserService.instance.changeRole(user.uid, role);
      _snack('Role updated to $role', _kGreen);
    } catch (e) {
      _snack('Error: $e', const Color(0xFFEF4444));
    }
  }

  void _snack(String msg, Color bg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(
              fontWeight: FontWeight.w600, color: Colors.white)),
      backgroundColor: bg,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(20),
    ));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATS SECTION
// ─────────────────────────────────────────────────────────────────────────────

class _StatsSection extends StatelessWidget {
  final List<AppUser> users;
  const _StatsSection({required this.users});

  @override
  Widget build(BuildContext context) {
    final total = users.length;
    final online = users.where((u) => u.isOnline).length;
    final approved = users.where((u) => u.membershipStatus == 'approved').length;
    final pending = users.where((u) => u.membershipStatus == 'pending').length;
    final admins = users.where((u) => u.role == 'admin').length;
    final mods = users.where((u) => u.role == 'moderator').length;

    final stats = [
      _StatDef('Total Users', '$total', Icons.people_alt_rounded,
          const Color(0xFF6366F1), const Color(0xFFEEF2FF)),
      _StatDef('Online Now', '$online', Icons.circle,
          const Color(0xFF10B981), const Color(0xFFECFDF5)),
      _StatDef('Approved', '$approved', Icons.check_circle_rounded,
          const Color(0xFF1B6B3A), const Color(0xFFF0FAF4)),
      _StatDef('Pending', '$pending', Icons.hourglass_top_rounded,
          const Color(0xFFF59E0B), const Color(0xFFFFFBEB)),
      _StatDef('Admins', '$admins', Icons.admin_panel_settings_rounded,
          const Color(0xFF8B5CF6), const Color(0xFFF5F3FF)),
      _StatDef('Moderators', '$mods', Icons.verified_user_rounded,
          const Color(0xFF0EA5E9), const Color(0xFFE0F2FE)),
    ];

    return Container(
      color: _kSurface,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      child: LayoutBuilder(
        builder: (context, c) {
          final cols = c.maxWidth >= 900
              ? 6
              : c.maxWidth >= 600
              ? 3
              : 2;
          return GridView.count(
            crossAxisCount: cols,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: c.maxWidth >= 900 ? 2.2 : 1.8,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: stats.map((s) => _StatCard(def: s)).toList(),
          );
        },
      ),
    );
  }
}

class _StatDef {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bg;
  const _StatDef(this.label, this.value, this.icon, this.color, this.bg);
}

class _StatCard extends StatelessWidget {
  final _StatDef def;
  const _StatCard({required this.def});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: def.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: def.color.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: def.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(def.icon, color: def.color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(def.value,
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: def.color,
                        letterSpacing: -0.5)),
                Text(def.label,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: _kTextSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SEARCH + FILTER BAR
// ─────────────────────────────────────────────────────────────────────────────

class _SearchFilterBar extends StatelessWidget {
  final TextEditingController controller;
  final _Filter currentFilter;
  final ValueChanged<String> onSearch;
  final ValueChanged<_Filter> onFilter;

  const _SearchFilterBar({
    required this.controller,
    required this.currentFilter,
    required this.onSearch,
    required this.onFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kSurface,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kBorder),
            ),
            child: TextField(
              controller: controller,
              onChanged: onSearch,
              style: const TextStyle(fontSize: 14, color: _kTextPrimary),
              decoration: InputDecoration(
                hintText: 'Search by name, email or phone...',
                hintStyle: const TextStyle(
                    fontSize: 14, color: _kTextSecondary),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: _kTextSecondary, size: 20),
                suffixIcon: controller.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: _kTextSecondary, size: 18),
                  onPressed: () {
                    controller.clear();
                    onSearch('');
                  },
                )
                    : null,
                border: InputBorder.none,
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _Filter.values
                  .map((f) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _FilterChip(
                  label: f.label,
                  active: currentFilter == f,
                  onTap: () => onFilter(f),
                ),
              ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatefulWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _FilterChip(
      {required this.label, required this.active, required this.onTap});

  @override
  State<_FilterChip> createState() => _FilterChipState();
}

class _FilterChipState extends State<_FilterChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: widget.active
                ? _kGreen
                : _hovered
                ? _kGreen.withOpacity(0.09)
                : _kGreen.withOpacity(0.05),
            borderRadius: BorderRadius.circular(50),
            border: Border.all(
                color: widget.active
                    ? _kGreen
                    : _kGreen.withOpacity(0.20)),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: widget.active ? Colors.white : _kGreen,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// USERS LIST
// ─────────────────────────────────────────────────────────────────────────────

class _UsersList extends StatelessWidget {
  final List<AppUser> users;
  final ValueChanged<AppUser> onDelete;
  final ValueChanged<AppUser> onToggleBlock;
  final void Function(AppUser, String) onRoleChange;

  const _UsersList({
    required this.users,
    required this.onDelete,
    required this.onToggleBlock,
    required this.onRoleChange,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;

        if (isWide) {
          return _UsersTable(
            users: users,
            onDelete: onDelete,
            onToggleBlock: onToggleBlock,
            onRoleChange: onRoleChange,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          itemCount: users.length,
          itemBuilder: (context, i) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _UserCard(
              user: users[i],
              onDelete: () => onDelete(users[i]),
              onToggleBlock: () => onToggleBlock(users[i]),
              onRoleChange: (role) => onRoleChange(users[i], role),
            ),
          ),
        );
      },
    );
  }
}

// ── Wide: Table layout ────────────────────────────────────────────────────────

class _UsersTable extends StatelessWidget {
  final List<AppUser> users;
  final ValueChanged<AppUser> onDelete;
  final ValueChanged<AppUser> onToggleBlock;
  final void Function(AppUser, String) onRoleChange;

  const _UsersTable({
    required this.users,
    required this.onDelete,
    required this.onToggleBlock,
    required this.onRoleChange,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Table header
        Container(
          margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          padding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: _kGreen.withOpacity(0.05),
            borderRadius:
            const BorderRadius.vertical(top: Radius.circular(14)),
            border: Border.all(color: _kBorder),
          ),
          child: const Row(
            children: [
              SizedBox(width: 44),  // avatar
              SizedBox(width: 14),
              Expanded(flex: 3, child: _HeaderCell('User')),
              Expanded(flex: 2, child: _HeaderCell('Contact')),
              Expanded(flex: 2, child: _HeaderCell('Role')),
              Expanded(flex: 2, child: _HeaderCell('Status')),
              Expanded(flex: 2, child: _HeaderCell('Joined')),
              Expanded(flex: 2, child: _HeaderCell('Last Seen')),
              SizedBox(width: 180, child: _HeaderCell('Actions')),
            ],
          ),
        ),

        // Table rows
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            decoration: BoxDecoration(
              color: _kSurface,
              borderRadius:
              const BorderRadius.vertical(bottom: Radius.circular(14)),
              border: Border.all(color: _kBorder),
            ),
            child: ListView.separated(
              itemCount: users.length,
              separatorBuilder: (_, __) =>
              const Divider(height: 1, color: _kBorder),
              itemBuilder: (_, i) => _TableRow(
                user: users[i],
                onDelete: () => onDelete(users[i]),
                onToggleBlock: () => onToggleBlock(users[i]),
                onRoleChange: (role) => onRoleChange(users[i], role),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  const _HeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: _kTextSecondary,
          letterSpacing: 0.6),
    );
  }
}

class _TableRow extends StatefulWidget {
  final AppUser user;
  final VoidCallback onDelete;
  final VoidCallback onToggleBlock;
  final ValueChanged<String> onRoleChange;

  const _TableRow({
    required this.user,
    required this.onDelete,
    required this.onToggleBlock,
    required this.onRoleChange,
  });

  @override
  State<_TableRow> createState() => _TableRowState();
}

class _TableRowState extends State<_TableRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        color: _hovered ? _kHover : Colors.transparent,
        padding:
        const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            // Avatar
            _OnlineAvatar(name: u.name, isOnline: u.isOnline, size: 44),
            const SizedBox(width: 14),

            // User info
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          u.name.isEmpty ? 'Unknown' : u.name,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _kTextPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (u.blocked) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('BLOCKED',
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFEF4444))),
                        ),
                      ],
                    ],
                  ),
                  Text(u.email,
                      style: const TextStyle(
                          fontSize: 12, color: _kTextSecondary),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),

            // Contact
            Expanded(
              flex: 2,
              child: Text(
                u.phone.isEmpty ? '—' : u.phone,
                style: const TextStyle(
                    fontSize: 13, color: _kTextSecondary),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Role dropdown
            Expanded(
              flex: 2,
              child: _RoleDropdown(
                role: u.role,
                onChanged: widget.onRoleChange,
              ),
            ),

            // Membership status
            Expanded(
              flex: 2,
              child: _StatusBadge(status: u.membershipStatus),
            ),

            // Joined
            Expanded(
              flex: 2,
              child: Text(
                u.joinedAt != null ? _fmtDate(u.joinedAt!) : '—',
                style: const TextStyle(
                    fontSize: 12, color: _kTextSecondary),
              ),
            ),

            // Last seen
            Expanded(
              flex: 2,
              child: Text(
                u.lastSeen != null ? _timeAgo(u.lastSeen!) : '—',
                style: const TextStyle(
                    fontSize: 12, color: _kTextSecondary),
              ),
            ),

            // Actions
            SizedBox(
              width: 180,
              child: _ActionButtons(
                user: u,
                onDelete: widget.onDelete,
                onToggleBlock: widget.onToggleBlock,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Narrow: Card layout ───────────────────────────────────────────────────────

class _UserCard extends StatefulWidget {
  final AppUser user;
  final VoidCallback onDelete;
  final VoidCallback onToggleBlock;
  final ValueChanged<String> onRoleChange;

  const _UserCard({
    required this.user,
    required this.onDelete,
    required this.onToggleBlock,
    required this.onRoleChange,
  });

  @override
  State<_UserCard> createState() => _UserCardState();
}

class _UserCardState extends State<_UserCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _hovered ? _kHover : _kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: _hovered ? _kGreen.withOpacity(0.30) : _kBorder),
          boxShadow: const [
            BoxShadow(color: _kShadow, blurRadius: 4, offset: Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _OnlineAvatar(
                    name: u.name, isOnline: u.isOnline, size: 48),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Flexible(
                          child: Text(
                            u.name.isEmpty ? 'Unknown' : u.name,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: _kTextPrimary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (u.blocked) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('BLOCKED',
                                style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFEF4444))),
                          ),
                        ]
                      ]),
                      Text(u.email,
                          style: const TextStyle(
                              fontSize: 12, color: _kTextSecondary),
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                _StatusBadge(status: u.membershipStatus),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, color: _kBorder),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CardField('Phone', u.phone.isEmpty ? '—' : u.phone),
                      const SizedBox(height: 6),
                      _CardField('Joined',
                          u.joinedAt != null ? _fmtDate(u.joinedAt!) : '—'),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CardField('Last Seen',
                          u.lastSeen != null ? _timeAgo(u.lastSeen!) : '—'),
                      const SizedBox(height: 6),
                      _RoleDropdown(
                        role: u.role,
                        onChanged: widget.onRoleChange,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _ActionButtons(
              user: u,
              onDelete: widget.onDelete,
              onToggleBlock: widget.onToggleBlock,
            ),
          ],
        ),
      ),
    );
  }
}

class _CardField extends StatelessWidget {
  final String label;
  final String value;
  const _CardField(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: _kTextSecondary,
                letterSpacing: 0.5)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _kTextPrimary)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REUSABLE WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

// ── Online avatar ─────────────────────────────────────────────────────────────

class _OnlineAvatar extends StatelessWidget {
  final String name;
  final bool isOnline;
  final double size;

  const _OnlineAvatar({
    required this.name,
    required this.isOnline,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final words = name.trim().split(' ').where((w) => w.isNotEmpty).toList();
    final initials = words.length >= 2
        ? '${words[0][0]}${words[1][0]}'.toUpperCase()
        : words.isNotEmpty
        ? words[0][0].toUpperCase()
        : '?';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: _kGreen.withOpacity(0.12),
            borderRadius: BorderRadius.circular(size * 0.28),
          ),
          child: Center(
            child: Text(initials,
                style: TextStyle(
                    fontSize: size * 0.32,
                    fontWeight: FontWeight.w700,
                    color: _kGreen)),
          ),
        ),
        Positioned(
          right: 0,
          top: 0,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: isOnline
                  ? const Color(0xFF10B981)
                  : const Color(0xFFD1D5DB),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Status badge ──────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg, border, dot, text;
    String label;

    switch (status) {
      case 'approved':
        bg = const Color(0xFFECFDF5);
        border = const Color(0xFF6EE7B7);
        dot = const Color(0xFF10B981);
        text = const Color(0xFF065F46);
        label = 'Approved';
        break;
      case 'rejected':
        bg = const Color(0xFFFEF2F2);
        border = const Color(0xFFFCA5A5);
        dot = const Color(0xFFEF4444);
        text = const Color(0xFF991B1B);
        label = 'Rejected';
        break;
      default:
        bg = const Color(0xFFFFFBEB);
        border = const Color(0xFFFCD34D);
        dot = const Color(0xFFF59E0B);
        text = const Color(0xFF92400E);
        label = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: text)),
        ],
      ),
    );
  }
}

// ── Role dropdown ─────────────────────────────────────────────────────────────

class _RoleDropdown extends StatelessWidget {
  final String role;
  final ValueChanged<String> onChanged;

  const _RoleDropdown({required this.role, required this.onChanged});

  Color get _roleColor {
    switch (role) {
      case 'admin':     return const Color(0xFF8B5CF6);
      case 'moderator': return const Color(0xFF0EA5E9);
      default:          return _kGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: _roleColor.withOpacity(0.09),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _roleColor.withOpacity(0.25)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: role,
          isDense: true,
          icon: Icon(Icons.expand_more_rounded,
              size: 16, color: _roleColor),
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _roleColor),
          items: const [
            DropdownMenuItem(value: 'member',    child: Text('Member')),
            DropdownMenuItem(value: 'moderator', child: Text('Moderator')),
            DropdownMenuItem(value: 'admin',     child: Text('Admin')),
          ],
          onChanged: (v) {
            if (v != null && v != role) onChanged(v);
          },
        ),
      ),
    );
  }
}

// ── Action buttons ────────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  final AppUser user;
  final VoidCallback onDelete;
  final VoidCallback onToggleBlock;

  const _ActionButtons({
    required this.user,
    required this.onDelete,
    required this.onToggleBlock,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Block / Unblock
        _SmallBtn(
          label: user.blocked ? 'Unblock' : 'Block',
          icon: user.blocked
              ? Icons.lock_open_rounded
              : Icons.block_rounded,
          color: user.blocked
              ? const Color(0xFF10B981)
              : const Color(0xFFF59E0B),
          onTap: onToggleBlock,
        ),
        const SizedBox(width: 8),
        // Delete
        _SmallBtn(
          label: 'Delete',
          icon: Icons.delete_outline_rounded,
          color: const Color(0xFFEF4444),
          onTap: onDelete,
        ),
      ],
    );
  }
}

class _SmallBtn extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SmallBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_SmallBtn> createState() => _SmallBtnState();
}

class _SmallBtnState extends State<_SmallBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: _hovered
                ? widget.color
                : widget.color.withOpacity(0.09),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: widget.color.withOpacity(_hovered ? 0 : 0.30)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon,
                  size: 14,
                  color: _hovered ? Colors.white : widget.color),
              const SizedBox(width: 5),
              Text(widget.label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _hovered ? Colors.white : widget.color)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Confirm dialog ────────────────────────────────────────────────────────────

class _ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final Color confirmColor;
  final VoidCallback onConfirm;

  const _ConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.confirmColor,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title,
          style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _kTextPrimary)),
      content: Text(message,
          style: const TextStyle(fontSize: 14, color: _kTextSecondary)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel',
              style: TextStyle(color: _kTextSecondary)),
        ),
        ElevatedButton(
          onPressed: onConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmColor,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LOADING / EMPTY / ERROR
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
        child: CircularProgressIndicator(color: _kGreen, strokeWidth: 2.5));
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  const _ErrorState({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFFFEF2F2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded,
                  size: 36, color: Color(0xFFEF4444)),
            ),
            const SizedBox(height: 20),
            const Text('Something went wrong',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: _kTextPrimary)),
            const SizedBox(height: 8),
            Text(error,
                style: const TextStyle(
                    fontSize: 13, color: _kTextSecondary),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _kGreen.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.people_outline_rounded,
                size: 38, color: _kGreen),
          ),
          const SizedBox(height: 20),
          const Text('No users found',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _kTextPrimary)),
          const SizedBox(height: 8),
          const Text('Try adjusting your search or filter.',
              style:
              TextStyle(fontSize: 13, color: _kTextSecondary)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// UTILITIES
// ─────────────────────────────────────────────────────────────────────────────

String _fmtDate(DateTime dt) {
  const m = [
    'Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec'
  ];
  return '${dt.day} ${m[dt.month - 1]} ${dt.year}';
}

String _timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inSeconds < 60) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return _fmtDate(dt);
}