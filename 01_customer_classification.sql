-- Databricks SQL. Run this script before 02 and 03 in the SAME session.
-- A temporary view keeps the source tables unchanged.
-- Recent means date >= 2024-12-09 and <= 2025-03-09 (inclusive).
-- This reproduces the reviewed query; names/emails are omitted from output.
CREATE OR REPLACE TEMP VIEW customer_churn_classification AS
WITH payments AS (
    SELECT customer_id,
           MAX(CAST(transaction_date AS DATE)) AS last_payment_date
    FROM analysis.churn_rate_analysis.transactions
    WHERE CAST(transaction_date AS DATE) <= DATE '2025-03-09'
    GROUP BY customer_id
),
logins AS (
    SELECT customer_id,
           MAX(CAST(event_date AS DATE)) AS last_login_date
    FROM analysis.churn_rate_analysis.user_activity
    WHERE event_type = 'Login'
      AND CAST(event_date AS DATE) <= DATE '2025-03-09'
    GROUP BY customer_id
)
SELECT c.customer_id, p.last_payment_date, l.last_login_date,
    CASE
        WHEN p.last_payment_date < DATE_SUB(DATE '2025-03-09', 90)
            THEN 'Financial churn'
        WHEN p.last_payment_date >= DATE_SUB(DATE '2025-03-09', 90)
         AND (l.last_login_date < DATE_SUB(DATE '2025-03-09', 90)
              OR l.last_login_date IS NULL)
            THEN 'Silent churn'
        WHEN p.last_payment_date IS NULL
         AND (l.last_login_date < DATE_SUB(DATE '2025-03-09', 90)
              OR l.last_login_date IS NULL)
            THEN 'Engagement churn'
        WHEN p.last_payment_date IS NULL
         AND l.last_login_date >= DATE_SUB(DATE '2025-03-09', 90)
            THEN 'No payment history'
        WHEN p.last_payment_date >= DATE_SUB(DATE '2025-03-09', 90)
         AND l.last_login_date >= DATE_SUB(DATE '2025-03-09', 90)
            THEN 'Active'
        ELSE 'Needs review'
    END AS churn_type
FROM analysis.churn_rate_analysis.customers c
LEFT JOIN payments p ON c.customer_id = p.customer_id
LEFT JOIN logins l ON c.customer_id = l.customer_id
WHERE CAST(c.signup_date AS DATE) <= DATE '2025-03-09';
