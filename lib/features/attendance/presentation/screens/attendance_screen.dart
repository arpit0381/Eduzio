import 'package:flutter/material.dart';
import '../../../../core/constants/sizes.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  String? _selectedBatch = 'Class 12 - Physics';
  DateTime _selectedDate = DateTime.now();

  final List<Map<String, dynamic>> _students = [
    {'name': 'Aarav Sharma', 'roll': 'EDZ2026001', 'status': 'present'},
    {'name': 'Ananya Patel', 'roll': 'EDZ2026002', 'status': 'present'},
    {'name': 'Kabir Singh', 'roll': 'EDZ2026003', 'status': 'absent'},
    {'name': 'Diya Sen', 'roll': 'EDZ2026004', 'status': 'leave'},
    {'name': 'Rohan Gupta', 'roll': 'EDZ2026005', 'status': 'present'},
  ];

  void _updateStatus(int index, String status) {
    setState(() {
      _students[index]['status'] = status;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'QR Scan Attendance',
            onPressed: () {},
          ),
          const SizedBox(width: AppSizes.sm),
        ],
      ),
      body: Column(
        children: [
          // Filter Panel
          Container(
            padding: const EdgeInsets.all(AppSizes.md),
            color: colors.surface,
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedBatch,
                    decoration: const InputDecoration(
                      labelText: 'Batch',
                      contentPadding: EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 8),
                    ),
                    items: ['Class 12 - Physics', 'Class 12 - Chemistry', 'Class 11 - Mathematics', 'IIT-JEE Crash Course']
                        .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                        .toList(),
                    onChanged: (value) => setState(() => _selectedBatch = value),
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                OutlinedButton.icon(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => _selectedDate = date);
                    }
                  },
                  icon: const Icon(Icons.calendar_month),
                  label: Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(120, 48),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Student List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSizes.md),
              itemCount: _students.length,
              itemBuilder: (context, index) {
                final student = _students[index];
                final status = student['status'];

                return Card(
                  margin: const EdgeInsets.only(bottom: AppSizes.sm),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.sm),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                student['name'],
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Roll No: ${student['roll']}',
                                style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        // Attendance Status Buttons
                        Row(
                          children: [
                            _buildStatusBtn('P', 'present', status, Colors.green, () => _updateStatus(index, 'present')),
                            const SizedBox(width: 4),
                            _buildStatusBtn('A', 'absent', status, Colors.red, () => _updateStatus(index, 'absent')),
                            const SizedBox(width: 4),
                            _buildStatusBtn('L', 'leave', status, Colors.orange, () => _updateStatus(index, 'leave')),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: colors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Attendance recorded successfully!')),
            );
          },
          child: const Text('Save Attendance'),
        ),
      ),
    );
  }

  Widget _buildStatusBtn(String label, String value, String currentStatus, Color color, VoidCallback onTap) {
    final isSelected = currentStatus == value;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade400,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
