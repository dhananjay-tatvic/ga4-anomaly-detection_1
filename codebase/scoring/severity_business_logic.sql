CREATE OR REPLACE TABLE
`tvc-ecommerce.analytics_live.ga4_anomaly_scored_events`
PARTITION BY event_date
AS
SELECT
  e.event_date,
  e.event_name,
  e.actual_value,
  e.expected_value,
  e.lower_bound,
  e.upper_bound,
  e.deviation_pct,
  e.anomaly_probability,
  e.z_score,
  e.bound_distance,
  e.is_outside_bounds,
  e.is_anomaly,

  /* =====================================================
     SEVERITY CLASSIFICATION
     ===================================================== */
  CASE
    -- Hard gate
    WHEN e.is_anomaly = FALSE OR e.is_outside_bounds = FALSE THEN 'NONE'

    -- PURCHASE (Negative only)
    WHEN e.event_name = 'purchase'
      AND e.deviation_pct < 0
      AND (e.deviation_pct <= -0.60 OR e.z_score <= -3.5)
      THEN 'CRITICAL'

    -- ADD_TO_CART (Negative only per requirement)
    WHEN e.event_name = 'add_to_cart'
      AND e.deviation_pct < 0
      AND (e.deviation_pct <= -0.80 OR e.z_score <= -8.0)
      THEN 'CRITICAL'

    -- ADD_PAYMENT_INFO (Negative only per requirement)
    WHEN e.event_name = 'add_payment_info'
      AND e.deviation_pct < 0
      AND (e.deviation_pct <= -0.60 OR e.z_score <= -5.0)
      THEN 'CRITICAL'

    -- PAGE_VIEW (Both positive and negative)
    WHEN e.event_name = 'page_view'
      AND (
        -- Negative: severe traffic decline
        (e.deviation_pct < 0 AND (e.deviation_pct <= -0.50 OR e.z_score <= -5.5))
        OR
        -- Positive: unusual traffic spike
        (e.deviation_pct > 0 AND (e.deviation_pct >= 0.60 OR e.z_score >= 5.5))
      )
      THEN 'CRITICAL'

    -- SESSION_START (Both positive and negative)
    WHEN e.event_name = 'session_start'
      AND (
        -- Negative: severe session decline
        (e.deviation_pct < 0 AND (e.deviation_pct <= -0.45 OR e.z_score <= -6.5))
        OR
        -- Positive: unusual session spike
        (e.deviation_pct > 0 AND (e.deviation_pct >= 0.55 OR e.z_score >= 6.5))
      )
      THEN 'CRITICAL'

    -- USER_ENGAGEMENT (Both positive and negative)
    WHEN e.event_name = 'user_engagement'
      AND (
        -- Negative: severe engagement decline
        (e.deviation_pct < 0 AND (e.deviation_pct <= -0.60 OR e.z_score <= -4.0))
        OR
        -- Positive: unusual engagement spike
        (e.deviation_pct > 0 AND (e.deviation_pct >= 0.70 OR e.z_score >= 4.0))
      )
      THEN 'CRITICAL'

    -- BEGIN_CHECKOUT (Negative only - placeholder for new event)
    WHEN e.event_name = 'begin_checkout'
  AND e.deviation_pct < 0
  AND (e.deviation_pct <= -0.65 OR e.z_score <= -4.5)
  THEN 'CRITICAL'

    -- VIEW_ITEM (Both positive and negative - placeholder for new event)
    WHEN e.event_name = 'view_item'
  AND (
    -- Negative: severe product discovery decline
    (e.deviation_pct < 0 AND (e.deviation_pct <= -0.55 OR e.z_score <= -5.0))
    OR
    -- Positive: unusual product view spike
    (e.deviation_pct > 0 AND (e.deviation_pct >= 0.65 OR e.z_score >= 5.0))
  )
  THEN 'CRITICAL'

    -- SCROLL (Both positive and negative - placeholder for new event)
    WHEN e.event_name = 'scroll'
  AND (
    -- Negative: severe engagement degradation
    (e.deviation_pct < 0 AND (e.deviation_pct <= -0.65 OR e.z_score <= -5.5))
    OR
    -- Positive: unusual scroll inflation
    (e.deviation_pct > 0 AND (e.deviation_pct >= 0.75 OR e.z_score >= 5.5))
  )
  THEN 'CRITICAL'

    /* ===== HIGH SEVERITY ===== */
   
    -- PURCHASE (Negative only)
    WHEN e.event_name = 'purchase'
      AND e.deviation_pct < 0
      AND (e.deviation_pct <= -0.30 OR e.z_score <= -2.0)
      THEN 'HIGH'

    -- ADD_TO_CART (Negative only)
    WHEN e.event_name = 'add_to_cart'
      AND e.deviation_pct < 0
      AND (e.deviation_pct <= -0.40 OR e.z_score <= -4.0)
      THEN 'HIGH'

    -- ADD_PAYMENT_INFO (Negative only)
    WHEN e.event_name = 'add_payment_info'
      AND e.deviation_pct < 0
      AND (e.deviation_pct <= -0.40 OR e.z_score <= -3.5)
      THEN 'HIGH'

    -- PAGE_VIEW (Both positive and negative)
    WHEN e.event_name = 'page_view'
      AND (
        (e.deviation_pct < 0 AND (e.deviation_pct <= -0.35 OR e.z_score <= -4.0))
        OR
        (e.deviation_pct > 0 AND (e.deviation_pct >= 0.45 OR e.z_score >= 4.0))
      )
      THEN 'HIGH'

    -- SESSION_START (Both positive and negative)
    WHEN e.event_name = 'session_start'
      AND (
        (e.deviation_pct < 0 AND (e.deviation_pct <= -0.25 OR e.z_score <= -4.0))
        OR
        (e.deviation_pct > 0 AND (e.deviation_pct >= 0.35 OR e.z_score >= 4.0))
      )
      THEN 'HIGH'

    -- USER_ENGAGEMENT (Both positive and negative)
    WHEN e.event_name = 'user_engagement'
      AND (
        (e.deviation_pct < 0 AND (e.deviation_pct <= -0.35 OR e.z_score <= -3.5))
        OR
        (e.deviation_pct > 0 AND (e.deviation_pct >= 0.45 OR e.z_score >= 3.5))
      )
      THEN 'HIGH'

    -- BEGIN_CHECKOUT (Negative only - placeholder for new event)
    WHEN e.event_name = 'begin_checkout'
  AND e.deviation_pct < 0
  AND (e.deviation_pct <= -0.35 OR e.z_score <= -3.5)
  THEN 'HIGH'

    -- VIEW_ITEM (Both positive and negative - placeholder for new event)
    WHEN e.event_name = 'view_item'
  AND (
    (e.deviation_pct < 0 AND (e.deviation_pct <= -0.30 OR e.z_score <= -3.5))
    OR
    (e.deviation_pct > 0 AND (e.deviation_pct >= 0.40 OR e.z_score >= 3.5))
  )
  THEN 'HIGH'

    -- SCROLL (Both positive and negative - placeholder for new event)
    WHEN e.event_name = 'scroll'
  AND (
    (e.deviation_pct < 0 AND (e.deviation_pct <= -0.40 OR e.z_score <= -4.0))
    OR
    (e.deviation_pct > 0 AND (e.deviation_pct >= 0.50 OR e.z_score >= 4.0))
  )
  THEN 'HIGH'

    /* ===== MEDIUM SEVERITY ===== */
    WHEN (
      ABS(e.deviation_pct) BETWEEN 0.10 AND 0.30
      OR (e.anomaly_probability >= 0.85 OR ABS(e.z_score) >= 1.5)
    ) THEN 'MEDIUM'

    /* ===== LOW SEVERITY ===== */
    ELSE 'LOW'
  END AS severity_level,

  /* =====================================================
     BUSINESS IMPACT
     Taken directly from metric_config table
     ===================================================== */
  COALESCE(mc.business_impact, 'LOW') AS business_impact,

  /* =====================================================
     ROOT CAUSE IDENTIFICATION (HUMAN FRIENDLY)
     ===================================================== */
  CASE
    /* ================= PURCHASE - NEGATIVE ONLY ================= */
    WHEN e.event_name = 'purchase'
      AND e.deviation_pct < 0
      AND e.deviation_pct <= -0.90
      THEN 'A sustained revenue drop 90% below expected typically indicates partial platform-level failures rather than total system collapse. In real ecommerce environments, this often manifests as regional payment gateway failures, currency conversion bugs, or checkout flow breakage on specific browsers or devices (commonly mobile Safari or Android WebView). Another common cause is fraud-prevention overblocking, where newly deployed risk rules incorrectly flag legitimate transactions, causing mass declines while traffic remains stable. In multi-region stores, this deviation band frequently correlates with geo-specific outages rather than global failures.'

    WHEN e.event_name = 'purchase'
      AND e.deviation_pct < 0
      AND e.deviation_pct > -0.90
      AND e.deviation_pct <= -0.60
      THEN 'Revenue declines in the 60% to 90% range are commonly associated with high-friction checkout degradation rather than outright outages. Customers reach checkout but abandon due to late-stage blockers such as unexpected shipping charges, tax miscalculations, broken discount logic, forced account creation, or payment UI changes that reduce trust. This pattern is also observed when fraud detection thresholds are tightened without adequate monitoring, causing a sudden surge in legitimate transaction rejections. Unlike full outages, some transactions still succeed, but the majority fail at the final step.'

    WHEN e.event_name = 'purchase'
      AND e.deviation_pct < 0
      AND e.deviation_pct > -0.60
      AND e.deviation_pct <= -0.45
      THEN 'Revenue drops in this range usually reflect demand-quality or campaign misalignment issues rather than core platform failures. Paid traffic may continue to arrive, but users do not convert due to mismatched messaging, broken landing pages, incorrect pricing promises, or targeting drift. This deviation band often appears when promotional campaigns drive volume without purchase intent, or when landing pages fail to match ad copy, leading to early checkout exits.'

    WHEN e.event_name = 'purchase'
      AND e.deviation_pct < 0
      AND e.deviation_pct > -0.45
      AND e.deviation_pct <= -0.30
      THEN 'This deviation range typically represents early-stage revenue degradation, often caused by subtle UX or performance issues rather than explicit failures. Common drivers include increased page load times, mobile usability regressions, trust signal removal (security badges, payment logos), or delivery promise changes that discourage completion. While not immediately catastrophic, persistence in this band often precedes deeper funnel collapse if unaddressed.'

    /* ================= ADD_TO_CART - NEGATIVE ONLY ================= */
    WHEN e.event_name = 'add_to_cart'
      AND e.deviation_pct < 0
      AND e.deviation_pct <= -0.80
      THEN 'Drops below 80% usually indicate behavioral deterrents rather than hard failures. Users can technically add items to the cart, but choose not to due to sudden friction introduced at the product evaluation stage.Common causes include unexpected price increases, incorrect discount application, shipping fee visibility changes, broken product images, or misleading availability indicators (Only 1 left logic misfiring). In many cases, recent merchandising changes unintentionally degrade trust at the PDP level.'

    WHEN e.event_name = 'add_to_cart'
      AND e.deviation_pct < 0
      AND e.deviation_pct > -0.80
      AND e.deviation_pct <= -0.60
      THEN 'This deviation band typically reflects traffic quality degradation, where users arrive at product pages but lack genuine purchase intent. This often correlates with campaign misconfiguration—broad targeting, irrelevant keywords, or upper-funnel campaigns driving curiosity clicks rather than shopping intent. Unlike CRITICAL scenarios, cart functionality remains intact, but user motivation is weak.'

    WHEN e.event_name = 'add_to_cart'
      AND e.deviation_pct < 0
      AND e.deviation_pct > -0.60
      AND e.deviation_pct <= -0.40
      THEN 'A moderate decline in this range often represents early funnel softening, commonly driven by subtle UX regressions or market factors rather than structural issues. Examples include slower page load times, degraded mobile performance, reduced promotional urgency, or competitor pricing pressure. While not immediately catastrophic, persistence here is a leading indicator of downstream purchase decline.'

    /* ================= ADD_PAYMENT_INFO - NEGATIVE ONLY ================= */
    WHEN e.event_name = 'add_payment_info'
      AND e.deviation_pct < 0
      AND e.deviation_pct <= -0.90
      THEN 'Drops below 90% typically indicate partial payment step failure, where only certain users, devices, or payment methods are affected. This commonly occurs when mobile checkout flows break independently of desktop, or when specific payment methods (UPI, wallets, BNPL) silently fail. Another major contributor in this range is trust erosion caused by unexpected changes at checkout—such as sudden shipping fee additions, tax recalculations, forced account creation, or security warnings (mixed content, expired SSL chains). These do not technically block payment entry but cause users to abandon before submitting payment information.'

    WHEN e.event_name = 'add_payment_info'
      AND e.deviation_pct < 0
      AND e.deviation_pct > -0.90
      AND e.deviation_pct <= -0.60
      THEN 'This deviation band indicates checkout usability degradation rather than outright failure. Users reach the payment step but abandon due to friction, complexity, or cognitive overload. Common drivers include overly long checkout forms, auto-focus bugs that prevent input on mobile keyboards, poorly handled error states (e.g., "Something went wrong" without resolution), or accessibility regressions that disproportionately affect certain user segments.'

    WHEN e.event_name = 'add_payment_info'
      AND e.deviation_pct < 0
      AND e.deviation_pct > -0.60
      AND e.deviation_pct <= -0.40
      THEN 'Moderate declines in this band typically reflect behavioral hesitation rather than technical failure. Users reach payment but delay or abandon due to price sensitivity, low urgency, or external comparison behavior (e.g., checking competitors before completing payment). This is often observed during non-promotional periods, post-campaign cooldowns, or when shipping timelines lengthen unexpectedly.'

    /* ================= PAGE_VIEW - BOTH POSITIVE AND NEGATIVE ================= */
    WHEN e.event_name = 'page_view'
      AND e.deviation_pct < 0
      AND e.deviation_pct <= -0.75
      THEN 'A collapse exceeding 75% below forecast in page views indicates a severe upstream traffic acquisition or tracking failure, not a demand-side issue. At this magnitude, users are either not reaching the site at all or reaching it without being tracked. The most common real-world cause is analytics instrumentation failure following a frontend deployment. Examples include the GA4 configuration tag being removed from newly deployed templates, GTM containers failing to load due to CSP misconfiguration, or consent mode misfires that block analytics entirely in certain regions. Another frequent cause is sudden traffic source shutdown, such as paused Google Ads or Meta campaigns, revoked ad accounts, exhausted daily budgets, or broken destination URLs returning 404/500 errors—causing platforms to silently stop sending traffic.'

    WHEN e.event_name = 'page_view'
      AND e.deviation_pct < 0
      AND e.deviation_pct > -0.75
      AND e.deviation_pct <= -0.50
      THEN 'Drops in the 50–75% range typically indicate partial traffic loss or selective tracking failure rather than a total outage. This often occurs when one or two major channels fail, while others continue normally. Common causes include organic search ranking collapses due to SEO misconfigurations (robots.txt blocking, noindex tags, canonical errors), region-specific consent enforcement blocking GA4 in GDPR geographies, or CDN/firewall rules blocking traffic from certain countries or user agents.'

    WHEN e.event_name = 'page_view'
      AND e.deviation_pct < 0
      AND e.deviation_pct > -0.50
      AND e.deviation_pct <= -0.35
      THEN 'This deviation band represents significant but non-catastrophic traffic degradation, usually driven by marketing or discoverability changes rather than hard failures. Typical drivers include paused remarketing campaigns, reduced bids on high-performing keywords, content removals affecting SEO landing pages, or broken internal links that reduce crawl depth and user flow.'

    WHEN e.event_name = 'page_view'
      AND e.deviation_pct > 0
      AND e.deviation_pct >= 0.90
      THEN 'An extreme positive spike (>90%) in page views is rarely organic. In ecommerce environments, this typically signals artificial traffic inflation rather than genuine user growth. Common causes include bot traffic (scrapers, crawlers, competitor price monitors), DDoS-style low-level floods, or misconfigured internal systems repeatedly hitting pages (e.g., uptime monitors, QA automation running in production). Another frequent cause is duplicate page_view firing, where SPA route changes or reload loops trigger multiple page_view events per single user action.'

    WHEN e.event_name = 'page_view'
      AND e.deviation_pct > 0
      AND e.deviation_pct < 0.90
      AND e.deviation_pct >= 0.60
      THEN 'This range often represents coordinated but explainable traffic surges—such as flash sales, influencer campaigns, or viral content—if supported by marketing context. If no campaigns exist, the surge may still reflect crawler or referral spam traffic.'

    WHEN e.event_name = 'page_view'
      AND e.deviation_pct > 0
      AND e.deviation_pct < 0.60
      AND e.deviation_pct >= 0.45
      THEN 'Moderate positive deviations usually indicate healthy traffic growth, seasonal uplift, or short-term promotional impact. However, they may also represent early-stage bot activity if engagement metrics fail to rise proportionally.'

    /* ================= SESSION_START - BOTH POSITIVE AND NEGATIVE ================= */
    WHEN e.event_name = 'session_start'
      AND e.deviation_pct < 0
      AND e.deviation_pct <= -0.75
      THEN 'A drop greater than 75% in session_start events indicates a systemic failure in session initialization, where users may still be landing on the site but GA4 is unable to establish sessions. The most frequent real-world cause is Consent Management Platform (CMP) misconfiguration after regulatory or UX changes. In such cases, analytics cookies are blocked entirely until explicit consent, and GA4 is not operating in Consent Mode v2 "denied" state—resulting in zero or near-zero session creation. Another common cause is redirect-heavy landing flows, such as geo-based redirects, login redirects, or campaign URL rewrites that strip GA4 session parameters (_ga, gclid, utm_*), causing sessions to fail initialization repeatedly.'

    WHEN e.event_name = 'session_start'
      AND e.deviation_pct < 0
      AND e.deviation_pct > -0.75
      AND e.deviation_pct <= -0.45
      THEN 'This range typically indicates partial session suppression, where sessions initialize for some users but fail for others. Common causes include device-specific issues (mobile-only failures due to JS execution timing), browser-specific restrictions (Safari ITP aggressively expiring cookies), or conditional GTM triggers that fire session_start only when specific DOM elements exist—which may have been removed in recent UI updates.'

    WHEN e.event_name = 'session_start'
      AND e.deviation_pct < 0
      AND e.deviation_pct > -0.45
      AND e.deviation_pct <= -0.25
      THEN 'Moderate session declines usually reflect changes in attribution or entry behavior, not outright failures. This often happens when marketing teams modify UTM structures, switch to server-side tagging without full validation, or shorten session timeout windows—causing sessions to merge unexpectedly and reduce session_start counts even though users are present.'

    WHEN e.event_name = 'session_start'
      AND e.deviation_pct > 0
      AND e.deviation_pct >= 0.80
      THEN 'A surge exceeding 80% in session_start is a strong indicator of session fragmentation, not real traffic growth. This typically occurs when session IDs reset repeatedly due to cookie persistence failures—often caused by SameSite cookie attribute misconfigurations, cross-domain navigation without linker parameters, or broken consent logic resetting cookies on every page load.'

    WHEN e.event_name = 'session_start'
      AND e.deviation_pct > 0
      AND e.deviation_pct < 0.80
      AND e.deviation_pct >= 0.55
      THEN 'This deviation band often reflects mid-level session inflation, commonly caused by SPA routing issues or misfiring session_start events. In React/Vue applications, incorrect lifecycle hooks may fire session_start on route changes rather than true session boundaries, artificially inflating session counts without corresponding user growth.'

    WHEN e.event_name = 'session_start'
      AND e.deviation_pct > 0
      AND e.deviation_pct < 0.55
      AND e.deviation_pct >= 0.35
      THEN 'Moderate positive session increases can represent legitimate re-engagement (email campaigns, retargeting) or early signs of session fragmentation. The distinction depends on downstream engagement health.'

    /* ================= USER_ENGAGEMENT - BOTH POSITIVE AND NEGATIVE ================= */
    WHEN e.event_name = 'user_engagement'
      AND e.deviation_pct < 0
      AND e.deviation_pct <= -0.85
      THEN 'A collapse greater than 85% in user_engagement indicates that users are reaching the site but failing to interact meaningfully. This almost never represents demand loss and instead signals severe experience degradation. The most common cause is critical performance failure, where pages technically load but become interactive too late. Core Web Vitals regressions—especially Largest Contentful Paint (LCP > 4s) or Cumulative Layout Shift (CLS > 0.25)—cause users to abandon before any engagement event can fire. Another frequent cause is broken engagement instrumentation, where the engagement_time_msec parameter stops incrementing due to JavaScript execution errors, consent misfires, or incorrect GA4 config placement below blocking scripts.'

    WHEN e.event_name = 'user_engagement'
      AND e.deviation_pct < 0
      AND e.deviation_pct > -0.85
      AND e.deviation_pct <= -0.60
      THEN 'This range reflects partial engagement suppression, where only certain user segments lose interaction capability. Typical real-world causes include mobile-specific layout failures, where CTA buttons, scroll containers, or navigation elements become inaccessible due to CSS overlap or viewport miscalculations. Another frequent trigger is cookie banner or modal overlays that block interaction while still allowing page views.'

    WHEN e.event_name = 'user_engagement'
      AND e.deviation_pct < 0
      AND e.deviation_pct > -0.60
      AND e.deviation_pct <= -0.35
      THEN 'Moderate engagement drops often indicate content relevance or layout hierarchy issues rather than technical failure. This frequently follows template redesigns, where key content is pushed below the fold, CTA prominence is reduced, or informational density is diluted. Users still arrive but disengage quickly.'

    WHEN e.event_name = 'user_engagement'
      AND e.deviation_pct > 0
      AND e.deviation_pct >= 0.90
      THEN 'An engagement surge above 90% is rarely organic. It usually indicates artificial engagement inflation. Common causes include bot traffic executing JavaScript, automated QA or load-testing tools interacting with pages, or SPA misconfiguration where engagement timers reset or accumulate incorrectly on route changes.'

    WHEN e.event_name = 'user_engagement'
      AND e.deviation_pct > 0
      AND e.deviation_pct < 0.90
      AND e.deviation_pct >= 0.70
      THEN 'This band often reflects misfiring engagement timers rather than true interaction uplift. In many GA4 implementations, engagement_time_msec can accumulate if page visibility APIs are misused or if tabs left open in background continue registering active time.'

    WHEN e.event_name = 'user_engagement'
      AND e.deviation_pct > 0
      AND e.deviation_pct < 0.70
      AND e.deviation_pct >= 0.45
      THEN 'This can represent legitimate content success (viral blog, campaign landing page) or early-stage inflation. Differentiation depends on downstream funnel behavior.'

    /* ================= BEGIN_CHECKOUT - NEGATIVE ONLY ================= */
    -- Placeholder for begin_checkout root causes
    WHEN e.event_name = 'begin_checkout'
  AND e.deviation_pct < 0
  AND e.deviation_pct <= -0.85
  THEN 'A collapse exceeding 85% in begin_checkout typically indicates cart-to-checkout transition infrastructure failure rather than user hesitation. The most common cause is broken "Proceed to Checkout" or "Go to Checkout" button functionality, often due to JavaScript errors in cart page scripts, missing event listeners after React/Vue component re-renders, or failed API calls to checkout initialization endpoints (session creation, cart validation, inventory locks). Another frequent trigger is session or cart state persistence failures, where users click checkout but encounter "Your cart is empty" errors because cart data failed to serialize correctly—commonly due to cookie domain misconfigurations (missing leading dot for subdomain sharing), session timeout drift between cart and checkout services, or localStorage/sessionStorage quota exceeded errors on browsers with strict storage limits. Payment provider SDK initialization failures (Stripe Elements, PayPal SDK, Razorpay Checkout) can also block checkout entry if scripts fail to load due to Content Security Policy restrictions, ad blockers, or network CDN outages.'

