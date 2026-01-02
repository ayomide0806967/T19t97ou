class ToastDurations {
  // Slightly longer so important toasts (like repost) stay visible.
  static const standard = Duration(milliseconds: 2500);

  // Keep repost feedback visible slightly longer on the profile feed.
  static const profileRepost = Duration(milliseconds: 2000);
}
