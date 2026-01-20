# Decision: B-Bot Cloud Branding

**Document Class:** Decision  
**Status:** APPROVED  
**Date:** 2026-01-20  
**Author:** AI Assistant (Governance Mode)

---

## Context

The Americano Padel App was developed by B-Bot Cloud. Branding attribution is required to acknowledge the creators and provide contact information for custom app development inquiries.

---

## Decision

Integrate B-Bot Cloud branding into the application using Firebase Storage for logo assets.

### Logo Source

- **Firebase Storage Path:** `logo/B-Bot_Xero.jpg`
- **Bucket:** `americano-padel-app.firebasestorage.app`
- **Access Method:** Direct public URL with token (SDK init not required)
- **Full URL:** `https://firebasestorage.googleapis.com/v0/b/americano-padel-app.firebasestorage.app/o/logo%2FB-Bot_Xero.jpg?alt=media&token=cd0368b3-440d-41de-97db-89b7c7c745e7`

### Branding Surfaces

| Surface | Placement | Logo Size | Notes |
|---------|-----------|-----------|-------|
| Home Screen (empty state) | Top of screen | 80px height | With "Powered by B-Bot Cloud" text |
| App Settings → About | Top of section | 80px height | Primary branding |
| Final Results Screen | Bottom footer | 40px height | Subtle, opacity 0.85 |
| Social Sharing (OG tags) | Link preview | - | Shows B-Bot logo in WhatsApp/social |

### Attribution Tiles (Settings Screen)

1. **"Designed by B-Bot Cloud"**
   - Subtitle: "Custom tournament apps & club tools"
   - Action: Opens https://b-bot.cloud

2. **"Need a custom app?"**
   - Subtitle: "Ask for Sean & Melanie Bezuidenhout • b-bot.cloud"
   - Action: Opens https://b-bot.cloud

3. **Footer:** "Powered by B-Bot Cloud • b-bot.cloud"

---

## Security Considerations

- ✅ No hardcoded secrets in source code (token is public access token, not a secret)
- ✅ Logo URL is static constant for reliability
- ✅ Graceful fallback if image fails to load
- ✅ No sensitive data exposed
- ✅ Open Graph meta tags for social sharing

---

## Implementation Details

### New Files

| File | Purpose |
|------|---------|
| `lib/src/services/branding_service.dart` | Fetches logo URL from Firebase Storage with caching |
| `lib/src/utils/url_utils.dart` | Utility for launching external URLs |

### Modified Files

| File | Changes |
|------|---------|
| `app_settings_screen.dart` | Added logo widget, promo tiles, footer |
| `final_results_screen.dart` | Added branding footer widget |
| `home_screen.dart` | Added logo and "Powered by B-Bot Cloud" to empty state |
| `pubspec.yaml` | Added firebase_storage, url_launcher deps |
| `web/index.html` | Added Open Graph meta tags for social sharing |
| `web/manifest.json` | Updated app name and description |

### Dependencies Added

- `firebase_storage: ^12.4.10`
- `url_launcher: ^6.3.1`

---

## Fallback Behavior

If Firebase Storage access fails (permissions, network, missing file):

1. Logo displays `Icons.auto_awesome` icon (purple)
2. Promo tiles remain functional
3. No crash or error dialog shown
4. User experience uninterrupted

---

## Related Documents

- [../security/SECRETS-INVENTORY.md](../security/SECRETS-INVENTORY.md)
- [../operations/QA_TESTS.md](../operations/QA_TESTS.md)