WHEN e.event_name = 'begin_checkout'
  AND e.deviation_pct < 0
  AND e.deviation_pct > -0.85
  AND e.deviation_pct <= -0.65
  THEN 'This deviation range reflects partial checkout access failures affecting specific user segments, device types, or cart compositions. Common causes include mobile-specific cart UI breakage, where "Proceed to Checkout" buttons become hidden beneath fixed bottom navigation bars, obscured by cookie consent banners with high z-index values, or rendered off-screen due to viewport height miscalculations on notched devices (iPhone X+, Android with bottom navigation). Another frequent trigger is pre-checkout validation failures, such as real-time inventory re-checks that incorrectly mark in-stock items as unavailable, minimum order value requirements that activate unexpectedly due to discount miscalculations, or shipping zone restrictions that trigger late in the cart review step for certain postal codes. Guest checkout versus mandatory login gate changes can also suppress begin_checkout—forcing account creation or authentication before checkout access, causing friction especially for mobile users and first-time visitors who prefer express checkout.'

WHEN e.event_name = 'begin_checkout'
  AND e.deviation_pct < 0
  AND e.deviation_pct > -0.65
  AND e.deviation_pct <= -0.35
  THEN 'Moderate declines in this band usually indicate behavioral friction or trust degradation at the cart review stage rather than hard technical failures. This often follows cart page redesigns that introduce unexpected last-minute information—such as newly visible shipping costs not previewed on PDPs, extended delivery timelines (5-7 days vs. previously promised 2-3 days), visible return policy restrictions, or membership/subscription upsell prompts that create confusion about one-time purchase options. Another common cause is promotional code friction, where users abandon to search externally for discount codes they believe should exist, or where promo code entry fields are removed or relocated from prominent cart positions to hidden checkout steps, creating uncertainty about whether advertised offers will apply. Trust signal removal or relocation (security badges, payment method logos, "Secure Checkout" assurances, free shipping threshold progress bars) can also reduce checkout initiation confidence, particularly among first-time visitors or during high-fraud periods (holidays, sales events).'

    /* ================= VIEW_ITEM - BOTH POSITIVE AND NEGATIVE ================= */
    -- Placeholder for view_item root causes
   WHEN e.event_name = 'view_item'
  AND e.deviation_pct < 0
  AND e.deviation_pct <= -0.80
  THEN 'Drops exceeding 80% in view_item indicate structural failures in product discovery or navigation, not demand loss. The most common causes are product catalog sync failures, where recent updates to inventory systems, PIM platforms, or headless commerce backends break the product feed entirely—causing PDPs to return 404 errors or display empty content. Another frequent cause is search infrastructure collapse, particularly with third-party search providers (Algolia, Elasticsearch) where API authentication expires, rate limits are exceeded, or index rebuilds fail mid-deployment. Category navigation breakage is also common, often due to broken filter logic, missing URL parameters after frontend rewrites, or infinite redirect loops in product routing. Unlike page_view collapses, users are reaching the site but cannot access individual products.'

