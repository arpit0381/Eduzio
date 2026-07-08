import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../shared/presentation/widgets/mesh_gradient_background.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/domain/entities/user_profile.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _isSplashDelayOver = false;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _startSplashTimer();
  }

  Future<void> _startSplashTimer() async {
    // Wait for the animation to play beautifully (at least 2.5 seconds)
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;

    setState(() {
      _isSplashDelayOver = true;
    });
    _checkAuthAndNavigate();
  }

  void _checkAuthAndNavigate() {
    if (_hasNavigated || !mounted) return;

    final authState = ref.read(authStateProvider);
    
    // Only navigate if the auth state has completed loading
    if (!authState.isLoading) {
      _navigateToNextScreen(authState.value);
    }
  }

  void _navigateToNextScreen(UserProfile? user) {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;

    if (user == null) {
      context.go('/login');
    } else {
      if (user.organizationId == null && user.role != UserProfileRole.superAdmin) {
        context.go('/onboard');
      } else {
        context.go('/dashboard');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for auth state changes and navigate once loading is complete AND splash delay has passed
    ref.listen(authStateProvider, (previous, next) {
      if (_isSplashDelayOver && !next.isLoading && mounted) {
        _navigateToNextScreen(next.value);
      }
    });

    return Scaffold(
      body: Stack(
        children: [
          // The beautiful mesh gradient background
          const MeshGradientBackground(),
          
          // The Logo and branding
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Logo Container
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    size: 64,
                    color: Color(0xFF6B4EFF), // A vibrant pastel purple
                  ),
                )
                .animate()
                .scale(duration: 800.ms, curve: Curves.easeOutBack)
                .then()
                .shimmer(duration: 1200.ms, color: Colors.white54),
                
                const SizedBox(height: 24),
                
                // Typography
                Text(
                  'Eduzio',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -1.5,
                    color: const Color(0xFF1E293B),
                  ),
                )
                .animate()
                .fadeIn(delay: 400.ms, duration: 600.ms)
                .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
                
                const SizedBox(height: 12),
                
                Text(
                  'The Future of Education',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                    color: const Color(0xFF64748B),
                  ),
                )
                .animate()
                .fadeIn(delay: 800.ms, duration: 600.ms),
              ],
            ),
          ),
          
          // Loading indicator at bottom
          Positioned(
            bottom: 64,
            left: 0,
            right: 0,
            child: Center(
              child: const CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6B4EFF)),
              )
              .animate()
              .fadeIn(delay: 1200.ms, duration: 600.ms),
            ),
          ),
        ],
      ),
    );
  }
}
