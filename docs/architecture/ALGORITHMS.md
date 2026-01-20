# Americano App - Scheduling Algorithms

**Document Class:** Architecture  
**Lifecycle State:** ACTIVE  
**Version:** 2.0  
**Last Updated:** 2026-01-20

---

## Overview

This document describes the scheduling algorithms used to generate fair Padel Americana tournament schedules.

## Algorithm Summary

### Constraint-Based Optimization

1. Generate N candidate schedules (default: 200)
2. Score each based on fairness metrics
3. Select candidate with lowest score

### Scoring Function

```
Score = 1000 × PartnerRepeats 
      + 300  × OpponentRepeats 
      + 50   × CourtVariance 
      + 200  × ByeVariance
```

## Time Recommendation Algorithm

### Serve-to-Points Mapping

| Serves per Player | Recommended Total Points |
|-------------------|-------------------------|
| 4 | 16 |
| 6 | 24 |
| 8 | 32 |

### Duration Multipliers

| Points per Match | Duration Multiplier |
|------------------|---------------------|
| 16 | 0.75 |
| 24 | 1.00 |
| 32 | 1.25 |

## Tournament Health Algorithm

### Health Levels

| Level | Threshold | Description |
|-------|-----------|-------------|
| `healthy` | ≥75% | Progressing well |
| `warning` | 50-74% | Attention needed |
| `critical` | <50% | Significant issues |

## Winner Calculation Algorithm

### Tie-Breaker Priority

1. **Total Points** (highest wins)
2. **Total Wins** (most matches won)
3. **Point Differential** (points for - against)
4. **Alphabetical Name** (final breaker)

## Score Auto-Balance

When `lockTotalPoints` enabled:
- Adjusting Team A auto-sets Team B to `(total - scoreA)`
- Prevents invalid score combinations

---

## Related Documents

- [ARCHITECTURE.md](ARCHITECTURE.md)
- [DATA_MODEL.md](DATA_MODEL.md)
