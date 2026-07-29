import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/config/app_theme.dart';
import 'core/config/constants.dart';
import 'core/services/supabase_service.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/notifications_provider.dart';
import 'providers/presence_provider.dart';
import 'providers/theme_provider.dart';
import 'routes/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();
  runApp(const PropelApp());
}

class PropelApp extends StatelessWidget {
  const PropelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, NotificationsProvider>(
          create: (_) => NotificationsProvider(),
          update: (_, auth, notifications) {
            notifications!.updateUserId(auth.user?.id);
            return notifications;
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, PresenceProvider>(
          create: (_) => PresenceProvider(),
          update: (_, auth, presence) {
            presence!.updateUserId(auth.user?.id);
            return presence;
          },
        ),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: Consumer2<ThemeProvider, AuthProvider>(
        builder: (context, themeProvider, authProvider, child) {
          final router = createRouter(authProvider);

          return MaterialApp.router(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            routerConfig: router,
          );
        },
      ),
    );
  }
}
