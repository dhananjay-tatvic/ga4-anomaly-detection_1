# =====================================================
# GA4 CONTEXTUAL ANOMALY AGENT - CLOUD RUN PRODUCTION
# Gemini 2.5 Flash + Deterministic JSON + BigQuery Load
# =====================================================

from flask import Flask, jsonify
from google.cloud import bigquery
from google.cloud import aiplatform
from vertexai.generative_models import GenerativeModel
from datetime import datetime, timedelta, timezone
import pytz
import json

# =====================================================
# CONFIG
# =====================================================

PROJECT_ID = "tvc-ecommerce"
LOCATION = "us-central1"
DATASET = "analytics_live"

SCORING_TABLE = f"{PROJECT_ID}.{DATASET}.ga4_anomaly_scored_events"
CONTEXT_TABLE = f"{PROJECT_ID}.{DATASET}.ga4_anomaly_contextualized_events"
CAMPAIGN_TABLE = f"{PROJECT_ID}.{DATASET}.campaign_context"
NEWS_TABLE = f"{PROJECT_ID}.{DATASET}.news_context"

TIMEZONE = "Asia/Kolkata"

# =====================================================
# INITIALIZE GLOBAL CLIENTS
# =====================================================

print("Initializing BigQuery client...")
bq = bigquery.Client(project=PROJECT_ID)

print("Initializing Vertex AI...")
aiplatform.init(project=PROJECT_ID, location=LOCATION)

model = GenerativeModel("gemini-2.5-flash")

app = Flask(__name__)

# =====================================================
# LLM DECISION (DETERMINISTIC JSON)
# =====================================================

def llm_decision(event_name, deviation, severity, campaigns, news_items):

    context_text = ""

    for c in campaigns:
        desc = (c.description[:200] + "...") if c.description else ""
        context_text += f"Campaign: {c.campaign_name}. {desc}\n"

    for n in news_items:
        desc = (n.description[:200] + "...") if n.description else ""
        context_text += f"News: {n.headline}. {desc}\n"

    prompt = f"""
Return ONLY valid JSON.
No markdown.
No explanations.

Format:
{{"decision":"INFLUENCED"}}
OR
{{"decision":"NOT_INFLUENCED"}}

Event: {event_name}
Deviation: {deviation} percent
Severity: {severity}

Context:
{context_text}

Does this context plausibly explain the anomaly?
"""

    try:
        response = model.generate_content(
            prompt,
            generation_config={
                "temperature": 0,
                "max_output_tokens": 100
            }
        )

        if not response.candidates:
            return "NOT_INFLUENCED"

        candidate = response.candidates[0]

        if not candidate.content or not candidate.content.parts:
            return "NOT_INFLUENCED"

        raw = candidate.content.parts[0].text.strip()
        print(f"LLM RAW OUTPUT for {event_name}: {raw}")

        try:
            parsed = json.loads(raw)
            decision = parsed.get("decision", "NOT_INFLUENCED")
            return "INFLUENCED" if decision == "INFLUENCED" else "NOT_INFLUENCED"

        except json.JSONDecodeError:
            print("JSON parsing failed.")
            return "NOT_INFLUENCED"

    except Exception as e:
        print(f"LLM error: {e}")
        return "NOT_INFLUENCED"


# =====================================================
# CORE AGENT LOGIC
# =====================================================

def run_context_agent():

    tz = pytz.timezone(TIMEZONE)
    yesterday = (datetime.now(tz) - timedelta(days=1)).date()

    print(f"Processing anomalies for date: {yesterday}")

    # Fetch anomalies
    anomaly_query = f"""
    SELECT *
    FROM `{SCORING_TABLE}`
    WHERE event_date = @event_date
      AND is_anomaly = TRUE
    """

    job_config = bigquery.QueryJobConfig(
        query_parameters=[
            bigquery.ScalarQueryParameter("event_date", "DATE", yesterday)
        ]
    )

    anomalies = list(bq.query(anomaly_query, job_config=job_config))

    if not anomalies:
        return {"message": "No anomalies found."}

    print(f"Found {len(anomalies)} anomalies.")

    # Fetch context
    campaigns = list(bq.query(
        f"SELECT * FROM `{CAMPAIGN_TABLE}` WHERE campaign_date = @event_date",
        job_config=job_config
    ))

    news_items = list(bq.query(
        f"SELECT * FROM `{NEWS_TABLE}` WHERE news_date = @event_date",
        job_config=job_config
    ))

    print(f"Campaigns found: {len(campaigns)}")
    print(f"News found: {len(news_items)}")

    rows_to_insert = []

    for anomaly in anomalies:

        deviation = float(anomaly.deviation_pct)

        decision = llm_decision(
            anomaly.event_name,
            deviation,
            anomaly.severity_level,
            campaigns,
            news_items
        )

        context_override = decision == "INFLUENCED"

        source = "NONE"
        summary = None

        if context_override:
            if campaigns:
                source = "CAMPAIGN"
                summary = "Anomaly aligns with active campaign activity."
            elif news_items:
                source = "NEWS"
                summary = "Anomaly coincides with relevant external news."

        row_dict = {}

        for key, value in anomaly.items():
            if hasattr(value, "isoformat"):
                row_dict[key] = value.isoformat()
            else:
                row_dict[key] = value

        row_dict.update({
            "context_override": context_override,
            "context_source": source,
            "context_summary": summary,
            "context_decision_time": datetime.now(timezone.utc).isoformat()
        })

        rows_to_insert.append(row_dict)

    # BigQuery load job
    load_job = bq.load_table_from_json(
        rows_to_insert,
        CONTEXT_TABLE,
        job_config=bigquery.LoadJobConfig(
            write_disposition="WRITE_APPEND"
        )
    )

    load_job.result()

    print(f"Inserted {len(rows_to_insert)} rows.")

    return {
        "status": "success",
        "rows_inserted": len(rows_to_insert)
    }


# =====================================================
# ROUTES
# =====================================================

@app.route("/", methods=["GET"])
def health():
    return "GA4 Context Agent Running", 200


@app.route("/run", methods=["POST"])
def trigger():
    result = run_context_agent()
    return jsonify(result), 200


# =====================================================
# ENTRYPOINT
# =====================================================

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)