WHEN e.event_name = 'view_item'
  AND e.deviation_pct < 0
  AND e.deviation_pct > -0.80
  AND e.deviation_pct <= -0.55
  THEN 'This deviation range typically reflects partial product discovery degradation affecting specific user segments or product categories. Common causes include mobile-specific PDP rendering failures, where viewport meta tags or lazy-loading configurations prevent product images and details from displaying correctly on smaller screens. Another frequent trigger is category-specific outages, where certain product types (e.g., seasonal items, newly launched collections) have broken metadata, missing variant options, or incorrect pricing that causes users to abandon before view_item fires. Merchandising rule changes can also suppress visibility—such as aggressive out-of-stock filtering, price range restrictions, or search relevance algorithm updates that bury popular products below the fold.'

WHEN e.event_name = 'view_item'
  AND e.deviation_pct < 0
  AND e.deviation_pct > -0.55
  AND e.deviation_pct <= -0.30
  THEN 'Moderate declines in this band usually represent navigation friction or content quality degradation rather than hard failures. This often follows homepage or PLP redesigns where hero carousels, featured product grids, or "Shop by Category" modules are removed or pushed below the fold, reducing direct product discovery paths. Another common cause is search autocomplete or filtering degradation—where previously functional features become slower, less accurate, or return irrelevant results, causing users to abandon search before reaching PDPs. Internal linking erosion, such as removed cross-sell recommendations or breadcrumb navigation issues, can also reduce view_item counts by limiting product discoverability.'

