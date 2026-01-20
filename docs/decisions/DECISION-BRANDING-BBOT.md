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
- **Access Method:** Firebase Storage SDK's `getDownloadURL()`

### Branding Surfaces

| Surface | Placement | Logo Size | Notes |
|---------|-----------|-----------|-------|
| App Settings → About | Top of section | 64px height | Primary branding |
| Final Results Screen | Bottom footer | 40px height | Subtle, opacity 0.85 |

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

- ✅ No hardcoded tokens or secrets in source code
- ✅ Logo URL fetched dynamically via Firebase SDK
- ✅ Graceful fallback if storage access fails
- ✅ No sensitive data exposed

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
| `pubspec.yaml` | Added firebase_storage, url_launcher deps |

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
