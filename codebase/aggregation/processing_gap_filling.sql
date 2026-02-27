DECLARE run_date DATE;

-- Resolve processing date (live vs replay)
SET run_date = (
  SELECT
    CASE
      WHEN replay_mode = TRUE THEN current_run_date
      ELSE DATE_SUB(CURRENT_DATE('Asia/Kolkata'), INTERVAL 1 DAY)
    END
  FROM `tvc-ecommerce.analytics_live.pipeline_runtime`
);

-- Idempotency: remove existing rows
DELETE
FROM `tvc-ecommerce.analytics_live.ga4_event_metrics_daily_filled`
WHERE event_date = run_date;

-- =========================
-- INSERT GAP-FILLED METRICS (CONFIG-DRIVEN)
-- =========================
INSERT INTO `tvc-ecommerce.analytics_live.ga4_event_metrics_daily_filled`
SELECT
  run_date AS event_date,
  mc.metric_name AS event_name,
  COALESCE(d.event_value, 0) AS event_value
FROM (
  SELECT metric_name
  FROM `tvc-ecommerce.analytics_live.metric_config`
  WHERE is_enabled = TRUE
) mc
LEFT JOIN `tvc-ecommerce.analytics_live.ga4_event_metrics_daily` d
  ON d.event_date = run_date
 AND d.event_name = mc.metric_name;