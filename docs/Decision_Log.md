# Project Decision Log
# Logistics SLA Performance & Customer Retention Risk Analysis

## 1. Purpose

This document records significant business, analytical and technical decisions throughout the project.

Each decision should include its rationale, implications and current status.

The log will be updated whenever a meaningful architectural, data-quality or analytical decision is made.

## 2. Phase 1 Decisions

| Decision ID | Decision | Rationale | Status |
|---|---|---|---|
| D-001 | Focus on logistics SLA performance and customer retention signals. | Strong relationship between delivery operations and customer experience. | Proposed |
| D-002 | Use estimated delivery date as the operational SLA proxy. | Actual contractual SLA agreements are unavailable. | Proposed |
| D-003 | Compare SLA dates using calendar dates. | Prevent same-day afternoon deliveries being incorrectly classified as late. | Proposed |
| D-004 | Use customer_unique_id for repeat-customer analysis. | customer_id is order-specific. | Proposed |
| D-005 | Use SQL Server as the central relational data foundation. | Supports reusable relational transformations and data integrity. | Proposed |
| D-006 | Use Python for EDA and statistical testing. | Provides flexible analytical and statistical libraries. | Proposed |
| D-007 | Use Power BI for executive reporting. | Provides interactive management reporting. | Proposed |
| D-008 | Exclude Excel from the core pipeline. | Its required responsibilities are already covered by SQL Server and Power BI. | Proposed |
| D-009 | Maintain separate raw, staging and analytical layers. | Preserves source records and separates transformation responsibilities. | Proposed |
| D-010 | Use a 90-day subsequent-order observation window. | Creates a consistent and measurable follow-up period. | Proposed |
| D-011 | Distinguish customer attrition signals from proven churn. | The dataset has no explicit churn labels or customer departure reasons. | Proposed |
| D-012 | Treat freight values as recorded customer-facing charges. | Actual logistics expenditure is not available. | Proposed |
| D-013 | Separate multi-seller orders in seller performance rankings. | Avoids unsupported seller-level attribution of order delivery outcomes. | Proposed |
| D-014 | Keep one latest valid review per order for order-level review analysis. | Prevents review records from multiplying order-level measures. | Proposed |
| D-015 | Exclude customers without complete 90-day observation windows from cohort-rate denominators. | Prevents incomplete follow-up periods from being treated as non-repeat behaviour. | Proposed |

## 3. Decision Governance

A decision should be added when it changes or clarifies:

- Business scope.
- KPI definitions.
- Data treatment.
- Analytical methodology.
- Database design.
- Tool responsibilities.
- Reporting methodology.

Previous decisions should not be silently overwritten.

When a decision changes, update its status and document the reason for the revision.

## 4. Future Decision Records

| Decision ID | Phase | Decision | Status |
|---|---|---|---|
| Future | Phase 2 | Database and schema design | Pending |
| Future | Phase 2 | CSV ingestion method | Pending |
| Future | Phase 2 | Database key strategy | Pending |
| Future | Phase 3 | Data quality treatment | Pending |
| Future | Phase 4 | Statistical testing methodology | Pending |
| Future | Phase 5 | Reporting model and dashboard design | Pending |

---

*End of Project Decision Log.*
