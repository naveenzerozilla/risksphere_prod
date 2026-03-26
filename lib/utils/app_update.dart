import 'dart:io';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';

class UpdateService {
  // ============================================================
  // 📱 VERSION CONFIGURATION - UPDATE THESE FOR EACH RELEASE
  // ============================================================

  // Minimum version that is still supported (older versions will get FORCED update)
  static const String minSupportedVersion = "7.0.0";

  // Target version for soft update (current release version)
  // ⚠️ IMPORTANT: Set this to the version you're releasing NOW
  static const String softUpdateVersion = "7.1.0";

  // NEXT version that will trigger updates (set to next planned version)
  // Users on versions below this will see update prompt
  static const String nextVersion = "7.1.0";

  static const String releaseNotes = """
✨ New Features:
• Enhanced dashboard performance
• Improved location sharing
• Bug fixes and stability improvements

📱 Version 7.6.0 Updates:
• Added new hazard reporting features
• Fixed map loading issues
• Improved offline capabilities
• UI/UX enhancements
  """;

  static const String appStoreId = '6748542499';
  static const String playStorePackage = 'com.risksphere.green';

  static int _versionToInt(String version) {
    final clean = version.split('+').first.trim();
    final parts = clean.split('.');
    if (parts.length != 3) return 0;
    return int.parse(parts[0]) * 1000000 +
        int.parse(parts[1]) * 1000 +
        int.parse(parts[2]);
  }

  static Future<UpdateStatus> checkForUpdate() async {
    try {
      final info = await PackageInfo.fromPlatform();

      final currentVersion = info.version;
      final buildNumber = info.buildNumber;

      final current = _versionToInt(currentVersion);
      final minSupported = _versionToInt(minSupportedVersion);
      final softUpdate = _versionToInt(softUpdateVersion);
      final next = _versionToInt(nextVersion);

      debugPrint('══════════════════════════════════════');
      debugPrint('📱 Current app version  : $currentVersion+$buildNumber');
      debugPrint('🔒 Min supported version : $minSupportedVersion');
      debugPrint('🔄 Soft update target    : $softUpdateVersion');
      debugPrint('🎯 Next version target   : $nextVersion');
      debugPrint('══════════════════════════════════════');

      // FORCE UPDATE: Current version is below minimum supported
      if (current < minSupported) {
        debugPrint('⚠️ FORCE update required - version too old');
        return UpdateStatus(
          hasUpdate: true,
          isForce: true,
          currentVersion: currentVersion,
          buildNumber: buildNumber,
          latestVersion: softUpdateVersion,
          updateUrl: getStoreUrl(),
          releaseNotes: releaseNotes,
        );
      }

      // SOFT UPDATE: Current version is below the next version target
      if (current < next) {
        debugPrint('✅ SOFT update available - new version released');
        return UpdateStatus(
          hasUpdate: true,
          isForce: false,
          currentVersion: currentVersion,
          buildNumber: buildNumber,
          latestVersion: softUpdateVersion,
          updateUrl: getStoreUrl(),
          releaseNotes: releaseNotes,
        );
      }

      debugPrint('✅ App is up to date (v$currentVersion)');
    } catch (e) {
      debugPrint('❌ Update check failed: $e');
    }

    return UpdateStatus(hasUpdate: false);
  }

  static String getStoreUrl() {
    if (Platform.isIOS) {
      return 'https://apps.apple.com/app/id$appStoreId';
    } else if (Platform.isAndroid) {
      return 'https://play.google.com/store/apps/details?id=$playStorePackage';
    }
    return '';
  }

  static Future<void> launchStore(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  static Future<void> showUpdateDialog(
    BuildContext context,
    UpdateStatus status,
  ) async {
    if (status.isForce == true) {
      await _showForceUpdateSheet(context, status);
    } else {
      await _showSoftUpdateSheet(context, status);
    }
  }

  static Future<void> _showForceUpdateSheet(
    BuildContext context,
    UpdateStatus status,
  ) async {
    await showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => WillPopScope(
        onWillPop: () async => false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          decoration: const BoxDecoration(
            color: Color(0xFF0D0D0D),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Title
              Row(
                children: const [
                  Icon(Icons.warning_amber_rounded,
                      color: Colors.orange, size: 28),
                  SizedBox(width: 10),
                  Text(
                    "Update Required",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              const Text(
                "This version of the app is no longer supported. Please update to continue using the app with full functionality and security.",
                style: TextStyle(
                  color: Color(0xFFB0B0B0),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 16),

              // Release Notes Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _versionTag("Current v${status.currentVersion ?? "--"}",
                            Colors.red),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward,
                            size: 12, color: Colors.grey),
                        const SizedBox(width: 8),
                        _versionTag("Latest v${status.latestVersion ?? "--"}",
                            Colors.green),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "What's New:",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      status.releaseNotes ?? "",
                      style: const TextStyle(
                        color: Color(0xFFB0B0B0),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Update button (ONLY option)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7FB3D5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () async {
                    await UpdateService.launchStore(status.updateUrl ?? "");
                  },
                  child: const Text(
                    "Update Now",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _versionTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  static Future<void> _showSoftUpdateSheet(
    BuildContext context,
    UpdateStatus status,
  ) async {
    await showModalBottomSheet(
      context: context,
      isDismissible: true,
      enableDrag: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
        decoration: const BoxDecoration(
          color: Color(0xFF0D0D0D),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            const Text(
              "What's New in This Update",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            // Description
            const Text(
              "We've made important improvements to enhance your experience, security, and app performance.",
              style: TextStyle(
                color: Color(0xFFB0B0B0),
                fontSize: 13,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 16),

            // Highlights
            const Text(
              "Update Highlights:",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 10),

            _bullet(
                "Improved Performance: Faster load times and smoother navigation."),
            _bullet(
                "Enhanced Security: Stronger protection for your account and data."),
            _bullet(
                "New Features: Access the latest tools designed to make tasks easier."),
            _bullet(
                "Bug Fixes: Resolved known issues for a more reliable experience."),

            const SizedBox(height: 16),

            Text(
              "Version ${status.latestVersion ?? ""}",
              style: const TextStyle(
                color: Color(0xFFB0B0B0),
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 20),

            // Update button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7FB3D5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  await UpdateService.launchStore(status.updateUrl ?? "");
                  Navigator.pop(ctx);
                },
                child: const Text(
                  "Update Now",
                  style: TextStyle(color: Colors.black, fontSize: 15),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Cancel button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF2A2A2A)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _handleBar() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  static Widget _releaseNotesBox(UpdateStatus status) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Current: v${status.currentVersion ?? "—"}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.blue.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward, size: 12, color: Colors.grey),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Latest: v${status.latestVersion ?? "—"}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.green.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (status.releaseNotes != null) ...[
            const SizedBox(height: 12),
            const Text(
              "What's New:",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              status.releaseNotes!,
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }

  static Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("• ", style: TextStyle(color: Colors.white)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFFB0B0B0),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class UpdateStatus {
  final bool hasUpdate;
  final bool? isForce;
  final String? currentVersion;
  final String? buildNumber;
  final String? latestVersion;
  final String? updateUrl;
  final String? releaseNotes;

  UpdateStatus({
    required this.hasUpdate,
    this.isForce,
    this.currentVersion,
    this.buildNumber,
    this.latestVersion,
    this.updateUrl,
    this.releaseNotes,
  });
}
