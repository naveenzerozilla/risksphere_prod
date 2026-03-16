class PendingLocation {
  static String? latitude;
  static String? longitude;

  static bool get hasLocation => latitude != null && longitude != null;

  static void clear() {
    latitude = null;
    longitude = null;
  }
}
