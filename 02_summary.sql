-- Run 01 first in the same session, or run the scripts together.
SELECT churn_type, COUNT(*) AS customers,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 3)
           AS percentage_of_customers
FROM customer_churn_classification
GROUP BY churn_type
ORDER BY customers DESC;

SELECT COUNT(*) AS total_customers,
       SUM(CASE WHEN churn_type IN ('Financial churn', 'Silent churn',
                                    'Engagement churn') THEN 1 ELSE 0 END)
           AS flagged_customers,
       ROUND(100.0 * SUM(CASE WHEN churn_type IN
           ('Financial churn', 'Silent churn', 'Engagement churn')
           THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0), 3)
           AS flagged_percentage
FROM customer_churn_classification;
