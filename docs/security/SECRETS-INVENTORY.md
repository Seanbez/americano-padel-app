# Secrets Inventory

**Document Class:** Security  
**Lifecycle State:** ACTIVE  
**Version:** 1.0  
**Last Updated:** 2026-01-20

---

## Purpose

This document inventories all secrets used by the Americano App project. **NO VALUES ARE STORED HERE** - only secret names and their purposes.

---

## Environment Secrets

| Secret Name | Purpose | Required For | Storage Location |
|-------------|---------|--------------|------------------|
| `FIREBASE_PROJECT_ID` | Firebase project identifier | Web hosting, analytics | `.env.local` |
| `FIREBASE_API_KEY` | Firebase API key | Firebase services | `.env.local` |
| `FIREBASE_AUTH_DOMAIN` | Firebase auth domain | Authentication | `.env.local` |
| `FIREBASE_STORAGE_BUCKET` | Firebase storage bucket | File storage | `.env.local` |
| `FIREBASE_MESSAGING_SENDER_ID` | FCM sender ID | Push notifications | `.env.local` |
| `FIREBASE_APP_ID` | Firebase app identifier | Firebase services | `.env.local` |
| `FIREBASE_MEASUREMENT_ID` | Google Analytics ID | Analytics | `.env.local` |

---

## CI/CD Secrets (GitHub Actions)

| Secret Name | Purpose | Required For |
|-------------|---------|--------------|
| `FIREBASE_SERVICE_ACCOUNT` | Service account JSON for Firebase deployment | GitHub Actions deploy |
| `GITHUB_TOKEN` | Auto-provided by GitHub Actions | PR comments, deployments |

## GitHub Repository Variables

| Variable Name | Purpose | Required For |
|---------------|---------|--------------|
| `FIREBASE_PROJECT_ID` | Firebase project identifier | GitHub Actions deploy |

---

## Platform Config Files (Auto-generated, Gitignored)

| File | Platform | Contains |
|------|----------|----------|
| `lib/firebase_options.dart` | All | Firebase configuration |
| `android/app/google-services.json` | Android | Firebase Android config |
| `ios/Runner/GoogleService-Info.plist` | iOS | Firebase iOS config |
| `web/firebase-config.js` | Web | Firebase Web config |

---

## Secret Rotation Policy

- Firebase API keys: Rotate annually or on suspected compromise
- Service accounts: Rotate every 90 days
- All rotations must be logged in DEPLOYMENT-LOG.md

---

## Access Control

- Production secrets: DevOps team only
- Development secrets: Development team
- CI/CD secrets: Repository admins only

---

## Compliance Notes

- No secrets in source code
- No secrets in commit messages
- No secrets in logs or chat
- All secrets in approved secret managers only

---

## B-Bot Branding Integration (2026-01-20)

**No new secrets added.**

The B-Bot logo is fetched from Firebase Storage using SDK's `getDownloadURL()` method.
- Storage path: `logo/B-Bot_Xero.jpg`
- No hardcoded tokens in source code
- Access controlled by Firebase Storage security rules