WHEN e.event_name = 'view_item'
  AND e.deviation_pct > 0
  AND e.deviation_pct >= 0.90
  THEN 'Extreme positive spikes (>90%) in view_item are rarely organic and usually indicate tracking instrumentation errors or bot activity. The most common cause is duplicate view_item firing, where SPA frameworks (React Router, Vue Router) trigger view_item on every state update, modal open, or image gallery interaction rather than only on true PDP loads. Another frequent cause is automated price monitoring bots or competitor scrapers systematically crawling product catalogs, particularly after new product launches or price updates. Infinite scroll implementations can also misfire, where view_item fires repeatedly as users scroll through product grids without actually viewing individual PDPs.'

WHEN e.event_name = 'view_item'
  AND e.deviation_pct > 0
  AND e.deviation_pct < 0.90
  AND e.deviation_pct >= 0.65
  THEN 'This range often represents coordinated product interest surges—such as influencer product drops, viral social media posts linking directly to PDPs, or flash sale announcements. However, if no marketing context exists, the surge may reflect early-stage bot activity or catalog crawling. Another possibility is internal QA or load testing accidentally running in production against live product URLs.'

WHEN e.event_name = 'view_item'
  AND e.deviation_pct > 0
  AND e.deviation_pct < 0.65
  AND e.deviation_pct >= 0.40
  THEN 'Moderate positive spikes typically represent legitimate campaign success—such as email product recommendations, retargeting ads driving direct-to-PDP traffic, or effective merchandising changes that increase product click-through from PLPs. However, validation against downstream funnel metrics (add_to_cart, purchase) is essential to confirm genuine interest versus low-quality traffic.'
  

    /* ================= SCROLL - BOTH POSITIVE AND NEGATIVE ================= */
    -- Placeholder for scroll root causes
    WHEN e.event_name = 'scroll'
  AND e.deviation_pct < 0
  AND e.deviation_pct <= -0.85
  THEN 'A collapse exceeding 85% in scroll events indicates structural content loading failures or scroll tracking instrumentation breakdown, not user disinterest. The most common cause is lazy-loading or infinite scroll implementation failures, where JavaScript errors prevent additional content from rendering as users scroll—causing users to reach the "end" of perceived content prematurely, even though more exists below. Another frequent cause is scroll event listener detachment, often occurring after DOM manipulation by third-party scripts (consent banners, chat widgets, A/B testing tools) that remove or block scroll event propagation. Intersection Observer API misconfigurations can also suppress scroll tracking, particularly when threshold values are set incorrectly or when polyfills fail on older browsers. Critical performance regressions—especially Total Blocking Time >1000ms—can prevent scroll handlers from executing, even though users are technically scrolling.'

WHEN e.event_name = 'scroll'
  AND e.deviation_pct < 0
  AND e.deviation_pct > -0.85
  AND e.deviation_pct <= -0.65
  THEN 'This range typically reflects partial scroll suppression, where tracking works for some users or page types but fails for others. Common causes include mobile-specific scroll failures, where fixed headers, sticky "Add to Cart" bars, or bottom sheet modals intercept scroll events or reduce scrollable viewport height to near-zero. Another frequent trigger is SPA route transition issues, where scroll position restoration fails or scroll event listeners are not reattached after client-side navigation between category pages, PDPs, and cart. Content changes that drastically reduce page length—such as removing long product descriptions, collapsing size guides into hidden accordions, or consolidating multi-section PDPs into minimalist layouts—can legitimately reduce scroll counts without representing engagement loss.'

