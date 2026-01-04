import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/auth_repository.dart';
import '../class/class_repository.dart';
import '../comment/comment_repository.dart';
import '../config/app_config.dart';
import '../messaging/messaging_repository.dart';
import '../note/note_repository.dart';
import '../notification/notification_repository.dart';
import '../profile/profile_repository.dart';
import '../quiz/quiz_repository.dart';
import '../supabase/supabase_auth_repository.dart';
import '../supabase/supabase_class_repository.dart';
import '../supabase/supabase_comment_repository.dart';
import '../supabase/supabase_messaging_repository.dart';
import '../supabase/supabase_note_repository.dart';
import '../supabase/supabase_notification_repository.dart';
import '../supabase/supabase_post_repository.dart';
import '../supabase/supabase_profile_repository.dart';
import '../supabase/supabase_quiz_repository.dart';
import '../../services/data_service.dart';
import '../../features/feed/domain/post_repository.dart';

/// Core dependency graph wired through Riverpod.
///
/// All repositories and services are accessed through these providers,
/// enabling easy swapping between local and Supabase implementations.

// ─────────────────────────────────────────────────────────────────────────────
// Data Services
// ─────────────────────────────────────────────────────────────────────────────

final dataServiceProvider = Provider<DataService>((ref) {
  throw UnimplementedError('dataServiceProvider is overridden in main.dart');
});

// ─────────────────────────────────────────────────────────────────────────────
// Supabase Client
// ─────────────────────────────────────────────────────────────────────────────

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  if (!AppConfig.hasSupabaseConfig) {
    throw StateError('Supabase is not configured');
  }
  return Supabase.instance.client;
});

// ─────────────────────────────────────────────────────────────────────────────
// Repository Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Authentication repository - handles sign in/up/out operations.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (!AppConfig.hasSupabaseConfig) {
    throw StateError('Supabase is not configured');
  }
  return SupabaseAuthRepository(ref.read(supabaseClientProvider));
});

/// Profile repository - handles user profile CRUD and image uploads.
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  if (!AppConfig.hasSupabaseConfig) {
    throw StateError('Supabase is not configured');
  }
  return SupabaseProfileRepository(ref.read(supabaseClientProvider));
});

/// Post/feed repository - handles timeline, posts, reposts, bookmarks.
final postRepositoryProvider = Provider<PostRepository>((ref) {
  if (!AppConfig.hasSupabaseConfig) {
    throw StateError('Supabase is not configured');
  }
  if (!AppConfig.enableSupabaseFeed) {
    throw StateError('Supabase feed is disabled (SUPABASE_FEED=false)');
  }
  return SupabasePostRepository(ref.read(supabaseClientProvider));
});

/// Quiz repository - handles quiz CRUD, attempts, and leaderboards.
final quizRepositoryProvider = Provider<QuizRepository>((ref) {
  if (!AppConfig.hasSupabaseConfig) {
    throw StateError('Supabase is not configured');
  }
  return SupabaseQuizRepository(ref.read(supabaseClientProvider));
});

/// Comment repository - handles post comments with realtime updates.
final commentRepositoryProvider = Provider<CommentRepository>((ref) {
  if (!AppConfig.hasSupabaseConfig) {
    throw StateError('Supabase is not configured');
  }
  return SupabaseCommentRepository(ref.read(supabaseClientProvider));
});

/// Class repository - handles class CRUD, membership, and invites.
final classRepositoryProvider = Provider<ClassRepository>((ref) {
  if (!AppConfig.hasSupabaseConfig) {
    throw StateError('Supabase is not configured');
  }
  return SupabaseClassRepository(ref.read(supabaseClientProvider));
});

/// Note repository - handles class notes with sections.
final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  if (!AppConfig.hasSupabaseConfig) {
    throw StateError('Supabase is not configured');
  }
  return SupabaseNoteRepository(ref.read(supabaseClientProvider));
});

/// Messaging repository - handles conversations and messages.
final messagingRepositoryProvider = Provider<MessagingRepository>((ref) {
  if (!AppConfig.hasSupabaseConfig) {
    throw StateError('Supabase is not configured');
  }
  return SupabaseMessagingRepository(ref.read(supabaseClientProvider));
});

/// Notification repository - handles user notifications.
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  if (!AppConfig.hasSupabaseConfig) {
    throw StateError('Supabase is not configured');
  }
  return SupabaseNotificationRepository(ref.read(supabaseClientProvider));
});
