import 'package:flutter/material.dart';

import 'app_error_handler.dart';
import 'app_exceptions.dart';

/// Shows a snackbar with an appropriate error message.
///
/// Uses [AppErrorHandler] to convert the error into a user-friendly message.
/// Optionally shows a retry action for recoverable errors.
void showAppError(
  BuildContext context,
  Object error, {
  VoidCallback? onRetry,
  Duration duration = const Duration(seconds: 4),
}) {
  final appError = error is AppException ? error : AppErrorHandler.handle(error);
  final isRecoverable = AppErrorHandler.isRecoverable(error);
  final theme = Theme.of(context);

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(
            _iconForError(appError),
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              appError.message,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      backgroundColor: _colorForError(appError, theme),
      duration: duration,
      action: onRetry != null && isRecoverable
          ? SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: onRetry,
            )
          : null,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      margin: const EdgeInsets.all(16),
    ),
  );
}

/// Shows an error dialog for critical errors that need acknowledgment.
Future<void> showAppErrorDialog(
  BuildContext context,
  Object error, {
  String? title,
  VoidCallback? onDismiss,
}) async {
  final appError = error is AppException ? error : AppErrorHandler.handle(error);
  final theme = Theme.of(context);

  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      icon: Icon(
        _iconForError(appError),
        color: _colorForError(appError, theme),
        size: 48,
      ),
      title: Text(title ?? _titleForError(appError)),
      content: Text(appError.message),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onDismiss?.call();
          },
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

IconData _iconForError(AppException error) {
  return switch (error) {
    NetworkException() => Icons.wifi_off_rounded,
    AuthException() => Icons.lock_outline_rounded,
    PermissionException() => Icons.block_rounded,
    ValidationException() => Icons.warning_amber_rounded,
    NotFoundException() => Icons.search_off_rounded,
    ServerException() => Icons.cloud_off_rounded,
    StorageException() => Icons.folder_off_rounded,
    RateLimitException() => Icons.hourglass_empty_rounded,
    _ => Icons.error_outline_rounded,
  };
}

Color _colorForError(AppException error, ThemeData theme) {
  return switch (error) {
    NetworkException() => Colors.orange.shade700,
    AuthException() => theme.colorScheme.error,
    PermissionException() => Colors.red.shade700,
    ValidationException() => Colors.amber.shade700,
    NotFoundException() => Colors.blueGrey,
    ServerException() => Colors.red.shade600,
    StorageException() => Colors.purple.shade600,
    RateLimitException() => Colors.orange.shade600,
    _ => theme.colorScheme.error,
  };
}

String _titleForError(AppException error) {
  return switch (error) {
    NetworkException() => 'Connection Error',
    AuthException() => 'Authentication Error',
    PermissionException() => 'Permission Denied',
    ValidationException() => 'Invalid Data',
    NotFoundException() => 'Not Found',
    ServerException() => 'Server Error',
    StorageException() => 'Storage Error',
    RateLimitException() => 'Too Many Requests',
    _ => 'Error',
  };
}

/// Extension on [BuildContext] for convenient error display.
extension AppErrorContext on BuildContext {
  /// Shows an error snackbar.
  void showError(Object error, {VoidCallback? onRetry}) {
    showAppError(this, error, onRetry: onRetry);
  }

  /// Shows an error dialog.
  Future<void> showErrorDialog(Object error, {String? title}) {
    return showAppErrorDialog(this, error, title: title);
  }
}
