import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/config/app_theme.dart';
import 'core/config/constants.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/notifications_provider.dart';
import 'providers/presence_provider.dart';
import 'providers/theme_provider.dart';
import 'routes/app_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure Global Flutter Error Handlers for production & debugging
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('[FlutterError] ${details.exceptionAsString()}');
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    debugPrint('[UncaughtPlatformError] $error\n$stack');
    return true;
  };

  // Set immersive mobile UI overlays and preferred device orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize Firebase with fallback error handling
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e, stack) {
    debugPrint('[FirebaseInitError] Could not initialize Firebase: $e\n$stack');
  }

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
            notifications!.updateUserId(auth.user?.uid);
            return notifications;
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, PresenceProvider>(
          create: (_) => PresenceProvider(),
          update: (_, auth, presence) {
            presence!.updateUserId(auth.user?.uid);
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
            scrollBehavior: const MaterialScrollBehavior().copyWith(
              dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
                PointerDeviceKind.stylus,
                PointerDeviceKind.unknown,
              },
            ),
          );
        },
      ),
    );
  }
}
