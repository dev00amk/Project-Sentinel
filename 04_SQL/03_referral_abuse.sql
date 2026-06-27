-- ============================================================
-- FRAUD SIGNAL: Referral Abuse Detection
-- Category: Financial Fraud / Network Fraud
-- Signal ID: FIN-003
-- Logic: Identify drivers gaming referral bonus programs via
--        self-referrals, ring referrals, or fake activations
-- ============================================================

-- Query 1: Self-Referral Detection (Same Device / IP)
SELECT
    r.referrer_id,
    d_ref.first_name || ' ' || d_ref.last_name AS referrer_name,
    r.referred_id,
    d_rfd.first_name || ' ' || d_rfd.last_name AS referred_name,
    r.bonus_amount,
    r.status,
    r.created_at,
    -- Check if both accounts share a device
    CASE WHEN shared_device.device_id IS NOT NULL THEN TRUE ELSE FALSE END AS shares_device,
    -- Check if both accounts share an IP at registration
    CASE WHEN shared_ip.ip_address IS NOT NULL THEN TRUE ELSE FALSE END AS shares_registration_ip
FROM referrals r
JOIN drivers d_ref ON d_ref.driver_id = r.referrer_id
JOIN drivers d_rfd ON d_rfd.driver_id = r.referred_id
-- Device overlap check
LEFT JOIN (
    SELECT le1.entity_id AS id1, le2.entity_id AS id2, le1.device_id
    FROM login_events le1
    JOIN login_events le2 ON le1.device_id = le2.device_id
      AND le1.entity_id != le2.entity_id
      AND le1.entity_type = 'driver'
      AND le2.entity_type = 'driver'
) shared_device ON shared_device.id1 = r.referrer_id AND shared_device.id2 = r.referred_id
-- IP overlap check at first login
LEFT JOIN (
    SELECT le1.entity_id AS id1, le2.entity_id AS id2, le1.ip_address
    FROM login_events le1
    JOIN login_events le2 ON le1.ip_address = le2.ip_address
      AND le1.entity_id != le2.entity_id
      AND le1.entity_type = 'driver'
      AND le2.entity_type = 'driver'
    WHERE le1.login_timestamp = (
        SELECT MIN(login_timestamp) FROM login_events
        WHERE entity_id = le1.entity_id AND entity_type = 'driver'
    )
) shared_ip ON shared_ip.id1 = r.referrer_id AND shared_ip.id2 = r.referred_id
WHERE r.referrer_type = 'driver'
  AND (shared_device.device_id IS NOT NULL OR shared_ip.ip_address IS NOT NULL)
  AND r.bonus_paid = FALSE  -- Focus on unpaid to prevent loss
ORDER BY r.created_at DESC;


-- Query 2: Referral Ring Detection (Driver A refers B, B refers C, C refers A)
WITH referral_graph AS (
    SELECT
        referrer_id AS from_driver,
        referred_id AS to_driver,
        bonus_amount,
        status
    FROM referrals
    WHERE referrer_type = 'driver'
      AND referred_type = 'driver'
)
SELECT
    rg1.from_driver AS driver_a,
    da.first_name || ' ' || da.last_name AS driver_a_name,
    rg1.to_driver AS driver_b,
    db.first_name || ' ' || db.last_name AS driver_b_name,
    rg2.to_driver AS driver_c,
    dc.first_name || ' ' || dc.last_name AS driver_c_name,
    rg1.bonus_amount + rg2.bonus_amount + COALESCE(rg3.bonus_amount, 0) AS total_ring_bonus
FROM referral_graph rg1
JOIN referral_graph rg2 ON rg2.from_driver = rg1.to_driver
LEFT JOIN referral_graph rg3 ON rg3.from_driver = rg2.to_driver
    AND rg3.to_driver = rg1.from_driver  -- Completes the ring
JOIN drivers da ON da.driver_id = rg1.from_driver
JOIN drivers db ON db.driver_id = rg1.to_driver
JOIN drivers dc ON dc.driver_id = rg2.to_driver
WHERE rg3.from_driver IS NOT NULL  -- Only show completed rings
ORDER BY total_ring_bonus DESC;


-- Query 3: High-Volume Referrers (Suspicious Referral Count)
SELECT
    r.referrer_id,
    d.first_name || ' ' || d.last_name AS referrer_name,
    d.onboarding_date,
    d.status,
    COUNT(*) AS total_referrals,
    COUNT(*) FILTER (WHERE r.status = 'completed') AS completed_referrals,
    SUM(r.bonus_amount) FILTER (WHERE r.bonus_paid = TRUE) AS bonuses_paid,
    SUM(r.bonus_amount) FILTER (WHERE r.bonus_paid = FALSE) AS bonuses_pending,
    -- Red flag: referral-to-delivery ratio
    ROUND(COUNT(*)::decimal / NULLIF(d.total_deliveries, 0), 2) AS referrals_per_delivery,
    ROUND(SUM(r.bonus_amount)::decimal / NULLIF(d.total_earnings, 0), 3) AS bonus_to_earnings_ratio
FROM referrals r
JOIN drivers d ON d.driver_id = r.referrer_id
WHERE r.referrer_type = 'driver'
GROUP BY r.referrer_id, d.first_name, d.last_name, d.onboarding_date,
         d.status, d.total_deliveries, d.total_earnings
HAVING COUNT(*) >= 10
   OR SUM(r.bonus_amount) >= 2000
ORDER BY total_referrals DESC;
