# Business Requirements Document (BRD)
# Logistics SLA Performance & Customer Retention Risk Analysis

| Document Control | Details |
|---|---|
| Project ID | OLIST-SLA-RET-001 |
| Version | 1.0 |
| Status | Proposed for Business Approval |
| Prepared Date | 16 November 2026 |
| Project Owner | Abhi Udnoor |
| Business Owner | Head of Marketplace Operations (Simulated) |
| Business Domain | E-commerce Marketplace / Supply Chain |
| Target Business Perspective | Prague, Czechia |
| Data Source | Brazilian E-Commerce Public Dataset by Olist |
| Analytical Classification | Historical Descriptive and Diagnostic Analytics |

---

# 1. Executive Business Overview

## 1.1 Business Background

An e-commerce marketplace coordinates transactions between customers and independent sellers while managing multiple activities associated with order fulfilment and delivery.

Customers expect their orders to arrive within the delivery dates communicated during checkout. Delays, inconsistent fulfilment performance and poor delivery experiences can negatively affect customer satisfaction and future purchasing behaviour.

Management requires a consolidated analytical view of logistics performance and customer purchasing patterns to understand where operational inefficiencies occur and which customer segments may require attention.

This project simulates an analytical engagement for an e-commerce marketplace operating in a Prague/European retail environment.

The investigation will use the historical Brazilian E-Commerce Public Dataset by Olist as its analytical source.

**Business-context limitation:** This is a Prague-oriented portfolio case study using Brazilian historical data. It does not represent the actual operational performance of a Czech company or current Olist operations.

## 1.2 Business Problem

The business currently lacks a consolidated analytical view connecting:

- Customer delivery commitments.
- Actual order delivery performance.
- Order fulfilment and logistics stages.
- Seller and geographical performance.
- Customer satisfaction.
- Observed subsequent purchasing behaviour.

Without these connected measurements, management cannot reliably identify where delivery performance is falling short, understand the customer experience associated with those failures, or prioritise potential operational improvements.

## 1.3 Primary Business Question

**How effectively does the marketplace meet its customer delivery commitments, which operational and geographical segments are associated with delivery delays, and are poor delivery experiences associated with a lower likelihood of subsequent customer orders?**

---

# 2. Business Objectives

The project will address five primary objectives.

| ID | Business Objective | Expected Analytical Outcome |
|---|---|---|
| BO-01 | Establish overall logistics performance. | Baseline order fulfilment and delivery SLA indicators. |
| BO-02 | Identify delivery inefficiencies. | Quantification of delays and investigation of fulfilment stages. |
| BO-03 | Identify operational performance differences. | Seller, destination geography and product-level comparisons. |
| BO-04 | Evaluate customer experience. | Measurement of customer ratings and negative delivery experiences. |
| BO-05 | Investigate customer retention signals. | Comparison of observed repeat-order behaviour across delivery-experience cohorts. |

## 2.1 Detailed Business Questions

### Logistics SLA Performance

1. What proportion of eligible delivered orders arrive within the estimated delivery date?
2. What is the frequency and severity of late deliveries?
3. How long do customers wait between placing an order and receiving it?
4. Which fulfilment stage contributes the most elapsed time?
5. Do delivery outcomes differ across seller and customer locations?
6. Are some product categories associated with longer delivery times?
7. How do freight charges vary across product categories and geographical segments?

### Customer Experience and Retention Risk

8. What proportion of delivered orders receive negative customer reviews?
9. Are late deliveries associated with lower review scores?
10. Which customer segments experience both late delivery and poor ratings?
11. What proportion of customers place another order within 90 days of an eligible first delivery?
12. Does observed subsequent ordering differ between customers with poor and positive delivery experiences?

---

# 3. Project Scope

## 3.1 In-Scope Activities

### A. Logistics Performance Analysis

- Order volume and delivery outcome analysis.
- Order completion and cancellation measurement.
- Customer delivery lead-time analysis.
- Delivery-date adherence analysis.
- Delivery delay measurement.
- Fulfilment-stage duration analysis.
- Identification of operational performance differences.

### B. Seller and Geographical Analysis

- Seller-associated delivery performance.
- Destination-state delivery performance.
- Seller-to-customer geographical comparisons.
- Product category and shipping performance.
- Freight charge patterns.

### C. Customer Experience Analysis

- Review score distribution.
- Negative review rate.
- Delivery delay versus review score analysis.
- Identification of poor delivery-experience customer segments.

### D. Observed Customer Retention Analysis

- Identification of unique customers using `customer_unique_id`.
- First observed delivery-experience cohort analysis.
- 90-day subsequent-order measurement.
- Comparison of subsequent-order behaviour between positive and poor delivery-experience cohorts.

