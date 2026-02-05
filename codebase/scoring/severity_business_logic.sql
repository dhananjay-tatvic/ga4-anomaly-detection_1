CREATE OR REPLACE TABLE
`tvc-ecommerce.analytics_live.ga4_anomaly_scored_events`
PARTITION BY event_date
AS
SELECT
 event_date,
 event_name,
 actual_value,
 expected_value,
 lower_bound,
 upper_bound,
 deviation_pct,
 anomaly_probability,
 z_score,
 bound_distance,
 is_outside_bounds,
 is_anomaly,


 /* =====================================================
    SEVERITY CLASSIFICATION
    ===================================================== */
 CASE
   -- Hard gate
   WHEN is_anomaly = FALSE OR is_outside_bounds = FALSE THEN 'NONE'


  -- PURCHASE (Negative only)
   WHEN event_name = 'purchase'
     AND deviation_pct < 0
     AND (deviation_pct <= -0.60 OR z_score <= -3.5)
     THEN 'CRITICAL'


   -- ADD_TO_CART (Negative only per requirement)
   WHEN event_name = 'add_to_cart'
     AND deviation_pct < 0
     AND (deviation_pct <= -0.80 OR z_score <= -8.0)
     THEN 'CRITICAL'


   -- ADD_PAYMENT_INFO (Negative only per requirement)
   WHEN event_name = 'add_payment_info'
     AND deviation_pct < 0
     AND (deviation_pct <= -0.60 OR z_score <= -5.0)
     THEN 'CRITICAL'


   -- PAGE_VIEW (Both positive and negative)
   WHEN event_name = 'page_view'
     AND (
       -- Negative: severe traffic decline
       (deviation_pct < 0 AND (deviation_pct <= -0.50 OR z_score <= -5.5))
       OR
       -- Positive: unusual traffic spike
       (deviation_pct > 0 AND (deviation_pct >= 0.60 OR z_score >= 5.5))
     )
     THEN 'CRITICAL'


   -- SESSION_START (Both positive and negative)
   WHEN event_name = 'session_start'
     AND (
       -- Negative: severe session decline
       (deviation_pct < 0 AND (deviation_pct <= -0.45 OR z_score <= -6.5))
       OR
       -- Positive: unusual session spike
       (deviation_pct > 0 AND (deviation_pct >= 0.55 OR z_score >= 6.5))
     )
     THEN 'CRITICAL'


   -- USER_ENGAGEMENT (Both positive and negative)
   WHEN event_name = 'user_engagement'
     AND (
       -- Negative: severe engagement decline
       (deviation_pct < 0 AND (deviation_pct <= -0.60 OR z_score <= -4.0))
       OR
       -- Positive: unusual engagement spike
       (deviation_pct > 0 AND (deviation_pct >= 0.70 OR z_score >= 4.0))
     )
     THEN 'CRITICAL'




   /* ===== HIGH SEVERITY ===== */
 
   -- PURCHASE (Negative only)
   WHEN event_name = 'purchase'
     AND deviation_pct < 0
     AND (deviation_pct <= -0.30 OR z_score <= -2.0)
     THEN 'HIGH'


   -- ADD_TO_CART (Negative only)
   WHEN event_name = 'add_to_cart'
     AND deviation_pct < 0
     AND (deviation_pct <= -0.40 OR z_score <= -4.0)
     THEN 'HIGH'


   -- ADD_PAYMENT_INFO (Negative only)
   WHEN event_name = 'add_payment_info'
     AND deviation_pct < 0
     AND (deviation_pct <= -0.40 OR z_score <= -3.5)
     THEN 'HIGH'


   -- PAGE_VIEW (Both positive and negative)
   WHEN event_name = 'page_view'
     AND (
       (deviation_pct < 0 AND (deviation_pct <= -0.35 OR z_score <= -4.0))
       OR
       (deviation_pct > 0 AND (deviation_pct >= 0.45 OR z_score >= 4.0))
     )
     THEN 'HIGH'


   -- SESSION_START (Both positive and negative)
   WHEN event_name = 'session_start'
     AND (
       (deviation_pct < 0 AND (deviation_pct <= -0.25 OR z_score <= -4.0))
       OR
       (deviation_pct > 0 AND (deviation_pct >= 0.35 OR z_score >= 4.0))
     )
     THEN 'HIGH'


   -- USER_ENGAGEMENT (Both positive and negative)
   WHEN event_name = 'user_engagement'
     AND (
       (deviation_pct < 0 AND (deviation_pct <= -0.35 OR z_score <= -3.5))
       OR
       (deviation_pct > 0 AND (deviation_pct >= 0.45 OR z_score >= 3.5))
     )
     THEN 'HIGH'


   /* ===== MEDIUM SEVERITY ===== */
   WHEN (
     ABS(deviation_pct) BETWEEN 0.10 AND 0.30
     OR (anomaly_probability >= 0.85 OR ABS(z_score) >= 1.5)
   ) THEN 'MEDIUM'


   /* ===== LOW SEVERITY ===== */
   ELSE 'LOW'
 END AS severity_level,


 /* =====================================================
    BUSINESS IMPACT
    Modified: AND → OR conditions
    ===================================================== */
 CASE
   WHEN is_anomaly = FALSE THEN 'LOW'
 
   -- PURCHASE (highest impact - revenue)
   WHEN event_name = 'purchase'
     AND deviation_pct < 0
     AND (deviation_pct <= -0.60 OR z_score <= -3.5)
     THEN 'VERY_HIGH'
 
   WHEN event_name = 'purchase' THEN 'HIGH'


   -- Bottom-funnel (negative only per requirement)
   WHEN event_name IN ('add_to_cart','add_payment_info')
     AND deviation_pct < 0
     AND (deviation_pct <= -0.30 OR z_score <= -3.0)
     THEN 'HIGH'


   -- Top/Mid-funnel (both positive and negative)
   WHEN event_name IN ('page_view','session_start')
     AND (ABS(deviation_pct) >= 0.30 OR ABS(z_score) >= 3.0)
     THEN 'MEDIUM'


   WHEN event_name = 'user_engagement'
     AND (ABS(deviation_pct) >= 0.30 OR ABS(z_score) >= 3.0)
     THEN 'MEDIUM'


   ELSE 'LOW'
 END AS business_impact,




 /* =====================================================
    ROOT CAUSE IDENTIFICATION (HUMAN FRIENDLY)
    ===================================================== */


