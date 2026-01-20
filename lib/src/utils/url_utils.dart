import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Utility functions for launching URLs.
class UrlUtils {
  UrlUtils._();

  /// Launches a URL in the external browser.
  /// 
  /// Shows a snackbar error if launch fails.
  static Future<void> launchExternalUrl(
    BuildContext context,
    String url,
  ) async {
    final uri = Uri.parse(url);
    
    try {
      final canLaunch = await canLaunchUrl(uri);
      if (canLaunch) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        if (context.mounted) {
          _showError(context, 'Could not open link');
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showError(context, 'Error opening link: $e');
      }
    }
  }

  static void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
