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

-- Insert gap-filled metrics
INSERT INTO `tvc-ecommerce.analytics_live.ga4_event_metrics_daily_filled`
SELECT
  run_date AS event_date,
  m.event_name,
  COALESCE(d.event_value, 0) AS event_value
FROM (
  SELECT 'page_view' AS event_name UNION ALL
  SELECT 'session_start' UNION ALL
  SELECT 'user_engagement' UNION ALL
  SELECT 'add_to_cart' UNION ALL
  SELECT 'add_payment_info' UNION ALL
  SELECT 'purchase'
) m
LEFT JOIN `tvc-ecommerce.analytics_live.ga4_event_metrics_daily` d
  ON d.event_date = run_date
 AND d.event_name = m.event_name;
