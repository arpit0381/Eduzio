import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/sizes.dart';
import '../controllers/auth_controller.dart';
import 'package:go_router/go_router.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Owner controllers
  final _ownerNameController = TextEditingController();
  final _ownerEmailController = TextEditingController();
  final _ownerPasswordController = TextEditingController();

  // Institute controllers
  final _instNameController = TextEditingController();
  final _subdomainController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _ownerNameController.dispose();
    _ownerEmailController.dispose();
    _ownerPasswordController.dispose();
    _instNameController.dispose();
    _subdomainController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleOnboard() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await ref.read(authControllerProvider.notifier).onboard(
              orgName: _instNameController.text.trim(),
              subdomain: _subdomainController.text.trim().toLowerCase(),
              phone: _phoneController.text.trim(),
              ownerName: _ownerNameController.text.trim(),
              ownerEmail: _ownerEmailController.text.trim(),
              ownerPassword: _ownerPasswordController.text,
            );
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Onboarding successful! Please login with your administrator account.'),
              backgroundColor: Colors.green,
            ),
          );
          context.go('/login');
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Onboarding failed: ${e.toString().replaceAll('Exception: ', '')}'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 550),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.xl),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.auto_stories, size: 36, color: colors.primary),
                          const SizedBox(width: AppSizes.sm),
                          Text(
                            'Eduzio',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: colors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.xs),
                      Text(
                        'Onboard Your Coaching Institute',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSizes.xl),

                      // Section 1: Institute Info
                      Row(
                        children: [
                          Icon(Icons.business, color: colors.primary),
                          const SizedBox(width: AppSizes.sm),
                          Text(
                            'Institute Details',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colors.primary,
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      const SizedBox(height: AppSizes.sm),
                      
                      TextFormField(
                        controller: _instNameController,
                        decoration: const InputDecoration(
                          labelText: 'Coaching Institute Name',
                          prefixIcon: Icon(Icons.apartment),
                        ),
                        validator: (value) => value == null || value.isEmpty ? 'Enter institute name' : null,
                      ),
                      const SizedBox(height: AppSizes.md),

                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _subdomainController,
                              decoration: const InputDecoration(
                                labelText: 'Subdomain / Short Slug',
                                prefixIcon: Icon(Icons.link),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Enter subdomain';
                                if (!RegExp(r'^[a-z0-9\-]+$').hasMatch(value)) {
                                  return 'Use letters, numbers, hyphens only';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: AppSizes.sm),
                          Expanded(
                            flex: 2,
                            child: Container(
                              height: 56,
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.only(left: AppSizes.sm),
                              decoration: BoxDecoration(
                                color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                                border: Border.all(color: colors.outline.withValues(alpha: 0.2)),
                              ),
                              child: Text(
                                '.eduzio.in',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.md),

                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Official Phone Number',
                          prefixIcon: Icon(Icons.phone),
                        ),
                        validator: (value) => value == null || value.isEmpty ? 'Enter contact number' : null,
                      ),
                      const SizedBox(height: AppSizes.xl),

                      // Section 2: Owner Info
                      Row(
                        children: [
                          Icon(Icons.person, color: colors.primary),
                          const SizedBox(width: AppSizes.sm),
                          Text(
                            'Owner / Admin Account',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colors.primary,
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      const SizedBox(height: AppSizes.sm),

                      TextFormField(
                        controller: _ownerNameController,
                        decoration: const InputDecoration(
                          labelText: 'Administrator Full Name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (value) => value == null || value.isEmpty ? 'Enter administrator name' : null,
                      ),
                      const SizedBox(height: AppSizes.md),

                      TextFormField(
                        controller: _ownerEmailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Administrator Email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Enter administrator email';
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                            return 'Enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSizes.md),

                      TextFormField(
                        controller: _ownerPasswordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Security Password',
                          prefixIcon: const Icon(Icons.lock_outlined),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Enter a password';
                          if (value.length < 6) return 'Password must be at least 6 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSizes.xl),

                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleOnboard,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Complete Onboarding'),
                      ),
                      const SizedBox(height: AppSizes.md),

                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            "Already have an account?",
                            style: TextStyle(color: colors.onSurfaceVariant),
                          ),
                          TextButton(
                            onPressed: () => context.go('/login'),
                            child: const Text('Sign In'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
