import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../features/landing/landing_screen.dart';
import '../features/auth/auth_layout_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/signup_screen.dart';
import '../features/auth/forgot_password_screen.dart';
import '../features/auth/verify_email_screen.dart';
import '../features/onboarding/mentor_onboarding_screen.dart';
import '../features/onboarding/mentee_onboarding_screen.dart';
import '../features/dashboard/dashboard_layout.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/explore/explore_mentors_screen.dart';
import '../features/mentor/mentor_profile_screen.dart';
import '../features/mentee/mentee_profile_screen.dart';
import '../features/goals/goals_screen.dart';
import '../features/messages/messages_screen.dart';
import '../features/events/events_screen.dart';
import '../features/ratings/ratings_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/settings/settings_screen.dart';

GoRouter createRouter(AuthProvider authProvider) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: authProvider,
    redirect: (BuildContext context, GoRouterState state) {
      if (!authProvider.isInitialized || authProvider.isLoading) {
        return null;
      }

      final loc = state.matchedLocation;
      final isAuthenticated = authProvider.isAuthenticated;
      final isOnboarded = authProvider.isOnboarded;
      final isPublicRoute = ['/', '/login', '/signup', '/forgot-password', '/verify-email', '/auth/callback'].contains(loc);
      final isOnboardingRoute = loc.startsWith('/onboarding');

      if (!isAuthenticated && !isPublicRoute) {
        return '/login';
      }

      if (isAuthenticated) {
        if (!isOnboarded) {
          final targetOnboarding = '/onboarding/${authProvider.role}';
          if (loc != targetOnboarding) {
            return targetOnboarding;
          }
        } else if (isPublicRoute || isOnboardingRoute) {
          return '/dashboard';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const LandingScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AuthLayoutScreen(child: child),
        routes: [
          GoRoute(
            path: '/login',
            builder: (context, state) => const LoginScreen(),
          ),
          GoRoute(
            path: '/signup',
            builder: (context, state) => const SignUpScreen(),
          ),
          GoRoute(
            path: '/forgot-password',
            builder: (context, state) => const ForgotPasswordScreen(),
          ),
          GoRoute(
            path: '/verify-email',
            builder: (context, state) => const VerifyEmailScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/onboarding/mentor',
        builder: (context, state) => const MentorOnboardingScreen(),
      ),
      GoRoute(
        path: '/onboarding/mentee',
        builder: (context, state) => const MenteeOnboardingScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => DashboardLayout(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/explore',
            builder: (context, state) => const ExploreMentorsScreen(),
          ),
          GoRoute(
            path: '/mentor/:id',
            builder: (context, state) => MentorProfileScreen(
              mentorId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/mentee/:id',
            builder: (context, state) => MenteeProfileScreen(
              menteeId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/goals',
            builder: (context, state) => const GoalsScreen(),
          ),
          GoRoute(
            path: '/messages',
            builder: (context, state) => const MessagesScreen(),
          ),
          GoRoute(
            path: '/events',
            builder: (context, state) => const EventsScreen(),
          ),
          GoRoute(
            path: '/calendar',
            builder: (context, state) => const EventsScreen(),
          ),
          GoRoute(
            path: '/ratings',
            builder: (context, state) => const RatingsScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
}
