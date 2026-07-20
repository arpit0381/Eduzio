import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  String _formatGoogleDriveUrl(String url) {
    if (url.contains('drive.google.com')) {
      final reg = RegExp(r'/d/([a-zA-Z0-9_-]+)');
      final match = reg.firstMatch(url);
      if (match != null) {
        final driveId = match.group(1);
        return 'https://drive.google.com/uc?export=download&id=$driveId';
      }
    }
    return url;
  }

  Future<Uint8List> _fetchPdfBytes(String fileUrl) async {
    final client = Supabase.instance.client;
    final formattedUrl = _formatGoogleDriveUrl(fileUrl);
    
    final Map<String, String> headers = {
      if (!kIsWeb)
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Accept': 'application/pdf,application/octet-stream,*/*',
    };

    final session = client.auth.currentSession;
    if (session != null) {
      headers['Authorization'] = 'Bearer ${session.accessToken}';
    }
    const anonKey = String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im50cnBpemxsYXFwbGJ5a3NqcWdyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI1MTA2ODAsImV4cCI6MjA5ODA4NjY4MH0.47NmxltJqxz9C4G6p-PRyUr2sQTYAuknehuWzw5yNXE',
    );
    headers['apikey'] = anonKey;

    final List<String> candidateUrls = [formattedUrl, fileUrl];

    // Supabase Signed URL candidate
    try {
      final uri = Uri.parse(fileUrl);
      if (uri.host.contains('supabase') && uri.pathSegments.contains('storage')) {
        final pathSegments = uri.pathSegments;
        final objectIdx = pathSegments.indexOf('object');
        if (objectIdx != -1 && objectIdx + 2 < pathSegments.length) {
          final bucketIdx = objectIdx + 2;
          final bucket = pathSegments[bucketIdx];
          final path = pathSegments.sublist(bucketIdx + 1).join('/');
          final signed = await client.storage.from(bucket).createSignedUrl(path, 3600);
          candidateUrls.insert(0, signed);
        }
      }
    } catch (e) {
      debugPrint('Supabase Signed URL generation error: $e');
    }

    final List<String> debugLog = [];

    // Attempt candidates with auth headers & safe headers
    for (final url in candidateUrls) {
      try {
        final response = await http.get(Uri.parse(url), headers: headers);
        if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
          return response.bodyBytes;
        }
        debugLog.add('$url [HTTP ${response.statusCode}]');
      } catch (e) {
        debugLog.add('$url [Error: $e]');
      }

      // Try without Supabase headers for public URLs
      try {
        final Map<String, String> safeHeaders = {
          if (!kIsWeb)
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        };
        final response = await http.get(
          Uri.parse(url),
          headers: safeHeaders.isEmpty ? null : safeHeaders,
        );
        if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
          return response.bodyBytes;
        }
      } catch (_) {}
    }

    // Direct Supabase SDK Storage Download fallback
    try {
      final uri = Uri.parse(fileUrl);
      if (uri.pathSegments.contains('storage')) {
        final pathSegments = uri.pathSegments;
        final objectIdx = pathSegments.indexOf('object');
        if (objectIdx != -1 && objectIdx + 2 < pathSegments.length) {
          final bucketIdx = objectIdx + 2;
          final bucket = pathSegments[bucketIdx];
          final path = pathSegments.sublist(bucketIdx + 1).join('/');
          final bytes = await client.storage.from(bucket).download(path);
          if (bytes.isNotEmpty) {
            return bytes;
          }
        }
      }
    } catch (e) {
      debugLog.add('Supabase SDK Download: $e');
    }

    throw Exception('Failed to load file preview. Tap "Open in Google Docs" or "Open Link" below.');
  }

  Future<void> _loadPdfBytes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final bytes = await _fetchPdfBytes(widget.note.fileUrl);
      if (mounted) {
        setState(() {
          _pdfBytes = bytes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _launchInBrowser({bool forceGoogleDocs = false}) async {
    try {
      String targetUrl = widget.note.fileUrl;

      if (forceGoogleDocs || !targetUrl.contains('drive.google.com')) {
        if (targetUrl.contains('drive.google.com')) {
          final reg = RegExp(r'/d/([a-zA-Z0-9_-]+)');
          final match = reg.firstMatch(targetUrl);
          if (match != null) {
            targetUrl = 'https://drive.google.com/file/d/${match.group(1)}/view';
          }
        } else {
          targetUrl = 'https://docs.google.com/gview?embedded=true&url=${Uri.encodeComponent(targetUrl)}';
        }
      }

      // If Supabase storage, generate signed URL
      final uri = Uri.parse(targetUrl);
      if (uri.host.contains('supabase') && uri.pathSegments.contains('storage')) {
        try {
          final pathSegments = uri.pathSegments;
          final objectIdx = pathSegments.indexOf('object');
          if (objectIdx != -1 && objectIdx + 2 < pathSegments.length) {
            final bucketIdx = objectIdx + 2;
            final bucket = pathSegments[bucketIdx];
            final path = pathSegments.sublist(bucketIdx + 1).join('/');
            targetUrl = await Supabase.instance.client.storage.from(bucket).createSignedUrl(path, 3600);
          }
        } catch (e) {
          debugPrint('Error creating signed url for browser: $e');
        }
      }

      final launchUri = Uri.parse(targetUrl);
      bool launched = await launchUrl(launchUri, mode: LaunchMode.externalApplication);
      if (!launched) {
        launched = await launchUrl(launchUri, mode: LaunchMode.platformDefault);
      }
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch browser for document.')),
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
          const SnackBar(content: Text('Preparing file for external viewer...')),
        );
      }

      final dir = await getTemporaryDirectory();
      final extension = widget.note.fileName.toLowerCase().endsWith('.pdf') ? '' : '.pdf';
      final sanitizedName = '${widget.note.fileName}$extension'.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final file = File('${dir.path}/$sanitizedName');

      Uint8List bytesToSave;
      if (_pdfBytes != null) {
        bytesToSave = _pdfBytes!;
      } else {
        bytesToSave = await _fetchPdfBytes(widget.note.fileUrl);
      }

      await file.writeAsBytes(bytesToSave);

      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done) {
        await _launchInBrowser();
      }
    } catch (e) {
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
            icon: const Icon(LucideIcons.fileText),
            tooltip: 'Open in Google Docs / Drive',
            onPressed: () => _launchInBrowser(forceGoogleDocs: true),
          ),
          IconButton(
            icon: const Icon(LucideIcons.externalLink),
            tooltip: 'Open Direct Link',
            onPressed: () => _launchInBrowser(),
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
                LucideIcons.fileText,
                size: 64,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Document Link Available',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? 'Tap below to view this document in Google Docs or your browser.',
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
                  FilledButton.icon(
                    onPressed: () => _launchInBrowser(forceGoogleDocs: true),
                    icon: const Icon(LucideIcons.fileText, size: 18),
                    label: const Text('Open in Google Docs'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _launchInBrowser(),
                    icon: const Icon(LucideIcons.externalLink, size: 18),
                    label: const Text('Open Direct Link'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _loadPdfBytes,
                    icon: const Icon(LucideIcons.refreshCw, size: 18),
                    label: const Text('Retry Preview'),
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
          icon: const Icon(LucideIcons.fileText),
          onPressed: (context, build, pageFormat) => _launchInBrowser(forceGoogleDocs: true),
        ),
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
                Icon(LucideIcons.fileText, size: 48, color: theme.colorScheme.primary),
                const SizedBox(height: 16),
                const Text(
                  'View Note in Google Docs',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => _launchInBrowser(forceGoogleDocs: true),
                  icon: const Icon(LucideIcons.fileText),
                  label: const Text('Open Note in Google Docs'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
