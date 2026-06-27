# 🛡️ Project Sentinel
## Enterprise Fraud Intelligence Platform

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python 3.10+](https://img.shields.io/badge/python-3.10+-blue.svg)](https://www.python.org/downloads/)
[![SQL](https://img.shields.io/badge/SQL-PostgreSQL-336791.svg)](https://www.postgresql.org/)
[![Status](https://img.shields.io/badge/status-active--development-brightgreen.svg)]()
[![Target Roles](https://img.shields.io/badge/target-Walmart%20%7C%20Airbnb%20%7C%20Uber%20%7C%20Stripe-orange.svg)]()

---

> **"How do we reduce fraud loss by 30% while increasing customer trust and minimizing investigator workload?"**
> — The CEO question that drives every decision in this platform.

---

## 📌 Executive Scenario

You are a **Senior Fraud Intelligence Analyst** hired to turn around a struggling marketplace fraud program.

| Metric | Baseline | Target |
|--------|----------|--------|
| Annual GMV | $4,000,000,000 | — |
| Annual Fraud Losses | $42,000,000 (1.05% of GMV) | < $29.4M (−30%) |
| Fraud Detection Rate | 63% | ≥ 85% |
| False Positive Rate | 18% | < 8% |
| Investigators | 500 | Same headcount |
| Users | 10,000,000 | — |
| Drivers | 250,000 | — |
| Deliveries | 50,000,000 | — |

This repository documents the complete fraud intelligence program built to answer that question — from data architecture through ML models to executive presentations.

---

## 🗂️ Project Structure

```
Project-Sentinel/
│
├── 01_Business_Context/          # Business model, fraud economics, risk appetite
│   ├── Business_Context.md
│   ├── Fraud_Economics.md
│   └── Risk_Appetite_Framework.md
│
├── 02_Data_Model/                # 20-table enterprise schema
│   ├── schema.sql
│   ├── ERD_Diagram.md
│   └── Data_Dictionary.md
│
├── 03_Data_Generation/           # Synthetic data generators
│   ├── generate_drivers.py
│   ├── generate_customers.py
│   ├── generate_orders.py
│   ├── generate_gps.py
│   ├── inject_fraud.py
│   └── README.md
│
├── 04_SQL/                       # 40-60 investigation queries
│   ├── 01_impossible_travel.sql
│   ├── 02_shared_devices.sql
│   ├── 03_shared_bank_accounts.sql
│   ├── 04_referral_abuse.sql
│   ├── 05_fraud_rings.sql
│   ├── 06_velocity_checks.sql
│   ├── 07_bonus_abuse.sql
│   ├── 08_geospatial_anomalies.sql
│   ├── 09_duplicate_identities.sql
│   ├── 10_chargeback_patterns.sql
│   └── README.md
│
├── 05_Python/                    # Analytics & feature engineering
│   ├── feature_engineering.py
│   ├── anomaly_detection.py
│   ├── time_series_analysis.py
│   ├── clustering.py
│   ├── statistical_tests.py
│   ├── survival_analysis.py
│   └── bayesian_inference.py
│
├── 06_Machine_Learning/          # ML models + evaluation
│   ├── logistic_regression.py
│   ├── random_forest.py
│   ├── xgboost_model.py
│   ├── isolation_forest.py
│   ├── autoencoder.py
│   ├── model_evaluation.py
│   └── README.md
│
├── 07_Behavioral_Analytics/      # Behavioral feature store
│   ├── feature_store.py
│   ├── route_entropy.py
│   ├── session_analysis.py
│   ├── temporal_patterns.py
│   └── README.md
│
├── 08_Graph_Analytics/           # Fraud network detection
│   ├── build_graph.py
│   ├── connected_components.py
│   ├── pagerank_fraud.py
│   ├── community_detection.py
│   └── README.md
│
├── 09_Fraud_Investigations/      # 100 sample investigations
│   ├── CASE-001_GPS_Spoofing/
│   ├── CASE-002_Device_Farm/
│   ├── CASE-003_Referral_Ring/
│   ├── investigation_template.md
│   └── README.md
│
├── 10_OSINT/                     # Open-source intelligence
│   ├── osint_framework.md
│   ├── identity_verification.md
│   └── external_signals.md
│
├── 11_Dashboards/                # Dashboard specs + Plotly prototypes
│   ├── executive_dashboard.py
│   ├── operations_dashboard.py
│   ├── threat_intelligence.py
│   └── README.md
│
├── 12_Product_Strategy/          # Product recommendations per fraud vector
│   ├── product_strategy.md
│   └── roi_calculator.py
│
├── 13_Executive_Presentations/   # 20-slide deck + speaker notes
│   ├── Sentinel_Executive_Deck.md
│   └── speaker_notes.md
│
├── 14_Decision_Logs/             # ADR-style fraud decisions
│   ├── DL-001_referral_payout_delay.md
│   ├── DL-002_gps_threshold.md
│   └── decision_log_template.md
│
├── 15_Audit/                     # SOPs, compliance, audit readiness
│   ├── SOPs/
│   ├── Compliance_Checklist.md
│   ├── Escalation_Matrix.md
│   └── KPI_Definitions.md
│
├── 16_Fraud_Signal_Catalog/      # 50+ documented fraud signals
│   ├── signal_catalog.md
│   └── signal_template.md
│
├── docs/
│   ├── ARCHITECTURE.md
│   ├── GLOSSARY.md
│   └── ROADMAP.md
│
└── README.md
```

---

## 🚀 16-Phase Program Overview

| Phase | Module | Status | Key Deliverable |
|-------|--------|--------|-----------------|
| 1 | Business Context | ✅ Complete | Business_Context.md + Fraud Economics |
| 2 | Data Model | ✅ Complete | 20-table schema.sql + ERD |
| 3 | Data Generation | 🔄 In Progress | Synthetic dataset generators |
| 4 | Fraud Types (15+) | 🔄 In Progress | inject_fraud.py with 15 scenarios |
| 5 | Behavioral Analytics | 🔄 In Progress | Feature Store (100+ features) |
| 6 | SQL Investigation Library | ✅ Complete | 40+ investigation queries |
| 7 | Python Analytics | 🔄 In Progress | Feature engineering + clustering |
| 8 | Machine Learning | 🔄 In Progress | 5 models with cost-based evaluation |
| 9 | Graph Analytics | 🔄 In Progress | Fraud network detection |
| 10 | Fraud Signal Catalog | ✅ Complete | 50+ documented signals |
| 11 | Investigation Workbench | 🔄 In Progress | 100 case files |
| 12 | Product Strategy | ✅ Complete | Per-vector recommendations + ROI |
| 13 | Executive Presentations | ✅ Complete | 20-slide deck |
| 14 | Decision Logs | ✅ Complete | ADR-style decision records |
| 15 | Audit Readiness | ✅ Complete | SOPs + compliance checklist |
| 16 | GitHub Wiki | 🔄 In Progress | Full wiki documentation |

---

## 🎯 Why This Project

This is not a coding exercise. It demonstrates the full scope of a **Senior Fraud Intelligence Analyst** role:

- **Business Thinking** — Translates ambiguous risk problems into measurable signals
- **SQL Mastery** — 40+ investigation queries across all major fraud vectors
- **Python Analytics** — Feature engineering, clustering, anomaly detection, Bayesian inference
- **Machine Learning** — 5 models evaluated with business cost metrics, not just AUC
- **Graph Analytics** — Connected components, PageRank, community detection on fraud networks
- **Investigation Discipline** — Structured case files, audit trails, evidence documentation
- **Executive Communication** — C-suite ready presentations with financial impact quantification
- **Product Partnership** — Root cause analysis mapped to engineering controls with ROI estimates

> A hiring manager reviewing this repository should come away with the impression that you understand not only *how* to detect fraud, but *how a modern fraud organization operates and makes decisions*.

---

## 🏢 Target Roles

This project is specifically designed to demonstrate competency for:

| Company | Role |
|---------|------|
| **Walmart** | LMD Fraud Prevention Analyst |
| **Airbnb** | Trust & Safety Analyst |
| **Uber** | Risk Operations Analyst |
| **DoorDash** | Integrity & Risk Analyst |
| **Stripe** | Risk Analyst |
| **Chime** | Fraud Intelligence Analyst |
| **Lyft** | Trust Operations |
| **Instacart** | Fraud Prevention |

---

## 🛠️ Tech Stack

| Layer | Tools |
|-------|-------|
| **Database** | PostgreSQL, SQLite (dev) |
| **Analytics** | Python, pandas, numpy, scipy |
| **ML** | scikit-learn, XGBoost, PyTorch |
| **Graph** | NetworkX, PyG (optional) |
| **Visualization** | Plotly, Matplotlib, Seaborn |
| **OSINT** | Shodan API, WHOIS, ipinfo.io |
| **Dashboards** | Plotly Dash, Streamlit |
| **Notebooks** | Jupyter |

---

## 📈 Expected Program Outcomes

After full implementation:

| KPI | Before | After |
|-----|--------|-------|
| Annual Fraud Loss | $42M | ~$28M (−33%) |
| Detection Rate | 63% | 87% |
| False Positive Rate | 18% | 7% |
| Investigator Efficiency | Baseline | +40% |
| Average Case Resolution | N/A | <4 hours |
| Audit Readiness Score | Unknown | 95%+ |

---

## 📅 Build Roadmap

```
Week 1-2:   Phases 1-3   (Foundation: Business Context, Schema, Data Generation)
Week 3-4:   Phases 4-6   (Core: Fraud Types, Behavioral Analytics, SQL Library)
Week 5-6:   Phases 7-8   (Analytics: Python + Machine Learning)
Week 7-8:   Phases 9-10  (Advanced: Graph Analytics + Signal Catalog)
Week 9-10:  Phases 11-13 (Operations: Investigations, Dashboards, Exec Deck)
Week 11-12: Phases 14-16 (Governance: Decision Logs, Audit, Wiki)
```

---

## 🤝 About the Author

Built by **Mahesh Kumar** — Fraud Analytics professional with background in card product lifecycle management, risk analysis, and enterprise data analytics.

[![GitHub](https://img.shields.io/badge/GitHub-dev00amk-black.svg)](https://github.com/dev00amk)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-Connect-blue.svg)](https://linkedin.com/in/maheshkumar)

---

⭐ **Star this repository if it helps your fraud ops interview prep!**
