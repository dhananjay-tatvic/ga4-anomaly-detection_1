-- ============================
-- PERIODIC ARIMA RETRAINING
-- ============================

DECLARE metrics ARRAY<STRING> DEFAULT [
  'page_view',
  'session_start',
  'user_engagement',
  'add_to_cart',
  'add_payment_info',
  'purchase'
];

FOR metric IN (
  SELECT metric_name FROM UNNEST(metrics) AS metric_name
) DO
  EXECUTE IMMEDIATE FORMAT("""
    CREATE OR REPLACE MODEL `tvc-ecommerce.analytics_live.model_%s_daily`
    OPTIONS (
      model_type = 'ARIMA_PLUS',
      time_series_timestamp_col = 'event_date',
      time_series_data_col = 'event_value',
      decompose_time_series = TRUE
    ) AS
    SELECT
      event_date,
      event_value
    FROM `tvc-ecommerce.analytics_live.ga4_event_metrics_daily_filled`
    WHERE event_name = '%s'
    ORDER BY event_date;
  """, metric.metric_name, metric.metric_name);
END FOR;