### E. Technical Deliverables

- SQL Server relational database and analytical models.
- Data profiling and validation.
- Python exploratory data analysis.
- Statistical relationship testing.
- Power BI executive dashboard.
- Management report and recommendations.

## 3.2 Out-of-Scope Activities

The available dataset does not support reliable investigation of the following:

| Excluded Area | Reason |
|---|---|
| Actual contractual SLA compliance | Contractual SLA agreements and targets are unavailable. |
| Individual courier performance | Reliable carrier-specific identifiers are unavailable. |
| Warehouse inventory management | No historical warehouse inventory records. |
| Actual logistics profitability | Freight charges are not equivalent to actual delivery costs. |
| True customer churn prediction | No explicit churn labels or customer departure reasons. |
| Customer lifetime value | Complete customer profitability and lifetime financial information is unavailable. |
| Website checkout abandonment | No browsing, cart or checkout-event data. |
| Live delivery tracking | Historical dataset only. |
| Causal proof of retention impact | Observational data cannot establish causality independently. |

---

# 4. Dataset Requirements

## 4.1 Source

Brazilian E-Commerce Public Dataset by Olist.

Source: https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce

## 4.2 Required Source Tables

| Source Table | Analytical Purpose |
|---|---|
| `olist_orders_dataset` | Order status, purchase date and delivery timestamps |
| `olist_order_items_dataset` | Product, seller, item price and freight information |
| `olist_customers_dataset` | Customer identification and geographical details |
| `olist_sellers_dataset` | Seller identification and origin geography |
| `olist_order_reviews_dataset` | Customer ratings and review information |
| `olist_products_dataset` | Product categories and physical characteristics |
| `olist_order_payments_dataset` | Payment information |
| `olist_geolocation_dataset` | ZIP-prefix geographical information |
| `product_category_name_translation` | English product category descriptions |

## 4.3 Important Data Relationships

The analytical model will primarily connect:

- Orders to customers through `customer_id`.
- Orders to order items through `order_id`.
- Orders to reviews through `order_id`.
- Order items to sellers through `seller_id`.
- Order items to products through `product_id`.
- Products to category translations through `product_category_name`.

`customer_unique_id` will be used for customer-level repeat-order analysis because `customer_id` is assigned separately to individual orders.

The order table represents one order per record, whereas order items and payments may contain multiple records per order.

All order-level performance metrics must be protected against duplication caused by one-to-many joins.

---

# 5. Business Definitions and Measurement Rules

## 5.1 Delivery SLA Definition

For this project, the delivery SLA is an operational proxy based on the estimated delivery date communicated to the customer.

The measurement compares:

- Actual customer delivery date.
- Estimated customer delivery date.

An order is classified as:

| Condition | Classification |
|---|---|
| Actual delivery date earlier than estimated date | Early |
| Actual delivery date equal to estimated date | On time |
| Actual delivery date later than estimated date | Late |

**Measurement rule:** Both values will be converted to calendar dates before comparison.

Time-of-day differences will not determine SLA failure because the estimated delivery field represents a date commitment.

## 5.2 Eligible Population

The following populations will be used consistently:

**Placed Orders**

Distinct orders with a valid purchase timestamp.

**Resolved Orders**

Orders with one of the following terminal outcome statuses:

- `delivered`
- `canceled`
- `unavailable`

Orders in other statuses will be reported separately as unresolved or non-terminal records.

**SLA-Eligible Delivered Orders**

Orders meeting all three conditions:

- `order_status = 'delivered'`
- Actual delivery date is available.
- Estimated delivery date is available.

**Reviewed Delivered Orders**

Delivered orders with a valid customer review score after the agreed order-level review selection rule.

Missing information will not automatically be treated as a negative outcome.

---

# 6. KPI Dictionary and Exact Calculation Formulas

The following definitions establish the initial business measurement contract.

All measures must be calculated using distinct business entities at their appropriate analytical grain.

## 6.1 Overall Order Performance KPIs

### KPI-01: Total Placed Orders

**Purpose:** Measure overall marketplace order volume.

Formula:

Total Placed Orders = COUNT(DISTINCT order_id)

Population: Orders with a valid purchase timestamp.

### KPI-02: Resolved Order Rate

**Purpose:** Measure the proportion of placed orders with a recognised terminal outcome.

Formula:

Resolved Order Rate (%) =

(Distinct Resolved Orders / Total Placed Orders) × 100

Resolved outcomes: delivered, canceled and unavailable.

### KPI-03: Delivered Completion Rate

