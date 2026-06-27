-- ============================================================
-- FRAUD SIGNAL: Chargeback Abuse / Friendly Fraud
-- Category: Financial Fraud
-- Signal ID: FIN-004
-- Logic: Customers who file chargebacks at rates that suggest
--        deliberate abuse rather than legitimate disputes
-- ============================================================

-- Query 1: High-Risk Chargeback Customers
SELECT
    c.customer_id,
    c.email,
    c.registration_date,
    c.lifetime_orders,
    c.chargeback_count,
    ROUND(100.0 * c.chargeback_count / NULLIF(c.lifetime_orders, 0), 2) AS chargeback_rate_pct,
    SUM(cb.amount) AS total_chargeback_amount,
    COUNT(cb.chargeback_id) FILTER (WHERE cb.resolution = 'won') AS chargebacks_won,
    COUNT(cb.chargeback_id) FILTER (WHERE cb.resolution = 'lost') AS chargebacks_lost,
    COUNT(cb.chargeback_id) FILTER (WHERE cb.is_friendly_fraud = TRUE) AS confirmed_friendly_fraud,
    MAX(cb.filed_date) AS last_chargeback_date,
    c.risk_score
FROM customers c
JOIN chargebacks cb ON cb.customer_id = c.customer_id
GROUP BY c.customer_id, c.email, c.registration_date,
         c.lifetime_orders, c.chargeback_count, c.risk_score
HAVING
    100.0 * c.chargeback_count / NULLIF(c.lifetime_orders, 0) > 5  -- >5% CB rate
    OR c.chargeback_count >= 3
ORDER BY chargeback_rate_pct DESC;


-- Query 2: Chargeback Filed After Delivery Confirmed (Strongest Friendly Fraud Signal)
SELECT
    cb.chargeback_id,
    c.email AS customer_email,
    o.order_id,
    o.total_amount,
    o.order_delivered_at,
    cb.filed_date,
    EXTRACT(DAY FROM cb.filed_date - o.order_delivered_at::date) AS days_after_delivery,
    cb.reason_code,
    cb.reason_description,
    o.driver_id,
    d.first_name || ' ' || d.last_name AS driver_name,
    -- Check for GPS confirmation of delivery
    EXISTS (
        SELECT 1 FROM gps_logs g
        WHERE g.order_id = o.order_id
          AND g.recorded_at BETWEEN o.order_picked_up_at AND o.order_delivered_at + INTERVAL '30 minutes'
        LIMIT 1
    ) AS has_gps_delivery_proof
FROM chargebacks cb
JOIN customers c ON c.customer_id = cb.customer_id
JOIN orders o ON o.order_id = cb.order_id
JOIN drivers d ON d.driver_id = o.driver_id
WHERE o.order_delivered_at IS NOT NULL
  AND o.order_status = 'delivered'
  AND cb.reason_code IN ('4853', '4855', 'item_not_received', 'not_as_described')
ORDER BY days_after_delivery ASC;
