// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Completes the Supabase OAuth sign-in flow on web by exchanging the `?code=...`
/// query parameter for a session, then removing sensitive query params from the URL.
Future<void> completeWebOAuthSignIn(SupabaseClient client) async {
  final uri = Uri.base;
  final code = uri.queryParameters['code'];
  if (code == null || code.isEmpty) return;

  try {
    await client.auth.exchangeCodeForSession(code);
  } catch (e) {
    debugPrint('OAuth code exchange failed: $e');
  }

  final cleanedParams = Map<String, String>.from(uri.queryParameters)
    ..remove('code')
    ..remove('state')
    ..remove('error')
    ..remove('error_code')
    ..remove('error_description');

  final cleaned = uri.replace(queryParameters: cleanedParams);
  html.window.history.replaceState(null, '', cleaned.toString());
}
