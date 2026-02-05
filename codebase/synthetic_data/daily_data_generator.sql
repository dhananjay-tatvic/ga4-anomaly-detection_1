DECLARE run_date DATE;
DECLARE table_suffix STRING;

-- Yesterday
SET run_date = DATE_SUB(CURRENT_DATE('Asia/Kolkata'), INTERVAL 1 DAY);
SET table_suffix = FORMAT_DATE('%Y%m%d', run_date);

EXECUTE IMMEDIATE FORMAT("""
CREATE OR REPLACE TABLE `tvc-ecommerce.GA4SampleData_live.events_%s` AS

WITH base_day AS (
  SELECT DATE('%s') AS event_date
),

calendar AS (
  SELECT
    event_date,
    (
      CASE
        WHEN EXTRACT(DAYOFWEEK FROM event_date) IN (1,7) THEN 0.85
        ELSE 1.00
      END
      *
      CASE
        WHEN event_date BETWEEN '2024-10-28' AND '2024-11-02' THEN 1.8
        WHEN event_date = '2024-12-25' THEN 1.5
        ELSE 1.0
      END
    ) AS total_multiplier
  FROM base_day
),

users AS (
  SELECT user_pseudo_id
  FROM `analytics_live.synthetic_users`
  ORDER BY RAND()
  LIMIT 12000
)

SELECT
  base.* REPLACE (
    FORMAT_DATE('%%Y%%m%%d', c.event_date) AS event_date,
    UNIX_MICROS(
      TIMESTAMP(c.event_date)
      + INTERVAL CAST(RAND() * 86400 AS INT64) SECOND
    ) AS event_timestamp,
    e.event_name AS event_name,
    u.user_pseudo_id AS user_pseudo_id,
    CASE
      WHEN e.event_name = 'purchase' THEN
        STRUCT(
          CAST(ROUND(500 + RAND()*4000, 2) AS FLOAT64) AS purchase_revenue,
          'INR' AS currency
        )
      ELSE NULL
    END AS ecommerce
  )
FROM calendar c
CROSS JOIN users u
CROSS JOIN UNNEST([
  STRUCT('page_view' AS event_name, 0.30 AS prob),
  STRUCT('session_start', 0.10),
  STRUCT('user_engagement', 0.10),
  STRUCT('scroll', 0.20),
  STRUCT('view_item', 0.15),
  STRUCT('add_to_cart', 0.03),
  STRUCT('begin_checkout', 0.02),
  STRUCT('add_payment_info', 0.015),
  STRUCT('purchase', 0.003)
]) e
CROSS JOIN `analytics_live.ga4_base_row` base
WHERE RAND() < e.prob * c.total_multiplier
""",
table_suffix,
CAST(run_date AS STRING)
);

