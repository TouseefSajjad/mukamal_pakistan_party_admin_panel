import 'package:flutter/material.dart';
import '../config/app_routes.dart';
import '../config/app_theme.dart';
import '../widgets/admin_app_bar.dart';
import '../widgets/dashboard_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  // ── Nav items ──────────────────────────────────────────────────────────────
  static const List<_NavItem> _navItems = [
    _NavItem(
      icon: Icons.people_alt_rounded,
      label: 'Users',
      description: 'View and manage all registered party members and their roles.',
      route: AppRoutes.users,
    ),
    _NavItem(
      icon: Icons.assignment_ind_rounded,
      label: 'Membership Applications',
      description: 'Review, approve or reject incoming membership requests.',
      route: AppRoutes.membershipApplications,
    ),
    _NavItem(
      icon: Icons.verified_user_rounded,
      label: 'Roles',
      description: 'Configure role-based permissions for admins and members.',
      route: AppRoutes.roles,
    ),
    _NavItem(
      icon: Icons.photo_library_rounded,
      label: 'Banners',
      description: 'Manage home-screen banner images and slider content.',
      route: AppRoutes.banners,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: const AdminAppBar(title: 'Mukammal Pakistan Party'),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          final isMedium = constraints.maxWidth >= 600;

          int crossCount;
          if (isWide) {
            crossCount = 4;
          } else if (isMedium) {
            crossCount = 2;
          } else {
            crossCount = 1;
          }

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? 64 : (isMedium ? 32 : 20),
              vertical: 40,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header ───────────────────────────────────────────────
                    _buildHeader(context),

                    const SizedBox(height: 40),

                    // ── Stats Row ────────────────────────────────────────────
                    _buildStatsRow(isMedium),

                    const SizedBox(height: 40),

                    // ── Section title ────────────────────────────────────────
                    const Text(
                      'Management Modules',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Select a module to manage party data',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Dashboard Cards Grid ─────────────────────────────────
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossCount,
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                        childAspectRatio: isWide
                            ? 0.85
                            : (isMedium ? 0.90 : 1.3),
                      ),
                      itemCount: _navItems.length,
                      itemBuilder: (context, index) {
                        final item = _navItems[index];
                        return DashboardCard(
                          icon: item.icon,
                          label: item.label,
                          description: item.description,
                          onTap: () =>
                              Navigator.of(context).pushNamed(item.route),
                        );
                      },
                    ),

                    const SizedBox(height: 48),

                    // ── Footer ───────────────────────────────────────────────
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryGreen,
            AppTheme.primaryGreenLight,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left text block
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Admin Dashboard',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Mukammal Pakistan Party',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage members, applications, roles and banners',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.80),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          // Right decorative icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.account_balance_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
        ],
      ),
    );
  }

  // ── Quick Stats Row ─────────────────────────────────────────────────────────
  Widget _buildStatsRow(bool isMedium) {
    final stats = [
      _StatItem(label: 'Total Users', value: '—', icon: Icons.people_rounded),
      _StatItem(
          label: 'Pending Applications',
          value: '—',
          icon: Icons.hourglass_top_rounded),
      _StatItem(
          label: 'Active Roles', value: '—', icon: Icons.verified_rounded),
      _StatItem(label: 'Banners', value: '—', icon: Icons.image_rounded),
    ];

    return isMedium
        ? Row(
            children: stats
                .map((s) => Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: stats.last == s ? 0 : 16,
                        ),
                        child: _StatCard(stat: s),
                      ),
                    ))
                .toList(),
          )
        : Column(
            children: stats
                .map((s) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _StatCard(stat: s),
                    ))
                .toList(),
          );
  }

  // ── Footer ──────────────────────────────────────────────────────────────────
  Widget _buildFooter() {
    return Center(
      child: Text(
        '© 2025 Mukammal Pakistan Party · Admin Panel v1.0',
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 13,
        ),
      ),
    );
  }
}

// ── Internal Models ──────────────────────────────────────────────────────────

class _NavItem {
  final IconData icon;
  final String label;
  final String description;
  final String route;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.description,
    required this.route,
  });
}

class _StatItem {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });
}

class _StatCard extends StatelessWidget {
  final _StatItem stat;
  const _StatCard({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowColor,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(stat.icon, color: AppTheme.primaryGreen, size: 20),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stat.value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                stat.label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
