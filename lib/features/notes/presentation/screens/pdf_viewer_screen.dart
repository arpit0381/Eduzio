import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/note.dart';

class PdfViewerScreen extends StatefulWidget {
  final Note note;

  const PdfViewerScreen({
    super.key,
    required this.note,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  Uint8List? _pdfBytes;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPdfBytes();
  }

  Future<void> _loadPdfBytes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final uri = Uri.parse(widget.note.fileUrl);
      final response = await http.get(uri);

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        if (mounted) {
          setState(() {
            _pdfBytes = response.bodyBytes;
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Server returned status code ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _launchInBrowser() async {
    try {
      final uri = Uri.parse(widget.note.fileUrl);
      bool launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch browser for PDF.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening link: $e')),
        );
      }
    }
  }

  Future<void> _openWithExternalApp() async {
    if (kIsWeb) {
      await _launchInBrowser();
      return;
    }

    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Opening file...')),
        );
      }

      final dir = await getTemporaryDirectory();
      final extension = widget.note.fileName.toLowerCase().endsWith('.pdf') ? '' : '.pdf';
      final sanitizedName = '${widget.note.fileName}$extension'.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final file = File('${dir.path}/$sanitizedName');

      if (_pdfBytes != null) {
        await file.writeAsBytes(_pdfBytes!);
      } else {
        final response = await http.get(Uri.parse(widget.note.fileUrl));
        if (response.statusCode == 200) {
          await file.writeAsBytes(response.bodyBytes);
        } else {
          throw Exception('Failed to download file: ${response.statusCode}');
        }
      }

      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done) {
        // Fallback to browser if no external PDF viewer app found
        await _launchInBrowser();
      }
    } catch (e) {
      // Fallback to launching URL in external browser
      await _launchInBrowser();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.note.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              widget.note.fileName,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.externalLink),
            tooltip: 'Open in Browser',
            onPressed: _launchInBrowser,
          ),
          IconButton(
            icon: const Icon(LucideIcons.share2),
            tooltip: 'Open / Share External',
            onPressed: _openWithExternalApp,
          ),
        ],
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Loading note document...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null || _pdfBytes == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.fileWarning,
                size: 64,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Could not load document preview',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? 'Unknown error occurred while opening file.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _loadPdfBytes,
                    icon: const Icon(LucideIcons.refreshCw, size: 18),
                    label: const Text('Retry'),
                  ),
                  FilledButton.icon(
                    onPressed: _launchInBrowser,
                    icon: const Icon(LucideIcons.externalLink, size: 18),
                    label: const Text('Open in Browser'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _openWithExternalApp,
                    icon: const Icon(LucideIcons.download, size: 18),
                    label: const Text('Download / External App'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return PdfPreview(
      build: (format) => _pdfBytes!,
      pdfFileName: widget.note.fileName,
      canChangePageFormat: false,
      canChangeOrientation: false,
      canDebug: false,
      actions: [
        PdfPreviewAction(
          icon: const Icon(LucideIcons.externalLink),
          onPressed: (context, build, pageFormat) => _launchInBrowser(),
        ),
      ],
      onError: (context, error) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.alertCircle, size: 48, color: theme.colorScheme.error),
                const SizedBox(height: 16),
                const Text(
                  'Format supported via external viewer',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _launchInBrowser,
                  icon: const Icon(LucideIcons.externalLink),
                  label: const Text('Open Note in Browser'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
