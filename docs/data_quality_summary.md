# Data Quality Assessment & Cleaning Summary

## 1. Project Overview

**Project:** Olist Logistics SLA & Customer Retention Analytics  
**Database:** OlistAnalytics  
**Source:** Brazilian E-Commerce Public Dataset by Olist  
**Database platform:** Microsoft SQL Server

This document summarises the data profiling, quality assessment, cleaning and validation activities performed before analytical exploration.

The objective was to transform the original source data into reliable, typed staging tables while preserving the original information.

## 2. Data Architecture

The project follows a three-layer data architecture:

| Schema | Purpose |
|---|---|
| `raw` | Original source data, preserved without modification |
| `stg` | Typed and validated staging tables |
| `mart` | Business-ready analytical datasets (planned) |

The `audit` schema is reserved for data-quality and process auditing.

## 3. Staging Tables

Nine staging tables were successfully created and populated.

| Staging table | Records |
|---|---:|
| orders | 99,441 |
| order_items | 112,650 |
| order_payments | 103,886 |
| customers | 99,441 |
| sellers | 3,095 |
| products | 32,951 |
| product_category_translation | 71 |
| order_reviews | 99,224 |
| geolocation | 1,000,163 |

All nine tables were checked for successful loading and appropriate data types.

## 4. Data Quality Findings

### 4.1 Primary and Candidate Keys

- Primary keys were established for the staging tables where appropriate.
- The order review table uses a composite primary key: `(review_id, order_id)`.
- `review_id` alone is not unique.
- Geolocation has no established unique row identifier, so no artificial primary key was introduced.

### 4.2 Missing Values

Important findings:

**Orders**
- 160 missing approval timestamps.
- 1,783 missing carrier handover timestamps.
- 2,965 missing customer delivery timestamps.

Most missing timestamps are consistent with order lifecycle statuses such as cancelled, processing, shipped and invoiced.

**Products**
- 610 products have missing category, name length, description length and photo quantity.
- 2 products have missing physical attribute values (weight and dimensions).

**Order Reviews**
- 87,656 missing review titles.
- 58,247 missing review messages.

These fields are optional customer feedback and were preserved.

### 4.3 Duplicate Observations

- Geolocation contains repeated observations.
- ZIP prefixes are not unique identifiers for geolocation records.
- All geolocation observations were preserved.

### 4.4 Timestamp Anomalies

The audit identified chronological inconsistencies:

- 1,359 orders have carrier handover timestamps before approval.
- 166 orders have carrier handover timestamps before purchase.
- 23 orders have customer delivery timestamps before carrier handover.

After accounting for overlapping anomalies, 1,382 unique orders are affected.

These observations were preserved. Invalid chronological intervals should be excluded from the relevant duration KPIs rather than silently corrected.

### 4.5 Numeric Anomalies

The following observations were identified:

- 383 order-item records have zero freight value.
- 9 payment records have zero payment value.
- 2 credit card payment records have zero installments.
- 4 products have zero weight.

These values were preserved because their actual causes could not be established from the available data.

### 4.6 Geographical Anomalies

A broad approximate Brazil bounding-box check identified 29 geolocation observations outside the expected geographical range.

These observations belong to 20 ZIP prefixes.

The coordinates were preserved without modification. The screening result is treated as a potential geographical inconsistency, not definitive proof that the records are incorrect.

### 4.7 Reference Data Issues

The following findings were identified:

- 157 distinct customer ZIP prefixes have no matching geolocation ZIP prefix.
- 7 distinct seller ZIP prefixes have no matching geolocation ZIP prefix.
- Two product categories have no English translation:
  - `pc_gamer`: 3 products.
  - `portateis_cozinha_e_preparadores_de_alimentos`: 10 products.

No artificial translations or geographical records were created.

## 5. Cross-table Relationship Validation

The staging relationships were validated using SQL Server LEFT JOIN checks.

| Relationship | Unmatched records |
|---|---:|
| Orders → Customers | 0 |
| Order Items → Orders | 0 |
| Order Items → Products | 0 |
| Order Items → Sellers | 0 |
| Payments → Orders | 0 |
| Reviews → Orders | 0 |

Additional findings:

- One order has no corresponding payment record.
- 13 products belong to categories without English translations.
- Customer and seller ZIP reference mismatches remain documented.

All six core order relationships passed validation.

## 6. Cleaning and Standardisation Decisions

The following principles were applied:

1. Preserve original source data in the `raw` schema.
2. Convert numeric and timestamp fields into appropriate SQL Server data types in `stg`.
3. Retain NULL values where information is genuinely unavailable.
4. Do not delete records solely because they contain suspicious or incomplete values.
5. Do not invent missing values or category translations.
6. Preserve repeated geolocation observations.
7. Document chronological and geographical anomalies.
8. Validate record counts, keys and important table relationships after loading.

## 7. Phase 4 Outcome

The following activities have been completed:

- Created and populated all nine staging tables.
- Converted source text fields into appropriate analytical data types.
- Validated record counts and key uniqueness.
- Checked missing values and suspicious numeric observations.
- Investigated timestamp and geographical anomalies.
- Validated cross-table relationships.
- Documented data-quality limitations and cleaning decisions.

**Final status:** Phase 4 — Data Cleaning, Standardisation and Staging Validation completed.

The staging layer is ready for the next analytical preparation phase, subject to the documented source-data limitations.
