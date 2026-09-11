/*
  Fraud Detection Query — PayFlowNG Portfolio Project
  Purpose: Flags potentially fraudulent transactions across three patterns —
  High Value Anomaly, High Velocity, and Repeated Amount — using a receiving
  account's (nameDest) transaction history within a 60,010-row sample.
*/

WITH account_averages AS (
    -- Calculates each receiving account's average transaction amount,
    -- used to detect transactions that are unusually large relative to
    -- that account's own typical activity.
    SELECT transaction_id, nameDest, amount,
        AVG(amount) OVER (PARTITION BY nameDest) AS account_average
    FROM paysim_fraud_sample
),

velocity_check AS (
    -- Flags receiving accounts with more than one transaction landing in
    -- the same hourly step — a proxy for high-frequency activity, given
    -- this dataset's hour-level (not minute-level) timestamp granularity.
    SELECT nameDest, step, COUNT(*) AS txn_count
    FROM paysim_fraud_sample
    GROUP BY nameDest, step
    HAVING COUNT(*) > 1
),

repeated_amount_check AS (
    -- Flags receiving accounts charged the identical amount more than once,
    -- a possible signal of duplicate or automated fraudulent transfers.
    SELECT nameDest, amount, COUNT(*) AS times_charged
    FROM paysim_fraud_sample
    GROUP BY nameDest, amount
    HAVING COUNT(*) > 1
)

-- Combines all three checks into a single flagged result. Order in the
-- CASE statement is deliberate: High Value Anomaly is checked first since
-- it's the most severe signal, followed by Velocity and Repeated Amount.
SELECT DISTINCT t.transaction_id, t.nameDest, t.amount, t.step,
CASE
    WHEN a.amount > 3 * a.account_average THEN 'High Value Anomaly'
    WHEN v.nameDest IS NOT NULL THEN 'High Velocity'
    WHEN r.nameDest IS NOT NULL THEN 'Repeated Amount'
    ELSE 'Unflagged'
END AS flag_type

FROM paysim_fraud_sample t
LEFT JOIN account_averages a ON t.transaction_id = a.transaction_id
LEFT JOIN velocity_check v ON t.nameDest = v.nameDest AND t.step = v.step
LEFT JOIN repeated_amount_check r ON t.nameDest = r.nameDest AND t.amount = r.amount

-- Only returns rows that triggered at least one of the three flags.
WHERE a.amount > 3 * a.account_average
   OR v.nameDest IS NOT NULL
   OR r.nameDest IS NOT NULL;
