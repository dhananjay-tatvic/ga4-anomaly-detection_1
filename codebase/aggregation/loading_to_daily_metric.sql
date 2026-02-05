DECLARE run_date DATE;
DECLARE table_suffix STRING;

-- Resolve processing date (live vs replay)
SET run_date = (
  SELECT
    CASE
      WHEN replay_mode = TRUE THEN current_run_date
      ELSE DATE_SUB(CURRENT_DATE('Asia/Kolkata'), INTERVAL 1 DAY)
    END
  FROM `tvc-ecommerce.analytics_live.pipeline_runtime`
);

SET table_suffix = FORMAT_DATE('%Y%m%d', run_date);

-- Idempotency: remove existing rows
DELETE
FROM `tvc-ecommerce.analytics_live.ga4_event_metrics_daily`
WHERE event_date = run_date;

-- =========================
-- INSERT DAILY METRICS
-- =========================
EXECUTE IMMEDIATE FORMAT("""
INSERT INTO `tvc-ecommerce.analytics_live.ga4_event_metrics_daily`
SELECT
  DATE('%s') AS event_date,
  metric_name AS event_name,
  metric_value AS event_value
FROM (
  -- Event counts
  SELECT
    event_name AS metric_name,
    COUNT(*) AS metric_value
  FROM `tvc-ecommerce.GA4SampleData_live.events_%s`
  WHERE event_name IN (
    'page_view',
    'session_start',
    'user_engagement',
    'add_to_cart',
    'add_payment_info'
  )
  GROUP BY event_name

  UNION ALL

  -- Purchase revenue
  SELECT
    'purchase' AS metric_name,
    COALESCE(SUM(ecommerce.purchase_revenue), 0) AS metric_value
  FROM `tvc-ecommerce.GA4SampleData_live.events_%s`
  WHERE event_name = 'purchase'
)
""", CAST(run_date AS STRING), table_suffix, table_suffix);
