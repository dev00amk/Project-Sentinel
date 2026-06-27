# SQL Investigation Library

**Project Sentinel | Phase 6 | 40+ Investigation Queries**

---

## Overview

This library contains production-ready SQL queries organized by fraud vector. Each query is designed to be:

- **Reusable** — parameterizable for different time windows and thresholds
- **Documented** — inline comments explain signal logic and false-positive mitigations
- **Audit-Ready** — deterministic and reproducible for case file attachment
- **Performance-Optimized** — leverages indexes defined in `schema.sql`

---

## Query Index

| File | Queries | Fraud Vector | Signal IDs |
|------|---------|--------------|------------|
| `01_impossible_travel.sql` | 2 | GPS/Location | LOC-001 |
| `02_shared_devices.sql` | 3 | Device/Multi-Account | DEV-001 |
| `03_referral_abuse.sql` | 3 | Financial/Network | FIN-003 |
| `04_velocity_checks.sql` | 3 | Behavioral | BEH-001 |
| `05_fraud_rings.sql` | 4 | Network/Coordinated | NET-001 |
| `06_chargeback_patterns.sql` | 2 | Financial | FIN-004 |

**Total: 17 queries across 6 files** (expanding to 40+ in subsequent commits)

---

## Usage Guide

### Running Queries

```sql
-- Always parameterize time windows for production use
-- Replace INTERVAL '30 days' with your analysis window
-- Replace threshold values (>= 3, >= 5) based on your signal calibration

-- Example: Run impossible travel for specific driver
-- Modify the WHERE clause:
WHERE driver_id = 'your-driver-uuid'
  AND recorded_at >= '2026-01-01'
```

### False Positive Framework

Every query includes embedded comments on known false positive sources. Before actioning:

1. Cross-reference with at least **2 independent signals**
2. Check **account age and tenure** (new accounts = higher suspicion)
3. Validate with **GPS route continuity** where applicable
4. Review **customer support history** for context
5. Apply **manual review** for edge cases before deactivation

---

## Query Naming Convention

```
[NN]_[vector_name].sql
  NN  = 2-digit sequence number
  vector_name = fraud vector category (snake_case)
```

## Signal Category Reference

| Code | Category |
|------|----------|
| LOC | Location / GPS Fraud |
| DEV | Device Fraud |
| FIN | Financial Fraud |
| BEH | Behavioral Anomaly |
| NET | Network / Ring Fraud |
| ID | Identity Fraud |
| OPS | Operational Fraud |