**Purpose:** Measure the proportion of resolved orders successfully delivered.

Formula:

Delivered Completion Rate (%) =

(Distinct Delivered Orders / Distinct Resolved Orders) × 100

### KPI-04: Cancellation Rate

Formula:

Cancellation Rate (%) =

(Distinct Canceled Orders / Distinct Resolved Orders) × 100

### KPI-05: Unavailable Order Rate

Formula:

Unavailable Order Rate (%) =

(Distinct Unavailable Orders / Distinct Resolved Orders) × 100

---

## 6.2 Logistics SLA Performance KPIs

Let:

E = Number of SLA-eligible delivered orders.

An eligible order must have both actual and estimated delivery dates.

### KPI-06: On-Time Delivery Rate

**Purpose:** Measure delivery-promise adherence.

Formula:

On-Time Delivery Rate (%) =

(Delivered Orders Where Actual Delivery Date ≤ Estimated Delivery Date / E) × 100

### KPI-07: Late Delivery Rate

**Purpose:** Quantify the proportion of deliveries missing the estimated delivery date.

Formula:

Late Delivery Rate (%) =

(Delivered Orders Where Actual Delivery Date > Estimated Delivery Date / E) × 100

On-time and late delivery rates should total 100% for the same eligible population.

Early deliveries are included in on-time delivery performance.

### KPI-08: Average Late Delivery Delay

**Purpose:** Measure delay severity among late orders.

Formula:

Average Late Delivery Delay (Days) =

SUM(Actual Delivery Date − Estimated Delivery Date) / Number of Late Delivered Orders

Population: Late deliveries only.

Both dates are measured using calendar days.

On-time deliveries are excluded from this particular average.

### KPI-09: Median End-to-End Delivery Lead Time

**Purpose:** Measure typical customer waiting time.

Formula:

Median Delivery Lead Time (Days) =

MEDIAN(Actual Delivery Timestamp − Purchase Timestamp)

Population: Delivered orders with valid purchase and actual delivery timestamps.

The duration uses elapsed time, rather than calendar-date comparison.

### KPI-10: Purchase-to-Approval Duration

**Purpose:** Investigate the time between order creation and payment approval.

Formula:

Median Approval Duration (Hours) =

MEDIAN(Approval Timestamp − Purchase Timestamp)

Population: Orders with valid purchase and approval timestamps.

### KPI-11: Approval-to-Carrier Handover Duration

**Purpose:** Investigate the elapsed time before the order is handed to the logistics partner.

Formula:

Median Pre-Carrier Duration (Hours) =

MEDIAN(Carrier Handover Timestamp − Approval Timestamp)

This is an operational proxy for the period covering seller preparation and handover. It does not separately measure packing or warehouse handling.

### KPI-12: Carrier-to-Customer Delivery Duration

**Purpose:** Measure the period between carrier handover and customer receipt.

Formula:

Median Carrier Transit Duration (Hours) =

MEDIAN(Customer Delivery Timestamp − Carrier Handover Timestamp)

The three stage durations will help identify where elapsed time is concentrated.

---

## 6.3 Freight and Shipping KPIs

### KPI-13: Average Freight Charge per Delivered Order

Formula:

Average Freight Charge per Delivered Order =

SUM(Freight Value for Delivered Order Items) / Number of Delivered Orders with Item Records

Freight is summed at order-item grain before being aggregated to orders.

### KPI-14: Freight-to-Product Value Ratio

**Purpose:** Measure customer freight charges relative to product value.

Formula:

Freight-to-Product Value Ratio (%) =

(SUM(Freight Value) / SUM(Product Item Price)) × 100

Population: Delivered order items with valid freight and product price values.

**Important:** Freight value represents the recorded customer-facing shipping charge, not verified actual logistics expenditure.

---

## 6.4 Customer Experience KPIs

For consistent order-level analysis, where multiple valid review records exist for one order, the latest valid review will be selected using review creation date, with deterministic tie-breaking.

### KPI-15: Average Order Review Score

Formula:

Average Review Score =

SUM(Selected Order Review Scores) / Number of Reviewed Delivered Orders

Review scores range from 1 to 5.

### KPI-16: Negative Review Rate

**Purpose:** Measure the share of poor customer ratings.

Business definition:

- Scores 1 and 2: Negative.
- Score 3: Neutral.
- Scores 4 and 5: Positive.

Formula:

Negative Review Rate (%) =

(Number of Reviewed Delivered Orders with Score ≤ 2 / Number of Reviewed Delivered Orders) × 100

### KPI-17: Poor Delivery-Experience Order Rate

**Purpose:** Measure the share of eligible customer orders that experienced both late delivery and a negative review.

