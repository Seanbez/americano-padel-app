# Deployment Log

**Document Class:** Operational  
**Lifecycle State:** ACTIVE  
**Version:** 1.0  
**Last Updated:** 2026-01-20

---

## Purpose

This document logs all production deployments for the Americano App.

---

## Deployment History

| Date | Version | Environment | Deployed By | URL | Notes |
|------|---------|-------------|-------------|-----|-------|
| 2026-01-20 | 1.0.0 | Firebase Hosting | CI/CD | *pending* | Initial deployment |

---

## Rollback Procedures

### Quick Rollback (Firebase Hosting)
```bash
# List recent releases
firebase hosting:channel:list

# Rollback to previous release
firebase hosting:rollback
```

### Manual Rollback
```bash
# Clone specific version
git checkout v1.0.0

# Build and deploy
flutter build web --release
firebase deploy --only hosting
```

---

## Environment URLs

| Environment | URL | Purpose |
|-------------|-----|---------|
| Production | https://americano-app.web.app | Live site |
| Preview | https://americano-app--pr-*.web.app | PR previews |

---

## Health Checks

After each deployment, verify:
- [ ] Home page loads
- [ ] Tournament creation works
- [ ] Score entry functions
- [ ] Data persistence works

