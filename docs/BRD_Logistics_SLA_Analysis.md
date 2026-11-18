# Business Requirements Document (BRD)
# Logistics SLA Performance & Customer Retention Risk Analysis

## 1. Document Control

| Attribute | Details |
|---|---|
| Project ID | OLIST-SLA-RET-001 |
| Document Version | 1.1 |
| Status | Proposed for Approval |
| Prepared Date | 16 November 2026 |
| Project Owner | Abhi Udnoor |
| Business Owner | Head of Marketplace Operations (Simulated) |
| Business Domain | E-commerce Marketplace / Supply Chain |
| Target Business Perspective | Prague, Czechia |
| Data Source | Brazilian E-Commerce Public Dataset by Olist |
| Project Classification | Historical Descriptive and Diagnostic Analytics |

---

## 2. Executive Business Overview

### 2.1 Business Background

E-commerce marketplaces coordinate transactions involving customers, independent sellers and logistics operations.

Customers expect their orders to arrive within the delivery dates communicated during checkout. Delayed deliveries and inconsistent fulfilment performance can negatively influence customer satisfaction and future purchasing behaviour.

Management requires an integrated view of delivery performance and customer purchasing patterns to identify operational inefficiencies and understand which customer segments may require attention.

This project simulates an analytics engagement for an e-commerce marketplace operating in a Prague/European retail environment.

The investigation uses the historical Brazilian E-Commerce Public Dataset by Olist.

**Contextual limitation:** The project uses Brazilian historical data to demonstrate analytical methods relevant to Czech and European e-commerce businesses. It does not measure actual performance of a Prague-based company.

### 2.2 Business Problem

The business lacks a consolidated analytical view connecting:

- Customer-facing delivery commitments.
- Actual delivery performance.
- Order fulfilment stages.
- Seller and geographical performance.
- Customer satisfaction.
- Observed subsequent purchasing behaviour.

Without these connected measurements, management cannot efficiently identify where delivery performance falls short, understand associated customer experiences or prioritise operational improvements.

### 2.3 Primary Business Question

**How effectively does the marketplace meet its customer delivery commitments, which operational and geographical segments are associated with delivery delays, and are poor delivery experiences associated with a lower likelihood of subsequent customer orders?**

---

## 3. Business Objectives

| ID | Objective | Expected Outcome |
|---|---|---|
| BO-01 | Establish overall logistics performance. | Baseline order and delivery performance indicators. |
| BO-02 | Identify delivery inefficiencies. | Quantification of delivery delays and fulfilment-stage durations. |
| BO-03 | Investigate operational differences. | Seller, geographical and product-level comparisons. |
| BO-04 | Evaluate customer experience. | Customer satisfaction and negative delivery-experience indicators. |
| BO-05 | Investigate customer retention signals. | Comparison of 90-day subsequent-order behaviour across delivery-experience cohorts. |

### 3.1 Business Questions

**Logistics performance**

1. What proportion of eligible delivered orders arrive within their estimated delivery dates?
2. How frequent and severe are late deliveries?
3. How long do customers wait between purchase and delivery?
4. Which fulfilment stage accounts for the largest elapsed time?
5. Do delivery outcomes differ across sellers and geographical regions?
6. Are certain product categories associated with longer delivery times?
7. How do recorded freight charges vary across product and geographical segments?

**Customer experience and retention**

8. What proportion of customers provide negative reviews?
9. Are late deliveries associated with higher negative review rates?
10. Which customer segments experience both delivery delays and poor ratings?
11. What proportion of eligible customers place another order within 90 days of their index delivery?
12. Does this subsequent-order rate differ between poor and positive delivery-experience cohorts?

---

## 4. Stakeholders

| Stakeholder | Business Responsibility | Analytical Interest |
|---|---|---|
| Head of Marketplace Operations | Overall operational performance | Delivery reliability and fulfilment efficiency |
| Supply Chain Manager | Order fulfilment and delivery | Delivery delays and stage durations |
| Commercial Manager | Commercial performance | Freight and product-value indicators |
| Customer Experience Manager | Customer satisfaction | Negative reviews and customer risk |
| Senior Management | Strategic decisions | Performance trends and improvement opportunities |

