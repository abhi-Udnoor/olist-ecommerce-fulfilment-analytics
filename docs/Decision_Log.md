# Project Decision Log
# Olist Logistics SLA & Customer Retention Analytics

## 1. Purpose

This document records significant business, analytical and technical decisions throughout the project.

Each decision includes its rationale and current status.

The log is maintained to ensure that project decisions remain transparent, consistent and reproducible throughout the analytical workflow.

Decisions are updated when meaningful changes occur in business scope, data treatment, database architecture, analytical methodology or reporting.

---

## 2. Phase 1 — Business Discovery & Project Strategy

| Decision ID | Decision | Rationale | Status |
|---|---|---|---|
| D-001 | Focus on logistics SLA performance and customer retention signals. | Delivery operations can influence customer experience and repeat purchasing behaviour. | Approved |
| D-002 | Use estimated delivery date as the operational SLA proxy. | Actual contractual SLA agreements are unavailable in the dataset. | Approved |
| D-003 | Compare SLA dates using calendar dates. | Prevents same-day deliveries from being incorrectly classified as late because of time-of-day differences. | Approved |
| D-004 | Use `customer_unique_id` for repeat-customer analysis. | `customer_id` represents an order-specific customer record, whereas `customer_unique_id` identifies the actual customer across orders. | Approved |
| D-005 | Use SQL Server as the central relational data foundation. | Supports relational joins, data validation and reusable transformations. | Approved |
| D-006 | Use Python for EDA and statistical testing. | Provides flexible data exploration, visualisation and statistical libraries. | Approved |
| D-007 | Use Power BI for executive reporting. | Supports interactive dashboards and business-facing performance reporting. | Approved |
| D-008 | Exclude Excel from the core analytical pipeline. | Its main responsibilities are already covered by SQL Server and Power BI. | Approved |
| D-009 | Maintain separate raw, staging and analytical layers. | Preserves source data and separates ingestion, preparation and business-analysis responsibilities. | Approved |
| D-010 | Use a 90-day subsequent-order observation window. | Creates a consistent follow-up period for repeat-purchase analysis. | Proposed — to validate |
| D-011 | Distinguish customer attrition signals from proven churn. | The dataset contains no explicit churn labels or customer departure reasons. | Approved |
| D-012 | Treat freight values as recorded customer-facing charges. | Actual logistics expenditure is not available in the dataset. | Approved |
| D-013 | Separate multi-seller orders in seller performance rankings. | Avoids unsupported attribution of an entire order's delivery outcome to an individual seller. | Approved |
| D-014 | Use one latest valid review per order for order-level review analysis. | Prevents multiple review records from multiplying order-level measures. | Proposed — to validate |
| D-015 | Exclude customers without complete 90-day observation windows from cohort-rate denominators. | Prevents incomplete follow-up periods from being classified as non-repeat behaviour. | Proposed — to validate |

---

## 3. Phase 2 — Strategy Blueprint, Database Architecture & Ingestion

| Decision ID | Decision | Rationale | Status |
|---|---|---|---|
| D-016 | Use SQL Server database `OlistAnalytics`. | Provides a central relational environment for the project. | Implemented |
| D-017 | Create four database schemas: `raw`, `stg`, `mart` and `audit`. | Separates source data, prepared data, analytical models and audit-related objects. | Implemented |
| D-018 | Preserve the original CSV data in the raw layer. | Maintains an unchanged source reference and allows transformations to be reproduced. | Implemented |
| D-019 | Use SQL Server CSV ingestion to load the nine source tables. | Provides a consistent and repeatable ingestion process. | Implemented |
| D-020 | Keep raw source columns as `NVARCHAR` during initial ingestion. | Avoids premature conversion and preserves the original source values for validation. | Implemented |
| D-021 | Use separate SQL scripts for table creation, data loading and ingestion validation. | Makes the ingestion workflow easier to understand, execute and maintain. | Implemented |
| D-022 | Validate raw table existence and row counts after ingestion. | Confirms that all expected source tables have been loaded. | Implemented |

### Database architecture

The project follows this structure:

- `raw` — original source data.
- `stg` — typed and standardised data.
- `mart` — future business-ready analytical datasets.
- `audit` — reserved for audit-related records and processes.

---

## 4. Phase 3 — Data Profiling & Quality Audit

| Decision ID | Decision | Rationale | Status |
|---|---|---|---|
| D-023 | Perform data-quality investigations before cleaning or modifying source data. | Cleaning decisions should be based on observed evidence rather than assumptions. | Completed |
| D-024 | Preserve all original raw records, including suspicious observations. | Prevents loss of potentially useful business information. | Approved |
| D-025 | Use `(review_id, order_id)` as the composite candidate key for reviews. | `review_id` alone is not unique, whereas the tested combination is unique across the review records. | Validated |
| D-026 | Preserve repeated geolocation observations. | The dataset does not provide a reliable unique identifier or established grain that justifies deleting observations. | Approved |
| D-027 | Preserve missing optional review comments and product attributes. | Missing values do not automatically indicate invalid records. | Approved |
| D-028 | Preserve missing order lifecycle timestamps and interpret them using order status. | Missing timestamps are often consistent with the order lifecycle, such as cancelled or processing orders. | Approved |
| D-029 | Flag suspicious timestamp sequences rather than correcting them. | The cause of chronological inconsistencies cannot be established from the available data. | Approved |
| D-030 | Exclude invalid timestamp sequences from the affected stage-duration calculations. | Prevents negative or misleading operational durations from entering relevant KPIs. | Approved |
| D-031 | Preserve zero freight, payment, installment and product-weight observations. | Their validity cannot be conclusively determined from the available source data. | Approved |
| D-032 | Preserve products without English category translations. | Avoids inventing translations or removing valid product records. | Approved |
| D-033 | Preserve customer and seller records whose ZIP prefixes have no geolocation match. | A missing reference match does not prove that the underlying customer or seller record is invalid. | Approved |

