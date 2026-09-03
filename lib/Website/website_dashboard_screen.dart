import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../widgets/admin_app_bar.dart';
import '../../widgets/dashboard_card.dart';
import 'generic_list_screen.dart';
import 'site_settings_screen.dart';
import 'website_module_configs.dart';
import 'websitebanner.dart';


/// Opened from the "Manage Website" card on the main DashboardScreen.
/// Same visual language (AdminAppBar, DashboardCard, AppTheme) as the
/// existing dashboard, just pointed at the website's own collections.
class WebsiteDashboardScreen extends StatelessWidget {
  const WebsiteDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final modules = <_WebsiteModule>[
      _WebsiteModule(
        icon: Icons.settings_suggest_rounded,
        label: 'Site Settings',
        description: 'Party name, slogan, symbol, about, vision, contact & footer.',
        builder: (_) => const SiteSettingsScreen(),
      ),
      _WebsiteModule(
        icon: Icons.groups_rounded,
        label: 'Leadership',
        description: 'Chairman and core team shown on the About page.',
        builder: (_) => const GenericListScreen(
          collectionName: 'leadership',
          title: 'Leadership',
          fields: leadershipFields,
          displayField: 'name',
          subtitleField: 'position',
          orderByField: 'order',
        ),
      ),
      _WebsiteModule(
        icon: Icons.list_alt_rounded,
        label: 'Manifesto',
        description: 'Agenda points and core objectives shown on the Manifesto page.',
        builder: (_) => const GenericListScreen(
          collectionName: 'manifesto_points',
          title: 'Manifesto Points',
          fields: manifestoFields,
          displayField: 'title',
          subtitleField: 'type',
          orderByField: 'order',
        ),
      ),
      _WebsiteModule(
        icon: Icons.newspaper_rounded,
        label: 'News',
        description: 'Press releases and news posts for the website.',
        builder: (_) => const GenericListScreen(
          collectionName: 'news',
          title: 'News',
          fields: newsFields,
          displayField: 'title',
          subtitleField: 'status',
          orderByField: 'publishedAt',
          orderDescending: true,
        ),
      ),
      _WebsiteModule(
        icon: Icons.event_rounded,
        label: 'Events',
        description: 'Upcoming and past party events.',
        builder: (_) => const GenericListScreen(
          collectionName: 'events',
          title: 'Events',
          fields: eventsFields,
          displayField: 'title',
          subtitleField: 'location',
          orderByField: 'eventDate',
          orderDescending: true,
        ),
      ),
      _WebsiteModule(
        icon: Icons.photo_library_outlined,
        label: 'Gallery',
        description: 'Photos shown on the Image Gallery page.',
        builder: (_) => const GenericListScreen(
          collectionName: 'gallery',
          title: 'Gallery',
          fields: galleryFields,
          displayField: 'caption',
          subtitleField: 'category',
        ),
      ),
      _WebsiteModule(
        icon: Icons.videocam_outlined,
        label: 'Videos',
        description: 'YouTube links and clips for the Videos page.',
        builder: (_) => const GenericListScreen(
          collectionName: 'videos',
          title: 'Videos',
          fields: videosFields,
          displayField: 'title',
          subtitleField: 'category',
        ),
      ),
      _WebsiteModule(
        icon: Icons.image_outlined,
        label: 'Banners',
        description: 'Homepage banners shown on the website only.',
        builder: (_) => const WebsiteBannersScreen(),
      ),

    ];

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: const AdminAppBar(title: 'Manage Website'),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          final isMedium = constraints.maxWidth >= 600;
          final crossCount = isWide ? 4 : (isMedium ? 2 : 1);

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? 64 : (isMedium ? 32 : 20),
              vertical: 32,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Website Content',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Everything here updates the public website directly.',
                      style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 24),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossCount,
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                        childAspectRatio: isWide ? 0.85 : (isMedium ? 0.90 : 1.3),
                      ),
                      itemCount: modules.length,
                      itemBuilder: (context, index) {
                        final m = modules[index];
                        return DashboardCard(
                          icon: m.icon,
                          label: m.label,
                          description: m.description,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: m.builder),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _WebsiteModule {
  final IconData icon;
  final String label;
  final String description;
  final WidgetBuilder builder;

  const _WebsiteModule({
    required this.icon,
    required this.label,
    required this.description,
    required this.builder,
  });
}