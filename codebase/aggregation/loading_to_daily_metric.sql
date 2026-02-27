DECLARE run_date DATE;
DECLARE table_suffix STRING;

-- Resolve processing date (manual > live vs replay)
SET run_date = (
  SELECT
    CASE
      WHEN replay_mode = TRUE THEN current_run_date
      ELSE DATE_SUB(CURRENT_DATE('Asia/Kolkata'), INTERVAL 1 DAY)
    END
  FROM `tvc-ecommerce.analytics_live.pipeline_runtime`
);

SET table_suffix = FORMAT_DATE('%Y%m%d', run_date);

-- Idempotency: remove existing rows for this date
DELETE
FROM `tvc-ecommerce.analytics_live.ga4_event_metrics_daily`
WHERE event_date = run_date;

-- =========================
-- INSERT DAILY METRICS (CONFIG-DRIVEN)
-- =========================
EXECUTE IMMEDIATE FORMAT("""
INSERT INTO `tvc-ecommerce.analytics_live.ga4_event_metrics_daily`
SELECT
  DATE('%s') AS event_date,
  metric_name AS event_name,
  metric_value AS event_value
FROM (

  -- =========================
  -- EVENT COUNT METRICS
  -- =========================
  SELECT
    mc.metric_name AS metric_name,
    COUNT(*) AS metric_value
  FROM `tvc-ecommerce.GA4SampleData_live.events_%s` e
  JOIN `tvc-ecommerce.analytics_live.metric_config` mc
    ON e.event_name = mc.event_name
  WHERE
    mc.is_enabled = TRUE
    AND mc.metric_name != 'purchase'
  GROUP BY mc.metric_name  -- <-- FIXED: Added metric_name to GROUP BY

  UNION ALL

  -- =========================
  -- PURCHASE REVENUE METRIC
  -- =========================
  SELECT
    mc.metric_name AS metric_name,
    COALESCE(SUM(ecommerce.purchase_revenue), 0) AS metric_value
  FROM `tvc-ecommerce.GA4SampleData_live.events_%s` e
  JOIN `tvc-ecommerce.analytics_live.metric_config` mc
    ON e.event_name = mc.event_name
  WHERE
    mc.is_enabled = TRUE
    AND mc.metric_name = 'purchase'
  GROUP BY mc.metric_name  -- <-- ADDED explicit GROUP BY for clarity
)
""",
CAST(run_date AS STRING),
table_suffix,
table_suffix
);