Formula:

Poor Delivery-Experience Rate (%) =

(Number of Late Delivered Orders with Review Score ≤ 2 / Number of Delivered Orders with Both Valid SLA Dates and Valid Review Scores) × 100

This KPI measures the combined occurrence of two observed events. It does not establish that delivery delay caused the negative review.

---

## 6.5 Customer Repeat-Order and Retention-Risk KPIs

The actual dataset does not contain an explicit churn variable.

Therefore, customer retention will be examined through observable repeat-order behaviour and negative delivery-experience indicators.

### KPI-18: Observed Repeat-Customer Rate

**Purpose:** Establish how many distinct customers placed multiple delivered orders during the observation period.

Formula:

Observed Repeat-Customer Rate (%) =

(Number of Unique Customers with ≥ 2 Delivered Orders / Number of Unique Customers with ≥ 1 Delivered Order) × 100

Customer identity must be based on `customer_unique_id`, not `customer_id`.

This is an observed historical repeat-customer proportion, not a time-adjusted customer retention rate.

### KPI-19: 90-Day Subsequent-Order Rate by Delivery-Experience Cohort

**Purpose:** Investigate whether customers with poor delivery experiences demonstrate different subsequent-order behaviour from customers with positive delivery experiences.

Cohort definitions:

| Cohort | Index-order conditions |
|---|---|
| Poor Experience | Late delivery and review score ≤ 2 |
| Positive Experience | On-time delivery and review score ≥ 4 |

Index order:

The customer's earliest delivered order with complete SLA dates and a valid selected review score.

Follow-up window:

The 90 days following the actual delivery date of the index order.

Formula:

90-Day Subsequent-Order Rate (%) =

(Number of Eligible Customers with at Least One Subsequent Distinct Order Placed Within 90 Days / Number of Eligible Customers with a Complete 90-Day Observation Window) × 100

Eligibility rules:

- A customer must have an identifiable `customer_unique_id`.
- The index order must belong to one of the two defined experience cohorts.
- The customer must have at least 90 days of observable follow-up before the dataset observation end date.
- A subsequent order is a distinct order placed after the index delivery and within the 90-day period.

This measure represents an observed subsequent-order signal, not a prediction of future churn.

Customers with insufficient observation time will be excluded from the cohort-rate denominator.

### KPI-20: Poor-Experience Customer Exposure

**Purpose:** Identify customers associated with negative delivery experiences.

Formula:

Poor-Experience Customer Exposure (%) =

(Number of Unique Customers with at Least One Late and Negatively Reviewed Delivered Order / Number of Unique Customers with Eligible Reviewed Deliveries) × 100

A customer is flagged when at least one eligible delivered order has both:

- Late delivery.
- Review score ≤ 2.

This flag is an operational early-warning indicator, not a verified customer attrition event.

---

# 7. Analytical Segmentation Requirements

The KPIs above must be investigated across relevant operational dimensions.

| Dimension | Required Analysis |
|---|---|
| Time | Monthly, quarterly and historical trends |
| Customer geography | State and city |
| Seller geography | Seller state and city |
| Seller | Seller-associated delivery performance |
| Product | Product category |
| Product characteristics | Weight and dimensions, where data quality permits |
| Delivery outcome | Early, on-time and late |
| Customer experience | Positive, neutral and negative reviews |
| Customer behaviour | First observed order and subsequent ordering |

**Seller attribution rule:**

Order-level delivery timestamps belong to the overall order. When an order contains multiple sellers, assigning the whole delivery result to every individual seller could create misleading conclusions.

Seller performance rankings will therefore primarily use single-seller orders, while multi-seller orders will be analysed separately.

---

# 8. Business and Technical Requirements

| Requirement ID | Requirement | Priority |
|---|---|---|
| BR-001 | Integrate all nine source datasets. | Must |
| BR-002 | Preserve the original source data. | Must |
| BR-003 | Establish validated relational relationships and table grain. | Must |
| BR-004 | Prevent duplicate counting from one-to-many joins. | Must |
| BR-005 | Develop a documented KPI framework. | Must |
| BR-006 | Calculate delivery-promise adherence and delay severity. | Must |
| BR-007 | Investigate operational stages and geographical variations. | Must |
| BR-008 | Connect delivery outcomes with customer reviews. | Must |
| BR-009 | Evaluate observed repeat-order behaviour. | Must |
| BR-010 | Develop a management-ready Power BI dashboard. | Must |
| BR-011 | Produce an executive report with actionable recommendations. | Must |
| BR-012 | Make the analytical workflow reproducible and documented. | Must |

---

# 9. Expected Deliverables

