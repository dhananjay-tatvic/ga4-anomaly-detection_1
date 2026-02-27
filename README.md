```markdown
# GA4 Anomaly Detection Platform – Technical Documentation

This repository contains the complete implementation of a **production-grade, serverless, context-aware GA4 anomaly detection platform** built on:

- **Google BigQuery**
- **BigQuery ML (ARIMA_PLUS)**
- **Cloud Run + Gemini 2.5 Flash (LLM Intelligence Layer)**
- **Google Cloud Scheduler**
- **Google Apps Script**

The system evolves from a deterministic statistical anomaly detector (Phase 1) into a **configurable, context-aware anomaly intelligence platform (Phase 2)**.

---

## 📁 Repository Structure

```
ga4-anomaly-detection-solution/
│
├── README.md
├── LOGIC.md
│
├── Documentation/
│   ├── Project Charter.docx
│   ├── Project Completion Plan.pdf
│
├── codebase/
│   ├── synthetic_data/
│   │   ├── daily_data_generator.sql
│   │   ├── anomaly_injector.sql
│   │
│   ├── aggregation/
│   │   ├── loading_to_daily_metric.sql
│   │   ├── processing_gap_filling.sql
│   │
│   ├── modeling/
│   │   ├── calculating_statistical_metric.sql
│   │   ├── ARIMA_retrain_30_days.sql
│   │
│   ├── scoring/
│   │   ├── severity_business_logic.sql
│   │   ├── alert_decision.sql
│   │
│   ├── agent/
│   │   ├── Dockerfile
│   │   ├── ga4_context_agent.py
│   │   ├── context_agent_readonly.py
│   │   ├── create_email_view.sql
│   │   ├── requirements.txt
│   │
│   ├── config/
│   │   ├── create_config_table.sql
│   │
│   ├── context/
│   │   ├── marketing_context_refresh.sql
│   │
│   ├── app_script/
│   │   ├── Code.gs
│
├── assets/
│   └── email_snapshot.png
│
└── diagrams/
    ├── architecture.png
    └── workflow.png
```

---

## 🚀 System Overview

A fully serverless anomaly intelligence platform for GA4 e-commerce metrics that:

### Phase 1 – Deterministic Statistical Detection
- Generates synthetic GA4 events
- Aggregates daily metrics
- Forecasts using ARIMA_PLUS
- Detects anomalies (statistical + ML)
- Classifies severity & business impact
- Decides alert eligibility
- Sends automated email alerts

### Phase 2 – Context-Aware Intelligence
- Introduces config-driven monitoring
- Integrates campaign & news context
- Deploys LLM-based contextual validation
- Dynamically refines root cause narratives
- Preserves deterministic alert logic

---

## 🧱 Architecture

### High-Level Pipeline (Phase 1 + Phase 2)

```
Synthetic GA4 Events
↓
Daily Metric Aggregation
↓
Gap Filling
↓
ARIMA_PLUS Forecasting
↓
Anomaly Detection
↓
Severity & Business Impact Classification
↓
Context Agent (Cloud Run + Gemini)
↓
Alert Eligibility & Suppression
↓
Email Payload View
↓
Google Apps Script (Email Delivery)
```

---

## 📊 Data Layers

### Datasets

| Dataset                | Purpose                                  |
|------------------------|------------------------------------------|
| `GA4SampleData_live`   | Raw synthetic GA4 events                 |
| `analytics_live`       | Derived metrics, models, anomalies, decisions |

### Core Tables

| Table                                   | Description                               |
|-----------------------------------------|-------------------------------------------|
| `events_YYYYMMDD`                       | Synthetic GA4 daily events                |
| `ga4_event_metrics_daily`                | Aggregated daily metrics                  |
| `ga4_event_metrics_daily_filled`         | Gap-filled metrics                        |
| `ga4_anomaly_enriched_all_events`        | Forecast outputs                          |
| `ga4_anomaly_scored_events`              | Severity & impact classification          |
| `ga4_anomaly_contextualized_events`      | LLM-validated anomalies                   |
| `ga4_anomaly_alert_decisions`            | Alert eligibility                         |
| `ga4_anomaly_email_payload_view`         | Final email payload                       |

---

## ⚙️ Phase 1 – Statistical Anomaly Engine

### Synthetic Data
- Seasonality modeling
- Holiday multipliers
- Persistent user simulation
- Controlled anomaly injection

### Modeling
- ARIMA_PLUS per metric
- Retraining every 30 days
- Prediction intervals enabled

### Anomaly Detection
Dual signal framework:
1. Prediction interval breach
2. `ML.DETECT_ANOMALIES`

Metric-specific probability thresholds:
- `purchase`: 0.99
- `session_start`: 0.99
- `page_view`: 0.97

---

### Severity & Business Logic

- Decline-only logic for revenue metrics
- Bidirectional logic for traffic metrics
- Severity Levels: CRITICAL, HIGH, MEDIUM, LOW
- Business Impact: VERY_HIGH, HIGH, MEDIUM, LOW
- Root cause deviation-band stratification

(See `LOGIC.md` for full rule definitions.)

---

### Alert Decision Layer

Eligibility Rule:

```
is_anomaly = TRUE
AND severity IN ('HIGH','CRITICAL')
AND business_impact IN ('HIGH','VERY_HIGH')
```

Suppression:
- Repeated alerts suppressed
- CRITICAL alerts never suppressed

Priority:
- P0 → CRITICAL
- P1 → HIGH + HIGH impact

---

## 🧠 Phase 2 – Context-Aware Intelligence Layer

Phase 2 upgrades the system into a configurable, LLM-augmented anomaly intelligence platform.

---

### 1️⃣ Configuration-Driven Monitoring

Thresholds and monitored metrics are externalized.

#### Config Table

```sql
CREATE TABLE analytics_live.ga4_anomaly_config (
  event_name STRING,
  is_enabled BOOLEAN,
  anomaly_probability_threshold FLOAT64,
  medium_deviation_threshold FLOAT64,
  critical_deviation_threshold FLOAT64
);
```

**Benefits:**
- Zero-code threshold changes
- Business-controlled sensitivity
- Multi-client scalability

---

### 2️⃣ Marketing Context Layer

Campaign & news metadata refresh daily.

#### `marketing_context` Table

```sql
CREATE OR REPLACE TABLE analytics_live.marketing_context
PARTITION BY context_date
AS
SELECT
  DATE_SUB(CURRENT_DATE('Asia/Kolkata'), INTERVAL 1 DAY) AS context_date,
  'CAMPAIGN' AS context_type,
  campaign_name AS title,
  description
