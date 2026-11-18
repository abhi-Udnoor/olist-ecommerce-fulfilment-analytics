# KPI Dictionary
# Logistics SLA Performance & Customer Retention Risk Analysis

## 1. Document Purpose

This document defines the business meaning, calculation methodology, population, exclusions and interpretation rules for all project KPIs.

It is the authoritative measurement specification for SQL Server, Python and Power BI.

All calculations must respect the underlying table grain and avoid duplicate counting.

## 2. Common Business Rules

### 2.1 Order Identification

- Order-level calculations use distinct order_id.
- Customer-level calculations use customer_unique_id.
- customer_id must not be treated as a permanent customer identifier.

### 2.2 Delivery SLA Eligibility

An SLA-eligible delivered order must satisfy:

- order_status = 'delivered'.
- Actual delivery timestamp is available.
- Estimated delivery timestamp is available.

### 2.3 Delivery Classification

Compare calendar dates rather than full timestamps.

- Early: actual delivery date < estimated delivery date.
- On time: actual delivery date = estimated delivery date.
- Late: actual delivery date > estimated delivery date.

### 2.4 Review Selection

Where multiple review records exist for one order:

1. Retain valid review scores from 1 to 5.
2. Select the latest review using review_creation_date.
3. Use review_id as a deterministic tie-breaker.
4. Retain no more than one selected review per order.

### 2.5 Missing and Invalid Values

- Missing values are not automatically treated as negative outcomes.
- Invalid or negative stage durations must be investigated.
- Denominators must contain only eligible records.
- Missing or invalid data must be reported through data-quality checks.

---

## 3. Executive KPI Register

These are the primary management-facing measures.

| KPI ID | KPI Name | Business Purpose |
|---|---|---|
| KPI-01 | Total Placed Orders | Overall order volume |
| KPI-02 | Delivered Order Rate | Successful delivery share |
| KPI-03 | Cancellation Rate | Cancelled order share |
| KPI-04 | On-Time Delivery Rate | Delivery-promise adherence |
| KPI-05 | Median Delivery Lead Time | Typical customer waiting time |
| KPI-06 | Average Late Delivery Delay | Severity of delivery delays |
| KPI-07 | Negative Review Rate | Overall customer dissatisfaction |
| KPI-08 | 90-Day Subsequent-Order Rate by Cohort | Observed customer return behaviour |

## 4. Detailed KPI Definitions

### KPI-01: Total Placed Orders

**Purpose:** Measure overall order volume.

Formula:

COUNT(DISTINCT order_id)

Population: Orders with a valid purchase timestamp.

Unit: Orders.

### KPI-02: Delivered Order Rate

**Purpose:** Measure the share of placed orders eventually recorded as delivered.

Formula:

(Distinct Delivered Orders / Distinct Placed Orders) × 100

Population: All valid placed orders.

Unit: Percentage.

### KPI-03: Cancellation Rate

**Purpose:** Measure the share of placed orders recorded as cancelled.

Formula:

(Distinct Cancelled Orders / Distinct Placed Orders) × 100

Population: All valid placed orders.

Unit: Percentage.

Note: This is an observed historical outcome rate. Orders in unresolved statuses remain in the denominator and are not silently excluded.

### KPI-04: On-Time Delivery Rate

**Purpose:** Measure delivery-promise adherence.

Formula:

(Distinct Eligible Delivered Orders with Actual Delivery Date ≤ Estimated Delivery Date / Distinct SLA-Eligible Delivered Orders) × 100

Population: Delivered orders with both required delivery dates.

Unit: Percentage.

Early deliveries count as on time.

### KPI-05: Median Delivery Lead Time

**Purpose:** Measure typical customer waiting time.

Formula:

MEDIAN(
Actual Delivery Timestamp - Purchase Timestamp
)

Convert elapsed duration to days by dividing elapsed seconds by 86,400.

Population: Delivered orders with valid purchase and actual delivery timestamps.

Unit: Days.

### KPI-06: Average Late Delivery Delay

**Purpose:** Measure the severity of late delivery.

Formula:

SUM(Actual Delivery Date - Estimated Delivery Date) in calendar days
/
Number of Late Delivered Orders

Population: Late delivered orders only.

Unit: Calendar days.

On-time and early deliveries are excluded.

### KPI-07: Negative Review Rate

**Purpose:** Measure overall customer dissatisfaction.

Review classification:

- Scores 1 and 2: Negative.
- Score 3: Neutral.
- Scores 4 and 5: Positive.

Formula:

(Distinct Reviewed Delivered Orders with Score ≤ 2 / Distinct Reviewed Delivered Orders) × 100

Population: Delivered orders with a valid selected review.

Unit: Percentage.

### KPI-08: 90-Day Subsequent-Order Rate by Delivery-Experience Cohort

**Purpose:** Investigate observed subsequent purchasing behaviour.

Cohort definitions:

Poor Experience:
- Index order classified as late.
- Selected review score ≤ 2.

Positive Experience:
- Index order classified as on time.
- Selected review score ≥ 4.

Index order:

The customer's earliest eligible delivered order with valid SLA dates and a selected valid review within the dataset observation period.

This is the earliest eligible observed experience, not necessarily the customer's first-ever order.

Follow-up window:

90 days after the index order's actual delivery timestamp.

Eligibility:

The complete 90-day observation window must be available before the dataset observation cutoff.

