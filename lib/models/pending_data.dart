class PendingDeepLink {
  static bool isDeepLinkPending = false;
}

class PendingSharedLocation {
  static String? sharedText;
  static bool wasLaunchedViaShare = false;

  static bool get hasSharedText => sharedText != null && sharedText!.isNotEmpty;
}
