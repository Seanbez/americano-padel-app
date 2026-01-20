# Americano App - QA Test Cases

**Document Class:** Operational  
**Lifecycle State:** ACTIVE  
**Version:** 2.0  
**Last Updated:** 2026-01-20

---

## Test Categories

1. Tournament Creation
2. Player Management
3. Schedule Generation
4. Score Entry
5. Tournament Modes (F1-F3)
6. Score Auto-Balance (F4)
7. Tournament Health (F5)
8. Final Results & Winners (F6-F7)
9. Reset Flows (F8)

---

## Key Test Cases

### TC-100: Open-Ended Tournament
- Create tournament with "Open-Ended" mode
- Play several rounds
- Tap "End Tournament" anytime
- **Expected:** Tournament ends, winners calculated

### TC-110: Lock Total Points ON
- Score entry screen, lock toggle ON
- Set Team A score to 14
- **Expected:** Team B auto-sets to 10 (24-point match)

### TC-120: Health Panel Display
- Tournament in progress
- **Expected:** Completion %, health level indicator

### TC-130: Final Results Screen
- End tournament with scores
- **Expected:** Winner, podium, leaderboard, share option

### TC-140: Reset Tournament Results
- Go to Settings → "Reset Tournament Results"
- Type "RESET"
- **Expected:** Scores cleared, schedule intact

### TC-143: Clear All App Data
- App Settings → "Clear All App Data"
- Type "CLEAR ALL"
- **Expected:** All tournaments deleted

---

## Regression Checklist

- [ ] Tournament creation (all formats)
- [ ] Tournament modes (all three)
- [ ] Score entry with auto-balance
- [ ] Winner calculation with tie-breakers
- [ ] Reset flows with confirmation
- [ ] Share results export
- [ ] Navigation between screens
- [ ] Data persistence
- [ ] B-Bot branding display

---

## B-Bot Branding Tests

### TC-200: Logo Display (Storage Allowed)
- Open App Settings screen
- **Expected:** B-Bot logo displays in About section

### TC-201: Logo Fallback (Storage Denied)
- Simulate storage permission denied
- **Expected:** Fallback icon displays, no crash

### TC-202: Promo Tiles Active
- Tap "Designed by B-Bot Cloud" tile
- **Expected:** Opens https://b-bot.cloud in external browser

### TC-203: Final Results Branding
- Complete a tournament
- View Final Results screen
- **Expected:** Small B-Bot logo at bottom (opacity 0.85)

### TC-204: Home Screen Branding
- Open app with no tournaments
- **Expected:** B-Bot logo displays at top with "Powered by B-Bot Cloud" text

### TC-205: Social Sharing Preview
- Share app URL on WhatsApp
- **Expected:** Preview shows "Padel Americana" title, "Powered by B-Bot Cloud" description, B-Bot logo image

---

## Related Documents

- [../architecture/ARCHITECTURE.md](../architecture/ARCHITECTURE.md)
- [../architecture/ALGORITHMS.md](../architecture/ALGORITHMS.md)
