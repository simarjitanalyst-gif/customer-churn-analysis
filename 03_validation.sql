-- Diagnostic checks to run on the source data. Not executed as part of
-- repository packaging; see docs/validation.md for observed evidence.
-- Run 01 first in the same session.

-- Expected: 50000 rows, 50000 distinct customers, 0 null IDs.
SELECT COUNT(*) AS row_count,
       COUNT(DISTINCT customer_id) AS distinct_customers,
       SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS null_ids
FROM customer_churn_classification;

-- Expected: no rows. Duplicate master records would multiply output rows.
SELECT customer_id, COUNT(*) AS records
FROM analysis.churn_rate_analysis.customers
GROUP BY customer_id
HAVING COUNT(*) > 1 OR customer_id IS NULL;

-- Missing dates need investigation; NULL does not prove no history.
SELECT 'customers.signup_date' AS field, COUNT(*) AS missing_dates
FROM analysis.churn_rate_analysis.customers WHERE signup_date IS NULL
UNION ALL
SELECT 'transactions.transaction_date', COUNT(*)
FROM analysis.churn_rate_analysis.transactions WHERE transaction_date IS NULL
UNION ALL
SELECT 'user_activity.event_date', COUNT(*)
FROM analysis.churn_rate_analysis.user_activity WHERE event_date IS NULL;

-- Expected: no rows; review any segment/count mismatch.
WITH expected AS (
    SELECT * FROM VALUES
        ('Financial churn', 21645), ('Silent churn', 14741),
        ('Active', 13612), ('No payment history', 1),
        ('Engagement churn', 1)
    AS e(churn_type, expected_count)
), actual AS (
    SELECT churn_type, COUNT(*) AS actual_count
    FROM customer_churn_classification GROUP BY churn_type
)
SELECT COALESCE(e.churn_type, a.churn_type) AS segment,
       e.expected_count, a.actual_count
FROM expected e FULL OUTER JOIN actual a ON e.churn_type = a.churn_type
WHERE COALESCE(e.expected_count, -1) <> COALESCE(a.actual_count, -1);
