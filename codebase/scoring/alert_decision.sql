CREATE OR REPLACE TABLE
`tvc-ecommerce.analytics_live.ga4_anomaly_alert_decisions` AS

WITH base AS (
  SELECT
    event_date,
    event_name,
    severity_level,
    business_impact,
    is_anomaly
  FROM `tvc-ecommerce.analytics_live.ga4_anomaly_scored_events`
),

/* =========================================
   ALERTS RAISED YESTERDAY (FOR DEDUP)
   ========================================= */
yesterday_alerts AS (
  SELECT
    event_date,
    event_name,
    severity_level
  FROM base
  WHERE
    is_anomaly = TRUE
    AND (
      severity_level = 'CRITICAL'
      OR (
        severity_level = 'HIGH'
        AND business_impact IN ('HIGH','VERY_HIGH')
      )
    )
),

evaluated AS (
  SELECT
    b.*,

    /* =========================================
       ALERT ELIGIBILITY
       ========================================= */
    CASE
      WHEN is_anomaly = TRUE
       AND (
         severity_level = 'CRITICAL'
         OR (
           severity_level = 'HIGH'
           AND business_impact IN ('HIGH','VERY_HIGH')
         )
       )
      THEN TRUE
      ELSE FALSE
    END AS alert_eligible,

    /* =========================================
       REPEATED ALERT CHECK
       ========================================= */
    CASE
      WHEN EXISTS (
        SELECT 1
        FROM yesterday_alerts y
        WHERE
          y.event_date = DATE_SUB(b.event_date, INTERVAL 1 DAY)
          AND y.event_name = b.event_name
          AND y.severity_level = b.severity_level
      )
      THEN TRUE
      ELSE FALSE
    END AS repeated_alert

  FROM base b
)

SELECT
  event_date,
  event_name,
  severity_level,
  business_impact,
  alert_eligible,
  repeated_alert,

  /* =========================================
     SUPPRESSION LOGIC
     ========================================= */
  CASE
    WHEN alert_eligible = FALSE THEN TRUE
    WHEN severity_level = 'CRITICAL' THEN FALSE
    ELSE FALSE
  END AS suppressed,

  /* =========================================
     ALERT PRIORITY
     ========================================= */
  CASE
    WHEN alert_eligible = FALSE THEN 'NONE'
    WHEN severity_level = 'CRITICAL' THEN 'P0'
    WHEN severity_level = 'HIGH'
         AND business_impact IN ('HIGH','VERY_HIGH')
    THEN 'P1'
    ELSE 'NONE'
  END AS alert_priority,

  CURRENT_TIMESTAMP() AS decision_timestamp

FROM evaluated;