WHEN e.event_name = 'scroll'
  AND e.deviation_pct < 0
  AND e.deviation_pct > -0.65
  AND e.deviation_pct <= -0.40
  THEN 'Moderate scroll declines often indicate above-the-fold content optimization or layout changes that reduce scroll necessity rather than engagement loss. This frequently follows "mobile-first" redesigns where critical elements (product images, prices, add-to-cart buttons, shipping badges) are moved higher, reducing the need to scroll for key information. Front-loading trust signals, customer reviews, and primary CTAs can improve conversions while suppressing scroll events. Another common cause is homepage or category page simplification, where multi-section layouts (featured products, seasonal banners, blog carousels, social proof widgets) are condensed into focused hero sections with prominent search bars, reducing exploratory scrolling but potentially improving direct product discovery.'

WHEN e.event_name = 'scroll'
  AND e.deviation_pct > 0
  AND e.deviation_pct >= 0.95
  THEN 'Extreme scroll spikes (>95%) almost always indicate instrumentation errors, not genuine engagement uplift. The most common cause is infinite scroll event loops, where poorly implemented scroll listeners fire continuously during single scroll actions—often due to missing debounce/throttle logic (should limit to 1 event per 100-200ms) or scroll position calculation errors that reset improperly on dynamic content injection. Another frequent cause is programmatic scrolling triggering event listeners, such as "Back to Top" buttons, smooth-scroll anchor navigation to product details/reviews, or image carousel auto-advance features inadvertently firing scroll events as if users initiated them. Bot traffic can also inflate scroll counts, particularly when automated testing frameworks (Selenium, Puppeteer) or scrapers simulate user scrolling to trigger lazy-loaded product images and pricing.'

WHEN e.event_name = 'scroll'
  AND e.deviation_pct > 0
  AND e.deviation_pct < 0.95
  AND e.deviation_pct >= 0.75
  THEN 'This deviation band often reflects scroll tracking configuration changes rather than user behavior changes. Common causes include scroll depth threshold modifications in GTM/GA4 (e.g., changing from default 90% single-fire to 25/50/75/90% multi-fire intervals), which artificially inflates event counts by 4x without actual behavior change. Another trigger is A/B testing tools or personalization engines (Dynamic Yield, Optimizely) inserting dynamic content sections (recommended products, social proof banners, email capture modals) that increase page length significantly, causing more scroll depth milestones to be crossed per user without necessarily increasing meaningful engagement quality.'

