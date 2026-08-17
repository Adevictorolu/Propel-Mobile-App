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

  static const List<_NavItem> _navItems = [
    _NavItem(route: '/dashboard', label: 'Home', icon: Icons.home_outlined, activeIcon: Icons.home),
    _NavItem(route: '/explore', label: 'Mentorship', icon: Icons.explore_outlined, activeIcon: Icons.explore),
    _NavItem(route: '/calendar', label: 'Calendar', icon: Icons.calendar_month_outlined, activeIcon: Icons.calendar_month),
    _NavItem(route: '/messages', label: 'Messages', icon: Icons.forum_outlined, activeIcon: Icons.forum),
    _NavItem(route: '/profile', label: 'Profile', icon: Icons.person_outline, activeIcon: Icons.person),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentLoc = GoRouterState.of(context).matchedLocation;
    final authProvider = context.watch<AuthProvider>();
    final notificationsProvider = context.watch<NotificationsProvider>();
    final userProfile = authProvider.profile;
    final currentIndex = _selectedIndex(currentLoc);
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Text(_titleForRoute(currentLoc)),
        centerTitle: false,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => _showNotificationsSheet(context),
              ),
              if (notificationsProvider.unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '${notificationsProvider.unreadCount}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: Icon(isDark ? Icons.wb_sunny_outlined : Icons.nightlight_round),
            onPressed: () => context.read<ThemeProvider>().toggleTheme(),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => context.go('/profile'),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.brandBlue600,
                backgroundImage: userProfile?.avatarUrl != null ? NetworkImage(userProfile!.avatarUrl!) : null,
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
      drawer: Drawer(child: _buildDrawerContent(context, currentLoc)),
      body: SafeArea(child: widget.child),
      bottomNavigationBar: isMobile
          ? NavigationBar(
              selectedIndex: currentIndex < 0 ? 0 : currentIndex,
              onDestinationSelected: (index) => _navigateTo(_navItems[index].route),
              destinations: _navItems
                  .map((item) => NavigationDestination(
                        icon: Icon(item.icon),
                        selectedIcon: Icon(item.activeIcon),
                        label: item.label,
                      ))
                  .toList(),
            )
          : null,
    );
  }

  Widget _buildDrawerContent(BuildContext context, String currentLoc) {
    final authProvider = context.watch<AuthProvider>();
    final userProfile = authProvider.profile;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        DrawerHeader(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark ? [AppColors.slate800, AppColors.slate700] : [AppColors.brandGreen600, AppColors.brandBlue600],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white24,
                child: Text(
                  userProfile?.firstName.isNotEmpty == true ? userProfile!.firstName[0].toUpperCase() : 'P',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              const SizedBox(height: 12),
              Text(userProfile?.fullName ?? 'Propel Member', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              Text(userProfile?.email ?? 'Mentorship dashboard', style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            children: [
              _drawerTile(context, currentLoc, 'Dashboard', '/dashboard', Icons.dashboard_outlined),
              _drawerTile(context, currentLoc, 'My Sessions', '/events', Icons.event_available_outlined),
              _drawerTile(context, currentLoc, 'My Bookings', '/events', Icons.calendar_month_outlined),
              _drawerTile(context, currentLoc, 'Saved Mentors', '/explore', Icons.bookmark_border),
              _drawerTile(context, currentLoc, 'Resources', '/goals', Icons.library_books_outlined),
              _drawerTile(context, currentLoc, 'Notifications', null, Icons.notifications_outlined, onTap: () => _showNotificationsSheet(context)),
              _drawerTile(context, currentLoc, 'Settings', '/settings', Icons.settings_outlined),
              _drawerTile(context, currentLoc, 'Help & Support', null, Icons.help_outline, onTap: () => _showSupportSheet(context)),
              _drawerTile(context, currentLoc, 'About', null, Icons.info_outline, onTap: () => _showAboutDialog(context)),
            ],
          ),
        ),
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.logout, color: AppColors.error),
          title: const Text('Logout', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
          onTap: () => _confirmLogout(context),
        ),
      ],
    );
  }

  Widget _drawerTile(
    BuildContext context,
    String currentLoc,
    String label,
    String? route,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isActive = route != null && currentLoc == route;

    return ListTile(
      leading: Icon(
        icon,
        color: isActive ? AppColors.brandBlue600 : (isDark ? AppColors.slate400 : AppColors.slate600),
      ),
      title: Text(label, style: TextStyle(fontWeight: isActive ? FontWeight.w700 : FontWeight.w500)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: () {
        if (_scaffoldKey.currentState?.isDrawerOpen == true) {
          Navigator.pop(context);
        }
        if (onTap != null) {
          onTap();
        } else if (route != null) {
          context.go(route);
        }
      },
    );
  }

  int _selectedIndex(String currentLoc) {
    for (var i = 0; i < _navItems.length; i++) {
      if (currentLoc == _navItems[i].route) return i;
    }
    return 0;
  }

  String _titleForRoute(String currentLoc) {
    switch (currentLoc) {
      case '/explore':
        return 'Mentorship';
      case '/calendar':
      case '/events':
        return 'Calendar & Sessions';
      case '/messages':
        return 'Messages';
      case '/profile':
        return 'Profile';
      case '/settings':
        return 'Settings';
      default:
        return 'Propel';
    }
  }

  void _navigateTo(String route) {
    context.go(route);
  }

  void _showNotificationsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          builder: (_, scrollController) {
            return Consumer<NotificationsProvider>(
              builder: (context, notificationsProvider, child) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Notifications', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 12),
                      if (notificationsProvider.isLoading)
                        const Center(child: CircularProgressIndicator())
                      else if (notificationsProvider.notifications.isEmpty)
                        const Expanded(child: Center(child: Text('You are all caught up.')))
                      else
                        Expanded(
                          child: ListView.separated(
                            controller: scrollController,
                            itemCount: notificationsProvider.notifications.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final item = notificationsProvider.notifications[index];
                              return ListTile(
                                title: Text(item.title, style: TextStyle(fontWeight: item.isRead ? FontWeight.normal : FontWeight.w700)),
                                subtitle: Text(item.body),
                                trailing: item.isRead ? null : const Icon(Icons.circle, color: AppColors.brandBlue600, size: 12),
                                onTap: () => notificationsProvider.markRead(item.id),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showSupportSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Help & Support', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              const Text('Reach out to the Propel support team for help with booking, profile updates, or onboarding. We reply within one business day.'),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.email_outlined),
                label: const Text('Contact support'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('About Propel'),
          content: const Text('Propel helps ambitious learners connect with mentors in a fast, thoughtful, and deeply personal way across every screen size.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Close')),
          ],
        );
      },
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Sign out?'),
          content: const Text('You will need to sign in again to continue using Propel.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Sign out')),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      await context.read<AuthProvider>().logout();
    }
  }
}

class _NavItem {
  final String route;
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const _NavItem({required this.route, required this.label, required this.icon, required this.activeIcon});
}
