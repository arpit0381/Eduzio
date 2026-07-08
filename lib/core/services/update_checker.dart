import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class UpdateChecker {
  // App Compile Constants
  static const String currentVersion = '1.0.0';
  
  // The build date of the current app compiled binary
  static final DateTime currentBuildDate = DateTime.utc(2026, 7, 8, 17, 0); // July 8, 2026 17:00 UTC

  // GitHub Repository Constants
  static const String repoOwner = 'arpit0381';
  static const String repoName = 'Eduzio';
  
  // Direct Download Page URL
  static const String downloadPageUrl = 'https://arpit0381.github.io/Eduzio/';

  /// Checks for updates and displays a dialog if a new version is available.
  static Future<void> checkForUpdates(BuildContext context, {bool showNoUpdateToast = false}) async {
    try {
      final url = Uri.parse('https://api.github.com/repos/$repoOwner/$repoName/releases/tags/latest');
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        
        final String publishedAtStr = data['published_at'] as String;
        final DateTime publishedAt = DateTime.parse(publishedAtStr).toUtc();
        
        final String tagName = (data['tag_name'] ?? 'latest') as String;
        final String body = (data['body'] ?? 'Performance improvements and bug fixes.') as String;

        // Clean changelog (remove commit logs)
        final cleanChangelog = body.replaceAll(RegExp(r'Commit:\s*[a-f0-9]{40}', caseSensitive: false), '').trim();

        // Check if the published release date is newer than our app's build date
        if (publishedAt.isAfter(currentBuildDate)) {
          if (context.mounted) {
            _showUpdateDialog(context, tagName, publishedAt, cleanChangelog);
          }
        } else {
          if (showNoUpdateToast && context.mounted) {
            _showNoUpdateDialog(context);
          }
        }
      } else {
        if (showNoUpdateToast && context.mounted) {
          _showErrorDialog(context, 'Unable to retrieve update information. Please check back later.');
        }
      }
    } catch (e) {
      if (showNoUpdateToast && context.mounted) {
        _showErrorDialog(context, 'Connection failed: Please check your internet connection.');
      }
    }
  }

  static void _showUpdateDialog(
    BuildContext context,
    String version,
    DateTime publishDate,
    String changelog,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    
    final formattedDate = "${publishDate.day}/${publishDate.month}/${publishDate.year}";

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: theme.scaffoldBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: colors.outline.withValues(alpha: 0.1)),
          ),
          title: Row(
            children: [
              Icon(Icons.system_update_rounded, color: colors.primary, size: 28),
              const SizedBox(width: 12),
              const Text(
                'Update Available!',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'A new version of Eduzio is ready to download.',
                style: TextStyle(color: colors.onSurface.withValues(alpha: 0.8)),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Release Date:',
                    style: TextStyle(
                      color: colors.onSurfaceVariant.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    formattedDate,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                "What's New:",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.maxFinite,
                constraints: const BoxConstraints(maxHeight: 120),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.outline.withValues(alpha: 0.05)),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    changelog,
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.onSurfaceVariant.withValues(alpha: 0.8),
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.only(bottom: 16, right: 16, left: 16),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Later',
                style: TextStyle(color: colors.onSurfaceVariant.withValues(alpha: 0.6)),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: const Text('Update Now'),
              onPressed: () async {
                Navigator.of(context).pop();
                final uri = Uri.parse(downloadPageUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),
          ],
        );
      },
    );
  }

  static void _showNoUpdateDialog(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: theme.scaffoldBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.check_circle_outline_rounded, color: colors.primary, size: 28),
              const SizedBox(width: 12),
              const Text('Up to Date'),
            ],
          ),
          content: Text(
            'You are already running the latest version of Eduzio ($currentVersion).',
            style: TextStyle(color: colors.onSurface.withValues(alpha: 0.8)),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  static void _showErrorDialog(BuildContext context, String message) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: theme.scaffoldBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.error_outline_rounded, color: colors.error, size: 28),
              const SizedBox(width: 12),
              const Text('Update Check Failed'),
            ],
          ),
          content: Text(
            message,
            style: TextStyle(color: colors.onSurface.withValues(alpha: 0.8)),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