CASE
   /* ================= PURCHASE - NEGATIVE ONLY ================= */


   WHEN event_name = 'purchase'
     AND deviation_pct < 0
     AND deviation_pct <= -0.90
     THEN 'A sustained revenue drop 90% below expected typically indicates partial platform-level failures rather than total system collapse. In real ecommerce environments, this often manifests as regional payment gateway failures, currency conversion bugs, or checkout flow breakage on specific browsers or devices (commonly mobile Safari or Android WebView). Another common cause is fraud-prevention overblocking, where newly deployed risk rules incorrectly flag legitimate transactions, causing mass declines while traffic remains stable. In multi-region stores, this deviation band frequently correlates with geo-specific outages rather than global failures.'


  
   WHEN event_name = 'purchase'
     AND deviation_pct < 0
     AND deviation_pct > -0.90
     AND deviation_pct <= -0.60
     THEN 'Revenue declines in the 60% to 90% range are commonly associated with high-friction checkout degradation rather than outright outages. Customers reach checkout but abandon due to late-stage blockers such as unexpected shipping charges, tax miscalculations, broken discount logic, forced account creation, or payment UI changes that reduce trust. This pattern is also observed when fraud detection thresholds are tightened without adequate monitoring, causing a sudden surge in legitimate transaction rejections. Unlike full outages, some transactions still succeed, but the majority fail at the final step.'




   WHEN event_name = 'purchase'
     AND deviation_pct < 0
     AND deviation_pct > -0.60
     AND deviation_pct <= -0.45
     THEN 'Revenue drops in this range usually reflect demand-quality or campaign misalignment issues rather than core platform failures. Paid traffic may continue to arrive, but users do not convert due to mismatched messaging, broken landing pages, incorrect pricing promises, or targeting drift. This deviation band often appears when promotional campaigns drive volume without purchase intent, or when landing pages fail to match ad copy, leading to early checkout exits.'




   WHEN event_name = 'purchase'
     AND deviation_pct < 0
     AND deviation_pct > -0.45
     AND deviation_pct <= -0.30
     THEN 'This deviation range typically represents early-stage revenue degradation, often caused by subtle UX or performance issues rather than explicit failures. Common drivers include increased page load times, mobile usability regressions, trust signal removal (security badges, payment logos), or delivery promise changes that discourage completion. While not immediately catastrophic, persistence in this band often precedes deeper funnel collapse if unaddressed.'


   /* ================= ADD_TO_CART - NEGATIVE ONLY ================= */

   WHEN event_name = 'add_to_cart'
     AND deviation_pct < 0
     AND deviation_pct <= -0.80
     THEN 'Drops below 80% usually indicate behavioral deterrents rather than hard failures. Users can technically add items to the cart, but choose not to due to sudden friction introduced at the product evaluation stage.Common causes include unexpected price increases, incorrect discount application, shipping fee visibility changes, broken product images, or misleading availability indicators (Only 1 left logic misfiring). In many cases, recent merchandising changes unintentionally degrade trust at the PDP level.'


   WHEN event_name = 'add_to_cart'
     AND deviation_pct < 0
     AND deviation_pct > -0.80
     AND deviation_pct <= -0.60
     THEN 'This deviation band typically reflects traffic quality degradation, where users arrive at product pages but lack genuine purchase intent. This often correlates with campaign misconfiguration—broad targeting, irrelevant keywords, or upper-funnel campaigns driving curiosity clicks rather than shopping intent. Unlike CRITICAL scenarios, cart functionality remains intact, but user motivation is weak.'


   WHEN event_name = 'add_to_cart'
     AND deviation_pct < 0
     AND deviation_pct > -0.60
     AND deviation_pct <= -0.40
     THEN 'A moderate decline in this range often represents early funnel softening, commonly driven by subtle UX regressions or market factors rather than structural issues. Examples include slower page load times, degraded mobile performance, reduced promotional urgency, or competitor pricing pressure. While not immediately catastrophic, persistence here is a leading indicator of downstream purchase decline.'
  


   /* ================= ADD_PAYMENT_INFO - NEGATIVE ONLY ================= */

   WHEN event_name = 'add_payment_info'
     AND deviation_pct < 0
     AND deviation_pct <= -0.90
     THEN 'Drops below 90% typically indicate partial payment step failure, where only certain users, devices, or payment methods are affected. This commonly occurs when mobile checkout flows break independently of desktop, or when specific payment methods (UPI, wallets, BNPL) silently fail. Another major contributor in this range is trust erosion caused by unexpected changes at checkout—such as sudden shipping fee additions, tax recalculations, forced account creation, or security warnings (mixed content, expired SSL chains). These do not technically block payment entry but cause users to abandon before submitting payment information.'


   WHEN event_name = 'add_payment_info'
     AND deviation_pct < 0
     AND deviation_pct > -0.90
     AND deviation_pct <= -0.60
     THEN 'This deviation band indicates checkout usability degradation rather than outright failure. Users reach the payment step but abandon due to friction, complexity, or cognitive overload. Common drivers include overly long checkout forms, auto-focus bugs that prevent input on mobile keyboards, poorly handled error states (e.g., “Something went wrong” without resolution), or accessibility regressions that disproportionately affect certain user segments.'


   WHEN event_name = 'add_payment_info'
     AND deviation_pct < 0
     AND deviation_pct > -0.60
     AND deviation_pct <= -0.40
     THEN 'Moderate declines in this band typically reflect behavioral hesitation rather than technical failure. Users reach payment but delay or abandon due to price sensitivity, low urgency, or external comparison behavior (e.g., checking competitors before completing payment). This is often observed during non-promotional periods, post-campaign cooldowns, or when shipping timelines lengthen unexpectedly.'


   /* ================= PAGE_VIEW - BOTH POSITIVE AND NEGATIVE ================= */
  
   WHEN event_name = 'page_view'
     AND deviation_pct < 0
     AND deviation_pct <= -0.75
     THEN 'A collapse exceeding 75% below forecast in page views indicates a severe upstream traffic acquisition or tracking failure, not a demand-side issue. At this magnitude, users are either not reaching the site at all or reaching it without being tracked. The most common real-world cause is analytics instrumentation failure following a frontend deployment. Examples include the GA4 configuration tag being removed from newly deployed templates, GTM containers failing to load due to CSP misconfiguration, or consent mode misfires that block analytics entirely in certain regions. Another frequent cause is sudden traffic source shutdown, such as paused Google Ads or Meta campaigns, revoked ad accounts, exhausted daily budgets, or broken destination URLs returning 404/500 errors—causing platforms to silently stop sending traffic.'


   WHEN event_name = 'page_view'
     AND deviation_pct < 0
     AND deviation_pct > -0.75
     AND deviation_pct <= -0.50
     THEN 'Drops in the 50–75% range typically indicate partial traffic loss or selective tracking failure rather than a total outage. This often occurs when one or two major channels fail, while others continue normally. Common causes include organic search ranking collapses due to SEO misconfigurations (robots.txt blocking, noindex tags, canonical errors), region-specific consent enforcement blocking GA4 in GDPR geographies, or CDN/firewall rules blocking traffic from certain countries or user agents.'


   WHEN event_name = 'page_view'
     AND deviation_pct < 0
     AND deviation_pct > -0.50
     AND deviation_pct <= -0.35
     THEN 'This deviation band represents significant but non-catastrophic traffic degradation, usually driven by marketing or discoverability changes rather than hard failures. Typical drivers include paused remarketing campaigns, reduced bids on high-performing keywords, content removals affecting SEO landing pages, or broken internal links that reduce crawl depth and user flow.'


   WHEN event_name = 'page_view'
     AND deviation_pct > 0
     AND deviation_pct >= 0.90
     THEN 'An extreme positive spike (>90%) in page views is rarely organic. In ecommerce environments, this typically signals artificial traffic inflation rather than genuine user growth. Common causes include bot traffic (scrapers, crawlers, competitor price monitors), DDoS-style low-level floods, or misconfigured internal systems repeatedly hitting pages (e.g., uptime monitors, QA automation running in production). Another frequent cause is duplicate page_view firing, where SPA route changes or reload loops trigger multiple page_view events per single user action.'


   WHEN event_name = 'page_view'
     AND deviation_pct > 0
     AND deviation_pct < 0.90
     AND deviation_pct >= 0.60
     THEN 'This range often represents coordinated but explainable traffic surges—such as flash sales, influencer campaigns, or viral content—if supported by marketing context. If no campaigns exist, the surge may still reflect crawler or referral spam traffic.'
  
   WHEN event_name = 'page_view'
     AND deviation_pct > 0
     AND deviation_pct < 0.60
     AND deviation_pct >= 0.45
     THEN 'Moderate positive deviations usually indicate healthy traffic growth, seasonal uplift, or short-term promotional impact. However, they may also represent early-stage bot activity if engagement metrics fail to rise proportionally.'


   /* ================= SESSION_START - BOTH POSITIVE AND NEGATIVE ================= */
 
   WHEN event_name = 'session_start'
     AND deviation_pct < 0
     AND deviation_pct <= -0.75
     THEN 'A drop greater than 75% in session_start events indicates a systemic failure in session initialization, where users may still be landing on the site but GA4 is unable to establish sessions. The most frequent real-world cause is Consent Management Platform (CMP) misconfiguration after regulatory or UX changes. In such cases, analytics cookies are blocked entirely until explicit consent, and GA4 is not operating in Consent Mode v2 “denied” state—resulting in zero or near-zero session creation. Another common cause is redirect-heavy landing flows, such as geo-based redirects, login redirects, or campaign URL rewrites that strip GA4 session parameters (_ga, gclid, utm_*), causing sessions to fail initialization repeatedly.'


   WHEN event_name = 'session_start'
     AND deviation_pct < 0
     AND deviation_pct > -0.75
     AND deviation_pct <= -0.45
     THEN 'This range typically indicates partial session suppression, where sessions initialize for some users but fail for others. Common causes include device-specific issues (mobile-only failures due to JS execution timing), browser-specific restrictions (Safari ITP aggressively expiring cookies), or conditional GTM triggers that fire session_start only when specific DOM elements exist—which may have been removed in recent UI updates.'


   WHEN event_name = 'session_start'
     AND deviation_pct < 0
     AND deviation_pct > -0.45
     AND deviation_pct <= -0.25
     THEN 'Moderate session declines usually reflect changes in attribution or entry behavior, not outright failures. This often happens when marketing teams modify UTM structures, switch to server-side tagging without full validation, or shorten session timeout windows—causing sessions to merge unexpectedly and reduce session_start counts even though users are present.'


   WHEN event_name = 'session_start'
     AND deviation_pct > 0
     AND deviation_pct >= 0.80
     THEN 'A surge exceeding 80% in session_start is a strong indicator of session fragmentation, not real traffic growth. This typically occurs when session IDs reset repeatedly due to cookie persistence failures—often caused by SameSite cookie attribute misconfigurations, cross-domain navigation without linker parameters, or broken consent logic resetting cookies on every page load.'


   WHEN event_name = 'session_start'
     AND deviation_pct > 0
     AND deviation_pct < 0.80
     AND deviation_pct >= 0.55
     THEN 'This deviation band often reflects mid-level session inflation, commonly caused by SPA routing issues or misfiring session_start events. In React/Vue applications, incorrect lifecycle hooks may fire session_start on route changes rather than true session boundaries, artificially inflating session counts without corresponding user growth.'
  
   WHEN event_name = 'session_start'
     AND deviation_pct > 0
     AND deviation_pct < 0.55
     AND deviation_pct >= 0.35
     THEN 'Moderate positive session increases can represent legitimate re-engagement (email campaigns, retargeting) or early signs of session fragmentation. The distinction depends on downstream engagement health.'


   /* ================= USER_ENGAGEMENT - BOTH POSITIVE AND NEGATIVE ================= */
 
   WHEN event_name = 'user_engagement'
     AND deviation_pct < 0
     AND deviation_pct <= -0.85
     THEN 'A collapse greater than 85% in user_engagement indicates that users are reaching the site but failing to interact meaningfully. This almost never represents demand loss and instead signals severe experience degradation. The most common cause is critical performance failure, where pages technically load but become interactive too late. Core Web Vitals regressions—especially Largest Contentful Paint (LCP > 4s) or Cumulative Layout Shift (CLS > 0.25)—cause users to abandon before any engagement event can fire. Another frequent cause is broken engagement instrumentation, where the engagement_time_msec parameter stops incrementing due to JavaScript execution errors, consent misfires, or incorrect GA4 config placement below blocking scripts.'


   WHEN event_name = 'user_engagement'
     AND deviation_pct < 0
     AND deviation_pct > -0.85
     AND deviation_pct <= -0.60
     THEN 'This range reflects partial engagement suppression, where only certain user segments lose interaction capability. Typical real-world causes include mobile-specific layout failures, where CTA buttons, scroll containers, or navigation elements become inaccessible due to CSS overlap or viewport miscalculations. Another frequent trigger is cookie banner or modal overlays that block interaction while still allowing page views.'


   WHEN event_name = 'user_engagement'
     AND deviation_pct < 0
     AND deviation_pct > -0.60
     AND deviation_pct <= -0.35
     THEN 'Moderate engagement drops often indicate content relevance or layout hierarchy issues rather than technical failure. This frequently follows template redesigns, where key content is pushed below the fold, CTA prominence is reduced, or informational density is diluted. Users still arrive but disengage quickly.'


   WHEN event_name = 'user_engagement'
     AND deviation_pct > 0
     AND deviation_pct >= 0.90
     THEN 'An engagement surge above 90% is rarely organic. It usually indicates artificial engagement inflation. Common causes include bot traffic executing JavaScript, automated QA or load-testing tools interacting with pages, or SPA misconfiguration where engagement timers reset or accumulate incorrectly on route changes.'


   WHEN event_name = 'user_engagement'
     AND deviation_pct > 0
     AND deviation_pct < 0.90
     AND deviation_pct >= 0.70
     THEN 'This band often reflects misfiring engagement timers rather than true interaction uplift. In many GA4 implementations, engagement_time_msec can accumulate if page visibility APIs are misused or if tabs left open in background continue registering active time.'
  
   WHEN event_name = 'user_engagement'
     AND deviation_pct > 0
     AND deviation_pct < 0.70
     AND deviation_pct >= 0.45
     THEN 'This can represent legitimate content success (viral blog, campaign landing page) or early-stage inflation. Differentiation depends on downstream funnel behavior.'


   ELSE 'No dominant root cause identified'
 END AS suspected_root_cause,


 /* =====================================================
    RECOMMENDED ACTIONS (EXACTLY 2, HUMAN FRIENDLY)
    ===================================================== */