These are simulated stakeholder roles for the portfolio case study, not actual Olist employees or commissioned business stakeholders.

---

## 5. Project Scope

### 5.1 In Scope

**A. Overall Order Performance**
- Order volume.
- Delivered, cancelled and unavailable order outcomes.
- Historical order trends.

**B. Logistics SLA Performance**
- Delivery-promise adherence.
- On-time and late delivery rates.
- Average late delivery delay.
- Purchase-to-delivery lead time.
- Purchase-to-approval duration.
- Approval-to-carrier handover duration.
- Carrier-to-customer delivery duration.

**C. Operational and Geographical Analysis**
- Seller-associated performance.
- Customer destination geography.
- Seller origin geography.
- Product category comparisons.
- Freight charge analysis.
- Product physical characteristics where data quality permits.

**D. Customer Experience**
- Review score distributions.
- Negative review rates.
- Delivery outcome versus customer satisfaction.
- Poor delivery-experience segmentation.

**E. Customer Retention Signals**
- Repeat-customer identification.
- Poor versus positive delivery-experience cohorts.
- Subsequent order behaviour within 90 days.
- Customer-level operational risk indicators.

**F. Technical Deliverables**
- SQL Server database and analytical models.
- Data quality validation.
- Python EDA and statistical analysis.
- KPI framework.
- Power BI executive dashboard.
- Executive report and recommendations.

### 5.2 Out of Scope

| Excluded Activity | Reason |
|---|---|
| Actual contractual SLA compliance | Contractual agreements and targets are unavailable. |
| Courier-specific performance | Reliable carrier identifiers are unavailable. |
| Warehouse inventory optimisation | No historical inventory records. |
| Actual logistics profitability | Freight charges do not represent complete logistics expenditure. |
| Predictive customer churn | No explicit churn labels or customer departure information. |
| Customer lifetime value | Complete customer profitability information is unavailable. |
| Checkout abandonment | No website browsing or checkout-event information. |
| Live delivery tracking | The dataset is historical. |
| Causal proof of customer retention impact | Observational data alone cannot establish causality. |

---

## 6. Dataset Requirements

### 6.1 Source

Brazilian E-Commerce Public Dataset by Olist.

https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce

Historical activity: Approximately September 2016 to October 2018. Exact source date coverage will be verified during data profiling.

### 6.2 Required Tables

| Source Table | Analytical Purpose |
|---|---|
| olist_orders_dataset | Order lifecycle and delivery timestamps |
| olist_order_items_dataset | Purchased products, sellers, prices and freight |
| olist_customers_dataset | Customer identification and geography |
| olist_sellers_dataset | Seller identification and geography |
| olist_order_reviews_dataset | Customer ratings and reviews |
| olist_products_dataset | Product information and characteristics |
| olist_order_payments_dataset | Payment information |
| olist_geolocation_dataset | Geographical coordinates |
| product_category_name_translation | Product category translation |

### 6.3 Important Relationship Requirements

- Orders connect to customers through customer_id.
- Orders connect to order items through order_id.
- Orders connect to reviews through order_id.
- Order items connect to sellers through seller_id.
- Order items connect to products through product_id.
- Products connect to translated categories through product_category_name.

The customer_unique_id field must be used for cross-order customer identification.

The customer_id field is order-specific and must not be used alone to identify repeat customers.

The orders table contains one record per order, while items, payments and reviews may contain multiple records per order.

All analytical calculations must respect the grain of each table and prevent duplicate counting caused by one-to-many joins.

---

## 7. Delivery SLA Business Definition

The dataset does not provide contractual SLA agreements.

Therefore, the project will use **customer delivery-promise adherence as an operational SLA proxy**.

The comparison uses:

- Actual delivery date: order_delivered_customer_date.
- Estimated delivery date: order_estimated_delivery_date.

| Condition | Classification |
|---|---|
| Actual delivery date earlier than estimated date | Early |
| Actual delivery date equal to estimated date | On time |
| Actual delivery date later than estimated date | Late |

**Date comparison rule:** Both fields must be converted to calendar dates before comparison.

This prevents deliveries occurring later in the day on the estimated date from being incorrectly marked late.

### 7.1 Eligible Populations

**Placed orders:** Distinct orders with valid purchase timestamps.

