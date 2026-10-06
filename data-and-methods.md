# Data and methods

## Required source tables

All tables reside under `analysis.churn_rate_analysis` by default.

| Table | Required columns | Expected grain |
|---|---|---|
| customers | customer_id, signup_date | One row per customer |
| transactions | customer_id, transaction_date | One row per recorded transaction |
| user_activity | customer_id, event_date, event_type | One row per recorded activity event |

The tutorial also includes subscriptions, but the current classification does not use it. Names, emails, amounts, and country fields are not required by the published classification SQL. Country and transaction-amount widgets in the dashboard are outside the scope of the summary reproduction scripts.

## Observation rules

- Analysis date: 2025-03-09.
- Payment and login cutoff: 2024-12-09, calculated by subtracting 90 days.
- Dates are cast to DATE. Preserve consistent session timezone settings when importing timestamps or comparing runs.
- Records after the analysis date are excluded before aggregation.
- Customers with signup dates after the analysis date are excluded; null signup dates are also excluded by the filter and should be investigated.
- Recent dates include both endpoints. This is a threshold convention, not a claim of exactly 90 inclusive calendar dates.
- Only events with exact label `Login` count as logins.
- Payments means recorded transactions in this implementation; a payment-success filter cannot be assumed without inspecting transaction status fields.
- Missing payment/login dates in the aggregate mean no qualifying dated record was found. They may reflect missing data.

## Why separate aggregation matters

Joining all transactions directly to all activity rows for a customer creates a many-to-many expansion. MAX dates can remain unchanged, but transaction counts and amounts become inflated. Aggregating each table by customer before joining prevents that expansion, assuming unique customer master IDs.

## Segment precedence

Financial is evaluated before Silent, then remaining Engagement, No payment history, and explicit Active. These are exclusive output labels, not independent flags. A financially inactive customer may also lack recent logins but is counted only once.

## Metric

Flagged share = (Financial + Silent + Engagement) / all classified customers × 100.

No payment history is not included in the numerator. It represents recent login without a qualifying payment record, not proven churn. Do not interpret 72.8% as subscription cancellation, revenue churn, or a monthly cohort churn rate.
