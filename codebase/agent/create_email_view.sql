CREATE OR REPLACE VIEW `tvc-ecommerce.analytics_live.ga4_anomaly_email_payload_view` AS
SELECT

'dhananjay@tatvic.com' AS email_from,
'ronit@tatvic.com' AS email_to,
['aarya@tatvic.com','vishnu@tatvic.com'] AS email_cc,

'tvc-ecommerce' AS client_id,
'GA4-Ecommerce-Prod' AS ga4_property_id,
c.event_name AS metric_name,
'Ecommerce' AS industry,
c.event_date AS alert_date,
'Asia/Kolkata' AS timezone,

c.actual_value,
c.expected_value,
c.lower_bound,
c.upper_bound,
c.deviation_pct,

c.severity_level,
c.business_impact,
c.anomaly_probability AS anomaly_score,

CASE
  WHEN c.context_override = TRUE
       AND c.context_summary IS NOT NULL
  THEN c.context_summary
  ELSE c.suspected_root_cause
END AS suspected_root_cause,

c.recommended_actions,

a.alert_eligible,
a.suppressed,
a.alert_priority,
a.repeated_alert,
a.decision_timestamp

FROM `tvc-ecommerce.analytics_live.ga4_anomaly_alert_decisions` a
JOIN `tvc-ecommerce.analytics_live.ga4_anomaly_contextualized_events` c
USING (event_date, event_name)

WHERE
a.alert_eligible = TRUE
AND a.suppressed = FALSE;   