**Delivered orders:** Orders with order_status = 'delivered'.

**SLA-eligible delivered orders:** Delivered orders with both actual and estimated delivery dates available.

**Reviewed delivered orders:** Delivered orders with a valid selected review score.

**Resolved order outcomes:** Delivered, canceled and unavailable statuses.

Unresolved statuses will be reported separately rather than silently excluded from overall order reporting.

---

## 8. KPI Requirements

The project maintains a complete KPI Dictionary in:

docs/KPI_Dictionary.md

Management-facing primary KPIs:

1. Total Placed Orders.
2. Delivered Order Rate.
3. Cancellation Rate.
4. On-Time Delivery Rate.
5. Median Delivery Lead Time.
6. Average Late Delivery Delay.
7. Negative Review Rate.
8. 90-Day Subsequent-Order Rate by Delivery-Experience Cohort.

Supporting diagnostic indicators:

- Purchase-to-approval duration.
- Approval-to-carrier handover duration.
- Carrier-to-customer delivery duration.
- Freight-to-product value ratio.
- Negative review rate by delivery outcome.
- Seller and geographical delivery performance.
- Poor delivery-experience customer exposure.

All formulas, denominators, eligibility conditions, exclusions and calculation grains are specified in the KPI Dictionary.

The KPI Dictionary is the authoritative measurement specification.

---

## 9. Customer Retention Analysis Requirements

### 9.1 Retention Proxy

The dataset does not contain a direct churn indicator.

Customer retention will therefore be investigated using observed subsequent-order behaviour.

Customers will be identified through customer_unique_id.

### 9.2 Experience Cohorts

| Cohort | Index-order conditions |
|---|---|
| Poor Experience | Late delivery and selected review score ≤ 2 |
| Positive Experience | On-time delivery and selected review score ≥ 4 |

The index order will be the customer's earliest eligible delivered order with valid delivery dates and a valid selected review score.

This is the earliest eligible observed experience in the dataset, not necessarily the customer's first-ever purchase.

Customers whose index experience does not meet either cohort definition will be excluded from the primary two-cohort comparison.

### 9.3 Follow-up Window

The subsequent-order observation period will be 90 days after the index order's actual delivery timestamp.

A customer is eligible only when the full 90-day follow-up period is observable before the dataset observation cutoff.

The cutoff will be derived from the maximum valid order purchase timestamp in the source dataset.

Subsequent orders must:
- Belong to the same customer_unique_id.
- Have a distinct order_id.
- Have a purchase timestamp strictly after index delivery.
- Fall within the 90-day follow-up window.

The analysis will measure subsequent order placement, not successful subsequent delivery.

### 9.4 Interpretation

The resulting measure represents an observed repeat-order signal.

It does not prove that delivery performance caused customers to return or leave.

Selection bias, incomplete historical observation, customer acquisition timing and missing reviews must be considered when interpreting results.

---

## 10. Analytical Segmentation

| Dimension | Required Investigation |
|---|---|
| Time | Monthly and quarterly trends |
| Customer geography | State and city |
| Seller geography | Seller state and city |
| Seller | Seller-associated delivery performance |
| Product category | Category-level delivery performance |
| Product characteristics | Weight and dimensions |
| Delivery outcome | Early, on time and late |
| Customer experience | Positive, neutral and negative |
| Customer behaviour | Repeat-order and subsequent-order patterns |

Seller attribution must account for multiple sellers within an order.

Order-level delivery outcomes should primarily be used for single-seller orders when preparing seller-specific performance rankings. Multi-seller orders must be separately identified or treated using an explicitly documented alternative attribution method.

---

## 11. Technical and Business Requirements

| ID | Requirement | Priority |
|---|---|---|
| BR-001 | Integrate all nine source datasets. | Must |
| BR-002 | Preserve original source data. | Must |
| BR-003 | Establish relational relationships and table grain. | Must |
| BR-004 | Prevent join-driven duplication. | Must |
| BR-005 | Implement documented KPI definitions. | Must |
| BR-006 | Measure delivery-promise adherence. | Must |
| BR-007 | Investigate operational and geographical differences. | Must |
| BR-008 | Analyse delivery outcomes against customer reviews. | Must |
| BR-009 | Evaluate observed 90-day subsequent ordering. | Must |
| BR-010 | Develop an executive Power BI dashboard. | Must |
| BR-011 | Produce an evidence-based executive report. | Must |
| BR-012 | Maintain reproducible scripts and documentation. | Must |

