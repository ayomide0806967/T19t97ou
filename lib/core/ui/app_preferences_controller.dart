import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

@immutable
class AppPreferencesState {
  const AppPreferencesState({
    this.isLoaded = false,
    this.notificationsEnabled = true,
    this.notificationSound = true,
    this.hapticsEnabled = true,
    this.reduceMotion = false,
    this.blackoutTheme = false,
    this.autoplayMedia = true,
    this.dataSaver = false,
    this.showSensitiveContent = false,
    this.showOnlineStatus = true,
    this.privateAccount = false,
    this.quizShowExplanations = true,
    this.quizTimerSounds = true,
    this.language = 'English',
  });

  final bool isLoaded;

  final bool notificationsEnabled;
  final bool notificationSound;
  final bool hapticsEnabled;
  final bool reduceMotion;
  final bool blackoutTheme;

  final bool autoplayMedia;
  final bool dataSaver;
  final bool showSensitiveContent;

  final bool showOnlineStatus;
  final bool privateAccount;

  final bool quizShowExplanations;
  final bool quizTimerSounds;

  final String language;

  AppPreferencesState copyWith({
    bool? isLoaded,
    bool? notificationsEnabled,
    bool? notificationSound,
    bool? hapticsEnabled,
    bool? reduceMotion,
    bool? blackoutTheme,
    bool? autoplayMedia,
    bool? dataSaver,
    bool? showSensitiveContent,
    bool? showOnlineStatus,
    bool? privateAccount,
    bool? quizShowExplanations,
    bool? quizTimerSounds,
    String? language,
  }) {
    return AppPreferencesState(
      isLoaded: isLoaded ?? this.isLoaded,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      notificationSound: notificationSound ?? this.notificationSound,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      blackoutTheme: blackoutTheme ?? this.blackoutTheme,
      autoplayMedia: autoplayMedia ?? this.autoplayMedia,
      dataSaver: dataSaver ?? this.dataSaver,
      showSensitiveContent: showSensitiveContent ?? this.showSensitiveContent,
      showOnlineStatus: showOnlineStatus ?? this.showOnlineStatus,
      privateAccount: privateAccount ?? this.privateAccount,
      quizShowExplanations: quizShowExplanations ?? this.quizShowExplanations,
      quizTimerSounds: quizTimerSounds ?? this.quizTimerSounds,
      language: language ?? this.language,
    );
  }
}

class AppPreferencesController extends Notifier<AppPreferencesState> {
  static const _kNotificationsEnabled = 'pref_notifications_enabled';
  static const _kNotificationSound = 'pref_notification_sound';
  static const _kHapticsEnabled = 'pref_haptics_enabled';
  static const _kReduceMotion = 'pref_reduce_motion';
  static const _kBlackoutTheme = 'pref_blackout_theme';
  static const _kAutoplayMedia = 'pref_autoplay_media';
  static const _kDataSaver = 'pref_data_saver';
  static const _kShowSensitive = 'pref_show_sensitive';
  static const _kShowOnlineStatus = 'pref_show_online_status';
  static const _kPrivateAccount = 'pref_private_account';
  static const _kQuizShowExplanations = 'pref_quiz_show_explanations';
  static const _kQuizTimerSounds = 'pref_quiz_timer_sounds';
  static const _kLanguage = 'pref_language';

  @override
  AppPreferencesState build() {
    _loadAsync();
    return const AppPreferencesState();
  }

  Future<void> _loadAsync() async {
    final prefs = await SharedPreferences.getInstance();
    state = state.copyWith(
      isLoaded: true,
      notificationsEnabled:
          prefs.getBool(_kNotificationsEnabled) ?? state.notificationsEnabled,
      notificationSound:
          prefs.getBool(_kNotificationSound) ?? state.notificationSound,
      hapticsEnabled: prefs.getBool(_kHapticsEnabled) ?? state.hapticsEnabled,
      reduceMotion: prefs.getBool(_kReduceMotion) ?? state.reduceMotion,
      blackoutTheme: prefs.getBool(_kBlackoutTheme) ?? state.blackoutTheme,
      autoplayMedia: prefs.getBool(_kAutoplayMedia) ?? state.autoplayMedia,
      dataSaver: prefs.getBool(_kDataSaver) ?? state.dataSaver,
      showSensitiveContent:
          prefs.getBool(_kShowSensitive) ?? state.showSensitiveContent,
      showOnlineStatus:
          prefs.getBool(_kShowOnlineStatus) ?? state.showOnlineStatus,
      privateAccount: prefs.getBool(_kPrivateAccount) ?? state.privateAccount,
      quizShowExplanations:
          prefs.getBool(_kQuizShowExplanations) ?? state.quizShowExplanations,
      quizTimerSounds:
          prefs.getBool(_kQuizTimerSounds) ?? state.quizTimerSounds,
      language: prefs.getString(_kLanguage) ?? state.language,
    );
  }

  Future<void> setNotificationsEnabled(bool value) async {
    state = state.copyWith(notificationsEnabled: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotificationsEnabled, value);
  }

  Future<void> setNotificationSound(bool value) async {
    state = state.copyWith(notificationSound: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotificationSound, value);
  }

  Future<void> setHapticsEnabled(bool value) async {
    state = state.copyWith(hapticsEnabled: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kHapticsEnabled, value);
  }

  Future<void> setReduceMotion(bool value) async {
    state = state.copyWith(reduceMotion: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kReduceMotion, value);
  }

  Future<void> setBlackoutTheme(bool value) async {
    state = state.copyWith(blackoutTheme: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kBlackoutTheme, value);
  }

  Future<void> setAutoplayMedia(bool value) async {
    state = state.copyWith(autoplayMedia: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAutoplayMedia, value);
  }

  Future<void> setDataSaver(bool value) async {
    state = state.copyWith(dataSaver: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDataSaver, value);
  }

  Future<void> setShowSensitiveContent(bool value) async {
    state = state.copyWith(showSensitiveContent: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kShowSensitive, value);
  }

  Future<void> setShowOnlineStatus(bool value) async {
    state = state.copyWith(showOnlineStatus: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kShowOnlineStatus, value);
  }

  Future<void> setPrivateAccount(bool value) async {
    state = state.copyWith(privateAccount: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPrivateAccount, value);
  }

  Future<void> setQuizShowExplanations(bool value) async {
    state = state.copyWith(quizShowExplanations: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kQuizShowExplanations, value);
  }

  Future<void> setQuizTimerSounds(bool value) async {
    state = state.copyWith(quizTimerSounds: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kQuizTimerSounds, value);
  }

  Future<void> setLanguage(String value) async {
    state = state.copyWith(language: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLanguage, value);
  }

  Future<void> resetToDefaults() async {
    state = const AppPreferencesState(isLoaded: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kNotificationsEnabled);
    await prefs.remove(_kNotificationSound);
    await prefs.remove(_kHapticsEnabled);
    await prefs.remove(_kReduceMotion);
    await prefs.remove(_kBlackoutTheme);
    await prefs.remove(_kAutoplayMedia);
    await prefs.remove(_kDataSaver);
    await prefs.remove(_kShowSensitive);
    await prefs.remove(_kShowOnlineStatus);
    await prefs.remove(_kPrivateAccount);
    await prefs.remove(_kQuizShowExplanations);
    await prefs.remove(_kQuizTimerSounds);
    await prefs.remove(_kLanguage);
  }
}

final appPreferencesControllerProvider =
    NotifierProvider<AppPreferencesController, AppPreferencesState>(
  AppPreferencesController.new,
);
