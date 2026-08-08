# Uber Data Analytics Dashboard

## Overview
This project analyzes a 150,000-row Uber ride-booking dataset from Delhi-NCR, India, covering the full pipeline from data cleaning through SQL analysis, Python EDA, and a Power BI dashboard.

## Objective
To answer key operational questions — when demand peaks, how fares relate to distance and vehicle type, and what drives cancellations — while demonstrating an end-to-end analytics workflow across Excel, SQL, Python, and Power BI.

## Tools Used
- **Excel** — Cleaned raw data: fixed ID formatting, verified numeric column types, preserved structurally meaningful nulls (fields like Booking Value/Ride Distance are null for non-completed rides, not missing data)
- **SQL (SQLite via SQLiteViz)** — Queried trip counts by time-of-day, average fare by distance and vehicle type, peak-hour demand (weekday vs. weekend), and cancellation rates under two definitions
- **Python (pandas, numpy)** — Built an hour × day-of-week demand pivot, ran a full correlation matrix across fare/distance/VTAT/CTAT/ratings, produced zone-wise groupby summaries, and checked wait-time/cancellation behavior against booking volume
- **Power BI** — Built an interactive dashboard: KPI cards, slicers, trend charts, and a status breakdown

## Dataset
Uber Ride Analytics dataset (Delhi-NCR, India), 150,000 bookings, 21 columns — booking status, vehicle type, pickup/drop location, fare, distance, VTAT/CTAT (vehicle/customer turnaround time), and ratings. 
**Limitation to note upfront:** Fare, distance, wait time, and ratings show no meaningful correlation with each other in this dataset — these fields appear to be generated independently rather than derived from a real fare/demand formula, so results shouldn't be over-interpreted as reflecting real-world Uber pricing or surge behavior.

## Process

### 1. Data Cleaning (Excel)
Removed formatting artifacts from ID columns, verified all numeric columns were typed correctly, and deliberately left nulls untouched in fields tied to non-completed rides (Booking Value, Ride Distance, VTAT, CTAT) since they reflect ride status, not data quality issues.

### 2. SQL Analysis
Key queries (see `queries.sql`):
- Trip counts by time-of-day bucket, using corrected 12-hour AM/PM time parsing (an initial naive parse mislabeled PM hours as AM, which was caught and fixed)
- Average fare by distance bucket and by vehicle type — both showed fare staying flat regardless of distance or vehicle type
- Peak-hour demand split by weekday/weekend — consistent peak at 6 PM in both cases
- Cancellation rate under two definitions: 25% (driver + customer cancellations only) and 32% (also including "No Driver Found")

### 3. Python EDA
- Hour × day-of-week pivot table showed near-identical demand shape across all seven days, including weekends
- Full correlation matrix confirmed fare, distance, VTAT, CTAT, and ratings are all uncorrelated (values under 0.01)
- Zone-wise groupby across 176 pickup zones showed trip volume, fare, and ratings evenly distributed — no zone stood out
- Hourly wait-time/cancellation-rate check showed no "surge" signal — VTAT and cancellation rate stayed flat regardless of booking volume

### 4. Power BI Dashboard
Includes:
- KPI cards: Total Bookings, Completion Rate, Cancellation Rate, Avg VTAT, Avg Driver Rating
- Slicers: Vehicle Type, Payment Method, Booking Status
- Line-and-column chart: hourly booking volume vs. average wait time
- Line charts: VTAT and CTAT trends over time
- Bar chart: hour-of-day demand distribution
- Donut chart: booking status breakdown

## Key Findings
- Peak demand hour is consistently 6 PM, across both weekdays and weekends
- Fare, wait time, and trip time show no meaningful correlation with distance, vehicle type, zone, or time of day (all correlations under 0.01)
- Demand volume by hour is nearly identical across all seven days of the week, including weekends
- Cancellation rate is 25% (driver + customer cancellations), rising to 32% if "No Driver Found" is included
- Trip volume is evenly distributed across all 176 pickup zones, with no single zone dominating demand

## Files in This Repo
- `uber data analytics raw` — raw dataset
-  `uber data analytics clean` — cleaned dataset
- `queries.sql` — all SQL queries
- `eda.ipynb` — Python analysis notebook
- `uber data analytics dashboard.pbix`  — Power BI dashboard export

## What I Learned
This project reinforced how much cross-tool type consistency matters — the same numeric columns imported as text in SQLiteViz but correctly as float64 in pandas, and a naive AM/PM time parse silently broke an early query until I caught it against expected results. It also taught me to report what the data actually shows rather than force a narrative — several expected relationships (fare vs. distance, demand vs. day-of-week) turned out to be statistically flat, and stating that clearly is itself a real analytical finding.
