// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Completes the Supabase OAuth sign-in flow on web by exchanging the `?code=...`
/// query parameter for a session, then removing sensitive query params from the URL.
Future<void> completeWebOAuthSignIn(SupabaseClient client) async {
  final uri = Uri.parse(html.window.location.href);

  // Supabase normally returns `?code=...` in query params, but in hash-based
  // Flutter routing the redirect can sometimes land with `code` inside the
  // URL fragment (e.g. `/#/?code=...`). Handle both.
  String? code = uri.queryParameters['code'];
  if (code == null || code.isEmpty) {
    final frag = uri.fragment;
    final idx = frag.indexOf('?');
    if (idx != -1 && idx + 1 < frag.length) {
      final fragQuery = frag.substring(idx + 1);
      code = Uri.parse('https://callback.local/?$fragQuery')
          .queryParameters['code'];
    }
  }

  if (code == null || code.isEmpty) return;

  try {
    await client.auth
        .exchangeCodeForSession(code)
        .timeout(const Duration(seconds: 12));
  } catch (e) {
    debugPrint('OAuth code exchange failed: $e');
  }

  // Remove sensitive query params from both the URL query and (if present)
  // the fragment query.
  final cleanedParams = Map<String, String>.from(uri.queryParameters)
    ..remove('code')
    ..remove('state')
    ..remove('error')
    ..remove('error_code')
    ..remove('error_description');

  String cleanedFragment = uri.fragment;
  final fragIdx = cleanedFragment.indexOf('?');
  if (fragIdx != -1 && fragIdx + 1 < cleanedFragment.length) {
    final fragPath = cleanedFragment.substring(0, fragIdx);
    final fragQuery = cleanedFragment.substring(fragIdx + 1);
    final fragParams = Map<String, String>.from(
      Uri.parse('https://callback.local/?$fragQuery').queryParameters,
    )
      ..remove('code')
      ..remove('state')
      ..remove('error')
      ..remove('error_code')
      ..remove('error_description');
    final nextFrag = fragParams.isEmpty
        ? fragPath
        : '$fragPath?${Uri(queryParameters: fragParams).query}';
    cleanedFragment = nextFrag;
  }

  final cleaned = uri.replace(
    queryParameters: cleanedParams,
    fragment: cleanedFragment,
  );
  html.window.history.replaceState(null, '', cleaned.toString());
}