FROM campaign_context_base
UNION ALL
SELECT
  DATE_SUB(CURRENT_DATE('Asia/Kolkata'), INTERVAL 1 DAY),
  'NEWS',
  headline,
  description
FROM news_context_base;
```

Scheduled at **08:30 UTC**.

---

### 3️⃣ Cloud Run Context Agent

#### Purpose
Determines whether anomaly is:
- `INFLUENCED`
- `NOT_INFLUENCED`

Based on marketing/news context.

#### Runtime Stack
- Python 3.11
- Flask
- Vertex AI SDK
- Gemini 2.5 Flash
- BigQuery Client

#### LLM Prompt Format
```
Return ONLY valid JSON.
{"decision": "INFLUENCED"}
OR
{"decision": "NOT_INFLUENCED"}
```

#### Deployment
```bash
gcloud run deploy ga4-context-agent \
  --image gcr.io/tvc-ecommerce/ga4-context-agent \
  --region us-central1 \
  --platform managed \
  --allow-unauthenticated \
  --memory 1Gi \
  --timeout 900
```

#### Scheduler Trigger
```bash
gcloud scheduler jobs create http ga4-context-agent-job \
  --schedule="0 21 * * *" \
  --uri="https://<service-url>/run" \
  --http-method=POST \
  --time-zone="UTC"
```

Runs daily at **21:00 UTC** (02:30 IST).

---

### 4️⃣ Contextualized Output

**Table:** `ga4_anomaly_contextualized_events`

Adds:
- `context_override`
- `context_source`
- `context_summary`
- `context_decision_time`

Email payload dynamically adjusts root cause if `context_override = TRUE`.

---

## 🕒 Scheduling

### Execution Timeline (UTC)

| Time   | Stage                   |
|--------|-------------------------|
| 08:30  | Marketing Context Refresh |
| 19:00  | Synthetic Generator     |
| 19:10  | Anomaly Injector        |
| 20:30  | Aggregation             |
| 20:35  | Gap Filling             |
| 20:45  | Anomaly Detection       |
| 20:50  | Severity Logic          |
| 20:55  | Alert Decision          |
| 21:00  | Context Agent           |
| 21:05  | Email Delivery          |

---

## 📧 Email Delivery

- Logic-free Apps Script
- One email per metric
- Uses `ga4_anomaly_email_payload_view`
- Exactly-once semantics

---

## 🛡️ Production-Grade Guarantees

- Idempotent daily processing
- Deterministic outputs
- IST-safe date handling
- Serverless architecture
- Strict separation of concerns
- Replay-safe
- Config-driven extensibility
- LLM isolated from alert eligibility

---

## 🔮 Strategic Direction

The platform evolves from:

1. **Deterministic anomaly detection**
2. **Configurable monitoring**
3. **Context-aware intelligence**
4. **LLM-augmented analytics reasoning**

Without redesigning core architecture.

---

## 👥 Maintainers

- Dhananjay Kanjariya  
- Ronit Rajput  
- Aarya Samaiya  
- Vishnu Nair  

---

## 📄 License

**Proprietary** – Tatvic Analytics Private Limited.

---

> If you'd like next, I can:
> • Add a professional GitHub badges section  
> • Add a Phase 2 architecture diagram block for README  
> • Generate a System Design Doc (SDD)  
> • Create a `deploy.md` guide  
> • Create investor/demo pitch version  
> • Convert this into a whitepaper  
> 
> Tell me the next target 🚀
```
