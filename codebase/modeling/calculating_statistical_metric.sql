DECLARE run_date DATE;

-- Always process yesterday (IST-safe)
SET run_date = DATE_SUB(CURRENT_DATE('Asia/Kolkata'), INTERVAL 1 DAY);

-- =========================
-- IDEMPOTENCY
-- =========================
DELETE
FROM `tvc-ecommerce.analytics_live.ga4_anomaly_enriched_all_events`
WHERE event_date = run_date;

-- =========================
-- INSERT DAILY ANOMALIES
-- =========================
INSERT INTO `tvc-ecommerce.analytics_live.ga4_anomaly_enriched_all_events`
(
  event_date,
  event_name,
  actual_value,
  expected_value,
  lower_bound,
  upper_bound,
  deviation_pct,
  z_score,
  bound_distance,
  is_outside_bounds,
  computation_timestamp,
  is_anomaly,
  anomaly_probability
)

WITH base AS (
  -- Only enabled metrics flow forward
  SELECT
    b.event_date,
    b.event_name,
    b.event_value
  FROM `tvc-ecommerce.analytics_live.ga4_event_metrics_daily_filled` b
  JOIN `tvc-ecommerce.analytics_live.metric_config` mc
    ON b.event_name = mc.metric_name
  WHERE
    b.event_date = run_date
    AND mc.is_enabled = TRUE
),

metric_cfg AS (
  SELECT
    metric_name,
    anomaly_probability_threshold,
    business_impact
  FROM `tvc-ecommerce.analytics_live.metric_config`
  WHERE is_enabled = TRUE
),

-- =========================
-- FORECASTS (STATIC MODELS)
-- =========================
forecast AS (
  SELECT * FROM (
    SELECT 'page_view' AS event_name, * FROM ML.FORECAST(MODEL `tvc-ecommerce.analysis_test.model_page_view_daily`, STRUCT(1 AS horizon))
    UNION ALL
    SELECT 'session_start', * FROM ML.FORECAST(MODEL `tvc-ecommerce.analysis_test.model_session_start_daily`, STRUCT(1 AS horizon))
    UNION ALL
    SELECT 'user_engagement', * FROM ML.FORECAST(MODEL `tvc-ecommerce.analysis_test.model_user_engagement_daily`, STRUCT(1 AS horizon))
    UNION ALL
    SELECT 'scroll', * FROM ML.FORECAST(MODEL `tvc-ecommerce.analysis_test.model_scroll_daily`, STRUCT(1 AS horizon))
    UNION ALL
    SELECT 'view_item', * FROM ML.FORECAST(MODEL `tvc-ecommerce.analysis_test.model_view_item_daily`, STRUCT(1 AS horizon))
    UNION ALL
    SELECT 'add_to_cart', * FROM ML.FORECAST(MODEL `tvc-ecommerce.analysis_test.model_add_to_cart_daily`, STRUCT(1 AS horizon))
    UNION ALL
    SELECT 'begin_checkout', * FROM ML.FORECAST(MODEL `tvc-ecommerce.analysis_test.model_begin_checkout_daily`, STRUCT(1 AS horizon))
    UNION ALL
    SELECT 'add_payment_info', * FROM ML.FORECAST(MODEL `tvc-ecommerce.analysis_test.model_add_payment_info_daily`, STRUCT(1 AS horizon))
    UNION ALL
    SELECT 'purchase', * FROM ML.FORECAST(MODEL `tvc-ecommerce.analysis_test.model_purchase_daily`, STRUCT(1 AS horizon))
  )
  QUALIFY ROW_NUMBER() OVER (PARTITION BY event_name ORDER BY forecast_timestamp DESC) = 1
),