### Key Phase 3 findings

- All tested primary and candidate keys were unique, except `review_id` alone.
- The composite review key `(review_id, order_id)` was validated.
- Six core relationships between orders, customers, order items, products, sellers, payments and reviews had no unmatched records.
- One order had no corresponding payment record.
- Thirteen products belonged to two categories without English translations.
- 157 distinct customer ZIP prefixes and 7 distinct seller ZIP prefixes had no geolocation match.
- Timestamp and geographical screening identified suspicious observations that were preserved rather than arbitrarily corrected.

---

## 5. Phase 4 — Data Cleaning, Standardisation & Staging Validation

| Decision ID | Decision | Rationale | Status |
|---|---|---|---|
| D-034 | Build typed staging tables from the raw layer. | Separates source preservation from analytical data preparation. | Implemented |
| D-035 | Use appropriate SQL Server data types for staging columns. | Improves data consistency and supports reliable calculations and analysis. | Implemented |
| D-036 | Use `DATETIME2(0)` for timestamps. | Provides appropriate date-and-time storage with second-level precision. | Implemented |
| D-037 | Use `DECIMAL(18,2)` for monetary values. | Preserves two decimal places for prices, freight and payments. | Implemented |
| D-038 | Use integer types for counts and quantities. | Represents whole-number measurements appropriately. | Implemented |
| D-039 | Use `DECIMAL(10,7)` for latitude and longitude. | Preserves the required coordinate precision. | Implemented |
| D-040 | Correct source spelling inconsistencies in staging column names without changing source values. | Provides consistent analytical column naming while preserving raw data. | Implemented |
| D-041 | Apply primary keys to staging tables where a reliable unique key exists. | Enforces uniqueness for the relevant business records. | Implemented |
| D-042 | Do not assign an artificial primary key to geolocation observations. | No reliable natural unique key was established for the source observations. | Implemented |
| D-043 | Preserve missing values and suspicious observations during staging. | Avoids unsupported imputation, deletion or correction. | Implemented |
| D-044 | Validate staging row counts, key uniqueness, data types and missing values after loading. | Confirms that conversions and staging loads preserve the expected data. | Completed |
| D-045 | Validate relationships between staging tables using cross-table checks. | Confirms referential consistency and identifies unmatched records. | Completed |

### Staging architecture

Nine staging tables were created and populated:

1. `stg.orders`
2. `stg.order_items`
3. `stg.order_payments`
4. `stg.customers`
5. `stg.sellers`
6. `stg.products`
7. `stg.product_category_translation`
8. `stg.order_reviews`
9. `stg.geolocation`

### Phase 4 validation outcome

- All nine staging tables were populated.
- Staging record counts matched the corresponding raw source record counts.
- Tested keys and uniqueness constraints passed.
- Data types were converted and checked.
- Missing and suspicious values were preserved.
- Cross-table validation identified no unmatched records in the six core relationships.
- One order had no payment record.
- Thirteen products had no English category translation.
- Customer and seller ZIP-prefix reference mismatches were retained and documented.

**Phase 4 status: Completed.**

---

## 6. Decision Governance

A decision should be recorded whenever it changes or clarifies:

- Business scope and objectives.
- KPI definitions and business rules.
- Data-quality treatment.
- Database architecture and design.
- Data preparation and transformation.
- Analytical methodology.
- Statistical testing.
- Reporting and dashboard design.

Previous decisions should not be silently overwritten.

When a decision changes:

1. Update the existing decision's status where appropriate.
2. Record the reason for the change.
3. Add a new decision if it introduces a materially different approach.
4. Preserve the history of important decisions.

---

## 7. Future Decision Records

The following decisions will be documented as their respective phases progress.

| Decision ID | Phase | Area | Status |
|---|---|---|---|
| Future | Phase 5 | Python data extraction and analysis workflow | Pending |
| Future | Phase 5 | EDA methodology and analytical questions | Pending |
| Future | Phase 5 | Statistical testing and hypothesis selection | Pending |
| Future | Phase 5 | Treatment of analytical outliers and exclusions | Pending |
| Future | Phase 6 | Business KPI definitions and calculations | Pending |
| Future | Phase 6 | Power BI data model and relationships | Pending |
| Future | Phase 6 | Dashboard layout and visualisation choices | Pending |
| Future | Phase 7 | Executive findings and business recommendations | Pending |
| Future | Phase 7 | Final stakeholder report and project presentation | Pending |

---

*End of Project Decision Log.*