WHEN e.event_name = 'scroll'
  AND e.deviation_pct > 0
  AND e.deviation_pct < 0.75
  AND e.deviation_pct >= 0.50
  THEN 'Moderate positive scroll increases can represent legitimate content engagement improvements, such as successful blog posts with detailed buying guides, expanded product descriptions with rich media (videos, 360° views, styling lookbooks), or interactive content (size finders, product configurators, comparison tools) that encourage deeper exploration. However, validation against session duration, pages per session, and conversion metrics is essential—scroll inflation without corresponding time-on-page increases or action completions suggests technical causes (duplicate events, bots) rather than behavioral improvements.'

    ELSE 'No dominant root cause identified'
  END AS suspected_root_cause,

  /* =====================================================
     RECOMMENDED ACTIONS (EXACTLY 2, HUMAN FRIENDLY)
     ===================================================== */
  CASE
    /* ================= PURCHASE - NEGATIVE ONLY ================= */
    WHEN e.event_name = 'purchase'
      AND e.deviation_pct < 0
      AND e.deviation_pct <= -0.90
      THEN ['Geo and Device Segmentation Analysis: Break down purchase success and failure rates by country, region, device category, and browser to identify whether the collapse is localized. A sharp revenue drop limited to one geography or device class strongly indicates gateway, browser compatibility, or regional compliance issues.', 'Checkout Regression Testing: Run full end-to-end checkout tests across affected regions and devices, focusing on coupon application, tax calculation, address validation, and payment redirection. Pay special attention to recent changes in payment provider SDK versions or iframe embedding logic.']

    WHEN e.event_name = 'purchase'
      AND e.deviation_pct < 0
      AND e.deviation_pct > -0.90
      AND e.deviation_pct <= -0.60
      THEN ['Checkout Funnel Drop-off Analysis: Analyze step-level funnel metrics (begin_checkout → add_payment_info → purchase) to identify the precise abandonment point. A sharp drop at add_payment_info or purchase confirms late-stage friction rather than traffic or product issues.', 'Recent Deployment Review: Audit all checkout-related releases deployed in the last 24 to 72 hours, including pricing logic, discount rules, shipping calculation, payment SDK updates, and fraud-rule changes. Roll back high-risk changes if correlation is strong.']

    WHEN e.event_name = 'purchase'
      AND e.deviation_pct < 0
      AND e.deviation_pct > -0.60
      AND e.deviation_pct <= -0.45
      THEN ['Campaign-to-Checkout Alignment Review: Verify that active marketing campaigns correctly reflect product availability, pricing, discounts, and delivery timelines. Ensure landing pages route users into valid, purchasable product flows.', 'Traffic Quality Diagnostics: Segment revenue by traffic source, campaign, and medium to identify channels with disproportionate conversion collapse. Pause or optimize low-quality sources until conversion stability returns.']

    WHEN e.event_name = 'purchase'
      AND e.deviation_pct < 0
      AND e.deviation_pct > -0.45
      AND e.deviation_pct <= -0.30
      THEN ['Performance and UX Review: Evaluate Core Web Vitals (LCP, CLS, INP) for checkout and confirmation pages. Even small degradations can significantly impact revenue at scale, especially on mobile networks.', 'Customer Feedback Scan: Review customer support tickets, chat transcripts, NPS feedback, and social media mentions for emerging complaints related to checkout experience, pricing surprises, or payment reliability.']

    /* ================= ADD_TO_CART - NEGATIVE ONLY ================= */
    WHEN e.event_name = 'add_to_cart'
      AND e.deviation_pct < 0
      AND e.deviation_pct <= -0.80
      THEN ['Pricing & Promotion Consistency Check: Compare prices displayed on product listing pages (PLP), PDPs, and cart previews to ensure consistency. Investigate whether discount logic, coupon stacking rules, or currency rounding changes have introduced unexpected price jumps.', 'Product Page Content Validation: Audit PDPs for broken images, missing descriptions, incorrect variant defaults, or misleading stock messages. Even minor content regressions can suppress add-to-cart behavior at scale.']

    WHEN e.event_name = 'add_to_cart'
      AND e.deviation_pct < 0
      AND e.deviation_pct > -0.80
      AND e.deviation_pct <= -0.60
      THEN ['Traffic Source Quality Analysis: Segment add-to-cart rates by source, medium, and campaign to identify channels contributing disproportionate low-intent traffic. Look for spikes in impressions or clicks without corresponding engagement depth.', 'Landing Page Relevance Review: Ensure that campaign landing pages align with user expectations set by ads—product category, pricing, availability, and offer clarity should be consistent to avoid immediate disengagement.']

    WHEN e.event_name = 'add_to_cart'
      AND e.deviation_pct < 0
      AND e.deviation_pct > -0.60
      AND e.deviation_pct <= -0.40
      THEN ['Performance & Speed Diagnostics: Review Core Web Vitals (especially LCP and INP) for product pages. Small performance regressions can significantly suppress cart initiation, particularly on mobile networks.', 'Competitive Benchmark Review: Compare pricing, delivery timelines, and promotions against key competitors during the anomaly window. External market shifts can explain gradual cart engagement erosion.']

    /* ================= ADD_PAYMENT_INFO - NEGATIVE ONLY ================= */
    WHEN e.event_name = 'add_payment_info'
      AND e.deviation_pct < 0
      AND e.deviation_pct <= -0.90
      THEN ['Device & Payment Method Segmentation: Segment add_payment_info events by device category and payment method to identify disproportionate drops. Focus on mobile-only failures and payment options introduced or modified recently (e.g., UPI mandates, BNPL rollouts).', 'Checkout Transparency Review: Audit the checkout UI for last-minute cost additions or policy changes (shipping, tax, COD fees). Compare pre- and post-release checkout screenshots to identify elements that may have triggered user distrust or confusion.']

    WHEN e.event_name = 'add_payment_info'
      AND e.deviation_pct < 0
      AND e.deviation_pct > -0.90
      AND e.deviation_pct <= -0.60
      THEN ['Form Interaction & Accessibility Audit: Test checkout flows using keyboard navigation, screen readers, and mobile input methods. Verify that all fields accept input correctly, error messages are visible and actionable, and autofill works as expected.', 'Session Replay Analysis: Review session recordings (Hotjar, FullStory, Clarity) for checkout abandonment sessions to observe where users hesitate, retry inputs repeatedly, or exit without submitting payment information.']

    WHEN e.event_name = 'add_payment_info'
      AND e.deviation_pct < 0
      AND e.deviation_pct > -0.60
      AND e.deviation_pct <= -0.40
      THEN ['Price & Delivery Expectation Validation: Verify that delivery timelines, return policies, and payment assurances (refunds, COD availability) are clearly communicated at checkout. Minor ambiguities can cause users to pause at the payment stage.', 'Checkout Incentive Review: Evaluate whether checkout-stage incentives (free shipping thresholds, limited-time discounts) were removed or expired shortly before the anomaly window.']

    /* ================= PAGE_VIEW - BOTH POSITIVE AND NEGATIVE ================= */
    WHEN e.event_name = 'page_view'
      AND e.deviation_pct < 0
      AND e.deviation_pct <= -0.75
      THEN ['Tracking Infrastructure Verification: Use Google Tag Assistant and GA4 DebugView to load multiple landing pages across environments (desktop, mobile, incognito). Confirm that the GA4 configuration tag fires on page load and that page_view events reach GA4 in real time, especially on templates deployed most recently.', 'Traffic Source Health Audit: Review Google Ads, Meta Ads, and affiliate dashboards for campaign pauses, disapproved ads, budget exhaustion, or broken final URLs. Cross-check timestamp alignment between campaign stoppage and page_view drop to isolate acquisition-side failures.']

    WHEN e.event_name = 'page_view'
      AND e.deviation_pct < 0
      AND e.deviation_pct > -0.75
      AND e.deviation_pct <= -0.50
      THEN ['Channel-Level Traffic Decomposition: Segment page_view data by default channel grouping and geo. Identify which channels (organic, paid, referral, direct) contribute most to the drop and validate against external tools like Google Search Console and ad platform logs.', 'Consent & Geo Behavior Review: Audit consent management behavior across regions. Verify whether GA4 tags fire in denied consent states using Consent Mode v2 rather than being completely blocked, particularly for EU traffic.']

    WHEN e.event_name = 'page_view'
      AND e.deviation_pct < 0
      AND e.deviation_pct > -0.50
      AND e.deviation_pct <= -0.35
      THEN ['Marketing Change Correlation: Review campaign change logs, bid adjustments, and content updates deployed within the last 7 to 14 days. Identify whether traffic loss aligns with intentional spend optimization or unintentional deactivation.', 'Landing Page Availability Check: Crawl top landing pages using automated tools or manual spot checks to ensure they return HTTP 200 and are indexable, accessible, and internally linked.']

    WHEN e.event_name = 'page_view'
      AND e.deviation_pct > 0
      AND e.deviation_pct >= 0.90
      THEN ['Bot & User Pattern Analysis: Segment page_view volume by user_pseudo_id and IP/ASN (if available). Look for users generating hundreds of page views per session, unusually short session durations, or identical navigation paths repeated at scale.', 'Event Deduplication Validation: Inspect GA4 implementation for duplicate page_view triggers—particularly in SPA frameworks (React/Vue/Next.js). Ensure page_view fires only on meaningful route changes, not on every state update or re-render.']

    WHEN e.event_name = 'page_view'
      AND e.deviation_pct > 0
      AND e.deviation_pct < 0.90
      AND e.deviation_pct >= 0.60
      THEN ['Campaign Attribution Validation: Confirm whether any marketing activations, influencer posts, email blasts, or app push notifications occurred during the anomaly window. Validate that traffic sources align with expected campaign channels.', 'Referral & Source Quality Review: Inspect referral domains and landing pages. Sudden surges from obscure domains or single referrers often indicate spam or automated scraping rather than real demand.']

    WHEN e.event_name = 'page_view'
      AND e.deviation_pct > 0
      AND e.deviation_pct < 0.60
      AND e.deviation_pct >= 0.45
      THEN ['Engagement Correlation Check: Compare page_view growth against user_engagement, session_start, and add_to_cart. Genuine traffic growth should lift downstream metrics; divergence suggests low-quality traffic.', 'Trend Stability Monitoring: Monitor whether elevated traffic sustains over multiple days. Organic growth tends to stabilize; artificial spikes decay rapidly.']

    /* ================= SESSION_START - BOTH POSITIVE AND NEGATIVE ================= */
    WHEN e.event_name = 'session_start'
      AND e.deviation_pct < 0
      AND e.deviation_pct <= -0.75
      THEN ['Consent Mode & CMP Audit: Inspect Cookiebot / OneTrust / custom CMP configurations to verify that GA4 runs in denied consent mode rather than being fully blocked. Validate session_start firing behavior in restricted regions using incognito + VPN testing.', 'Redirect Chain Validation: Trace entry URLs for major landing pages and campaign URLs. Ensure that redirects preserve GA4 parameters and do not reload the page before session_start can be registered.']

    WHEN e.event_name = 'session_start'
      AND e.deviation_pct < 0
      AND e.deviation_pct > -0.75
      AND e.deviation_pct <= -0.45
      THEN ['Device & Browser Segmentation: Break down session_start counts by device_category and browser. Look for asymmetric drops (e.g., iOS Safari collapsing while Chrome remains stable).', 'GTM Trigger Dependency Review: Audit session_start-related triggers in GTM to ensure they are not dependent on page elements, CSS selectors, or custom JS conditions that may have changed during frontend releases.']

    WHEN e.event_name = 'session_start'
      AND e.deviation_pct < 0
      AND e.deviation_pct > -0.45
      AND e.deviation_pct <= -0.25
      THEN ['Attribution Parameter Consistency Check: Compare current UTM structures against historical baselines. Ensure session_start is not suppressed due to missing or malformed campaign parameters.', 'Session Timeout Configuration Review: Validate GA4 session timeout settings. Aggressive timeouts or misconfigured engagement_time logic can suppress new session creation.']

    WHEN e.event_name = 'session_start'
      AND e.deviation_pct > 0
      AND e.deviation_pct >= 0.80
      THEN ['Session Timeout Configuration Review: Validate GA4 session timeout settings. Aggressive timeouts or misconfigured engagement_time logic can suppress new session creation.', 'Cross-Domain Linking Audit: Validate that GA4 linker parameters are properly implemented between domains (e.g., checkout, payment, blog subdomains) to prevent session resets.']

    WHEN e.event_name = 'session_start'
      AND e.deviation_pct > 0
      AND e.deviation_pct < 0.80
      AND e.deviation_pct >= 0.55
      THEN ['SPA Lifecycle Inspection: Review frontend routing logic to ensure session_start fires only once per real session, not on every route transition or state update.', 'Session-to-User Ratio Check: Analyze sessions per user. Values >3–4 in short timeframes usually indicate technical inflation rather than behavioral change.']

    WHEN e.event_name = 'session_start'
      AND e.deviation_pct > 0
      AND e.deviation_pct < 0.55
      AND e.deviation_pct >= 0.35
      THEN ['Downstream Metric Correlation: Validate whether page_view, user_engagement, and add_to_cart increase proportionally. If not, session inflation is likely technical.', 'Short-Term Persistence Monitoring: Track whether elevated session levels normalize within 1–2 days. True behavioral uplift persists; technical spikes decay quickly.']

    /* ================= USER_ENGAGEMENT - BOTH POSITIVE AND NEGATIVE ================= */
    WHEN e.event_name = 'user_engagement'
      AND e.deviation_pct < 0
      AND e.deviation_pct <= -0.85
      THEN ['Performance & CWV Diagnostics: Pull Lighthouse and CrUX reports for affected URLs. Focus on LCP, CLS, and Total Blocking Time. Correlate deployment timestamps with engagement collapse to identify regression-causing releases.', 
'Instrumentation Integrity Validation: Use GA4 DebugView and Tag Assistant to verify that engagement_time_msec is incrementing during active page usage. Confirm that GA4 config tags fire before heavy JS bundles and are not gated behind consent or DOM-ready dependencies.']

    WHEN e.event_name = 'user_engagement'
      AND e.deviation_pct < 0
      AND e.deviation_pct > -0.85
      AND e.deviation_pct <= -0.60
      THEN ['Device & Viewport UX Audit: Test top landing pages across mobile breakpoints. Inspect z-index conflicts, sticky banners, and modal overlays that may intercept clicks or prevent scrolling.', 
'Engagement Event Fire Testing: Manually test scroll depth, click, and interaction tracking in GA4 DebugView to ensure engagement events fire when users interact, particularly on mobile browsers.']

    WHEN e.event_name = 'user_engagement'
      AND e.deviation_pct < 0
      AND e.deviation_pct > -0.60
      AND e.deviation_pct <= -0.35
      THEN ['Above-the-Fold Content Review: Compare pre- and post-change layouts to ensure primary CTAs, value propositions, and navigation remain visible without scrolling.', 
'Heatmap & Scroll Analysis: Use tools like Hotjar or Microsoft Clarity to identify where users stop scrolling or fail to click. Validate whether engagement drop aligns with visual hierarchy changes.']

    WHEN e.event_name = 'user_engagement'
      AND e.deviation_pct > 0
      AND e.deviation_pct >= 0.90
      THEN ['Bot & Automation Segmentation: Segment engagement by user_pseudo_id and session duration. Identify patterns such as thousands of users with identical engagement times or abnormal interaction frequency.', 
'SPA Engagement Logic Audit: Inspect frontend engagement tracking to ensure timers reset correctly on route changes and do not accumulate across virtual pageviews.']

    WHEN e.event_name = 'user_engagement'
      AND e.deviation_pct > 0
      AND e.deviation_pct < 0.90
      AND e.deviation_pct >= 0.70
      THEN ['Visibility API Validation: Confirm that engagement timers sure pause when tabs are inactive or backgrounded. Validate Page Visibility API implementation.', 
'Session Duration Distribution Check: Analyze session duration histograms. Long-tail spikes (e.g., many sessions >60 minutes) usually indicate technical inflation.']

    WHEN e.event_name = 'user_engagement'
      AND e.deviation_pct > 0
      AND e.deviation_pct < 0.70
      AND e.deviation_pct >= 0.45
      THEN ['Funnel Correlation Check: Verify whether increases in engagement translate into higher add_to_cart, add_payment_info, or purchase events. If not, engagement is likely artificial.', 
'Content Attribution Review: Identify top URLs driving engagement uplift. Validate whether content updates, SEO gains, or campaigns justify the increase.']

    /* ================= BEGIN_CHECKOUT - NEGATIVE ONLY ================= */
    -- Placeholder for begin_checkout recommendations
   WHEN e.event_name = 'begin_checkout'
  AND deviation_pct < 0
  AND deviation_pct <= -0.85
  THEN ['Cart Page Button & Flow Functionality Testing: Manually test "Proceed to Checkout" button functionality across all major browsers (Chrome, Safari, Firefox, Edge) and devices (iPhone, Android, desktop) using both guest and logged-in user sessions. Verify button click handlers execute correctly in browser DevTools, checkout pages load without 404/500 errors, and no JavaScript console errors appear related to cart serialization or checkout API calls.', 'Session & Cart State Persistence Validation: Review cart-to-checkout transition logic by tracing session IDs, cart tokens, and localStorage/sessionStorage values before and after checkout button clicks. Verify cart data persists correctly across domain transitions (www → checkout subdomain), cookie SameSite attributes allow cross-site cart sharing, and session timeout windows align between cart and checkout services. Test edge cases like cart abandonment >30 minutes, browser back-button navigation, and multi-tab cart editing.']

