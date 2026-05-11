import 'package:flutter/material.dart';
import 'package:mukammal_pakistan_admin/models/services/application_service.dart';
import 'package:mukammal_pakistan_admin/screens/application_detail_screen.dart';

import '../models/membership_application.dart';
// import '../services/application_service.dart';
import '../widgets/status_badge.dart';
// import 'application_detail_screen.dart';

// ── Theme constants ────────────────────────────────────────────────────────────
const _kGreen = Color(0xFF1B6B3A);
const _kGreenLight = Color(0xFF2E8B57);
const _kBg = Color(0xFFF7F9F7);
const _kSurface = Colors.white;
const _kTextPrimary = Color(0xFF111827);
const _kTextSecondary = Color(0xFF6B7280);
const _kBorder = Color(0xFFE5E7EB);
const _kShadow = Color(0x0D000000);
const _kHover = Color(0xFFF0FAF4);

class MembershipApplicationsScreen extends StatefulWidget {
  const MembershipApplicationsScreen({super.key});

  @override
  State<MembershipApplicationsScreen> createState() =>
      _MembershipApplicationsScreenState();
}

class _MembershipApplicationsScreenState
    extends State<MembershipApplicationsScreen> {
  String _filter = 'all';

  static const _filters = [
    ('all', 'All'),
    ('pending', 'Pending'),
    ('approved', 'Approved'),
    ('rejected', 'Rejected'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: _buildAppBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Stats ──────────────────────────────────────────────────────────
          StreamBuilder<Map<String, int>>(
            stream: ApplicationService.instance.streamCounts(),
            builder: (context, snap) {
              final counts = snap.data ??
                  {'total': 0, 'pending': 0, 'approved': 0, 'rejected': 0};
              return _StatsSection(counts: counts);
            },
          ),

          // ── Filter bar ────────────────────────────────────────────────────
          _FilterBar(
            current: _filter,
            filters: _filters,
            onChanged: (v) => setState(() => _filter = v),
          ),

          // ── Applications list ─────────────────────────────────────────────
          Expanded(
            child: StreamBuilder<List<MembershipApplication>>(
              stream: ApplicationService.instance
                  .streamApplications(filter: _filter),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const _LoadingState();
                }
                if (snap.hasError) {
                  return _ErrorState(error: snap.error.toString());
                }
                final apps = snap.data ?? [];
                if (apps.isEmpty) return const _EmptyState();
                return _ApplicationsList(applications: apps);
              },
            ),
          ),
        ],
      ),
    );
  }

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
                    'Membership Applications',
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
}

// ── Stats Section ─────────────────────────────────────────────────────────────

class _StatsSection extends StatelessWidget {
  final Map<String, int> counts;
  const _StatsSection({required this.counts});

  static const _statDefs = [
    _StatDef('Total', 'total', Icons.folder_copy_rounded, Color(0xFF6366F1), Color(0xFFEEF2FF)),
    _StatDef('Pending', 'pending', Icons.hourglass_top_rounded, Color(0xFFF59E0B), Color(0xFFFFFBEB)),
    _StatDef('Approved', 'approved', Icons.check_circle_rounded, Color(0xFF10B981), Color(0xFFECFDF5)),
    _StatDef('Rejected', 'rejected', Icons.cancel_rounded, Color(0xFFEF4444), Color(0xFFFEF2F2)),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kSurface,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 600;
          if (isWide) {
            return Row(
              children: _statDefs
                  .map((d) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: d == _statDefs.last ? 0 : 16,
                  ),
                  child: _StatCard(def: d, value: counts[d.key] ?? 0),
                ),
              ))
                  .toList(),
            );
          }
          return GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.0,
            children: _statDefs
                .map((d) => _StatCard(def: d, value: counts[d.key] ?? 0))
                .toList(),
          );
        },
      ),
    );
  }
}

class _StatDef {
  final String label;
  final String key;
  final IconData icon;
  final Color color;
  final Color bg;
  const _StatDef(this.label, this.key, this.icon, this.color, this.bg);
}