| Deliverable | Description |
|---|---|
| Business Requirements Document | Approved business objectives, KPIs and requirements |
| SQL Database | Structured source and analytical data layers |
| Data Quality Report | Validation results, defects and cleaning decisions |
| Data Dictionary | Definitions of tables, columns and relationships |
| Python EDA | Descriptive and diagnostic analysis |
| Statistical Analysis | Investigation of selected delivery and customer-experience relationships |
| KPI Framework | Documented business measurements |
| Power BI Dashboard | Interactive executive reporting solution |
| Executive Report | Key findings, business implications and recommendations |

---

# 10. Acceptance Criteria

Project completion will be accepted when the following conditions are satisfied.

## 10.1 Data Foundation

- All nine source files are accounted for.
- Source row counts are documented and reconciled with loaded raw tables.
- Table grain and relationships are documented.
- Duplicate keys, missing values, orphan records and invalid values are investigated.
- One-to-many joins do not inflate order-level measurements.
- Original source records remain preserved.

## 10.2 KPI Accuracy

- All agreed KPIs have documented formulas and eligibility rules.
- On-time and late delivery calculations use calendar dates.
- Missing delivery timestamps are handled explicitly.
- Delivery-stage durations use valid chronological timestamps.
- Customer-level metrics use `customer_unique_id`.
- Review data is reduced to the agreed order-level review selection before joining.
- All reported KPI figures reconcile between their SQL source and Power BI outputs.

## 10.3 Customer Retention Investigation

- Poor and positive experience cohorts are defined consistently.
- Repeat-order calculations use a clearly defined 90-day observation window.
- Customers without sufficient observation time are excluded.
- Cohort sizes and sample limitations are disclosed.
- Findings are presented as observational associations, not causal or predictive claims.

## 10.4 Analytical and Reporting Quality

- Every business question has a documented analytical approach.
- Major findings are supported by validated evidence.
- Dashboard measures are understandable and consistent with the KPI dictionary.
- Dashboard pages answer the agreed stakeholder questions.
- The final report explains operational implications and recommended actions.
- At least three prioritised business-improvement opportunities are supported by analytical findings, where the evidence permits.

## 10.5 Reproducibility and Governance

- SQL scripts are stored in the correct execution order.
- Python notebooks contain explanations and reproducible analysis.
- Required dependencies and connection instructions are documented.
- No database credentials or private information are published.
- Raw and processed source data are not committed to GitHub by default.
- Source attribution and dataset usage conditions are documented.

**Acceptance note:** This is a diagnostic analytics project. No arbitrary target such as 95% on-time delivery will be imposed without an approved business benchmark. The project will establish a historical baseline and identify improvement opportunities.

---

# 11. Assumptions, Constraints and Risks

| ID | Assumption / Constraint | Management Treatment |
|---|---|---|
| A01 | Estimated delivery date represents the customer-facing delivery commitment. | Use as the operational SLA proxy. |
| A02 | Actual delivery date represents customer receipt. | Validate timestamps and chronology. |
| A03 | `customer_unique_id` identifies repeat customers. | Use for customer-level analysis. |
| A04 | Review scores represent recorded customer feedback. | Treat ratings as satisfaction indicators. |
| A05 | The data represents historical Brazilian marketplace activity. | Do not generalise directly to current Czech operations. |
| R01 | Missing delivery timestamps. | Quantify and report data coverage. |
| R02 | Multiple records per order in item, payment and review tables. | Respect table grain and prevent join fan-out. |
| R03 | Multi-seller orders. | Avoid unsupported seller-level blame. |
| R04 | Incomplete customer observation windows. | Apply cohort follow-up eligibility rules. |
| R05 | No contractual SLA or carrier identifier. | Avoid contractual compliance and courier attribution claims. |
| R06 | Observational review and purchasing data. | Avoid unsupported causal claims. |

---

# 12. Project Governance and Approval

This BRD defines the initial analytical scope and business measurement requirements.

Changes to stakeholder requirements, KPI definitions or scope must be documented in the project decision log.

The project will progress through approved phase gates:

1. Business requirements and project charter.
2. SQL Server database architecture and ingestion.
3. Data quality and validation.
4. Python exploratory and diagnostic analysis.
5. KPI and dashboard development.
6. Executive reporting and final business recommendations.

**Current approval status:** Awaiting project-owner sign-off.

| Approval Role   | Name                                     | Status                          |
|-----------------|-----------------------------------------------------------------------------
| Project Owner   | Abhi Udnoor                              | Pending                         |
| Business Owner  | Simulated Head of Marketplace Operations | Portfolio-case-study assumption |

---

# Document End