WHEN e.event_name = 'begin_checkout'
  AND deviation_pct < 0
  AND deviation_pct > -0.85
  AND deviation_pct <= -0.65
  THEN ['Device & User Segment Breakdown Analysis: Break down begin_checkout events by device_category (mobile, desktop, tablet), user_type (new vs. returning, guest vs. logged-in), cart_value buckets, and geographic region to identify disproportionately affected groups. A sharp decline limited to mobile iOS or carts above certain value thresholds strongly indicates UI rendering issues, cart value validation bugs, or region-specific checkout access restrictions.', 'Pre-Checkout Validation & Gate Logic Review: Audit all validation rules that execute before granting checkout access—inventory availability re-checks, minimum/maximum order value enforcement, shipping zone eligibility, product restriction checks (age-gated, prescription, geo-blocked items). Test these rules with various cart compositions (single item, bulk orders, mixed categories) to verify they are not incorrectly blocking legitimate checkout attempts. Review recent changes to guest checkout availability and mandatory login requirements.']

WHEN e.event_name = 'begin_checkout'
  AND deviation_pct < 0
  AND deviation_pct > -0.65
  AND deviation_pct <= -0.35
  THEN ['Cart Page Transparency & Cost Disclosure Audit: Review cart page content for unexpected cost additions, shipping timeline changes, return policy disclosures, or subscription upsell prompts introduced in recent releases. Compare pre- and post-deployment cart page screenshots to identify elements that may trigger price shock, delivery expectation mismatches, or purchase hesitation. Verify that all costs visible at cart match or are lower than those previewed on PDPs.', 'Promotional Code UX & Visibility Review: Verify that promotional code entry fields remain visible and prominently positioned on the cart page (not hidden in collapsed accordions or moved to later checkout steps). Test code validation logic with 10-15 active and expired codes to ensure valid codes apply correctly, invalid codes show clear error messages, and auto-applied codes display confirmation messaging. Check whether code entry field placement aligns with customer expectations set by marketing campaigns.']
  

    /* ================= VIEW_ITEM - BOTH POSITIVE AND NEGATIVE ================= */
    -- Placeholder for view_item recommendations
    WHEN e.event_name = 'view_item'
  AND e.deviation_pct < 0
  AND e.deviation_pct <= -0.80
  THEN ['Product Catalog & Feed Validation: Verify that product data feeds from PIM/ERP systems are syncing correctly by checking API logs for authentication failures, timeout errors, or schema mismatches. Manually test 20-30 top-selling product URLs across desktop and mobile to ensure PDPs load with complete data (images, prices, descriptions, variant selectors). Focus on recently updated or newly imported product batches.', 'Search & Navigation Infrastructure Audit: Test site search functionality end-to-end by executing 10-15 high-volume search queries and verifying result quality. Check search provider dashboards (Algolia, Elasticsearch) for index sync status, API rate limit warnings, and query error rates. Validate that category filters, faceted navigation, and sort options return expected product sets without 5xx errors.']

WHEN e.event_name = 'view_item'
  AND e.deviation_pct < 0
  AND e.deviation_pct > -0.80
  AND e.deviation_pct <= -0.55
  THEN ['Device & Category Segmentation Analysis: Break down view_item events by device_category (mobile, desktop, tablet), product_category, and brand to identify whether the drop is isolated to specific segments. A sharp decline limited to mobile or certain product lines strongly indicates rendering issues, variant selection bugs, or category-specific data quality problems.', 'PDP Rendering & Performance Testing: Load top 20 PDPs on actual mobile devices (iOS Safari, Android Chrome) and slower networks (3G throttling). Verify that product images render within 2 seconds, variant selectors function correctly, and view_item events fire in GA4 DebugView. Check for JavaScript errors blocking event tracking or lazy-loading failures preventing content display.']

WHEN e.event_name = 'view_item'
  AND e.deviation_pct < 0
  AND e.deviation_pct > -0.55
  AND e.deviation_pct <= -0.30
  THEN ['Homepage & PLP Layout Review: Compare pre- and post-deployment homepage and category page layouts using screenshots or session recordings. Ensure primary product discovery paths (hero product carousels, "Best Sellers" grids, category navigation menus) remain prominent above the fold and accessible without excessive scrolling or clicks.', 'Search Quality & Autocomplete Validation: Test search autocomplete for top 20 product queries to verify relevance ranking, synonym handling, and result accuracy. Review recent algorithm changes, search weight adjustments, or filter configurations that may be suppressing expected products. Check whether zero-result queries increased sharply in the anomaly window.']