CASE
   /* ================= PURCHASE - NEGATIVE ONLY ================= */
   WHEN event_name = 'purchase'
     AND deviation_pct < 0
     AND deviation_pct <= -0.90
     THEN ['Geo and Device Segmentation Analysis: Break down purchase success and failure rates by country, region, device category, and browser to identify whether the collapse is localized. A sharp revenue drop limited to one geography or device class strongly indicates gateway, browser compatibility, or regional compliance issues.', 'Checkout Regression Testing: Run full end-to-end checkout tests across affected regions and devices, focusing on coupon application, tax calculation, address validation, and payment redirection. Pay special attention to recent changes in payment provider SDK versions or iframe embedding logic.'
     ]


  
   WHEN event_name = 'purchase'
     AND deviation_pct < 0
     AND deviation_pct > -0.90
     AND deviation_pct <= -0.60
     THEN ['Checkout Funnel Drop-off Analysis: Analyze step-level funnel metrics (begin_checkout → add_payment_info → purchase) to identify the precise abandonment point. A sharp drop at add_payment_info or purchase confirms late-stage friction rather than traffic or product issues.', 'Recent Deployment Review: Audit all checkout-related releases deployed in the last 24 to 72 hours, including pricing logic, discount rules, shipping calculation, payment SDK updates, and fraud-rule changes. Roll back high-risk changes if correlation is strong.'
     ]




   WHEN event_name = 'purchase'
     AND deviation_pct < 0
     AND deviation_pct > -0.60
     AND deviation_pct <= -0.45
     THEN ['Campaign-to-Checkout Alignment Review: Verify that active marketing campaigns correctly reflect product availability, pricing, discounts, and delivery timelines. Ensure landing pages route users into valid, purchasable product flows.', 'Traffic Quality Diagnostics: Segment revenue by traffic source, campaign, and medium to identify channels with disproportionate conversion collapse. Pause or optimize low-quality sources until conversion stability returns.'
     ]




   WHEN event_name = 'purchase'
     AND deviation_pct < 0
     AND deviation_pct > -0.45
     AND deviation_pct <= -0.30
     THEN ['Performance and UX Review: Evaluate Core Web Vitals (LCP, CLS, INP) for checkout and confirmation pages. Even small degradations can significantly impact revenue at scale, especially on mobile networks.', 'Customer Feedback Scan: Review customer support tickets, chat transcripts, NPS feedback, and social media mentions for emerging complaints related to checkout experience, pricing surprises, or payment reliability.'
     ]


   /* ================= ADD_TO_CART - NEGATIVE ONLY ================= */

   WHEN event_name = 'add_to_cart'
     AND deviation_pct < 0
     AND deviation_pct <= -0.80
     THEN ['Pricing & Promotion Consistency Check: Compare prices displayed on product listing pages (PLP), PDPs, and cart previews to ensure consistency. Investigate whether discount logic, coupon stacking rules, or currency rounding changes have introduced unexpected price jumps.', 'Product Page Content Validation: Audit PDPs for broken images, missing descriptions, incorrect variant defaults, or misleading stock messages. Even minor content regressions can suppress add-to-cart behavior at scale.'
     ]


   WHEN event_name = 'add_to_cart'
     AND deviation_pct < 0
     AND deviation_pct > -0.80
     AND deviation_pct <= -0.60
     THEN ['Traffic Source Quality Analysis: Segment add-to-cart rates by source, medium, and campaign to identify channels contributing disproportionate low-intent traffic. Look for spikes in impressions or clicks without corresponding engagement depth.', 'Landing Page Relevance Review: Ensure that campaign landing pages align with user expectations set by ads—product category, pricing, availability, and offer clarity should be consistent to avoid immediate disengagement.'
     ]
   WHEN event_name = 'add_to_cart'
     AND deviation_pct < 0
     AND deviation_pct > -0.60
     AND deviation_pct <= -0.40
     THEN ['Performance & Speed Diagnostics: Review Core Web Vitals (especially LCP and INP) for product pages. Small performance regressions can significantly suppress cart initiation, particularly on mobile networks.', 'Competitive Benchmark Review: Compare pricing, delivery timelines, and promotions against key competitors during the anomaly window. External market shifts can explain gradual cart engagement erosion.'
     ]
  


   /* ================= ADD_PAYMENT_INFO - NEGATIVE ONLY ================= */
 
   WHEN event_name = 'add_payment_info'
     AND deviation_pct < 0
     AND deviation_pct <= -0.90
     THEN ['Device & Payment Method Segmentation: Segment add_payment_info events by device category and payment method to identify disproportionate drops. Focus on mobile-only failures and payment options introduced or modified recently (e.g., UPI mandates, BNPL rollouts).', 'Checkout Transparency Review: Audit the checkout UI for last-minute cost additions or policy changes (shipping, tax, COD fees). Compare pre- and post-release checkout screenshots to identify elements that may have triggered user distrust or confusion.'
     ]


   WHEN event_name = 'add_payment_info'
     AND deviation_pct < 0
     AND deviation_pct > -0.90
     AND deviation_pct <= -0.60
     THEN ['Form Interaction & Accessibility Audit: Test checkout flows using keyboard navigation, screen readers, and mobile input methods. Verify that all fields accept input correctly, error messages are visible and actionable, and autofill works as expected.', 'Session Replay Analysis: Review session recordings (Hotjar, FullStory, Clarity) for checkout abandonment sessions to observe where users hesitate, retry inputs repeatedly, or exit without submitting payment information.'
     ]


   WHEN event_name = 'add_payment_info'
     AND deviation_pct < 0
     AND deviation_pct > -0.60
     AND deviation_pct <= -0.40
     THEN ['Price & Delivery Expectation Validation: Verify that delivery timelines, return policies, and payment assurances (refunds, COD availability) are clearly communicated at checkout. Minor ambiguities can cause users to pause at the payment stage.', 'Checkout Incentive Review: Evaluate whether checkout-stage incentives (free shipping thresholds, limited-time discounts) were removed or expired shortly before the anomaly window.'
     ]


   /* ================= PAGE_VIEW - BOTH POSITIVE AND NEGATIVE ================= */
  
   WHEN event_name = 'page_view'
     AND deviation_pct < 0
     AND deviation_pct <= -0.75
     THEN ['Tracking Infrastructure Verification: Use Google Tag Assistant and GA4 DebugView to load multiple landing pages across environments (desktop, mobile, incognito). Confirm that the GA4 configuration tag fires on page load and that page_view events reach GA4 in real time, especially on templates deployed most recently.', 'Traffic Source Health Audit: Review Google Ads, Meta Ads, and affiliate dashboards for campaign pauses, disapproved ads, budget exhaustion, or broken final URLs. Cross-check timestamp alignment between campaign stoppage and page_view drop to isolate acquisition-side failures.'
     ]


   WHEN event_name = 'page_view'
     AND deviation_pct < 0
     AND deviation_pct > -0.75
     AND deviation_pct <= -0.50
     THEN ['Channel-Level Traffic Decomposition: Segment page_view data by default channel grouping and geo. Identify which channels (organic, paid, referral, direct) contribute most to the drop and validate against external tools like Google Search Console and ad platform logs.', 'Consent & Geo Behavior Review: Audit consent management behavior across regions. Verify whether GA4 tags fire in denied consent states using Consent Mode v2 rather than being completely blocked, particularly for EU traffic.'
     ]


   WHEN event_name = 'page_view'
     AND deviation_pct < 0
     AND deviation_pct > -0.50
     AND deviation_pct <= -0.35
     THEN ['Marketing Change Correlation: Review campaign change logs, bid adjustments, and content updates deployed within the last 7 to 14 days. Identify whether traffic loss aligns with intentional spend optimization or unintentional deactivation.', 'Landing Page Availability Check: Crawl top landing pages using automated tools or manual spot checks to ensure they return HTTP 200 and are indexable, accessible, and internally linked.'
     ]


   WHEN event_name = 'page_view'
     AND deviation_pct > 0
     AND deviation_pct >= 0.90
     THEN ['Bot & User Pattern Analysis: Segment page_view volume by user_pseudo_id and IP/ASN (if available). Look for users generating hundreds of page views per session, unusually short session durations, or identical navigation paths repeated at scale.', 'Event Deduplication Validation: Inspect GA4 implementation for duplicate page_view triggers—particularly in SPA frameworks (React/Vue/Next.js). Ensure page_view fires only on meaningful route changes, not on every state update or re-render.'
     ]


   WHEN event_name = 'page_view'
     AND deviation_pct > 0
     AND deviation_pct < 0.90
     AND deviation_pct >= 0.60
     THEN ['Campaign Attribution Validation: Confirm whether any marketing activations, influencer posts, email blasts, or app push notifications occurred during the anomaly window. Validate that traffic sources align with expected campaign channels.', 'Referral & Source Quality Review: Inspect referral domains and landing pages. Sudden surges from obscure domains or single referrers often indicate spam or automated scraping rather than real demand.'
     ]
  
   WHEN event_name = 'page_view'
     AND deviation_pct > 0
     AND deviation_pct < 0.60
     AND deviation_pct >= 0.45
     THEN ['Engagement Correlation Check: Compare page_view growth against user_engagement, session_start, and add_to_cart. Genuine traffic growth should lift downstream metrics; divergence suggests low-quality traffic.', 'Trend Stability Monitoring: Monitor whether elevated traffic sustains over multiple days. Organic growth tends to stabilize; artificial spikes decay rapidly.'
     ]


   /* ================= SESSION_START - BOTH POSITIVE AND NEGATIVE ================= */
 
   WHEN event_name = 'session_start'
     AND deviation_pct < 0
     AND deviation_pct <= -0.75
     THEN ['Consent Mode & CMP Audit: Inspect Cookiebot / OneTrust / custom CMP configurations to verify that GA4 runs in denied consent mode rather than being fully blocked. Validate session_start firing behavior in restricted regions using incognito + VPN testing.', 'Redirect Chain Validation: Trace entry URLs for major landing pages and campaign URLs. Ensure that redirects preserve GA4 parameters and do not reload the page before session_start can be registered.'
     ]


   WHEN event_name = 'session_start'
     AND deviation_pct < 0
     AND deviation_pct > -0.75
     AND deviation_pct <= -0.45
     THEN ['Device & Browser Segmentation: Break down session_start counts by device_category and browser. Look for asymmetric drops (e.g., iOS Safari collapsing while Chrome remains stable).', 'GTM Trigger Dependency Review: Audit session_start-related triggers in GTM to ensure they are not dependent on page elements, CSS selectors, or custom JS conditions that may have changed during frontend releases.'
     ]


   WHEN event_name = 'session_start'
     AND deviation_pct < 0
     AND deviation_pct > -0.45
     AND deviation_pct <= -0.25
     THEN ['Attribution Parameter Consistency Check: Compare current UTM structures against historical baselines. Ensure session_start is not suppressed due to missing or malformed campaign parameters.', 'Session Timeout Configuration Review: Validate GA4 session timeout settings. Aggressive timeouts or misconfigured engagement_time logic can suppress new session creation.'
     ]


   WHEN event_name = 'session_start'
     AND deviation_pct > 0
     AND deviation_pct >= 0.80
     THEN ['Session Timeout Configuration Review: Validate GA4 session timeout settings. Aggressive timeouts or misconfigured engagement_time logic can suppress new session creation.', 'Cross-Domain Linking Audit: Validate that GA4 linker parameters are properly implemented between domains (e.g., checkout, payment, blog subdomains) to prevent session resets.'
     ]


   WHEN event_name = 'session_start'
     AND deviation_pct > 0
     AND deviation_pct < 0.80
     AND deviation_pct >= 0.55
     THEN ['SPA Lifecycle Inspection: Review frontend routing logic to ensure session_start fires only once per real session, not on every route transition or state update.', 'Session-to-User Ratio Check: Analyze sessions per user. Values >3–4 in short timeframes usually indicate technical inflation rather than behavioral change.'
     ]
  
   WHEN event_name = 'session_start'
     AND deviation_pct > 0
     AND deviation_pct < 0.55
     AND deviation_pct >= 0.35
     THEN ['Downstream Metric Correlation: Validate whether page_view, user_engagement, and add_to_cart increase proportionally. If not, session inflation is likely technical.', 'Short-Term Persistence Monitoring: Track whether elevated session levels normalize within 1–2 days. True behavioral uplift persists; technical spikes decay quickly.'
     ]


   /* ================= USER_ENGAGEMENT - BOTH POSITIVE AND NEGATIVE ================= */
 
   WHEN event_name = 'user_engagement'
     AND deviation_pct < 0
     AND deviation_pct <= -0.85
     THEN ['Performance & CWV Diagnostics: Pull Lighthouse and CrUX reports for affected URLs. Focus on LCP, CLS, and Total Blocking Time. Correlate deployment timestamps with engagement collapse to identify regression-causing releases.', 
'Instrumentation Integrity Validation: Use GA4 DebugView and Tag Assistant to verify that engagement_time_msec is incrementing during active page usage. Confirm that GA4 config tags fire before heavy JS bundles and are not gated behind consent or DOM-ready dependencies.'
     ]


   WHEN event_name = 'user_engagement'
     AND deviation_pct < 0
     AND deviation_pct > -0.85
     AND deviation_pct <= -0.60
     THEN ['Device & Viewport UX Audit: Test top landing pages across mobile breakpoints. Inspect z-index conflicts, sticky banners, and modal overlays that may intercept clicks or prevent scrolling.', 
'Engagement Event Fire Testing: Manually test scroll depth, click, and interaction tracking in GA4 DebugView to ensure engagement events fire when users interact, particularly on mobile browsers.'
     ]


   WHEN event_name = 'user_engagement'
     AND deviation_pct < 0
     AND deviation_pct > -0.60
     AND deviation_pct <= -0.35
     THEN ['Above-the-Fold Content Review: Compare pre- and post-change layouts to ensure primary CTAs, value propositions, and navigation remain visible without scrolling.', 
'Heatmap & Scroll Analysis: Use tools like Hotjar or Microsoft Clarity to identify where users stop scrolling or fail to click. Validate whether engagement drop aligns with visual hierarchy changes.'
     ]


   WHEN event_name = 'user_engagement'
     AND deviation_pct > 0
     AND deviation_pct >= 0.90
     THEN ['Bot & Automation Segmentation: Segment engagement by user_pseudo_id and session duration. Identify patterns such as thousands of users with identical engagement times or abnormal interaction frequency.', 
'SPA Engagement Logic Audit: Inspect frontend engagement tracking to ensure timers reset correctly on route changes and do not accumulate across virtual pageviews.'
     ]


   WHEN event_name = 'user_engagement'
     AND deviation_pct > 0
     AND deviation_pct < 0.90
     AND deviation_pct >= 0.70
     THEN ['Visibility API Validation: Confirm that engagement timers sure pause when tabs are inactive or backgrounded. Validate Page Visibility API implementation.', 
'Session Duration Distribution Check: Analyze session duration histograms. Long-tail spikes (e.g., many sessions >60 minutes) usually indicate technical inflation.'
     ]
  
   WHEN event_name = 'user_engagement'
     AND deviation_pct > 0
     AND deviation_pct < 0.70
     AND deviation_pct >= 0.45
     THEN ['Funnel Correlation Check: Verify whether increases in engagement translate into higher add_to_cart, add_payment_info, or purchase events. If not, engagement is likely artificial.', 
'Content Attribution Review: Identify top URLs driving engagement uplift. Validate whether content updates, SEO gains, or campaigns justify the increase.'
     ]


   ELSE [
     'NA',
     'NA'
   ]
 END AS recommended_actions


FROM `tvc-ecommerce.analytics_live.ga4_anomaly_enriched_all_events`
WHERE event_date = DATE_SUB(CURRENT_DATE('Asia/Kolkata'), INTERVAL 1 DAY);
