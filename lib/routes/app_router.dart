import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Import providers
import '../features/auth/presentation/controllers/auth_controller.dart';

// Import screens
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/onboarding_screen.dart';
import '../features/dashboard/presentation/screens/admin_dashboard_screen.dart';
import '../features/dashboard/presentation/screens/student_dashboard_screen.dart';
import '../features/dashboard/presentation/screens/super_admin_dashboard_screen.dart';
import '../features/dashboard/presentation/screens/shell_screen.dart';
import '../features/dashboard/presentation/screens/institute_list_screen.dart';
import '../features/dashboard/presentation/screens/institute_details_screen.dart';
import '../features/auth/domain/entities/user_profile.dart';
import '../features/batch/presentation/screens/batch_list_screen.dart';
import '../features/student/presentation/screens/student_list_screen.dart';
import '../features/teacher/presentation/screens/teacher_list_screen.dart';
import '../features/attendance/presentation/screens/attendance_screen.dart';
import '../features/attendance/presentation/screens/take_attendance_screen.dart';
import '../features/attendance/presentation/screens/attendance_report_screen.dart';
import '../features/attendance/presentation/screens/qr_scanner_screen.dart';
import '../features/homework/presentation/screens/homework_screen.dart';
import '../features/exam/presentation/screens/exam_screen.dart';
import '../features/fees/presentation/screens/fees_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/splash/presentation/screens/splash_screen.dart';

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
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshStream(repository.authStateChanges),
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
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
            builder: (context, state) {
              final role = ref.read(authStateProvider).value?.role;
              if (role == UserProfileRole.student) return const StudentDashboardScreen();
              if (role == UserProfileRole.superAdmin) return const SuperAdminDashboardScreen();
              return const AdminDashboardScreen();
            },
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
            routes: [
              GoRoute(
                path: 'take',
                name: 'attendance-take',
                builder: (context, state) => const TakeAttendanceScreen(),
              ),
              GoRoute(
                path: 'reports',
                name: 'attendance-reports',
                builder: (context, state) => const AttendanceReportScreen(),
              ),
              GoRoute(
                path: 'scan',
                name: 'attendance-scan',
                builder: (context, state) => const QrScannerScreen(),
              ),
            ],
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
            path: '/institutes',
            name: 'institutes',
            builder: (context, state) => const InstituteListScreen(),
            routes: [
              GoRoute(
                path: ':id',
                name: 'institute-details',
                builder: (context, state) => InstituteDetailsScreen(
                  orgId: state.pathParameters['id']!,
                ),
              ),
            ],
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

      // 0. If we are on splash screen, let it handle its own navigation
      if (currentLoc == '/splash') return null;

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
      // (Unless they are a superAdmin, who doesn't need an org)
      if (user.organizationId == null && user.role != UserProfileRole.superAdmin && currentLoc != '/onboard') {
        return '/onboard';
      }

      // ── 4. Role-based route guards ──

      // Students cannot access admin/teacher-only routes
      if (user.role == UserProfileRole.student) {
        const studentBlockedRoutes = ['/batches', '/students', '/teachers', '/exams', '/institutes'];
        for (final route in studentBlockedRoutes) {
          if (currentLoc.startsWith(route)) return '/dashboard';
        }
      }

      // Admins/Teachers cannot access super-admin-only routes
      if (user.role == UserProfileRole.admin || user.role == UserProfileRole.teacher) {
        const adminBlockedRoutes = ['/institutes'];
        for (final route in adminBlockedRoutes) {
          if (currentLoc.startsWith(route)) return '/dashboard';
        }
      }

      return null;
    },
  );
});
