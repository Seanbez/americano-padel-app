import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service for B-Bot Cloud branding assets.
/// 
/// Fetches logo from Firebase Storage using object path only.
/// No hardcoded tokens - uses SDK's getDownloadURL().
class BrandingService {
  BrandingService();

  /// Cached logo URL to avoid repeated network calls
  String? _cachedLogoUrl;
  
  /// Firebase Storage object path for B-Bot logo
  static const String _logoPath = 'logo/B-Bot_Xero.jpg';
  
  /// B-Bot Cloud website URL
  static const String bbotWebsiteUrl = 'https://b-bot.cloud';
  
  /// Tagline for attribution
  static const String tagline = 'Designed by B-Bot Cloud';
  
  /// Promo subtitle
  static const String promoSubtitle = 'Custom tournament apps & club tools';
  
  /// Contact info
  static const String contactInfo = 'Ask for Sean & Melanie Bezuidenhout • b-bot.cloud';

  /// Gets the B-Bot logo download URL from Firebase Storage.
  /// 
  /// Returns cached URL if available, otherwise fetches from Firebase.
  /// Returns null on failure (permissions denied, network error, etc.)
  /// 
  /// Caller must handle null gracefully by showing fallback UI.
  Future<String?> getBbotLogoUrl() async {
    // Return cached URL if available
    if (_cachedLogoUrl != null) {
      return _cachedLogoUrl;
    }

    try {
      final ref = FirebaseStorage.instance.ref(_logoPath);
      final url = await ref.getDownloadURL();
      _cachedLogoUrl = url;
      return url;
    } catch (e) {
      // Graceful failure - permissions, network, or missing file
      // Caller should show fallback icon
      return null;
    }
  }

  /// Clears the cached logo URL (for testing or refresh)
  void clearCache() {
    _cachedLogoUrl = null;
  }
}

/// Provider for BrandingService
final brandingServiceProvider = Provider<BrandingService>((ref) {
  return BrandingService();
});

/// Provider for the B-Bot logo URL
final bbotLogoUrlProvider = FutureProvider<String?>((ref) async {
  final service = ref.watch(brandingServiceProvider);
  return service.getBbotLogoUrl();
});
