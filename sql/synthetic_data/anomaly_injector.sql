DECLARE run_date DATE;
DECLARE table_suffix STRING;
DECLARE anomaly_today BOOL;

-- Yesterday
SET run_date = DATE_SUB(CURRENT_DATE('Asia/Kolkata'), INTERVAL 1 DAY);
SET table_suffix = FORMAT_DATE('%Y%m%d', run_date);

-- Decide randomly if today is an anomaly day (~7% chance)
SET anomaly_today = RAND() < 0.07;

-- =========================
-- EXIT EARLY IF NOT ANOMALY DAY
-- =========================
IF NOT anomaly_today THEN
  -- Do nothing
  SELECT 'No anomaly injected today' AS status;
ELSE

  -- =========================
  -- 1️⃣ NEGATIVE TRAFFIC ANOMALY
  -- =========================
  EXECUTE IMMEDIATE FORMAT("""
    DELETE FROM `tvc-ecommerce.GA4SampleData_live.events_%s`
    WHERE event_name IN ('page_view','session_start','user_engagement')
      AND RAND() < 0.45
  """, table_suffix);

  -- =========================
  -- 2️⃣ POSITIVE PURCHASE SPIKE
  -- =========================
  EXECUTE IMMEDIATE FORMAT("""
    INSERT INTO `tvc-ecommerce.GA4SampleData_live.events_%s`
    SELECT *
    FROM `tvc-ecommerce.GA4SampleData_live.events_%s`
    WHERE event_name = 'purchase'
      AND RAND() < 0.60
  """, table_suffix, table_suffix);

  SELECT 'Anomaly injected for date ' || CAST(run_date AS STRING) AS status;

END IF;
