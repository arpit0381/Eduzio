import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/domain/entities/user_profile.dart';
import '../controllers/fees_controller.dart';
import '../../domain/entities/student_fee.dart';

class FeesScreen extends ConsumerStatefulWidget {
  const FeesScreen({super.key});

  @override
  ConsumerState<FeesScreen> createState() => _FeesScreenState();
}

class _FeesScreenState extends ConsumerState<FeesScreen> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _filterTab = 'all'; // 'all', 'pending', 'paid'

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showReceiptSheet(BuildContext context, StudentFee fee) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final colors = Theme.of(ctx).colorScheme;
        final theme = Theme.of(ctx);
        final isPaid = fee.status == 'paid';
        final outstanding = fee.amount - fee.paidAmount;

        return Container(
          margin: const EdgeInsets.all(16),
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.onSurfaceVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Header Badge & Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (isPaid ? Colors.green : colors.primary).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          LucideIcons.receipt,
                          color: isPaid ? Colors.green : colors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fee Statement & Receipt',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Invoice #${fee.id.substring(0, fee.id.length > 8 ? 8 : fee.id.length).toUpperCase()}',
                            style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant.withValues(alpha: 0.6)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isPaid ? Colors.green : (fee.paidAmount > 0 ? Colors.amber : colors.error)).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      fee.status.toUpperCase(),
                      style: TextStyle(
                        color: isPaid ? Colors.green : (fee.paidAmount > 0 ? Colors.amber.shade800 : colors.error),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),

              // Details grid
              _buildReceiptRow(context, 'Student Name', fee.studentName),
              if (fee.batchName != null && fee.batchName!.isNotEmpty)
                _buildReceiptRow(context, 'Batch / Course', fee.batchName!),
              _buildReceiptRow(context, 'Due Date', DateFormat('dd MMMM yyyy').format(fee.dueDate)),
              _buildReceiptRow(context, 'Total Fee Amount', '₹${fee.amount.toStringAsFixed(2)}'),
              _buildReceiptRow(context, 'Amount Paid', '₹${fee.paidAmount.toStringAsFixed(2)}', isHighlight: isPaid),
              _buildReceiptRow(context, 'Remaining Balance', '₹${outstanding.toStringAsFixed(2)}', isWarning: outstanding > 0),
              if (fee.paidDate != null)
                _buildReceiptRow(context, 'Last Payment Date', DateFormat('dd MMMM yyyy, hh:mm a').format(fee.paidDate!)),
              if (fee.remarks != null && fee.remarks!.isNotEmpty)
                _buildReceiptRow(context, 'Notes / Remarks', fee.remarks!),

              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(LucideIcons.check),
                label: const Text('Close Statement'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReceiptRow(BuildContext context, String label, String value, {bool isHighlight = false, bool isWarning = false}) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isHighlight
                    ? Colors.green
                    : (isWarning ? colors.error : colors.onSurface),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentSheet(BuildContext context, StudentFee fee) {
    final outstanding = fee.amount - fee.paidAmount;
    final amountCtrl = TextEditingController(text: outstanding.toStringAsFixed(0));
    final remarksCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final colors = Theme.of(ctx).colorScheme;
        final theme = Theme.of(ctx);

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              margin: const EdgeInsets.all(16),
              padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: colors.onSurfaceVariant.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Record Payment',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Student: ${fee.studentName}\nTotal Due: ₹${fee.amount.toStringAsFixed(2)} | Paid: ₹${fee.paidAmount.toStringAsFixed(2)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Payment Amount (INR)',
                        prefixIcon: Icon(LucideIcons.indianRupee),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Enter payment amount';
                        }
                        final numVal = double.tryParse(val.trim());
                        if (numVal == null || numVal <= 0) {
                          return 'Enter a valid amount';
                        }
                        if (numVal > outstanding) {
                          return 'Cannot exceed outstanding balance of ₹${outstanding.toStringAsFixed(2)}';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: remarksCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Payment Remarks (Optional)',
                        prefixIcon: Icon(LucideIcons.fileText),
                      ),
                    ),
                    const SizedBox(height: 24),
                    isSaving
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton.icon(
                            onPressed: () async {
                              if (!formKey.currentState!.validate()) return;
                              setModalState(() {
                                isSaving = true;
                              });

                              try {
                                await ref.read(feesControllerProvider.notifier).submitPayment(
                                      feeId: fee.id,
                                      paidAmount: double.parse(amountCtrl.text.trim()),
                                      remarks: remarksCtrl.text.trim().isEmpty ? null : remarksCtrl.text.trim(),
                                    );
                                if (ctx.mounted) {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Payment registered successfully!')),
                                  );
                                }
                              } catch (e) {
                                setModalState(() {
                                  isSaving = false;
                                });
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed to submit: $e')),
                                  );
                                }
                              }
                            },
                            icon: const Icon(LucideIcons.check),
                            label: const Text('Confirm Payment'),
                          ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final feesAsync = ref.watch(feesControllerProvider);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final isAdmin = user != null && (user.role == UserProfileRole.admin || user.role == UserProfileRole.superAdmin || user.role == UserProfileRole.teacher);
    final isStudent = !isAdmin;

    final horizontalPadding = getValueForScreenType<double>(
      context: context,
      mobile: 16,
      tablet: 24,
      desktop: 24,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(isStudent ? 'My Fees Dashboard' : 'Fee Management'),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => context.go('/fees/add'),
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
              ),
              icon: const Icon(LucideIcons.creditCard),
              label: const Text('Add Fee Record'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () => ref.read(feesControllerProvider.notifier).refresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Banner
              Builder(
                builder: (context) {
                  final isMobile = getValueForScreenType<bool>(
                    context: context,
                    mobile: true,
                    tablet: false,
                    desktop: false,
                  );
                  return Card(
                    elevation: 0,
                    color: colors.primaryContainer.withValues(alpha: 0.15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: BorderSide(color: colors.primary.withValues(alpha: 0.08)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isStudent ? 'My Fee Dashboard 💳' : 'Fee Summary 💰',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colors.onSurface,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  isStudent
                                      ? 'Track your total paid fees, pending balance dues, and view payment statements.'
                                      : 'Track collections, record student fee structures, record payments, and manage pending balances.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colors.onSurfaceVariant.withValues(alpha: 0.7),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!isMobile) ...[
                            const SizedBox(width: 24),
                            Expanded(
                              flex: 2,
                              child: SvgPicture.asset(
                                'public/undraw_calculator_os9t.svg',
                                height: 100,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }
              ),
              const SizedBox(height: 24),

              // Summary Stat Cards
              feesAsync.when(
                data: (fees) {
                  double totalPaid = 0;
                  double totalOutstanding = 0;

                  for (final fee in fees) {
                    totalPaid += fee.paidAmount;
                    if (fee.status != 'paid') {
                      totalOutstanding += (fee.amount - fee.paidAmount);
                    }
                  }

                  return Builder(
                    builder: (context) {
                      final isMobile = getValueForScreenType<bool>(
                        context: context,
                        mobile: true,
                        tablet: false,
                        desktop: false,
                      );
                      return Flex(
                        direction: isMobile ? Axis.vertical : Axis.horizontal,
                        crossAxisAlignment: isMobile ? CrossAxisAlignment.stretch : CrossAxisAlignment.start,
                        children: [
                          isMobile 
                            ? _buildFeeCard(isStudent ? 'Total Paid' : 'Total Collected', '₹${totalPaid.toStringAsFixed(0)}', true, theme, colors)
                            : Expanded(child: _buildFeeCard(isStudent ? 'Total Paid' : 'Total Collected', '₹${totalPaid.toStringAsFixed(0)}', true, theme, colors)),
                          
                          if (!isMobile) const SizedBox(width: 16) else const SizedBox(height: 16),
                          
                          isMobile 
                            ? _buildFeeCard(isStudent ? 'Pending Balance' : 'Outstanding Dues', '₹${totalOutstanding.toStringAsFixed(0)}', false, theme, colors)
                            : Expanded(child: _buildFeeCard(isStudent ? 'Pending Balance' : 'Outstanding Dues', '₹${totalOutstanding.toStringAsFixed(0)}', false, theme, colors)),
                        ],
                      );
                    }
                  );
                },
                loading: () => const Center(child: LinearProgressIndicator()),
                error: (err, _) => Text('Error calculating summary: $err'),
              ),
              const SizedBox(height: 32),

              // Search Bar (Admin-only)
              if (isAdmin) ...[
                SearchBar(
                  controller: _searchCtrl,
                  hintText: 'Search by student name...',
                  leading: const Icon(LucideIcons.search, size: 20),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.trim().toLowerCase();
                    });
                  },
                  elevation: WidgetStateProperty.all(0),
                  backgroundColor: WidgetStateProperty.all(colors.surfaceContainerHighest.withValues(alpha: 0.3)),
                  padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 16)),
                ),
                const SizedBox(height: 24),
              ],

              // Filter Chips for Students
              if (isStudent) ...[
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text('All Invoices'),
                      selected: _filterTab == 'all',
                      onSelected: (val) => setState(() => _filterTab = 'all'),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Pending Dues'),
                      selected: _filterTab == 'pending',
                      onSelected: (val) => setState(() => _filterTab = 'pending'),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Paid'),
                      selected: _filterTab == 'paid',
                      onSelected: (val) => setState(() => _filterTab = 'paid'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],

              // Header for List
              Text(
                isAdmin ? 'Dues & Collections' : 'Your Invoices',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),

              // Fees List
              feesAsync.when(
                data: (fees) {
                  final filteredFees = fees.where((fee) {
                    if (isAdmin) {
                      return fee.studentName.toLowerCase().contains(_searchQuery);
                    } else {
                      if (_filterTab == 'pending') return fee.status != 'paid';
                      if (_filterTab == 'paid') return fee.status == 'paid';
                      return true;
                    }
                  }).toList();

                  if (filteredFees.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40.0),
                        child: Column(
                          children: [
                            Icon(LucideIcons.fileX, size: 48, color: colors.onSurfaceVariant.withValues(alpha: 0.4)),
                            const SizedBox(height: 16),
                            Text(
                              isStudent ? 'No fee invoices found' : 'No fee records found',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: colors.onSurfaceVariant.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredFees.length,
                    itemBuilder: (context, index) {
                      final fee = filteredFees[index];
                      final outstanding = fee.amount - fee.paidAmount;
                      final isPaid = fee.status == 'paid';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () => _showReceiptSheet(context, fee),
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: (isPaid ? Colors.green : colors.error).withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(
                                    isPaid ? LucideIcons.checkCircle2 : LucideIcons.alertTriangle,
                                    color: isPaid ? Colors.green : colors.error,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (isAdmin) ...[
                                        Text(
                                          fee.studentName,
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                      ],
                                      Text(
                                        fee.batchName != null && fee.batchName!.isNotEmpty
                                            ? fee.batchName!
                                            : 'Global Fee Structure',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          fontWeight: isAdmin ? FontWeight.normal : FontWeight.bold,
                                          color: colors.onSurfaceVariant.withValues(alpha: 0.8),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Due Date: ${DateFormat('dd MMM yyyy').format(fee.dueDate)}',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: colors.onSurfaceVariant.withValues(alpha: 0.5),
                                        ),
                                      ),
                                      if (fee.remarks != null && fee.remarks!.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'Note: ${fee.remarks}',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: colors.onSurfaceVariant.withValues(alpha: 0.6),
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '₹${fee.amount.toStringAsFixed(0)}',
                                      style: GoogleFonts.inter(
                                        textStyle: theme.textTheme.titleMedium?.copyWith(
                                          color: isPaid ? Colors.green : colors.error,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    if (!isPaid) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Due: ₹${outstanding.toStringAsFixed(0)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: colors.onSurfaceVariant.withValues(alpha: 0.6),
                                        ),
                                      ),
                                    ],
                                    if (isAdmin && !isPaid) ...[
                                      const SizedBox(height: 8),
                                      InkWell(
                                        onTap: () => _showPaymentSheet(context, fee),
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: colors.primary,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            'Collect',
                                            style: theme.textTheme.labelMedium?.copyWith(
                                              color: colors.onPrimary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ] else if (isStudent) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: (isPaid ? Colors.green : colors.error).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          isPaid ? 'PAID' : 'PENDING',
                                          style: TextStyle(
                                            color: isPaid ? Colors.green : colors.error,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Error: $err')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeeCard(String title, String amount, bool isPositive, ThemeData theme, ColorScheme colors) {
    return Card(
      color: colors.primary.withValues(alpha: 0.03),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Icon(
                  isPositive ? LucideIcons.arrowUpRight : LucideIcons.arrowDownRight, 
                  color: isPositive ? Colors.green : Colors.red, 
                  size: 18,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              amount,
              style: GoogleFonts.inter(
                textStyle: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
