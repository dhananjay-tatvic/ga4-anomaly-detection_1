# GA4 Anomaly Detection Platform

A production-grade analytics platform that proactively detects, classifies, and explains anomalies in Google Analytics 4 (GA4) data using native BigQuery ML (ARIMA_PLUS) and deterministic business intelligence logic.

---

## 🚀 Overview

Organizations rely heavily on GA4 for revenue, conversion, and engagement insights. However, GA4 data quality issues, tracking failures, and sudden metric drops often go unnoticed until significant business impact occurs.

This platform shifts analytics teams from **reactive investigation** to **proactive monitoring** by:

- Forecasting expected GA4 behavior using time-series models
- Detecting statistically significant anomalies
- Translating anomalies into **actionable business incidents**
- Delivering explainable alerts via Slack / Email / Webhooks

---

## 🎯 Objectives

- Detect high-severity anomalies with ≥ **90% accuracy**
- Reduce manual GA4 investigation time by **75%**
- Minimize false positives through deterministic severity and suppression logic
- Provide **business-contextual alerts**, not raw statistical noise

---

## 🧠 Core Capabilities

### 1. Data Ingestion
- **P0 (Primary)**: GA4 BigQuery Export (event-level)
- **P1 (Fallback)**: GA4 Data API → BigQuery (aggregated)

### 2. Canonical Time-Series Construction
- Metric normalization into a single canonical schema
- Gap filling and temporal continuity enforcement
- Timezone normalization per GA4 property

### 3. Forecasting & Anomaly Detection
- One ARIMA_PLUS model per:
  - Client
  - GA4 Property
  - Metric
  - Granularity
- Native BigQuery ML execution
- Seasonality, trend, and variance decomposition

### 4. Business Intelligence Layer
- Deterministic severity classification
- Business impact scoring
- Root-cause inference using cross-metric reasoning
- Alert eligibility and suppression logic

### 5. Alerting & Notifications
- Slack, Email, and Webhook delivery
- Human-readable incident narratives
- Repetition control and business-hours awareness

---

## 🏗️ Architecture Overview

GA4 (BQ Export / API)
↓
Raw & Staging Tables
↓
Prepared Canonical Metrics (Gap-Free)
↓
BigQuery ML (ARIMA_PLUS)
↓
Anomaly Detection
↓
Severity & Business Impact Scoring
↓
Root-Cause Inference
↓
Alerting & Incident Narratives


---

## 📂 Repository Structure

ga4-anomaly-detection/
│
├── configs/ # Client, metric, threshold configuration
├── sql/
│ ├── raw/ # GA4 extraction logic
│ ├── staging/ # Normalization & cleaning
│ ├── prepared/ # Canonical time-series construction
│ ├── ml/ # ARIMA_PLUS training & detection
│ └── intelligence/ # Severity, impact, RCA logic
│
├── src/
│ ├── ingestion/ # GA4 API / BQ ingestion
│ ├── orchestration/ # Scheduling & execution control
│ ├── alerting/ # Slack, Email, Webhook clients
│ └── utils/ # Shared helpers
│
├── docs/ # Architecture, data model, runbooks
├── tests/ # Unit & integration tests
├── infra/ # BigQuery, Cloud Functions, Pub/Sub
├── .github/workflows/ # CI pipelines
│
├── README.md
├── LICENSE
└── .gitignore


---

## 🧩 Canonical Data Model

### `prepared_ga4_table`

| Column | Description |
|------|------------|
| client_id | Logical client identifier |
| ga4_property_id | GA4 property |
| timestamp | Business-date (normalized) |
| metric_name | sessions / revenue / conversions |
| metric_value | Metric value |
| granularity | DAILY / HOURLY |
| data_source | GA4_BQ / GA4_API |

This table is the **single source of truth** for all ML and intelligence logic.

---

## 📊 Anomaly Detection Logic

### Model
- **ARIMA_PLUS (BigQuery ML)**
- Deterministic, explainable, and seasonality-aware

### Detection Criteria
A data point is anomalous if:
- It lies outside the forecast confidence interval
- The anomaly probability exceeds the metric-specific threshold

---

## 🚨 Severity Classification

Severity is derived from deviation magnitude and anomaly type:

| Deviation | Severity |
|---------|----------|
| < 10% | LOW |
| 10–30% | MEDIUM |
| 30–60% | HIGH |
| ≥ 60% or Flatline | CRITICAL |

Additional escalation rules:
- Revenue anomalies ≥ MEDIUM
- Flatline on any core metric → CRITICAL
- Consecutive anomalies escalate severity

---

## 💼 Business Impact Scoring

Severity ≠ Business Impact.

Business impact considers:
- Metric type (Revenue, Conversions, Sessions)
- Duration
- Industry sensitivity
- Magnitude of loss

This prevents alert fatigue while ensuring revenue risks are never missed.

---

## 🔍 Root-Cause Inference

The system infers causes using deterministic rules:

| Observed Pattern | Likely Cause |
|-----------------|------------|
| Revenue ↓, Sessions stable | Checkout failure |
| All metrics = 0 | Tracking break |
| Sessions ↓, Revenue ↓ | Traffic source loss |
| Spike across metrics | Bot / duplicate firing |

Each incident includes:
- Suspected root cause
- Confidence level
- Supporting signals

---

## 📨 Alerting Philosophy

Only **operational incidents** generate alerts.

Alert eligibility requires:
- Statistical anomaly
- Severity ≥ MEDIUM
- Business impact ≥ MEDIUM
- Not suppressed by context

Alerts include:
- What happened
- Where it happened
- How bad it is
- What to do next

---

## 🔐 Configuration-Driven Design

All behavior is controlled via configuration tables:
- Clients
- Metrics
- Thresholds
- Business hours
- Alert channels

No client-specific logic is hardcoded.

---

## 🛠️ Tech Stack

- **Google BigQuery**
- **BigQuery ML (ARIMA_PLUS)**
- **GA4 BigQuery Export**
- **GA4 Data API**
- **Python (Cloud Functions)**
- **Slack / Email / Webhooks**

---

## 🧪 Testing & Validation

- SQL logic validation
- Severity and impact unit tests
- Alert payload schema tests
- GA4 UI vs system metric validation

---

## 📈 Success Metrics

- ≥ 90% anomaly detection accuracy
- < 10% false positive rate
- 100% acknowledgment of critical alerts
- ≥ 75% reduction in manual investigation time

---

## 📜 License

This project is licensed under the MIT License.

---

## 👥 Contributors

- **Ronit Rajput** – Lead Data Scientist & Platform Owner  
- **Vishnu Nair** – Business Intelligence & Severity Logic  
- **Aarya Samaiya** – GA4 Ingestion & Schema Mapping  
- **Dhananjay Kanjariya** – BigQuery Automation & Alerting  

---

## 🧠 Final Note

This platform is designed as an **operational analytics system**, not a research prototype.  
It prioritizes determinism, explainability, and business trust over experimental complexity.
