from google.cloud import bigquery
from datetime import datetime, timedelta
import pytz

# -----------------------------------------------------
# CONFIG
# -----------------------------------------------------
PROJECT_ID = "tvc-ecommerce"
DATASET = "analytics_live"

SCORING_TABLE = f"{PROJECT_ID}.{DATASET}.ga4_anomaly_scored_events"
CAMPAIGN_TABLE = f"{PROJECT_ID}.{DATASET}.campaign_context"
NEWS_TABLE = f"{PROJECT_ID}.{DATASET}.news_context"

TIMEZONE = "Asia/Kolkata"

# -----------------------------------------------------
# INIT CLIENT
# -----------------------------------------------------
client = bigquery.Client(project=PROJECT_ID)

# -----------------------------------------------------
# GET YESTERDAY DATE (IST)
# -----------------------------------------------------
tz = pytz.timezone(TIMEZONE)
yesterday = (datetime.now(tz) - timedelta(days=1)).date()

print(f"\n🔎 Evaluating anomalies for date: {yesterday}\n")

# -----------------------------------------------------
# STEP 1 — FETCH ELIGIBLE ANOMALIES
# -----------------------------------------------------
query_anomalies = f"""
SELECT *
FROM `{SCORING_TABLE}`
WHERE
  event_date = @event_date
  AND is_anomaly = TRUE
  AND severity_level IN ('MEDIUM','HIGH','CRITICAL')
"""

job_config = bigquery.QueryJobConfig(
    query_parameters=[
        bigquery.ScalarQueryParameter("event_date", "DATE", yesterday)
    ]
)

anomalies = list(client.query(query_anomalies, job_config=job_config))

if not anomalies:
    print("No eligible anomalies found.")
    exit()

print(f"Found {len(anomalies)} eligible anomalies.\n")

# -----------------------------------------------------
# STEP 2 — FETCH CONTEXT DATA
# -----------------------------------------------------
query_campaign = f"""
SELECT *
FROM `{CAMPAIGN_TABLE}`
WHERE campaign_date = @event_date
"""

query_news = f"""
SELECT *
FROM `{NEWS_TABLE}`
WHERE news_date = @event_date
"""

campaigns = list(client.query(query_campaign, job_config=job_config))
news_items = list(client.query(query_news, job_config=job_config))

print(f"Campaigns found: {len(campaigns)}")
print(f"News items found: {len(news_items)}\n")

# -----------------------------------------------------
# STEP 3 — PROCESS EACH ANOMALY
# -----------------------------------------------------
for anomaly in anomalies:
    deviation = anomaly.deviation_pct
    direction = "POSITIVE" if deviation > 0 else "NEGATIVE"

    has_campaign = len(campaigns) > 0
    has_news = len(news_items) > 0

    # Simple direction alignment rule
    direction_aligned = False

    if direction == "POSITIVE" and has_campaign:
        direction_aligned = True

    if direction == "NEGATIVE" and has_news:
        direction_aligned = True

    print("--------------------------------------------------")
    print(f"Event: {anomaly.event_name}")
    print(f"Deviation: {deviation:.2f}% ({direction})")
    print(f"Severity: {anomaly.severity_level}")
    print(f"Campaign Found: {has_campaign}")
    print(f"News Found: {has_news}")
    print(f"Direction Aligned: {direction_aligned}")
    print(f"Eligible for LLM Evaluation: {direction_aligned and (has_campaign or has_news)}")
    print("--------------------------------------------------\n")