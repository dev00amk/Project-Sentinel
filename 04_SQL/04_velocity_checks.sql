-- ============================================================
-- FRAUD SIGNAL: Velocity Anomaly Detection
-- Category: Behavioral Fraud
-- Signal ID: BEH-001
-- Logic: Identify unusual spikes in transaction velocity that
--        exceed statistical norms for a given entity
-- ============================================================

-- Query 1: Order Velocity Spike (Driver completes implausible # of orders)
WITH driver_hourly_orders AS (
    SELECT
        driver_id,
        DATE_TRUNC('hour', order_placed_at) AS hour_bucket,
        COUNT(*) AS orders_in_hour,
        SUM(total_amount) AS revenue_in_hour
    FROM orders
    WHERE order_status = 'delivered'
      AND order_placed_at >= NOW() - INTERVAL '30 days'
    GROUP BY driver_id, DATE_TRUNC('hour', order_placed_at)
),
driver_avg AS (
    SELECT
        driver_id,
        AVG(orders_in_hour) AS avg_hourly_orders,
        STDDEV(orders_in_hour) AS stddev_hourly_orders,
        MAX(orders_in_hour) AS max_hourly_orders
    FROM driver_hourly_orders
    GROUP BY driver_id
)
SELECT
    dho.driver_id,
    d.first_name || ' ' || d.last_name AS driver_name,
    d.status,
    dho.hour_bucket,
    dho.orders_in_hour,
    ROUND(da.avg_hourly_orders::numeric, 1) AS avg_hourly,
    ROUND(da.stddev_hourly_orders::numeric, 2) AS stddev_hourly,
    ROUND((dho.orders_in_hour - da.avg_hourly_orders)
          / NULLIF(da.stddev_hourly_orders, 0), 1) AS z_score,
    dho.revenue_in_hour
FROM driver_hourly_orders dho
JOIN driver_avg da ON da.driver_id = dho.driver_id
JOIN drivers d ON d.driver_id = dho.driver_id
WHERE (dho.orders_in_hour - da.avg_hourly_orders)
      / NULLIF(da.stddev_hourly_orders, 0) > 3  -- 3+ standard deviations
  AND dho.orders_in_hour >= 8                   -- Physical minimum: 8 orders/hour is suspicious
ORDER BY z_score DESC;


-- Query 2: Refund Request Velocity (Customers abusing refunds)
SELECT
    cs.entity_id AS customer_id,
    c.email,
    c.registration_date,
    COUNT(*) AS refund_requests_30d,
    SUM(cs.resolution_amount) AS total_refunds_30d,
    COUNT(DISTINCT cs.order_id) AS distinct_orders_refunded,
    c.lifetime_orders,
    ROUND(100.0 * COUNT(DISTINCT cs.order_id) / NULLIF(c.lifetime_orders, 0), 1) AS refund_rate_pct,
    MAX(cs.opened_at) AS last_refund_request
FROM customer_support cs
JOIN customers c ON c.customer_id = cs.entity_id
WHERE cs.entity_type = 'customer'
  AND cs.resolution_type = 'refund'
  AND cs.opened_at >= NOW() - INTERVAL '30 days'
GROUP BY cs.entity_id, c.email, c.registration_date,
         c.lifetime_orders
HAVING COUNT(*) >= 5
   OR SUM(cs.resolution_amount) >= 200
ORDER BY total_refunds_30d DESC;


-- Query 3: Login Velocity (Account Takeover Pattern)
SELECT
    le.entity_type,
    le.entity_id,
    COUNT(*) AS total_logins_24h,
    COUNT(*) FILTER (WHERE le.login_success = FALSE) AS failed_logins_24h,
    COUNT(DISTINCT le.ip_address) AS distinct_ips,
    COUNT(DISTINCT le.device_id) AS distinct_devices,
    COUNT(DISTINCT LEFT(le.ip_address::text, POSITION('.' IN le.ip_address::text || '.') - 1)) AS distinct_asns_approx,
    BOOL_OR(le.is_vpn) AS any_vpn_login,
    BOOL_OR(le.is_tor) AS any_tor_login,
    MIN(le.login_timestamp) AS window_start,
    MAX(le.login_timestamp) AS window_end
FROM login_events le
WHERE le.login_timestamp >= NOW() - INTERVAL '24 hours'
GROUP BY le.entity_type, le.entity_id
HAVING
    COUNT(*) FILTER (WHERE le.login_success = FALSE) >= 5
    OR COUNT(DISTINCT le.ip_address) >= 4
    OR COUNT(DISTINCT le.device_id) >= 3
ORDER BY failed_logins_24h DESC;
