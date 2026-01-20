import 'package:flutter/material.dart';
import 'theme.dart';

/// Types of snackbars
enum SnackbarType { success, error, warning, info }

/// A beautiful snackbar service for the app
class SnackbarService {
  /// Show a success snackbar
  static void showSuccess(BuildContext context, String message) {
    _show(context, message, SnackbarType.success);
  }

  /// Show an error snackbar
  static void showError(BuildContext context, String message) {
    _show(context, message, SnackbarType.error);
  }

  /// Show a warning snackbar
  static void showWarning(BuildContext context, String message) {
    _show(context, message, SnackbarType.warning);
  }

  /// Show an info snackbar
  static void showInfo(BuildContext context, String message) {
    _show(context, message, SnackbarType.info);
  }

  static void _show(BuildContext context, String message, SnackbarType type) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getIcon(type),
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: _getColor(type),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusS),
        ),
        margin: const EdgeInsets.all(AppDimens.paddingL),
        duration: Duration(seconds: type == SnackbarType.error ? 4 : 3),
        action: SnackBarAction(
          label: 'DISMISS',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  static IconData _getIcon(SnackbarType type) {
    switch (type) {
      case SnackbarType.success:
        return Icons.check_circle;
      case SnackbarType.error:
        return Icons.error;
      case SnackbarType.warning:
        return Icons.warning;
      case SnackbarType.info:
        return Icons.info;
    }
  }

  static Color _getColor(SnackbarType type) {
    switch (type) {
      case SnackbarType.success:
        return AppColors.success;
      case SnackbarType.error:
        return AppColors.error;
      case SnackbarType.warning:
        return AppColors.warning;
      case SnackbarType.info:
        return AppColors.info;
    }
  }
}
