import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service for B-Bot Cloud branding assets.
/// 
/// Uses direct Firebase Storage public URL for logo access.
/// This avoids requiring full Firebase SDK initialization.
class BrandingService {
  BrandingService();

  /// B-Bot logo public URL from Firebase Storage
  /// Note: Using public URL since Firebase SDK requires initialization
  static const String bbotLogoUrl = 
      'https://firebasestorage.googleapis.com/v0/b/americano-padel-app.firebasestorage.app/o/logo%2FB-Bot_Xero.jpg?alt=media&token=cd0368b3-440d-41de-97db-89b7c7c745e7';
  
  /// B-Bot Cloud website URL
  static const String bbotWebsiteUrl = 'https://b-bot.cloud';
  
  /// Tagline for attribution
  static const String tagline = 'Designed by B-Bot Cloud';
  
  /// Promo subtitle
  static const String promoSubtitle = 'Custom tournament apps & club tools';
  
  /// Contact info
  static const String contactInfo = 'Ask for Sean & Melanie Bezuidenhout • b-bot.cloud';

  /// Gets the B-Bot logo URL.
  /// Returns the public Firebase Storage URL directly.
  Future<String?> getBbotLogoUrl() async {
    return bbotLogoUrl;
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