-- =========================
-- RAW ANOMALY SCORES (FIXED THRESHOLD)
-- =========================
raw_anomaly AS (
  SELECT event_name, is_anomaly, anomaly_probability FROM (
    SELECT 'page_view' AS event_name, * FROM ML.DETECT_ANOMALIES(
      MODEL `tvc-ecommerce.analysis_test.model_page_view_daily`,
      STRUCT(0.95 AS anomaly_prob_threshold),
      (SELECT event_date, event_value FROM base WHERE event_name = 'page_view')
    )
    UNION ALL
    SELECT 'session_start', * FROM ML.DETECT_ANOMALIES(
      MODEL `tvc-ecommerce.analysis_test.model_session_start_daily`,
      STRUCT(0.95 AS anomaly_prob_threshold),
      (SELECT event_date, event_value FROM base WHERE event_name = 'session_start')
    )
    UNION ALL
    SELECT 'user_engagement', * FROM ML.DETECT_ANOMALIES(
      MODEL `tvc-ecommerce.analysis_test.model_user_engagement_daily`,
      STRUCT(0.95 AS anomaly_prob_threshold),
      (SELECT event_date, event_value FROM base WHERE event_name = 'user_engagement')
    )
    UNION ALL
    SELECT 'scroll', * FROM ML.DETECT_ANOMALIES(
      MODEL `tvc-ecommerce.analysis_test.model_scroll_daily`,
      STRUCT(0.95 AS anomaly_prob_threshold),
      (SELECT event_date, event_value FROM base WHERE event_name = 'scroll')
    )
    UNION ALL
    SELECT 'view_item', * FROM ML.DETECT_ANOMALIES(
      MODEL `tvc-ecommerce.analysis_test.model_view_item_daily`,
      STRUCT(0.95 AS anomaly_prob_threshold),
      (SELECT event_date, event_value FROM base WHERE event_name = 'view_item')
    )
    UNION ALL
    SELECT 'add_to_cart', * FROM ML.DETECT_ANOMALIES(
      MODEL `tvc-ecommerce.analysis_test.model_add_to_cart_daily`,
      STRUCT(0.95 AS anomaly_prob_threshold),
      (SELECT event_date, event_value FROM base WHERE event_name = 'add_to_cart')
    )
    UNION ALL
    SELECT 'begin_checkout', * FROM ML.DETECT_ANOMALIES(
      MODEL `tvc-ecommerce.analysis_test.model_begin_checkout_daily`,
      STRUCT(0.95 AS anomaly_prob_threshold),
      (SELECT event_date, event_value FROM base WHERE event_name = 'begin_checkout')
    )
    UNION ALL
    SELECT 'add_payment_info', * FROM ML.DETECT_ANOMALIES(
      MODEL `tvc-ecommerce.analysis_test.model_add_payment_info_daily`,
      STRUCT(0.95 AS anomaly_prob_threshold),
      (SELECT event_date, event_value FROM base WHERE event_name = 'add_payment_info')
    )
    UNION ALL
    SELECT 'purchase', * FROM ML.DETECT_ANOMALIES(
      MODEL `tvc-ecommerce.analysis_test.model_purchase_daily`,
      STRUCT(0.95 AS anomaly_prob_threshold),
      (SELECT event_date, event_value FROM base WHERE event_name = 'purchase')
    )
  )
)

SELECT
  b.event_date,
  b.event_name,
  b.event_value AS actual_value,
  f.forecast_value AS expected_value,
  f.prediction_interval_lower_bound AS lower_bound,
  f.prediction_interval_upper_bound AS upper_bound,
  SAFE_DIVIDE(b.event_value - f.forecast_value, f.forecast_value) AS deviation_pct,
  SAFE_DIVIDE(b.event_value - f.forecast_value, f.standard_error) AS z_score,
  GREATEST(
    f.prediction_interval_lower_bound - b.event_value,
    b.event_value - f.prediction_interval_upper_bound,
    0
  ) AS bound_distance,
  b.event_value < f.prediction_interval_lower_bound
    OR b.event_value > f.prediction_interval_upper_bound AS is_outside_bounds,
  CURRENT_TIMESTAMP() AS computation_timestamp,

  -- ✅ FINAL CONFIG-DRIVEN DECISION
  CASE
    WHEN ra.anomaly_probability >= mc.anomaly_probability_threshold
    THEN TRUE
    ELSE FALSE
  END AS is_anomaly,

  ra.anomaly_probability

FROM base b
JOIN forecast f
  ON b.event_name = f.event_name
LEFT JOIN raw_anomaly ra
  ON b.event_name = ra.event_name
JOIN metric_cfg mc
  ON b.event_name = mc.metric_name;