/// Application-specific exceptions for consistent error handling.
///
/// These exceptions provide typed errors that can be handled uniformly
/// across the application, with user-friendly messages.
library;

/// Base class for all application exceptions.
abstract class AppException implements Exception {
  const AppException(this.message, [this.code, this.originalError]);

  /// User-friendly error message.
  final String message;

  /// Optional error code for categorization.
  final String? code;

  /// The original error that caused this exception, if any.
  final Object? originalError;

  @override
  String toString() => 'AppException: $message${code != null ? ' ($code)' : ''}';
}

/// Network-related errors (no connection, timeout, etc.)
class NetworkException extends AppException {
  const NetworkException([
    String message = 'Unable to connect. Please check your internet connection.',
    String? code,
    Object? originalError,
  ]) : super(message, code, originalError);
}

/// Authentication errors (invalid credentials, session expired, etc.)
class AuthException extends AppException {
  const AuthException([
    String message = 'Authentication failed. Please sign in again.',
    String? code,
    Object? originalError,
  ]) : super(message, code, originalError);

  /// Session has expired and user needs to re-authenticate.
  const AuthException.sessionExpired()
      : super('Your session has expired. Please sign in again.', 'session_expired');

  /// Invalid credentials provided.
  const AuthException.invalidCredentials()
      : super('Invalid email or password.', 'invalid_credentials');

  /// User not found.
  const AuthException.userNotFound()
      : super('No account found with this email.', 'user_not_found');

  /// Email already in use.
  const AuthException.emailInUse()
      : super('An account with this email already exists.', 'email_in_use');

  /// Weak password.
  const AuthException.weakPassword()
      : super('Password is too weak. Please use a stronger password.', 'weak_password');
}

/// Permission/authorization errors.
class PermissionException extends AppException {
  const PermissionException([
    String message = 'You don\'t have permission to perform this action.',
    String? code,
    Object? originalError,
  ]) : super(message, code, originalError);
}

/// Data validation errors.
class ValidationException extends AppException {
  const ValidationException([
    String message = 'The provided data is invalid.',
    String? code,
    Object? originalError,
  ]) : super(message, code, originalError);

  /// Factory for field-specific validation errors.
  factory ValidationException.forField(String field, String reason) {
    return ValidationException('$field: $reason', 'validation_error');
  }
}

/// Resource not found errors.
class NotFoundException extends AppException {
  const NotFoundException([
    String message = 'The requested resource was not found.',
    String? code,
    Object? originalError,
  ]) : super(message, code, originalError);

  /// Factory for specific resource types.
  factory NotFoundException.forResource(String resourceType) {
    return NotFoundException('$resourceType not found.', 'not_found');
  }
}

/// Server/backend errors.
class ServerException extends AppException {
  const ServerException([
    String message = 'Something went wrong on our end. Please try again later.',
    String? code,
    Object? originalError,
  ]) : super(message, code, originalError);
}

/// Storage/file upload errors.
class StorageException extends AppException {
  const StorageException([
    String message = 'Failed to upload or retrieve file.',
    String? code,
    Object? originalError,
  ]) : super(message, code, originalError);

  /// File is too large.
  const StorageException.fileTooLarge([int? maxSizeMB])
      : super(
          maxSizeMB != null
              ? 'File is too large. Maximum size is ${maxSizeMB}MB.'
              : 'File is too large.',
          'file_too_large',
        );

  /// Invalid file type.
  const StorageException.invalidFileType([String? allowedTypes])
      : super(
          allowedTypes != null
              ? 'Invalid file type. Allowed types: $allowedTypes'
              : 'Invalid file type.',
          'invalid_file_type',
        );
}

/// Rate limiting errors.
class RateLimitException extends AppException {
  const RateLimitException([
    String message = 'Too many requests. Please wait a moment and try again.',
    String? code,
    Object? originalError,
  ]) : super(message, code, originalError);

  final Duration? retryAfter = null;
}

/// Unknown/fallback errors.
class UnknownException extends AppException {
  const UnknownException([
    String message = 'An unexpected error occurred. Please try again.',
    String? code,
    Object? originalError,
  ]) : super(message, code, originalError);
}
