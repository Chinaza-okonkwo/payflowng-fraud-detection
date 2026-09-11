# PayFlowNG: Transaction Fraud Detection Analysis

## Problem Statement
Built to test a rules-based fraud detection approach in SQL — flagging transactions that break from normal account behavior across three patterns, then summarizing the results in Excel the way a fraud team would actually review them.

## Data Source
**PaySim** (Kaggle) — a real, publicly available synthetic financial transaction dataset simulating fintech payment activity. Sampled 60,010 transactions across the full 30-day window using day-partitioned random sampling.

**Why 60,000 and not 10,000:** I first tried a 10,000-row sample, same size as my reconciliation project. It only returned 2 flagged transactions — not enough to build anything meaningful from. Fraud patterns depend on the same account showing up more than once, and a smaller sample just didn't have enough repeated activity. Bumped it up to ~60,000 to fix that.

## Detection Methodology
Three checks, run as one combined SQL query:
- **High Value Anomaly** — a transaction more than 3x the receiving account's average
- **High Velocity** — an account receiving more than one transaction in the same hour
- **Repeated Amount** — the same account charged the identical amount more than once

**A real snag worth mentioning:** PaySim's `nameOrig` field (the sending account) turned out to be unique per transaction — it never repeats, so there's no behavior pattern to actually detect on that column. I switched to `nameDest` (the receiving account), which does repeat in the data.

Built with CTEs, window functions, and a CASE statement to combine all three checks into one query, then cross-checked the row count before exporting.

## Findings
- **40 transactions flagged** out of 60,010 — 0.07% of the sample
- **All 40 were High Velocity.** Zero High Value Anomaly, zero Repeated Amount
- **Total flagged value: ₦30,089,960.13**
- Flagged amounts ranged from about ₦2,600 up to ₦649,000+, color-scaled in Excel so the highest-value ones stand out

**Why it's all velocity:** most receiving accounts in this sample only show up 2-3 times. That's too few transactions for "3x above average" to mean much, or for an exact amount to repeat — but velocity only needs two transactions in the same hour, which is a much lower bar to clear. Not a bug, just a real limit of working with a sampled dataset instead of full transaction history.

## Recommendations
1. **Velocity should really be checked against real timestamps, not hourly buckets.** PaySim's `step` field is hour-level, so this is a rough proxy — a system with true minute-level data would likely catch more real velocity patterns and fewer false ones.
2. **High Value Anomaly and Repeated Amount need more transactions per account to actually work.** With only 2-3 per account here, they're not being tested properly — not failed, just underpowered by the sample size.
3. **For now, I'd prioritize reviewing the velocity flags first**, since that's the pattern with actual signal in this data. The other two checks are built and ready, just waiting on richer data to prove out.

## Files in this Repo
- `fraud_detection_query.sql` — the combined SQL detection query
- `fraud_risk_summary.xlsx` — Excel summary with flag breakdown and color-scaled risk highlighting
- `README.md` — this file
