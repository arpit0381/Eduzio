import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../domain/entities/attendance_record.dart';
import '../controllers/attendance_controller.dart';
import '../../../batch/presentation/controllers/batch_controller.dart';
import '../../../student/domain/entities/student_detail.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  String? _selectedBatchId;
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  bool _isProcessing = false;
  final List<StudentDetail> _scannedStudents = [];

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final batchesAsync = ref.watch(batchesListProvider);
    final theme = Theme.of(context);

    // QR scanning via camera is not supported on web
    if (kIsWeb) {
      return Scaffold(
        appBar: AppBar(title: const Text('Scan Student ID Cards')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.qr_code_scanner, size: 72, color: theme.hintColor),
              const SizedBox(height: 20),
              Text('Camera scanning is not available on web.',
                  style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                'Use the Eduzio mobile app to scan student ID card QR codes.',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Student ID Cards'),
        actions: [
          // Torch toggle
          ValueListenableBuilder<MobileScannerState>(
            valueListenable: _scannerController,
            builder: (context, state, child) {
              final torchOn = state.torchState == TorchState.on;
              return IconButton(
                icon: Icon(torchOn ? Icons.flash_on : Icons.flash_off),
                tooltip: torchOn ? 'Torch Off' : 'Torch On',
                onPressed: () => _scannerController.toggleTorch(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => _scannerController.switchCamera(),
          ),
        ],
      ),
      body: batchesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading batches: $err')),
        data: (batches) {
          if (batches.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'Create a batch before starting the QR Attendance scanner.',
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (_selectedBatchId == null && batches.isNotEmpty) {
            _selectedBatchId = batches.first.id;
          }

          return Column(
            children: [
              // Batch dropdown selector
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: DropdownButtonFormField<String>(
                  value: _selectedBatchId,
                  decoration: const InputDecoration(
                    labelText: 'Active Batch',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.group),
                  ),
                  items: batches.map<DropdownMenuItem<String>>((b) {
                    return DropdownMenuItem<String>(
                      value: b.id,
                      child: Text('${b.name} (${b.code})'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedBatchId = val;
                      _scannedStudents.clear();
                    });
                  },
                ),
              ),

              // Scanner Viewport
              Expanded(
                flex: 4,
                child: Stack(
                  children: [
                    MobileScanner(
                      controller: _scannerController,
                      onDetect: (capture) => _onDetectBarcode(capture),
                    ),
                    // Scanning window frame overlay
                    Center(
                      child: Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          border: Border.all(color: theme.colorScheme.primary, width: 3),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    if (_isProcessing)
                      Container(
                        color: Colors.black54,
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                  ],
                ),
              ),

              // Recently checked-in panel
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  color: theme.cardColor,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Checked In (${_scannedStudents.length} Students)',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: _scannedStudents.isEmpty
                            ? Center(
                                child: Text(
                                  'Ready to scan. Align QR on Student ID Card.',
                                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _scannedStudents.length,
                                itemBuilder: (context, index) {
                                  final student = _scannedStudents[index];
                                  return ListTile(
                                    leading: const CircleAvatar(
                                      backgroundColor: Colors.green,
                                      child: Icon(Icons.check, color: Colors.white),
                                    ),
                                    title: Text(
                                      student.profile.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Text(student.profile.email),
                                    trailing: const Text(
                                      'Present',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _onDetectBarcode(BarcodeCapture capture) async {
    if (_isProcessing || _selectedBatchId == null) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final rawValue = barcodes.first.rawValue;
    if (rawValue == null) return;

    // Parse the QR code format: eduzio://student/<id>
    String studentId = rawValue.trim();
    const prefix = 'eduzio://student/';
    if (studentId.startsWith(prefix)) {
      studentId = studentId.substring(prefix.length);
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // 1. Fetch batch students to verify if this student belongs to the active batch
      final studentsList = await ref.read(batchStudentsProvider(_selectedBatchId!).future);
      final student = studentsList.firstWhere(
        (s) => s.profile.id == studentId,
        orElse: () => throw Exception('Student not enrolled in this batch.'),
      );

      // Check if student is already scanned in this session
      final isAlreadyScanned = _scannedStudents.any((s) => s.profile.id == studentId);
      if (isAlreadyScanned) {
        throw Exception('${student.profile.name} is already checked in.');
      }

      // 2. Build attendance record
      final record = AttendanceRecord(
        id: '',
        organizationId: '', // Filled in by repo
        batchId: _selectedBatchId!,
        studentId: studentId,
        date: DateTime.now(),
        status: AttendanceStatus.present,
        remarks: 'Scanned via QR Code ID Card',
      );

      // 3. Persist to Isar & Supabase immediately
      await ref.read(attendanceControllerProvider.notifier).saveAttendance(
            batchId: _selectedBatchId!,
            date: DateTime.now(),
            records: [record],
          );

      setState(() {
        _scannedStudents.insert(0, student);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Checked in: ${student.profile.name}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      // Delay slightly to prevent double scanning the same card instantly
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
}
