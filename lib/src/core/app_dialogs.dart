import 'package:flutter/material.dart';
import 'theme.dart';

/// Types of dialogs available
enum DialogType { success, error, warning, info, confirm }

/// A beautiful, reusable dialog system for the app
class AppDialogs {
  /// Show a success dialog
  static Future<void> showSuccess(
    BuildContext context, {
    required String title,
    required String message,
    String buttonText = 'OK',
    VoidCallback? onPressed,
  }) {
    return _showDialog(
      context,
      type: DialogType.success,
      title: title,
      message: message,
      primaryButtonText: buttonText,
      onPrimaryPressed: onPressed,
    );
  }

  /// Show an error dialog
  static Future<void> showError(
    BuildContext context, {
    required String title,
    required String message,
    String buttonText = 'OK',
    VoidCallback? onPressed,
  }) {
    return _showDialog(
      context,
      type: DialogType.error,
      title: title,
      message: message,
      primaryButtonText: buttonText,
      onPrimaryPressed: onPressed,
    );
  }

  /// Show a warning dialog
  static Future<void> showWarning(
    BuildContext context, {
    required String title,
    required String message,
    String buttonText = 'OK',
    VoidCallback? onPressed,
  }) {
    return _showDialog(
      context,
      type: DialogType.warning,
      title: title,
      message: message,
      primaryButtonText: buttonText,
      onPrimaryPressed: onPressed,
    );
  }

  /// Show an info dialog
  static Future<void> showInfo(
    BuildContext context, {
    required String title,
    required String message,
    String buttonText = 'OK',
    VoidCallback? onPressed,
  }) {
    return _showDialog(
      context,
      type: DialogType.info,
      title: title,
      message: message,
      primaryButtonText: buttonText,
      onPrimaryPressed: onPressed,
    );
  }

  /// Show a confirmation dialog
  static Future<bool> showConfirmation(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDangerous = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _ConfirmationDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        isDangerous: isDangerous,
      ),
    );
    return result ?? false;
  }

  /// Show a loading dialog
  static void showLoading(
    BuildContext context, {
    String message = 'Please wait...',
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _LoadingDialog(message: message),
    );
  }

  /// Hide the loading dialog
  static void hideLoading(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  /// Internal method to show dialogs
  static Future<void> _showDialog(
    BuildContext context, {
    required DialogType type,
    required String title,
    required String message,
    required String primaryButtonText,
    VoidCallback? onPrimaryPressed,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _AlertDialogContent(
        type: type,
        title: title,
        message: message,
        primaryButtonText: primaryButtonText,
        onPrimaryPressed: onPrimaryPressed,
      ),
    );
  }
}

/// Alert dialog content widget
class _AlertDialogContent extends StatelessWidget {
  final DialogType type;
  final String title;
  final String message;
  final String primaryButtonText;
  final VoidCallback? onPrimaryPressed;

  const _AlertDialogContent({
    required this.type,
    required this.title,
    required this.message,
    required this.primaryButtonText,
    this.onPrimaryPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusL),
      ),
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.paddingXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIcon(),
            const SizedBox(height: AppDimens.paddingL),
            Text(
              title,
              style: AppTextStyles.heading3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimens.paddingS),
            Text(
              message,
              style: AppTextStyles.bodySecondary,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimens.paddingXL),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onPrimaryPressed?.call();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getColor(),
                  padding: const EdgeInsets.symmetric(vertical: AppDimens.paddingM),
                ),
                child: Text(primaryButtonText),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: _getColor().withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        _getIcon(),
        color: _getColor(),
        size: 40,
      ),
    );
  }

  IconData _getIcon() {
    switch (type) {
      case DialogType.success:
        return Icons.check_circle_outline;
      case DialogType.error:
        return Icons.error_outline;
      case DialogType.warning:
        return Icons.warning_amber_outlined;
      case DialogType.info:
        return Icons.info_outline;
      case DialogType.confirm:
        return Icons.help_outline;
    }
  }

  Color _getColor() {
    switch (type) {
      case DialogType.success:
        return AppColors.success;
      case DialogType.error:
        return AppColors.error;
      case DialogType.warning:
        return AppColors.warning;
      case DialogType.info:
        return AppColors.info;
      case DialogType.confirm:
        return AppColors.primary;
    }
  }
}

/// Confirmation dialog widget
class _ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final bool isDangerous;

  const _ConfirmationDialog({
    required this.title,
    required this.message,
    required this.confirmText,
    required this.cancelText,
    required this.isDangerous,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusL),
      ),
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.paddingXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: (isDangerous ? AppColors.error : AppColors.warning).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isDangerous ? Icons.warning_amber_outlined : Icons.help_outline,
                color: isDangerous ? AppColors.error : AppColors.warning,
                size: 40,
              ),
            ),
            const SizedBox(height: AppDimens.paddingL),
            Text(
              title,
              style: AppTextStyles.heading3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimens.paddingS),
            Text(
              message,
              style: AppTextStyles.bodySecondary,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimens.paddingXL),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(cancelText),
                  ),
                ),
                const SizedBox(width: AppDimens.paddingM),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDangerous ? AppColors.error : AppColors.primary,
                    ),
                    child: Text(confirmText),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Loading dialog widget
class _LoadingDialog extends StatelessWidget {
  final String message;

  const _LoadingDialog({required this.message});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusL),
        ),
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.paddingXL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: AppDimens.paddingL),
              Text(
                message,
                style: AppTextStyles.subtitle,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