---

## 12. Acceptance Criteria

### 12.1 Data Quality

- All nine source datasets are accounted for.
- Raw source row counts are documented and reconciled.
- Table grain and relationships are documented.
- Duplicate keys, missing records, invalid values and orphan relationships are investigated.
- Original source data is preserved.
- One-to-many joins do not inflate order-level metrics.

### 12.2 KPI Accuracy

- All KPI formulas and populations are documented.
- On-time and late classifications use calendar-date comparisons.
- Missing timestamps are handled explicitly.
- Operational stage durations use valid chronological timestamps.
- Customer-level analysis uses customer_unique_id.
- Review records follow the agreed order-level selection rule.
- KPI calculations reconcile between SQL Server and Power BI.

### 12.3 Retention Investigation

- Experience cohorts are consistently defined.
- The 90-day follow-up window is correctly applied.
- Customers without a complete follow-up window are excluded.
- Cohort sizes and sample limitations are reported.
- Findings are presented as observed associations rather than proven causes or predictions.

### 12.4 Business Reporting

- All principal stakeholder questions have an analytical response.
- Dashboard measures follow the KPI Dictionary.
- Important findings are supported by validated evidence.
- At least three prioritised improvement opportunities are identified where the evidence supports them.
- Recommendations communicate business implications and limitations.

### 12.5 Reproducibility and Governance

- SQL scripts have a documented execution order.
- Python notebooks include methodology and interpretation.
- Required dependencies and connection instructions are documented.
- Credentials are excluded from GitHub.
- Raw and processed datasets are not committed by default.
- Dataset source and usage conditions are acknowledged.

No arbitrary 95% delivery target will be introduced without an approved business benchmark.

---

## 13. Assumptions, Constraints and Risks

| ID | Assumption / Risk | Mitigation |
|---|---|---|
| A01 | Estimated delivery date represents the customer-facing promise. | Use it as the operational SLA proxy. |
| A02 | Actual delivery timestamp represents customer receipt. | Validate chronology and completeness. |
| A03 | customer_unique_id identifies customers across purchases. | Use for customer analysis. |
| A04 | Review scores indicate recorded customer feedback. | Treat as a satisfaction proxy. |
| R01 | Missing timestamps may affect SLA coverage. | Quantify missingness and eligible populations. |
| R02 | Multiple item, payment and review records can inflate aggregates. | Respect grain and validate joins. |
| R03 | Orders may involve multiple sellers. | Separate multi-seller cases in seller rankings. |
| R04 | Customer observation windows vary. | Apply full 90-day follow-up eligibility. |
| R05 | No contractual SLA or courier identifier exists. | Avoid unsupported compliance and carrier claims. |
| R06 | Observational data cannot prove causation. | Report associations and limitations. |

---

## 14. Expected Deliverables

| Deliverable | Location |
|---|---|
| Business Requirements Document | docs/ |
| Project Charter | docs/ |
| KPI Dictionary | docs/ |
| Tool Stack and Architecture | docs/ |
| Decision Log | docs/ |
| SQL database and analytical models | sql/ |
| Python EDA and statistical analysis | notebooks/ |
| Power BI dashboard | powerbi/ |
| Executive report | reports/ |
| Supporting diagrams and visuals | assets/ |

---

## 15. Governance and Approval

This document defines the agreed business scope and measurement requirements for the portfolio case study.

Changes to project scope, KPI definitions or analytical assumptions must be recorded in the Decision Log.

The project follows formal approval gates:

1. Business requirements and project definition.
2. SQL Server architecture and ingestion.
3. Data quality and validation.
4. Exploratory and diagnostic analysis.
5. KPI and dashboard development.
6. Executive reporting and final recommendations.

| Approval Role | Name | Status |
|---|---|---|
| Project Owner | Abhi Udnoor | Pending approval |
| Business Owner | Simulated Head of Marketplace Operations | Portfolio-case-study assumption |

**Current Document Status: Proposed for Approval**

---

*End of Business Requirements Document.*
