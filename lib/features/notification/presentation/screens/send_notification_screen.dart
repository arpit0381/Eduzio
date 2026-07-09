import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../batch/presentation/controllers/batch_controller.dart';

class SendNotificationScreen extends ConsumerStatefulWidget {
  const SendNotificationScreen({super.key});

  @override
  ConsumerState<SendNotificationScreen> createState() => _SendNotificationScreenState();
}

class _SendNotificationScreenState extends ConsumerState<SendNotificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();

  String _targetType = 'all'; // 'all', 'role', 'batch'
  String _selectedRole = 'student';
  String? _selectedBatchId;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendBroadcast() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(authStateProvider).value;
    if (user == null || user.organizationId == null) {
      setState(() {
        _errorMessage = 'Authentication organization context not found.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final client = Supabase.instance.client;

      // 1. Insert announcement in DB
      final targetRoles = _targetType == 'role'
          ? [_selectedRole]
          : ['student', 'teacher', 'admin', 'parent'];

      final announcementPayload = {
        'organization_id': user.organizationId!,
        'title': _titleCtrl.text.trim(),
        'content': _bodyCtrl.text.trim(),
        'target_roles': targetRoles,
        'batch_id': _targetType == 'batch' ? _selectedBatchId : null,
        'created_by': user.id,
      };

      await client.from('announcements').insert(announcementPayload);

      // 2. Invoke FCM Edge Function to deliver real-time push notification
      try {
        await client.functions.invoke(
          'send-fcm',
          body: {
            'title': _titleCtrl.text.trim(),
            'body': _bodyCtrl.text.trim(),
            'target': _targetType,
            'targetRole': _targetType == 'role' ? _selectedRole : null,
            'batchId': _targetType == 'batch' ? _selectedBatchId : null,
            'organizationId': user.organizationId!,
          },
        );
      } catch (fcmError) {
        // FCM delivery error is reported but does not fail the whole broadcast since DB insertion succeeded.
        debugPrint('FCM Function invocation failed: $fcmError');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification broadcast sent successfully!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to broadcast: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final batchesAsync = ref.watch(batchesListProvider);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Broadcast Alert'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Intro
              Card(
                color: colors.primary.withValues(alpha: 0.05),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(LucideIcons.send, color: colors.primary),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Send real-time push alerts and announcement board notifications to your students or staff immediately.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Title input
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Alert Title',
                  prefixIcon: Icon(LucideIcons.bellRing),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a notification title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Message Body input
              TextFormField(
                controller: _bodyCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Message Body',
                  prefixIcon: Icon(LucideIcons.messageSquareText),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a message body';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Target Select
              Text(
                'Target Audience',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'all', label: Text('All Users'), icon: Icon(LucideIcons.globe)),
                  ButtonSegment(value: 'role', label: Text('By Role'), icon: Icon(LucideIcons.shieldCheck)),
                  ButtonSegment(value: 'batch', label: Text('By Batch'), icon: Icon(LucideIcons.graduationCap)),
                ],
                selected: {_targetType},
                onSelectionChanged: (val) {
                  setState(() {
                    _targetType = val.first;
                  });
                },
              ),
              const SizedBox(height: 20),

              // Conditional target options
              if (_targetType == 'role') ...[
                DropdownButtonFormField<String>(
                  initialValue: _selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Select Target Role',
                    prefixIcon: Icon(LucideIcons.userCheck),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'student', child: Text('Students')),
                    DropdownMenuItem(value: 'teacher', child: Text('Teachers')),
                    DropdownMenuItem(value: 'admin', child: Text('Administrators')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedRole = val;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
              ] else if (_targetType == 'batch') ...[
                batchesAsync.when(
                  data: (batches) {
                    if (_selectedBatchId == null && batches.isNotEmpty) {
                      _selectedBatchId = batches.first.id;
                    }
                    return DropdownButtonFormField<String?>(
                      initialValue: _selectedBatchId,
                      decoration: const InputDecoration(
                        labelText: 'Select Target Batch',
                        prefixIcon: Icon(LucideIcons.group),
                      ),
                      items: batches.map((batch) {
                        return DropdownMenuItem<String?>(
                          value: batch.id,
                          child: Text(batch.name),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedBatchId = val;
                        });
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Text('Error loading batches: $err'),
                ),
                const SizedBox(height: 16),
              ],

              if (_errorMessage != null) ...[
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],

              // Actions
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      onPressed: _sendBroadcast,
                      icon: const Icon(LucideIcons.sendHorizontal),
                      label: const Text('Send Broadcast'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
