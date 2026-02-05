function runGA4AnomalyEmailPipeline() {
  const projectId = 'tvc-ecommerce';
  const datasetId = 'analytics_live';
  const viewId = 'ga4_anomaly_email_payload_view';

  /* =====================================================
     STEP 1: FETCH FINAL PAYLOAD (NO VIEW CREATION HERE)
     ===================================================== */
  const fetchQuery = `
    SELECT
      client_id,
      ga4_property_id,
      metric_name,
      industry,
      alert_date,
      timezone,

      actual_value,
      expected_value,
      lower_bound,
      upper_bound,
      deviation_pct,

      severity_level,
      business_impact,

      suspected_root_cause,
      recommended_actions
    FROM \`${projectId}.${datasetId}.${viewId}\`
  `;

  const result = BigQuery.Jobs.query(
    { query: fetchQuery, useLegacySql: false },
    projectId
  );

  if (!result.rows || result.rows.length === 0) {
    Logger.log('No alerts to send today.');
    return;
  }

  /* =====================================================
     STEP 2: SEND EMAILS
     ===================================================== */
  result.rows.forEach(row => {
    const f = row.f;
    const v = i => f[i].v;

    /* ---------- Numeric formatting ---------- */
    const actual = Number(v(6)).toFixed(2);
    const expected = Number(v(7)).toFixed(2);
    const lower = Number(v(8)).toFixed(2);
    const upper = Number(v(9)).toFixed(2);

    // Assuming deviation_pct is already a percentage (like -15.63, not -0.1563)
    const deviationPct = Number(v(10));
    const deviationFormatted =
      (deviationPct > 0 ? '+' : '') + deviationPct.toFixed(2) + '%';

    /* ---------- Subject ---------- */
    const subject = `[${v(11)} | ${v(12)}] GA4 Anomaly Alert – ${v(2)}`;

    /* ---------- Recommended actions ---------- */
    let actionsHtml = '<li>No immediate action required</li>';
    if (v(14) && Array.isArray(v(14))) {
      const recommendedActions = v(14);
      if (recommendedActions.length >= 2) {
        actionsHtml = `<li>${recommendedActions[0].v}</li><li>${recommendedActions[1].v}</li>`;
      } else if (recommendedActions.length === 1 && recommendedActions[0].v) {
        actionsHtml = `<li>${recommendedActions[0].v}</li>`;
      }
    }

    /* ---------- Root cause ---------- */
    const rootCause = v(13) || 'No specific root cause identified yet.';

    /* =====================================================
       HTML EMAIL (PRESENTATION READY)
       ===================================================== */
    const htmlBody = `
      <div style="font-family: Arial, sans-serif; color:#222;">
        <h2 style="color:#c62828;">GA4 Anomaly Alert</h2>

        <table width="100%" border="1" cellpadding="8" cellspacing="0"
               style="border-collapse:collapse;">
          <tr><td><b>Client</b></td><td>${v(0)}</td></tr>
          <tr><td><b>GA4 Property</b></td><td>${v(1)}</td></tr>
          <tr><td><b>Metric</b></td><td>${v(2)}</td></tr>
          <tr><td><b>Industry</b></td><td>${v(3)}</td></tr>
          <tr><td><b>Date</b></td><td>${v(4)} (${v(5)})</td></tr>
          <tr><td><b>Severity</b></td><td><b>${v(11)}</b></td></tr>
          <tr><td><b>Business Impact</b></td><td><b>${v(12)}</b></td></tr>
        </table>

        <br/>

        <h3>Observed vs Expected</h3>
        <table width="100%" border="1" cellpadding="8" cellspacing="0"
               style="border-collapse:collapse;">
          <tr>
            <th>Actual</th>
            <th>Expected</th>
            <th>Expected Range</th>
            <th>Deviation</th>
          </tr>
          <tr>
            <td>${actual}</td>
            <td>${expected}</td>
            <td>${lower} – ${upper}</td>
            <td>${deviationFormatted}</td>
          </tr>
        </table>

        <br/>

        <h3>Suspected Root Cause</h3>
        <p>${rootCause}</p>

        <h3>Recommended Immediate Actions</h3>
        <ul>
          ${actionsHtml}
        </ul>

        <hr/>

        <p style="font-size:12px;color:#666;">
          This alert was generated automatically by the
          <b>Tatvic GA4 Anomaly Detection Platform</b>.
          The system will continue monitoring subsequent data points.
        </p>
      </div>
    `;

    GmailApp.sendEmail(
  'ronit@tatvic.com, aarya@tatvic.com, vishnu@tatvic.com',
  subject,
  '',
  { htmlBody }
);
  });

  Logger.log(`GA4 anomaly email pipeline completed. Sent ${result.rows.length} alerts.`);
}
