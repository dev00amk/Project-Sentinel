# Business Context: Marketplace Fraud Intelligence Program

**Project Sentinel | Phase 1 | Version 1.0**

---

## 1. Marketplace Business Model

### Platform Overview

Sentinel Marketplace is a last-mile delivery platform operating as a three-sided marketplace:

| Participant | Role | Scale |
|-------------|------|-------|
| **Customers** | Place delivery orders via app/web | 10,000,000 active |
| **Drivers** | Accept and fulfill deliveries | 250,000 active |
| **Merchants** | List products/services | 85,000 partners |

**Business Model:** The platform earns revenue via:
- **Service fee** (15–22% of order value charged to merchants)
- **Delivery fee** (flat/dynamic charged to customers)
- **Subscription revenue** (premium membership: $9.99/month)
- **Advertising** (promoted listings from merchants)

**Gross Merchandise Value (GMV):** $4,000,000,000 annually  
**Average Order Value (AOV):** $32.50  
**Orders per Year:** ~50,000,000  
**Platform Take Rate:** ~8% of GMV = ~$320M net revenue

---

## 2. Driver Lifecycle

```
Application → Background Check → Identity Verification → Vehicle Inspection
     → Onboarding Training → Active Driver → [Suspension/Deactivation]
```

### Key Lifecycle Events

| Stage | Fraud Risk |
|-------|------------|
| Application | Synthetic identity, stolen identity, fake licenses |
| Onboarding | Document fraud, multiple accounts |
| Active | GPS spoofing, fake deliveries, collusion |
| Incentive Programs | Bonus abuse, referral fraud |
| Deactivation | Account takeover for banned driver re-entry |

**Driver Incentive Structure:**
- Sign-up bonus: $300–$800 (varies by market)
- Referral bonus: $200 per new driver activation
- Quest bonuses: tiered completion incentives
- Surge pay: 1.2x–2.5x during peak demand

---

## 3. Customer Lifecycle

```
Registration → Email/Phone Verification → First Order → Repeat Customer
     → Subscription Upgrade → [Churn / Fraud Detection]
```

| Stage | Fraud Risk |
|-------|------------|
| Registration | Synthetic accounts, stolen identity |
| First Order | Stolen payment methods |
| Repeat Usage | Account takeover, refund fraud |
| Subscription | Payment fraud, chargebacks |
| Promotions | Promo abuse, multi-accounting |

---

## 4. Revenue Model

| Revenue Stream | Annual Value | Fraud Exposure |
|---------------|-------------|----------------|
| Service Fees | $190M | Merchant collusion |
| Delivery Fees | $95M | GPS fraud, fake deliveries |
| Subscription | $18M | Payment fraud |
| Advertising | $17M | Click fraud, fake merchants |
| **Total Net Revenue** | **$320M** | |

---

## 5. Fraud Economics

### Annual Fraud Loss Breakdown

| Fraud Category | Annual Loss | % of Total Fraud |
|---------------|-------------|------------------|
| GPS Spoofing / Fake Deliveries | $10.5M | 25% |
| Referral & Bonus Abuse | $8.4M | 20% |
| Identity / Account Fraud | $6.3M | 15% |
| Payment / Chargeback Fraud | $5.9M | 14% |
| Refund Abuse | $4.2M | 10% |
| Device / Multi-Account Fraud | $3.4M | 8% |
| Insider / Collusion | $2.1M | 5% |
| Other Vectors | $1.2M | 3% |
| **Total** | **$42,000,000** | **100%** |

### Fraud Rate Context

- Fraud Loss / GMV = **1.05%** (industry benchmark: 0.7–1.2% for gig platforms)
- Fraud Loss / Net Revenue = **13.1%** — material and addressable
- Each 0.1% reduction in fraud rate = **$4M saved annually**

### Cost of False Positives

| Metric | Value |
|--------|-------|
| False Positive Rate | 18% |
| Estimated FP Incidents/Year | ~90,000 |
| Avg driver earning loss per FP deactivation | $380 |
| Estimated FP operational cost | ~$8.2M (disputes, reinstatements, NPS) |
| Customer FP order blocks | ~500,000 incidents |
| Estimated customer GMV loss from FP | ~$7.5M |

> **Key Insight:** False positives cost the business nearly as much as fraud itself. Any detection strategy must minimize both.

---

## 6. Financial Impact of the Sentinel Program

### Target Outcomes

| KPI | Baseline | Year 1 Target | Year 2 Target |
|-----|----------|---------------|---------------|
| Fraud Losses | $42M | $29.4M | $22M |
| Detection Rate | 63% | 82% | 90% |
| False Positive Rate | 18% | 10% | 6% |
| Avg Investigation Time | 4.2 hrs | 2.5 hrs | 1.8 hrs |
| Investigator Productivity | 100% | 140% | 180% |

### ROI Calculation

```
Year 1 Fraud Savings:      $42M - $29.4M  = $12.6M
FP Reduction Savings:      ~$3.8M
Operational Efficiency:    ~$1.2M
───────────────────────────────────────────
Estimated Total Year 1 Value:   $17.6M
Estimated Program Cost:         ~$2.8M (team + tools)
Net ROI:                        ~530%
```

---

## 7. Investigation Process

### Standard Investigation Workflow

```
Alert Triggered → Auto-Triage (Risk Score) → Queue Assignment
     → Investigator Review (SQL + Behavioral Analysis)
     → OSINT Research → Evidence Documentation
     → Decision (Clear | Suspend | Deactivate | Escalate)
     → Case File Created → Audit Trail Locked
     → Appeals Process (if applicable)
```

### Investigation SLA Standards

| Priority | Trigger | SLA |
|----------|---------|-----|
| P1 — Critical | Active fraud, >$5K loss potential | 2 hours |
| P2 — High | High risk score (>80), device farm suspected | 8 hours |
| P3 — Medium | Moderate risk, pattern match | 24 hours |
| P4 — Low | Anomaly flagged, low confidence | 72 hours |

---

## 8. Risk Appetite Framework

### Risk Tolerance Thresholds

| Risk Category | Tolerance Level | Action Trigger |
|--------------|----------------|----------------|
| Fraud Loss / GMV | < 0.75% | Escalate to VP if exceeded |
| False Positive Rate | < 8% | Review detection rules if exceeded |
| Detection Rate | > 85% | Alert if drops below |
| P1 Case SLA Breach | < 2% | Daily review if exceeded |
| Driver Deactivation Appeals Win Rate | < 15% | Review investigation quality |

### Risk Appetite Statement

> Sentinel Marketplace will accept residual fraud risk at levels that do not materially impair customer trust, driver earnings, or regulatory compliance. We will not pursue zero-fraud at the cost of false positives exceeding 8%, driver deactivation rate exceeding 2% without appeal, or customer block rates exceeding 0.5% of monthly active users.

---

## 9. Success Metrics (OKRs)

### Objective: Reduce Fraud Loss by 30% in 12 Months

**Key Results:**
- KR1: Fraud detection rate ≥ 85% by Q3
- KR2: False positive rate ≤ 8% by Q2
- KR3: 100% of P1 investigations closed within SLA
- KR4: 50+ fraud signals documented in signal catalog
- KR5: Zero audit findings on investigation documentation

---

*Document Version: 1.0 | Owner: Fraud Intelligence Team | Last Updated: June 2026*