WHEN e.event_name = 'view_item'
  AND e.deviation_pct > 0
  AND e.deviation_pct >= 0.90
  THEN ['Event Deduplication & SPA Logic Audit: Inspect view_item implementation in GTM/GA4 to ensure it fires only once per unique PDP load, not on variant color changes, size selections, image zoom interactions, or quick-view modal opens. Test on React/Vue/Next.js applications where client-side routing can trigger false positives during state updates.', 'Bot Traffic & Crawler Analysis: Segment view_item volume by user_pseudo_id, session_id, and user-agent to identify users generating hundreds of product views per session with zero add_to_cart events or sub-second page durations. Review server access logs for automated scraping patterns (sequential product ID crawling, predictable URL structures, high request rates from single IP ranges).']

WHEN e.event_name = 'view_item'
  AND e.deviation_pct > 0
  AND e.deviation_pct < 0.90
  AND e.deviation_pct >= 0.65
  THEN ['Campaign Attribution & Source Validation: Verify whether marketing activations (influencer posts, email product drops, social media ads, affiliate promotions) occurred during the spike window by checking campaign calendars and UTM-tagged traffic volumes. Validate that traffic sources align with expected channels and that landing page URLs resolve correctly.', 'Funnel Conversion Correlation: Compare view_item growth against add_to_cart rate, average order value, and purchase conversion. Genuine product interest should drive proportional downstream conversions; flat or declining add_to_cart rates despite view_item spikes suggest low-quality traffic, bot activity, or instrumentation duplication.']

WHEN e.event_name = 'view_item'
  AND e.deviation_pct > 0
  AND e.deviation_pct < 0.65
  AND e.deviation_pct >= 0.40
  THEN ['Merchandising Effectiveness Review: Identify top product URLs and categories driving view_item uplift using GA4 product performance reports. Validate whether recent homepage hero features, email campaign product recommendations, or PLP layout changes (new sorting defaults, filter presets) successfully increased product discovery.', 'Traffic Quality & Intent Monitoring: Ensure elevated view_item levels convert proportionally by segmenting by traffic source and analyzing bounce rates, time on PDP, scroll depth, and add_to_cart rates. Monitor new traffic segments (new referral domains, geographic regions, device types) to confirm genuine shopping intent versus curiosity browsing.']

    /* ================= SCROLL - BOTH POSITIVE AND NEGATIVE ================= */
    -- Placeholder for scroll recommendations
    WHEN e.event_name = 'scroll'
  AND e.deviation_pct < 0
  AND e.deviation_pct <= -0.85
  THEN ['Scroll Tracking & Lazy Loading Validation: Test scroll behavior on top 10 landing pages (homepage, top category pages, best-selling PDPs) using Chrome DevTools with network throttling. Verify that lazy-loaded product images, review sections, and "You May Also Like" carousels render as expected when scrolling. Check browser console for JavaScript errors related to IntersectionObserver, scroll event listeners, or lazy-load library failures (lozad.js, react-lazyload).', 'Third-Party Script Conflict Analysis: Temporarily disable non-essential third-party scripts (live chat, exit-intent popups, A/B testing, heatmap tools) in a staging environment to identify whether they are blocking scroll event propagation or detaching listeners. Review timing of consent manager initialization and verify it does not prevent scroll tracking before user consent is granted.']

WHEN e.event_name = 'scroll'
  AND e.deviation_pct < 0
  AND e.deviation_pct > -0.85
  AND e.deviation_pct <= -0.65
  THEN ['Device & Page Type Segmentation: Break down scroll event data by device_category (mobile, desktop, tablet), page_type (homepage, category, product, cart), and browser to identify whether declines are isolated to specific segments. A sharp drop limited to mobile iOS or specific page templates strongly indicates viewport calculation errors, sticky element conflicts, or route-specific listener failures.', 'SPA Scroll Restoration & Listener Testing: For React/Vue/Next.js sites, verify that scroll event listeners reattach correctly after client-side navigation by testing multi-page journeys (homepage → category → PDP → cart) in GA4 DebugView. Ensure scroll position restoration does not interfere with event firing and that history.pushState transitions do not orphan listeners.']

WHEN e.event_name = 'scroll'
  AND e.deviation_pct < 0
  AND e.deviation_pct > -0.65
  AND e.deviation_pct <= -0.40
  THEN ['Above-the-Fold Content & Layout Audit: Review recent PDP, category page, and homepage redesigns by comparing before/after screenshots or video recordings. Verify that scroll reduction is intentional (improved information hierarchy, front-loaded CTAs) by checking whether conversion rates (add_to_cart, purchase) have remained stable or improved despite reduced scrolling.', 'Scroll vs. Conversion Correlation Analysis: Compare scroll event trends against key funnel metrics (view_item, add_to_cart, begin_checkout) by day. If conversions remain stable or improve while scroll declines, the reduction likely reflects successful UX optimization (less friction, clearer CTAs). If conversions decline proportionally, investigate whether critical content (size charts, shipping info, reviews) has been hidden or removed.']

WHEN e.event_name = 'scroll'
  AND e.deviation_pct > 0
  AND e.deviation_pct >= 0.95
  THEN ['Scroll Event Implementation & Debounce Audit: Inspect scroll tracking code in GTM/GA4 for missing throttle/debounce logic (should limit to max 1 event per 100-200ms). Verify that scroll depth thresholds fire only once per milestone (25%, 50%, 75%, 90%) rather than continuously. Test on multiple browsers (Chrome, Safari, Firefox) and devices (iPhone, Android, desktop) to identify platform-specific over-firing.', 'Programmatic Scroll & Auto-Behavior Detection: Review all auto-scroll features (smooth scroll to product reviews on CTA click, carousel auto-play, modal scroll-to-top on open, sticky header collapse animations) to ensure they do not inadvertently trigger scroll event listeners. Implement user-initiated vs. programmatic scroll differentiation in tracking logic using event.isTrusted or custom flags.']

WHEN e.event_name = 'scroll'
  AND e.deviation_pct > 0
  AND e.deviation_pct < 0.95
  AND e.deviation_pct >= 0.75
  THEN ['Scroll Depth Threshold Configuration Review: Audit GA4/GTM scroll tracking setup to verify depth thresholds have not changed recently (check GTM version history and workspace changes). Compare current implementation (e.g., 10/20/30/40/50/60/70/80/90%) against historical baseline (e.g., 90% only) to identify configuration drift that would artificially inflate event counts.', 'Dynamic Content & A/B Test Impact Analysis: Identify whether recent content management updates (added "Shop the Look" sections, expanded review modules, new shipping/return policy accordions) or active A/B tests have legitimately increased page length. Segment scroll events by experiment variant to isolate whether increases are limited to test groups receiving longer content.']

WHEN e.event_name = 'scroll'
  AND e.deviation_pct > 0
  AND e.deviation_pct < 0.75
  AND e.deviation_pct >= 0.50
  THEN ['Content Engagement & Attribution Validation: Identify top pages and URL paths driving scroll uplift using GA4 Engagement reports filtered by scroll event count. Review recent content updates (new blog posts, buying guides, product videos, interactive size finders) to determine whether increased scrolling reflects genuine interest in deeper content or technical inflation.', 'Session Quality & Funnel Correlation Check: Validate whether increased scroll events correlate with longer average session duration, higher pages per session, and improved conversion rates (view_item → add_to_cart). If downstream metrics remain flat despite scroll increases, the uplift likely represents technical duplication or bot activity rather than authentic engagement gains.']

    ELSE ['NA', 'NA']
  END AS recommended_actions

FROM `tvc-ecommerce.analytics_live.ga4_anomaly_enriched_all_events` e
INNER JOIN `tvc-ecommerce.analytics_live.metric_config` mc
  ON e.event_name = mc.event_name
WHERE e.event_date = DATE_SUB(CURRENT_DATE('Asia/Kolkata'), INTERVAL 1 DAY)
  AND mc.is_enabled = true;