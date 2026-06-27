# Entity Relationship Diagram

**Project Sentinel | Phase 2 | Data Model**

---

## Table Relationship Overview

```
┌───────────────────────────────────────────────────────────────────────┐
│                PROJECT SENTINEL: 20-TABLE ERD                    │
└───────────────────────────────────────────────────────────────────────┘

                        DRIVERS ─┬─ VEHICLE_INFORMATION
                           │    └─ IDENTITY_VERIFICATION
                           │
                    ORDERS ─┼─ GPS_LOGS
                           │
                  CUSTOMERS─┼─ PAYMENTS ─┬─ CHARGEBACKS
                           │
                    DEVICES ─┼─ LOGIN_EVENTS ── SESSION_EVENTS
                           │
               RISK_SIGNALS ─┼─ FRAUD_ALERTS ── INVESTIGATIONS ── APPEALS
                           │
                  REFERRALS ─┼─ INCENTIVES ── PROMOTIONS
                           │
          CUSTOMER_SUPPORT ─┴─ DRIVER_RATINGS
```

## Table Inventory

| # | Table | Primary Key | Core Relationships |
|---|-------|-------------|-------------------|
| 1 | drivers | driver_id | → orders, vehicle_information, referrals |
| 2 | customers | customer_id | → orders, payments, customer_support |
| 3 | orders | order_id | → gps_logs, payments, driver_ratings |
| 4 | gps_logs | gps_id | ← orders, drivers |
| 5 | devices | device_id | → login_events, session_events |
| 6 | login_events | login_id | ← devices, entities |
| 7 | session_events | session_id | ← login_events, devices |
| 8 | payments | payment_id | ← orders, customers → chargebacks |
| 9 | chargebacks | chargeback_id | ← payments |
| 10 | identity_verification | verification_id | ← drivers, customers |
| 11 | vehicle_information | vehicle_id | ← drivers |
| 12 | risk_signals | signal_id | → any entity |
| 13 | fraud_alerts | alert_id | → investigations |
| 14 | investigations | investigation_id | ← fraud_alerts → appeals |
| 15 | appeals | appeal_id | ← investigations |
| 16 | referrals | referral_id | ← drivers, customers |
| 17 | incentives | incentive_id | ← drivers |
| 18 | promotions | promo_id | ← orders |
| 19 | customer_support | ticket_id | ← orders, customers |
| 20 | driver_ratings | rating_id | ← orders, drivers |

## Key Design Decisions

1. **UUID primary keys** throughout for distributed system compatibility
2. **Polymorphic entity references** (entity_type + entity_id) for risk_signals, login_events, fraud_alerts allow unified risk tracking across drivers and customers
3. **JSONB columns** for flexible metadata (signals_triggered, audit_trail, risk_signals) without over-normalizing
4. **Partial indexes** on fraud-related booleans for query performance at scale
5. **Hash storage** for PII (SSN, document numbers) via SHA-256 — never store raw
