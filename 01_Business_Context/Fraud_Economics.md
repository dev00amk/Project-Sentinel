# Fraud Economics Deep Dive

**Project Sentinel | Phase 1 | Supplementary Analysis**

---

## The Economics of Marketplace Fraud

Fraud on a marketplace platform is not a random occurrence — it is a rational economic activity from the perspective of bad actors. Understanding this economic logic is essential to designing effective countermeasures.

### Why Fraud Happens: The Rational Actor Model

A bad actor commits fraud when:

```
Expected Gain > (Probability of Detection × Cost of Consequences)
```

Our current detection rate of 63% means 37% of fraud goes undetected. This creates a highly favorable risk/reward ratio for sophisticated fraudsters.

---

## Fraud P&L: What Each Vector Costs

| Vector | Avg Fraud Event Value | Events/Year | Annual Loss | Detection Rate |
|--------|-----------------------|-------------|-------------|----------------|
| GPS Spoofing | $87/incident | ~120,000 | $10.5M | 71% |
| Referral Abuse | $280/account | ~30,000 | $8.4M | 58% |
| Identity Fraud | $420/account | ~15,000 | $6.3M | 55% |
| Chargeback Fraud | $145/txn | ~40,700 | $5.9M | 61% |
| Refund Abuse | $58/incident | ~72,400 | $4.2M | 67% |
| Multi-Account | $190/account | ~17,900 | $3.4M | 52% |
| Collusion | $2,100/ring | ~1,000 | $2.1M | 41% |

---

## Cost Benchmarking

### Industry Comparisons (Gig Economy)

| Platform Type | Fraud Rate (% GMV) | Source |
|-------------|-------------------|--------|
| Ride-share platforms | 0.8–1.1% | Industry estimates |
| Food delivery | 0.9–1.3% | Industry estimates |
| Marketplace/last-mile | 0.7–1.2% | Industry estimates |
| Sentinel (current) | 1.05% | Internal |
| Sentinel (target) | 0.73% | Project Sentinel goal |

---

## The True Cost of a Fraud Event

The direct loss is only part of the story. Each fraud event has cascading costs:

```
Direct Loss (stolen funds):
+ Chargeback fee ($15–25)
+ Investigation cost ($28–45 per case)
+ Customer service cost ($12–20)
+ System/tooling cost (overhead)
+ NPS impact (estimated LTV loss)
= True Total Cost: ~2.4× the direct loss

True Annual Fraud Cost = $42M × 2.4 = ~$100M economic impact
```

---

## Fraud Prevention ROI Framework

### Rule: Every $1 Invested in Fraud Prevention Saves $8–12

| Investment Type | Annual Cost | Annual Savings | ROI |
|----------------|-------------|----------------|-----|
| ML Model Infrastructure | $450K | $6.2M | 12.8× |
| Graph Analytics Platform | $280K | $3.1M | 11.1× |
| OSINT Tooling | $120K | $1.4M | 11.7× |
| Investigator Training | $95K | $880K | 9.3× |
| Signal Development | $180K | $2.1M | 11.7× |

---

*Document Version: 1.0 | Owner: Fraud Intelligence Team*
