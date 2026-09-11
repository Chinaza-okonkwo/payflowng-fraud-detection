# PayFlowNG: Transaction Fraud Detection Analysis

## Problem Statement
This project demonstrates a rules-based approach to flagging potentially fraudulent transactions using SQL — identifying transactions that deviate from normal account behavior across three distinct patterns, then quantifying and visualizing the results in Excel for stakeholder review.

## Data Source
**PaySim** (Kaggle) — a real, publicly available synthetic financial transaction dataset simulating fintech payment activity. A 60,010-transaction sample was drawn using day-partitioned random sampling across the full 30-day window.

**Note on sample size:** an initial 10,000-transaction sample (consistent with the size used in the reconciliation project) returned only 2 flagged transactions — too sparse to produce a meaningful risk summary. The sample was expanded to ~60,000 transactions specifically to surface enough repeated account activity for the velocity and repeated-amount checks to function, since fraud pattern detection depends on accounts appearing multiple times in the dataset.

## Detection Methodology
Three fraud patterns were flagged using SQL:
- **High Value Anomaly** — a transaction exceeding 3x the receiving account's average transaction amount
- **High Velocity** — an account receiving more than one transaction within the same hourly `step`
- **Repeated Amount** — the same account receiving the identical transaction amount more than once

**Note on account identifier:** PaySim's `nameOrig` (originating account) field is effectively unique per transaction in this dataset and never repeats — making it unusable for detecting account-level behavioral patterns, which by definition require an account to appear more than once. `nameDest` (receiving account) was used instead, since it shows genuine repetition across the sample.

Each transaction was compared against account-level windowed averages and grouped counts via SQL (CTEs, window functions, and CASE logic), with all three checks combined into a single query and cross-checked with a final result count before export.

## Findings
- **40 transactions flagged** out of 60,010 (0.07% of the sample)
- **All 40 flags were High Velocity** — zero High Value Anomaly, zero Repeated Amount
- **Total flagged value: ₦30,089,960.13**
- Flagged amounts ranged widely, from roughly ₦2,600 to over ₦649,000 per transaction, visualized via a color scale in the Excel summary to surface the highest-value flags at a glance

**Why only velocity flags appeared:** receiving accounts in this sample typically repeat only 2–3 times each. With so few transactions per account, there's limited statistical room for a transaction to exceed 3x a very small average, or for an exact amount to repeat — but velocity only requires two transactions to land in the same hourly window, a much lower bar. This is a genuine characteristic of the sampled data, not a flaw in the detection logic.

## Recommendations
1. **Velocity thresholds should be re-tuned against real transaction-level timestamps, not hourly buckets.** This dataset's `step` field only provides hour-level granularity; a production system with true minute- or second-level timestamps would very likely surface additional High Velocity flags that this coarser grouping missed, and would reduce false positives from transactions that merely happen to share an hour.
2. **High Value Anomaly and Repeated Amount checks need a larger transaction history per account to be meaningful.** With only 2–3 transactions per account in this sample, these checks are effectively under-powered. In a live system with full transaction history per customer, both checks would likely surface real results — this sample simply doesn't have enough repeated activity per account to test them properly.
3. **Given the current findings, monitoring effort should prioritize velocity-based review first**, since it's the only pattern with enough signal in this sample to act on — while treating the value and repeated-amount checks as validated logic awaiting a richer dataset, not failed detection methods.

## Files in this Repo
- `fraud_detection_query.sql` — the combined SQL detection query
- `fraud_risk_summary.xlsx` — Excel summary with flag breakdown and color-scaled risk highlighting
- `README.md` — this file
