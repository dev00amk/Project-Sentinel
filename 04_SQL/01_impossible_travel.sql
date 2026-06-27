-- ============================================================
-- FRAUD SIGNAL: Impossible Travel Detection
-- Category: Location Fraud
-- Signal ID: LOC-001
-- Logic: Driver appears in two locations physically impossible
--        to reach in the elapsed time given speed of travel
-- Threshold: Distance > 20 km in < 2 minutes
-- False Positive Mitigations:
--   - GPS drift in tunnels/underpasses
--   - App crash + reconnect mid-route
--   - Require 3+ consecutive violations before flagging
-- ============================================================

-- Query 1: Basic Impossible Travel Detection
WITH ordered_gps AS (
    SELECT
        g.driver_id,
        g.order_id,
        g.latitude,
        g.longitude,
        g.recorded_at,
        LAG(g.latitude)    OVER (PARTITION BY g.driver_id ORDER BY g.recorded_at) AS prev_lat,
        LAG(g.longitude)   OVER (PARTITION BY g.driver_id ORDER BY g.recorded_at) AS prev_lng,
        LAG(g.recorded_at) OVER (PARTITION BY g.driver_id ORDER BY g.recorded_at) AS prev_time
    FROM gps_logs g
    WHERE g.recorded_at >= NOW() - INTERVAL '7 days'
),
distance_calc AS (
    SELECT
        driver_id,
        order_id,
        recorded_at,
        prev_time,
        EXTRACT(EPOCH FROM (recorded_at - prev_time)) / 60.0 AS elapsed_minutes,
        -- Haversine formula: approximate distance in km
        6371 * 2 * ASIN(
            SQRT(
                POWER(SIN(RADIANS(latitude - prev_lat) / 2), 2)
                + COS(RADIANS(prev_lat)) * COS(RADIANS(latitude))
                * POWER(SIN(RADIANS(longitude - prev_lng) / 2), 2)
            )
        ) AS distance_km
    FROM ordered_gps
    WHERE prev_lat IS NOT NULL
      AND prev_time IS NOT NULL
)
SELECT
    dc.driver_id,
    d.first_name || ' ' || d.last_name AS driver_name,
    d.status AS driver_status,
    d.risk_score,
    dc.order_id,
    ROUND(dc.distance_km::numeric, 2) AS distance_km,
    ROUND(dc.elapsed_minutes::numeric, 2) AS elapsed_minutes,
    ROUND((dc.distance_km / NULLIF(dc.elapsed_minutes, 0))::numeric, 1) AS speed_kmh_implied,
    dc.recorded_at AS event_timestamp
FROM distance_calc dc
JOIN drivers d ON d.driver_id = dc.driver_id
WHERE dc.distance_km > 20
  AND dc.elapsed_minutes < 2
  AND dc.elapsed_minutes > 0
ORDER BY dc.distance_km DESC;


-- Query 2: Impossible Travel with Frequency Analysis (Repeat Offenders)
WITH ordered_gps AS (
    SELECT
        g.driver_id,
        g.latitude, g.longitude, g.recorded_at,
        LAG(g.latitude)    OVER (PARTITION BY g.driver_id ORDER BY g.recorded_at) AS prev_lat,
        LAG(g.longitude)   OVER (PARTITION BY g.driver_id ORDER BY g.recorded_at) AS prev_lng,
        LAG(g.recorded_at) OVER (PARTITION BY g.driver_id ORDER BY g.recorded_at) AS prev_time
    FROM gps_logs g
    WHERE g.recorded_at >= NOW() - INTERVAL '30 days'
),
violations AS (
    SELECT
        driver_id,
        recorded_at,
        6371 * 2 * ASIN(
            SQRT(
                POWER(SIN(RADIANS(latitude - prev_lat) / 2), 2)
                + COS(RADIANS(prev_lat)) * COS(RADIANS(latitude))
                * POWER(SIN(RADIANS(longitude - prev_lng) / 2), 2)
            )
        ) AS distance_km,
        EXTRACT(EPOCH FROM (recorded_at - prev_time)) / 60.0 AS elapsed_minutes
    FROM ordered_gps
    WHERE prev_lat IS NOT NULL
)
SELECT
    v.driver_id,
    d.first_name || ' ' || d.last_name AS driver_name,
    COUNT(*) AS impossible_travel_events,
    ROUND(MAX(v.distance_km)::numeric, 1) AS max_distance_km,
    ROUND(MIN(v.elapsed_minutes)::numeric, 2) AS min_elapsed_minutes,
    MIN(v.recorded_at) AS first_violation,
    MAX(v.recorded_at) AS last_violation,
    d.risk_score,
    d.status
FROM violations v
JOIN drivers d ON d.driver_id = v.driver_id
WHERE v.distance_km > 20
  AND v.elapsed_minutes < 2
  AND v.elapsed_minutes > 0
GROUP BY v.driver_id, d.first_name, d.last_name, d.risk_score, d.status
HAVING COUNT(*) >= 3     -- Require 3+ violations to reduce false positives
ORDER BY impossible_travel_events DESC;