class _StatCard extends StatelessWidget {
  final _StatDef def;
  final int value;
  const _StatCard({required this.def, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: def.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: def.color.withOpacity(0.20)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: def.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(def.icon, color: def.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$value',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: def.color,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  def.label,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _kTextSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Filter Bar ────────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final String current;
  final List<(String, String)> filters;
  final ValueChanged<String> onChanged;

  const _FilterBar({
    required this.current,
    required this.filters,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kSurface,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((f) {
            final (value, label) = f;
            final active = current == value;
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: _FilterChip(
                label: label,
                active: active,
                onTap: () => onChanged(value),
              ),
            );
          }).toList(),
        ),
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
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
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
                  : _kGreen.withOpacity(0.20),
            ),
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

// ── Applications List ─────────────────────────────────────────────────────────

class _ApplicationsList extends StatelessWidget {
  final List<MembershipApplication> applications;
  const _ApplicationsList({required this.applications});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      itemCount: applications.length,
      itemBuilder: (context, i) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _ApplicationTile(app: applications[i]),
        );
      },
    );
  }
}

class _ApplicationTile extends StatefulWidget {
  final MembershipApplication app;
  const _ApplicationTile({required this.app});

  @override
  State<_ApplicationTile> createState() => _ApplicationTileState();
}

class _ApplicationTileState extends State<_ApplicationTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final a = widget.app;
    final name = a.personalInfo.fullName.trim().isEmpty
        ? 'Unknown Applicant'
        : a.personalInfo.fullName;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) =>
              ApplicationDetailScreen(applicationId: a.id),
        )),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: BoxDecoration(
            color: _hovered ? _kHover : _kSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _hovered ? _kGreen.withOpacity(0.35) : _kBorder,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _hovered
                    ? _kGreen.withOpacity(0.10)
                    : _kShadow,
                blurRadius: _hovered ? 16 : 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              // Avatar
              _Initials(name: name, size: 48),
              const SizedBox(width: 16),

              // Middle info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _kTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _MetaRow(app: a),
                    const SizedBox(height: 6),
                    Text(
                      'Submitted ${_fmtDate(a.submittedAt)}',
                      style: const TextStyle(
                          fontSize: 12, color: _kTextSecondary),
                    ),
                  ],
                ),
              ),

              // Right: badge + chevron
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  StatusBadge(status: a.status),
                  const SizedBox(height: 10),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: _hovered ? _kGreen : _kTextSecondary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final MembershipApplication app;
  const _MetaRow({required this.app});

  @override
  Widget build(BuildContext context) {
    final parts = <String>[];
    if (app.contactInfo.city.isNotEmpty) parts.add(app.contactInfo.city);
    if (app.educationInfo.profession.isNotEmpty) {
      parts.add(app.educationInfo.profession);
    }
    if (app.educationInfo.selectedRole.isNotEmpty) {
      parts.add(app.educationInfo.selectedRole.toUpperCase());
    }

    return Text(
      parts.join(' · '),
      style: const TextStyle(fontSize: 13, color: _kTextSecondary),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

// ── Loading / Error / Empty ───────────────────────────────────────────────────

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: _kGreen,
        strokeWidth: 2.5,
      ),
    );
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
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
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
                style: const TextStyle(fontSize: 13, color: _kTextSecondary),
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
            child:
            const Icon(Icons.inbox_rounded, size: 38, color: _kGreen),
          ),
          const SizedBox(height: 20),
          const Text('No applications found',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _kTextPrimary)),
          const SizedBox(height: 8),
          const Text('Applications matching this filter will appear here.',
              style: TextStyle(fontSize: 13, color: _kTextSecondary),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

class _Initials extends StatelessWidget {
  final String name;
  final double size;
  const _Initials({required this.name, required this.size});

  @override
  Widget build(BuildContext context) {
    final words = name.trim().split(' ').where((w) => w.isNotEmpty).toList();
    final initials = words.length >= 2
        ? '${words[0][0]}${words[1][0]}'.toUpperCase()
        : words.isNotEmpty
        ? words[0][0].toUpperCase()
        : '?';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _kGreen.withOpacity(0.12),
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: size * 0.35,
            fontWeight: FontWeight.w700,
            color: _kGreen,
          ),
        ),
      ),
    );
  }
}

String _fmtDate(DateTime dt) {
  const months = [
    'Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec'
  ];
  return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
}