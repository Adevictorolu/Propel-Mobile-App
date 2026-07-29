import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/config/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../providers/theme_provider.dart';

class DashboardLayout extends StatefulWidget {
  final Widget child;

  const DashboardLayout({super.key, required this.child});

  @override
  State<DashboardLayout> createState() => _DashboardLayoutState();
}

class _DashboardLayoutState extends State<DashboardLayout> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentLoc = GoRouterState.of(context).matchedLocation;
    final authProvider = context.watch<AuthProvider>();
    final notificationsProvider = context.watch<NotificationsProvider>();
    final userProfile = authProvider.profile;

    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: isDesktop
            ? null
            : IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.brandGreen600,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.rocket_launch, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              'PROPEL',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: 1.2,
                color: isDark ? Colors.white : AppColors.slate900,
              ),
            ),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => _showNotificationsDialog(context),
              ),
              if (notificationsProvider.unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '${notificationsProvider.unreadCount}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          IconButton(
            icon: Icon(isDark ? Icons.wb_sunny_outlined : Icons.nightlight_round),
            onPressed: () => context.read<ThemeProvider>().toggleTheme(),
          ),

          const SizedBox(width: 8),

          PopupMenuButton<String>(
            offset: const Offset(0, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            itemBuilder: (context) => [
              PopupMenuItem(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAlignment.start,
                  children: [
                    Text(
                      userProfile?.fullName ?? 'User',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.slate900),
                    ),
                    Text(
                      userProfile?.email ?? '',
                      style: const TextStyle(fontSize: 12, color: AppColors.slate500),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'profile',
                child: const Row(
                  children: [
                    Icon(Icons.person_outline, size: 18),
                    SizedBox(width: 8),
                    Text('My Profile'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'settings',
                child: const Row(
                  children: [
                    Icon(Icons.settings_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Settings'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'logout',
                child: const Row(
                  children: [
                    Icon(Icons.logout, color: AppColors.error, size: 18),
                    SizedBox(width: 8),
                    Text('Sign Out', style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
            onSelected: (val) {
              if (val == 'profile') context.go('/profile');
              if (val == 'settings') context.go('/settings');
              if (val == 'logout') context.read<AuthProvider>().logout();
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.brandBlue600,
                backgroundImage: userProfile?.avatarUrl != null
                    ? NetworkImage(userProfile!.avatarUrl!)
                    : null,
                child: userProfile?.avatarUrl == null
                    ? Text(
                        userProfile?.firstName.isNotEmpty == true ? userProfile!.firstName[0].toUpperCase() : 'U',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
      drawer: isDesktop ? null : Drawer(child: _buildNavigationContent(context, currentLoc)),
      body: Row(
        children: [
          if (isDesktop)
            Container(
              width: 250,
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    width: 1,
                  ),
                ),
              ),
              child: _buildNavigationContent(context, currentLoc),
            ),
          Expanded(child: widget.child),
        ],
      ),
    );
  }

  Widget _buildNavigationContent(BuildContext context, String currentLoc) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final navItems = [
      {'route': '/dashboard', 'label': 'Dashboard', 'icon': Icons.dashboard_outlined},
      {'route': '/explore', 'label': 'Explore Mentors', 'icon': Icons.explore_outlined},
      {'route': '/goals', 'label': 'Goals & Curriculum', 'icon': Icons.track_changes_outlined},
      {'route': '/messages', 'label': 'Messages', 'icon': Icons.chat_bubble_outline},
      {'route': '/events', 'label': 'Events', 'icon': Icons.calendar_today_outlined},
      {'route': '/ratings', 'label': 'Ratings & Reviews', 'icon': Icons.star_outline},
      {'route': '/profile', 'label': 'My Profile', 'icon': Icons.person_outline},
      {'route': '/settings', 'label': 'Settings', 'icon': Icons.settings_outlined},
    ];

    return Column(
      children: [
        const SizedBox(height: 16),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: navItems.map((item) {
              final route = item['route'] as String;
              final label = item['label'] as String;
              final icon = item['icon'] as IconData;
              final isActive = currentLoc == route;

              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  tileColor: isActive
                      ? (isDark ? AppColors.slate800 : AppColors.brandBlue50)
                      : Colors.transparent,
                  leading: Icon(
                    icon,
                    color: isActive
                        ? (isDark ? AppColors.brandBlue400 : AppColors.brandBlue600)
                        : (isDark ? AppColors.slate400 : AppColors.slate600),
                  ),
                  title: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                      color: isActive
                          ? (isDark ? AppColors.brandBlue400 : AppColors.brandBlue600)
                          : (isDark ? AppColors.slate300 : AppColors.slate700),
                    ),
                  ),
                  onTap: () {
                    if (_scaffoldKey.currentState?.isDrawerOpen == true) {
                      Navigator.pop(context);
                    }
                    context.go(route);
                  },
                ),
              );
            }).toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: const Icon(Icons.logout, color: AppColors.error),
            title: const Text(
              'Sign Out',
              style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
            ),
            onTap: () {
              context.read<AuthProvider>().logout();
            },
          ),
        ),
      ],
    );
  }

  void _showNotificationsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Consumer<NotificationsProvider>(
          builder: (context, notificationsProvider, child) {
            final notifs = notificationsProvider.notifications;

            return AlertDialog(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Notifications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  if (notificationsProvider.unreadCount > 0)
                    TextButton(
                      onPressed: () => context.read<NotificationsProvider>().markAllRead(),
                      child: const Text('Mark all read', style: TextStyle(fontSize: 12)),
                    ),
                ],
              ),
              content: SizedBox(
                width: 400,
                height: 400,
                child: notificationsProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : notifs.isEmpty
                        ? const Center(
                            child: Text(
                              'No notifications yet',
                              style: TextStyle(color: AppColors.slate400),
                            ),
                          )
                        : ListView.separated(
                            itemCount: notifs.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final n = notifs[index];
                              return ListTile(
                                dense: true,
                                title: Text(
                                  n.title,
                                  style: TextStyle(
                                    fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(n.body),
                                trailing: !n.isRead
                                    ? Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: AppColors.brandBlue600,
                                          shape: BoxShape.circle,
                                        ),
                                      )
                                    : null,
                                onTap: () {
                                  context.read<NotificationsProvider>().markRead(n.id);
                                },
                              );
                            },
                          ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
