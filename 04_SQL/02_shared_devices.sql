-- ============================================================
-- FRAUD SIGNAL: Shared Device Detection
-- Category: Device Fraud / Multi-Account
-- Signal ID: DEV-001
-- Logic: Multiple distinct accounts (drivers or customers) are
--        associated with the same device fingerprint
-- Threshold: 3+ distinct entity accounts on one device
-- False Positive Mitigations:
--   - Family members sharing a device (apply same-address check)
--   - Platform device for support staff (whitelist by employer)
-- ============================================================

-- Query 1: Drivers Sharing Devices
SELECT
    le.device_id,
    dev.device_fingerprint,
    dev.device_type,
    dev.manufacturer,
    dev.model,
    dev.is_emulator,
    dev.is_rooted,
    COUNT(DISTINCT le.entity_id) AS accounts_on_device,
    STRING_AGG(DISTINCT d.first_name || ' ' || d.last_name, ', ' ORDER BY d.first_name || ' ' || d.last_name) AS driver_names,
    MIN(le.login_timestamp) AS first_seen,
    MAX(le.login_timestamp) AS last_seen,
    dev.risk_score AS device_risk_score
FROM login_events le
JOIN devices dev ON dev.device_id = le.device_id
JOIN drivers d ON d.driver_id = le.entity_id
WHERE le.entity_type = 'driver'
  AND le.login_timestamp >= NOW() - INTERVAL '90 days'
GROUP BY le.device_id, dev.device_fingerprint, dev.device_type,
         dev.manufacturer, dev.model, dev.is_emulator, dev.is_rooted, dev.risk_score
HAVING COUNT(DISTINCT le.entity_id) >= 3
ORDER BY accounts_on_device DESC;


-- Query 2: Cross-Type Sharing (Same Device Used by Both Driver and Customer)
SELECT
    le.device_id,
    dev.device_fingerprint,
    COUNT(DISTINCT le.entity_id) FILTER (WHERE le.entity_type = 'driver') AS driver_accounts,
    COUNT(DISTINCT le.entity_id) FILTER (WHERE le.entity_type = 'customer') AS customer_accounts,
    COUNT(DISTINCT le.entity_id) AS total_accounts,
    MIN(le.login_timestamp) AS first_login,
    MAX(le.login_timestamp) AS last_login,
    dev.is_emulator,
    dev.is_vpn_detected
FROM login_events le
JOIN devices dev ON dev.device_id = le.device_id
GROUP BY le.device_id, dev.device_fingerprint, dev.is_emulator, dev.is_vpn_detected
HAVING
    COUNT(DISTINCT le.entity_id) FILTER (WHERE le.entity_type = 'driver') >= 1
    AND COUNT(DISTINCT le.entity_id) FILTER (WHERE le.entity_type = 'customer') >= 1
    AND COUNT(DISTINCT le.entity_id) >= 4
ORDER BY total_accounts DESC;


-- Query 3: Device Farm Detection (High-volume device sharing across new accounts)
SELECT
    le.device_id,
    dev.manufacturer,
    dev.model,
    dev.os_version,
    COUNT(DISTINCT le.entity_id) AS total_accounts,
    COUNT(DISTINCT le.entity_id) FILTER (
        WHERE d.onboarding_date >= NOW() - INTERVAL '30 days'
    ) AS new_accounts_30d,
    ROUND(
        100.0 * COUNT(DISTINCT le.entity_id) FILTER (
            WHERE d.onboarding_date >= NOW() - INTERVAL '30 days'
        ) / NULLIF(COUNT(DISTINCT le.entity_id), 0)
    , 1) AS pct_new_accounts,
    SUM(d.total_earnings) AS combined_earnings
FROM login_events le
JOIN devices dev ON dev.device_id = le.device_id
LEFT JOIN drivers d ON d.driver_id = le.entity_id AND le.entity_type = 'driver'
GROUP BY le.device_id, dev.manufacturer, dev.model, dev.os_version
HAVING COUNT(DISTINCT le.entity_id) >= 5
   AND COUNT(DISTINCT le.entity_id) FILTER (
       WHERE d.onboarding_date >= NOW() - INTERVAL '30 days'
   ) >= 3
ORDER BY new_accounts_30d DESC;
