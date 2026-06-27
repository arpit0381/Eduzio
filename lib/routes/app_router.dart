import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Import providers
import '../features/auth/presentation/controllers/auth_controller.dart';
import '../features/auth/domain/entities/user_profile.dart';

// Import screens
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/onboarding_screen.dart';
import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../features/dashboard/presentation/screens/shell_screen.dart';
import '../features/batch/presentation/screens/batch_list_screen.dart';
import '../features/student/presentation/screens/student_list_screen.dart';
import '../features/teacher/presentation/screens/teacher_list_screen.dart';
import '../features/attendance/presentation/screens/attendance_screen.dart';
import '../features/homework/presentation/screens/homework_screen.dart';
import '../features/exam/presentation/screens/exam_screen.dart';
import '../features/fees/presentation/screens/fees_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';

/// Helper class to convert a Stream into a Listenable for GoRouter refresh notifier
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (dynamic _) => notifyListeners(),
        );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// Riverpod provider for GoRouter
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final repository = ref.read(authRepositoryProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: GoRouterRefreshStream(repository.authStateChanges),
    routes: [
      // Auth Routes
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/onboard',
        name: 'onboard',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Shell Route wrapping core application features
      ShellRoute(
        builder: (context, state, child) {
          return ShellScreen(child: child);
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/batches',
            name: 'batches',
            builder: (context, state) => const BatchListScreen(),
          ),
          GoRoute(
            path: '/students',
            name: 'students',
            builder: (context, state) => const StudentListScreen(),
          ),
          GoRoute(
            path: '/teachers',
            name: 'teachers',
            builder: (context, state) => const TeacherListScreen(),
          ),
          GoRoute(
            path: '/attendance',
            name: 'attendance',
            builder: (context, state) => const AttendanceScreen(),
          ),
          GoRoute(
            path: '/homework',
            name: 'homework',
            builder: (context, state) => const HomeworkScreen(),
          ),
          GoRoute(
            path: '/exams',
            name: 'exams',
            builder: (context, state) => const ExamScreen(),
          ),
          GoRoute(
            path: '/fees',
            name: 'fees',
            builder: (context, state) => const FeesScreen(),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
    redirect: (context, state) {
      // Get current auth state (loading/error is represented, value is UserProfile?)
      final user = authState.value;
      final currentLoc = state.matchedLocation;
      
      final isAuthPage = currentLoc == '/login' ||
          currentLoc == '/register' ||
          currentLoc == '/onboard';

      // 1. If user is NOT logged in, redirect them to login
      if (user == null) {
        return isAuthPage ? null : '/login';
      }

      // 2. If user IS logged in and trying to access login/register, push them to dashboard
      if (isAuthPage) {
        // If owner onboarding is still incomplete (profile exists but no org yet)
        if (user.organizationId == null) {
          return '/onboard';
        }
        return '/dashboard';
      }

      // 3. If user is logged in but belongs to no organization, force onboarding
      if (user.organizationId == null && currentLoc != '/onboard') {
        return '/onboard';
      }

      return null;
    },
  );
});