The cutoff is the maximum valid purchase timestamp in the source order dataset.

Formula for each cohort:

(Number of Eligible Customers with at Least One Subsequent Placed Order Within 90 Days / Number of Eligible Customers with a Complete 90-Day Follow-up Window) × 100

A subsequent order must:

- Belong to the same customer_unique_id.
- Have a distinct order_id.
- Have a purchase timestamp strictly after the index delivery timestamp.
- Be placed on or before 90 days after the index delivery timestamp.

Subsequent orders are counted based on order placement, regardless of eventual delivery status.

Unit: Percentage.

Interpretation: Observed subsequent-order behaviour, not proven customer retention or churn.

---

## 5. Supporting Operational KPIs

### KPI-09: Unavailable Order Rate

Formula:

(Distinct Unavailable Orders / Distinct Placed Orders) × 100

Unit: Percentage.

### KPI-10: Late Delivery Rate

Formula:

(Distinct Eligible Late Delivered Orders / Distinct SLA-Eligible Delivered Orders) × 100

Unit: Percentage.

On-time delivery rate plus late delivery rate must equal 100% for the same eligible population.

### KPI-11: Median Purchase-to-Approval Duration

Formula:

MEDIAN(Approval Timestamp - Purchase Timestamp)

Population: Orders with valid chronological purchase and approval timestamps.

Unit: Hours.

### KPI-12: Median Approval-to-Carrier Handover Duration

Formula:

MEDIAN(Carrier Handover Timestamp - Approval Timestamp)

Population: Orders with valid chronological approval and carrier handover timestamps.

Unit: Hours.

Interpretation: Proxy for the period covering seller preparation and handover. It does not isolate actual packing time.

### KPI-13: Median Carrier-to-Customer Delivery Duration

Formula:

MEDIAN(Customer Delivery Timestamp - Carrier Handover Timestamp)

Population: Orders with valid chronological carrier handover and customer delivery timestamps.

Unit: Hours.

### KPI-14: Average Freight Charge per Delivered Order

Formula:

SUM(Freight Value Across Delivered Order Items)
/
Distinct Delivered Orders Represented in the Valid Item Population

Aggregation must occur at order-item grain before calculating order-level totals.

Unit: Currency per order.

### KPI-15: Freight-to-Product Value Ratio

Formula:

(SUM(Freight Value) / SUM(Product Item Price)) × 100

Population: Delivered order items with valid freight and product price values.

Unit: Percentage.

The denominator must be greater than zero.

Interpretation: Recorded customer-facing freight charges relative to recorded item prices, not actual logistics expenditure.

### KPI-16: Average Review Score

Formula:

SUM(Selected Valid Review Scores) / Number of Selected Valid Reviews

Population: Reviewed delivered orders.

Unit: Score from 1 to 5.

### KPI-17: Negative Review Rate by Delivery Outcome

Calculate two independent rates:

Late Delivery Negative Review Rate:

(Negatively Reviewed Late Delivered Orders / Reviewed Late Delivered Orders) × 100

On-Time Delivery Negative Review Rate:

(Negatively Reviewed On-Time Delivered Orders / Reviewed On-Time Delivered Orders) × 100

Population: SLA-eligible delivered orders with selected valid reviews.

Unit: Percentage.

This comparison measures association, not causation.

### KPI-18: Poor Delivery-Experience Order Rate

Formula:

(Reviewed SLA-Eligible Delivered Orders That Were Both Late and Negatively Reviewed / All Reviewed SLA-Eligible Delivered Orders) × 100

Negative review means score ≤ 2.

Unit: Percentage.

### KPI-19: Observed Repeat-Customer Share

Formula:

(Unique Customers with at Least Two Delivered Orders / Unique Customers with At Least One Delivered Order) × 100

Customer identity: customer_unique_id.

Population: Customers observed within the full historical dataset.

Unit: Percentage.

Interpretation: Full-observation-period repeat-customer share, not a time-adjusted retention rate.

### KPI-20: Poor-Experience Customer Exposure

Formula:

(Unique Customers with at Least One Late and Negatively Reviewed Eligible Delivery / Unique Customers with at Least One Eligible Reviewed Delivery) × 100

A customer is flagged if at least one eligible delivery is both late and negatively reviewed.

Unit: Percentage.

Interpretation: Historical exposure to poor delivery experiences, not confirmed customer attrition risk.

---

## 6. KPI Measurement and Governance Rules

| Measurement Concern | Agreed Rule |
|---|---|
| Order-level aggregation | Distinct order_id |
| Customer-level aggregation | customer_unique_id |
| SLA comparison | Calendar dates |
| Delivery lead time | Elapsed timestamps |
| Missing delivery dates | Exclude from SLA denominator and report coverage |
| Duplicate review records | Apply agreed latest-valid-review rule |
| Freight calculations | Aggregate at order-item grain first |
| Multiple sellers per order | Handle separately in seller performance attribution |
| Subsequent-order observation | Require complete 90-day follow-up |
| Causal interpretation | Not permitted without supporting causal design |

## 7. Metric Validation

For each KPI:

1. Confirm the source columns.
2. Confirm the appropriate table grain.
3. Validate numerator and denominator populations.
4. Check missing and invalid values.
5. Reconcile results across SQL Server and Power BI.
6. Document any exclusions or changes.

All KPI definitions must be approved before they are used as formal management performance measures.

---

*End of KPI Dictionary.*
