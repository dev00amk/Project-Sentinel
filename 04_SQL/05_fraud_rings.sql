-- ============================================================
-- FRAUD SIGNAL: Fraud Ring / Network Detection
-- Category: Network Fraud / Coordinated Fraud
-- Signal ID: NET-001
-- Logic: Identify clusters of accounts sharing multiple
--        identity signals (device, bank, address, phone prefix)
--        that indicate coordinated/organized fraud rings
-- ============================================================

-- Query 1: Shared Bank Account Detection
SELECT
    p.card_bin,
    p.card_last_four,
    p.bank_name,
    COUNT(DISTINCT p.customer_id) AS customers_sharing_payment,
    STRING_AGG(DISTINCT c.email, ', ' ORDER BY c.email) AS customer_emails,
    MIN(p.created_at) AS first_use,
    MAX(p.created_at) AS last_use,
    SUM(p.amount) AS total_amount_processed,
    COUNT(DISTINCT CASE WHEN p.is_chargeback THEN p.payment_id END) AS chargebacks
FROM payments p
JOIN customers c ON c.customer_id = p.customer_id
WHERE p.card_last_four IS NOT NULL
  AND p.card_bin IS NOT NULL
GROUP BY p.card_bin, p.card_last_four, p.bank_name
HAVING COUNT(DISTINCT p.customer_id) >= 3
ORDER BY customers_sharing_payment DESC;


-- Query 2: Shared Address Clustering (Driver Application Fraud)
SELECT
    d.zip_code,
    d.city,
    d.state,
    COUNT(*) AS drivers_at_location,
    COUNT(*) FILTER (WHERE d.status = 'active') AS active_drivers,
    COUNT(*) FILTER (WHERE d.status IN ('suspended', 'deactivated')) AS deactivated_drivers,
    COUNT(*) FILTER (
        WHERE d.onboarding_date >= NOW() - INTERVAL '30 days'
    ) AS new_drivers_30d,
    ROUND(AVG(d.risk_score), 2) AS avg_risk_score,
    SUM(d.total_earnings) AS combined_earnings
FROM drivers d
WHERE d.zip_code IS NOT NULL
GROUP BY d.zip_code, d.city, d.state
HAVING COUNT(*) >= 5
   AND COUNT(*) FILTER (
       WHERE d.onboarding_date >= NOW() - INTERVAL '30 days'
   ) >= 3
ORDER BY new_drivers_30d DESC;


-- Query 3: Coordinated GPS Spoofing Ring
-- Drivers who spoofed GPS at the same time window (within 10 min)
-- in the same geographic area — possible shared VPN/farm operation
WITH mocked_gps AS (
    SELECT
        g.driver_id,
        g.order_id,
        g.latitude,
        g.longitude,
        g.recorded_at,
        DATE_TRUNC('hour', g.recorded_at) AS hour_window
    FROM gps_logs g
    WHERE g.is_mocked = TRUE
      AND g.recorded_at >= NOW() - INTERVAL '30 days'
)
SELECT
    m1.hour_window,
    COUNT(DISTINCT m1.driver_id) AS simultaneous_spoofers,
    STRING_AGG(DISTINCT d.first_name || ' ' || d.last_name, ', ') AS driver_names,
    ROUND(AVG(m1.latitude)::numeric, 4) AS cluster_lat,
    ROUND(AVG(m1.longitude)::numeric, 4) AS cluster_lng,
    COUNT(DISTINCT m1.order_id) AS affected_orders
FROM mocked_gps m1
JOIN drivers d ON d.driver_id = m1.driver_id
GROUP BY m1.hour_window
HAVING COUNT(DISTINCT m1.driver_id) >= 3
ORDER BY simultaneous_spoofers DESC;


-- Query 4: Multi-Signal Ring Score (Composite Fraud Ring Score)
WITH device_overlap AS (
    SELECT le1.entity_id AS d1, le2.entity_id AS d2
    FROM login_events le1
    JOIN login_events le2 ON le1.device_id = le2.device_id
        AND le1.entity_id < le2.entity_id
        AND le1.entity_type = 'driver' AND le2.entity_type = 'driver'
    GROUP BY le1.entity_id, le2.entity_id
),
address_overlap AS (
    SELECT d1.driver_id AS d1, d2.driver_id AS d2
    FROM drivers d1
    JOIN drivers d2 ON d1.zip_code = d2.zip_code
        AND d1.driver_id < d2.driver_id
),
referral_overlap AS (
    SELECT referrer_id AS d1, referred_id AS d2
    FROM referrals
    WHERE referrer_type = 'driver' AND referred_type = 'driver'
)
SELECT
    COALESCE(de.d1, ao.d1, ro.d1) AS driver_1,
    COALESCE(de.d2, ao.d2, ro.d2) AS driver_2,
    (CASE WHEN de.d1 IS NOT NULL THEN 1 ELSE 0 END +
     CASE WHEN ao.d1 IS NOT NULL THEN 1 ELSE 0 END +
     CASE WHEN ro.d1 IS NOT NULL THEN 1 ELSE 0 END) AS overlap_signals,
    CASE WHEN de.d1 IS NOT NULL THEN 'YES' ELSE 'NO' END AS shared_device,
    CASE WHEN ao.d1 IS NOT NULL THEN 'YES' ELSE 'NO' END AS shared_address,
    CASE WHEN ro.d1 IS NOT NULL THEN 'YES' ELSE 'NO' END AS referral_link
FROM device_overlap de
FULL OUTER JOIN address_overlap ao ON de.d1 = ao.d1 AND de.d2 = ao.d2
FULL OUTER JOIN referral_overlap ro ON COALESCE(de.d1, ao.d1) = ro.d1
    AND COALESCE(de.d2, ao.d2) = ro.d2
WHERE (
    CASE WHEN de.d1 IS NOT NULL THEN 1 ELSE 0 END +
    CASE WHEN ao.d1 IS NOT NULL THEN 1 ELSE 0 END +
    CASE WHEN ro.d1 IS NOT NULL THEN 1 ELSE 0 END
) >= 2  -- At least 2 overlapping signals
ORDER BY overlap_signals DESC;
