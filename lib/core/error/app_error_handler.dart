import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import 'app_exceptions.dart';

/// Centralized error handler that converts various exceptions into
/// user-friendly [AppException] types.
///
/// Usage:
/// ```dart
/// try {
///   await someOperation();
/// } catch (e) {
///   final appError = AppErrorHandler.handle(e);
///   // Use appError.message for user-facing display
/// }
/// ```
class AppErrorHandler {
  const AppErrorHandler._();

  /// Converts any exception into an appropriate [AppException].
  ///
  /// This method categorizes errors and returns typed exceptions with
  /// user-friendly messages suitable for display.
  static AppException handle(Object error, [StackTrace? stackTrace]) {
    // Log the original error for debugging
    if (kDebugMode) {
      debugPrint('AppErrorHandler: $error');
      if (stackTrace != null) {
        debugPrint(stackTrace.toString());
      }
    }

    // Already an AppException - return as-is
    if (error is AppException) {
      return error;
    }

    // Supabase Auth Exceptions
    if (error is supabase.AuthException) {
      return _handleSupabaseAuthError(error);
    }

    // Supabase Postgrest Exceptions (database errors)
    if (error is supabase.PostgrestException) {
      return _handlePostgrestError(error);
    }

    // Supabase Storage Exceptions
    if (error is supabase.StorageException) {
      return _handleStorageError(error);
    }

    // Network errors
    if (error is SocketException || error is TimeoutException) {
      return NetworkException(
        'Unable to connect. Please check your internet connection.',
        'network_error',
        error,
      );
    }

    // HTTP status code errors (if using dio or similar)
    if (error is HttpException) {
      return _handleHttpError(error);
    }

    // Format exceptions (usually parsing errors)
    if (error is FormatException) {
      return ValidationException(
        'Invalid data format received.',
        'format_error',
        error,
      );
    }

    // Fallback for unknown errors
    return UnknownException(
      'An unexpected error occurred. Please try again.',
      'unknown_error',
      error,
    );
  }

  /// Handles Supabase authentication errors.
  static AppException _handleSupabaseAuthError(supabase.AuthException error) {
    final message = error.message.toLowerCase();

    if (message.contains('invalid login credentials') ||
        message.contains('invalid password')) {
      return const AuthException.invalidCredentials();
    }

    if (message.contains('user not found') ||
        message.contains('no user found')) {
      return const AuthException.userNotFound();
    }

    if (message.contains('email already') ||
        message.contains('already registered')) {
      return const AuthException.emailInUse();
    }

    if (message.contains('weak password') ||
        message.contains('password should be')) {
      return const AuthException.weakPassword();
    }

    if (message.contains('session') ||
        message.contains('token') ||
        message.contains('expired') ||
        message.contains('refresh')) {
      return const AuthException.sessionExpired();
    }

    if (message.contains('rate limit') || message.contains('too many')) {
      return RateLimitException(
        'Too many attempts. Please wait a moment and try again.',
        'rate_limit',
        error,
      );
    }

    // Generic auth error
    return AuthException(
      error.message.isNotEmpty ? error.message : 'Authentication failed.',
      error.statusCode,
      error,
    );
  }

  /// Handles Supabase Postgrest (database) errors.
  static AppException _handlePostgrestError(supabase.PostgrestException error) {
    final code = error.code;

    // Row-level security violations
    if (code == '42501' || code == 'PGRST301') {
      return PermissionException(
        'You don\'t have permission to perform this action.',
        code,
        error,
      );
    }

    // Not found (no rows returned when expecting one)
    if (code == 'PGRST116') {
      return NotFoundException(
        'The requested item was not found.',
        code,
        error,
      );
    }

    // Unique constraint violation
    if (code == '23505') {
      return ValidationException(
        'This item already exists.',
        code,
        error,
      );
    }

    // Foreign key violation
    if (code == '23503') {
      return ValidationException(
        'Cannot complete this action due to related data.',
        code,
        error,
      );
    }

    // Check constraint violation
    if (code == '23514') {
      return ValidationException(
        'The provided data does not meet requirements.',
        code,
        error,
      );
    }

    // Not null violation
    if (code == '23502') {
      return ValidationException(
        'Required information is missing.',
        code,
        error,
      );
    }

    // Generic database error
    return ServerException(
      'A database error occurred. Please try again.',
      code,
      error,
    );
  }

  /// Handles Supabase storage errors.
  static AppException _handleStorageError(supabase.StorageException error) {
    final message = error.message.toLowerCase();

    if (message.contains('object not found') ||
        message.contains('not found')) {
      return const NotFoundException('File not found.', 'storage_not_found');
    }

    if (message.contains('payload too large') ||
        message.contains('file size')) {
      return const StorageException.fileTooLarge();
    }

    if (message.contains('mime type') ||
        message.contains('content type') ||
        message.contains('not allowed')) {
      return const StorageException.invalidFileType();
    }

    if (message.contains('permission') || message.contains('policy')) {
      return PermissionException(
        'You don\'t have permission to access this file.',
        'storage_permission',
        error,
      );
    }

    return StorageException(
      'Failed to process file. Please try again.',
      'storage_error',
      error,
    );
  }

  /// Handles HTTP errors.
  static AppException _handleHttpError(HttpException error) {
    final message = error.message.toLowerCase();

    if (message.contains('401') || message.contains('unauthorized')) {
      return const AuthException.sessionExpired();
    }

    if (message.contains('403') || message.contains('forbidden')) {
      return const PermissionException();
    }

    if (message.contains('404') || message.contains('not found')) {
      return const NotFoundException();
    }

    if (message.contains('429') || message.contains('rate limit')) {
      return const RateLimitException();
    }

    if (message.contains('5')) {
      return const ServerException();
    }

    return const NetworkException();
  }

  /// Returns a user-friendly message for any error.
  ///
  /// Convenience method that handles the error and returns just the message.
  static String getDisplayMessage(Object error) {
    return handle(error).message;
  }

  /// Checks if an error is recoverable (user can retry).
  static bool isRecoverable(Object error) {
    final appError = error is AppException ? error : handle(error);

    // Network and rate limit errors are typically recoverable
    if (appError is NetworkException || appError is RateLimitException) {
      return true;
    }

    // Server errors might be temporary
    if (appError is ServerException) {
      return true;
    }

    // Auth errors require user action but are "recoverable"
    if (appError is AuthException) {
      return true;
    }

    return false;
  }

  /// Checks if an error requires re-authentication.
  static bool requiresReauth(Object error) {
    if (error is AuthException && error.code == 'session_expired') {
      return true;
    }

    if (error is supabase.AuthException) {
      final message = error.message.toLowerCase();
      return message.contains('session') ||
          message.contains('token') ||
          message.contains('expired') ||
          message.contains('refresh');
    }

    return false;
  }
}
