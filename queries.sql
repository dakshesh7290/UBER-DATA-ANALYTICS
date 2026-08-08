-- ============================================================
-- Uber Ride Analytics Dashboard - SQL Queries
-- Dataset: uber_data_analytics_clean (150,000 bookings, Delhi-NCR)
-- Tool: SQLite (run via SQLiteViz)
-- ============================================================

-- ------------------------------------------------------------
-- Query 1: Trip counts by time-of-day
-- Note: Time column is stored as 12-hour AM/PM text (e.g. "6:01:39 PM"),
-- so a naive substr(Time,1,2) extraction misreads PM hours as AM.
-- This version correctly derives a 24-hour hour value first.
-- ------------------------------------------------------------
SELECT
  CASE
    WHEN hour_24 BETWEEN 5 AND 11 THEN 'Morning'
    WHEN hour_24 BETWEEN 12 AND 16 THEN 'Afternoon'
    WHEN hour_24 BETWEEN 17 AND 20 THEN 'Evening'
    ELSE 'Night'
  END AS time_of_day,
  COUNT(*) AS total_bookings,
  SUM(CASE WHEN "Booking Status" = 'Completed' THEN 1 ELSE 0 END) AS completed_trips
FROM (
  SELECT *,
    CASE
      WHEN Time LIKE '%AM' AND CAST(substr(Time, 1, instr(Time, ':') - 1) AS INTEGER) = 12
        THEN 0
      WHEN Time LIKE '%AM'
        THEN CAST(substr(Time, 1, instr(Time, ':') - 1) AS INTEGER)
      WHEN Time LIKE '%PM' AND CAST(substr(Time, 1, instr(Time, ':') - 1) AS INTEGER) = 12
        THEN 12
      WHEN Time LIKE '%PM'
        THEN CAST(substr(Time, 1, instr(Time, ':') - 1) AS INTEGER) + 12
    END AS hour_24
  FROM uber_data_analytics_clean_in_
)
GROUP BY time_of_day
ORDER BY total_bookings DESC;


-- ------------------------------------------------------------
-- Query 2a: Average fare by zone (Pickup Location)
-- Note: Booking Value and Ride Distance imported as TEXT in
-- SQLiteViz despite being numeric in Excel - cast explicitly.
-- ------------------------------------------------------------
SELECT
  "Pickup Location" AS zone,
  COUNT(*) AS completed_trips,
  ROUND(AVG(CAST("Booking Value" AS REAL)), 2) AS avg_fare,
  ROUND(AVG(CAST("Ride Distance" AS REAL)), 2) AS avg_distance,
  ROUND(AVG(CAST("Booking Value" AS REAL)) / NULLIF(AVG(CAST("Ride Distance" AS REAL)), 0), 2) AS avg_fare_per_km
FROM uber_data_analytics_clean_in_
WHERE "Booking Status" = 'Completed'
GROUP BY zone
ORDER BY completed_trips DESC
LIMIT 20;

-- ------------------------------------------------------------
-- Query 2b: Average fare by distance bucket
-- Finding: fare stays flat (~₹502-513) regardless of distance bucket,
-- suggesting Booking Value is not distance-derived in this dataset.
-- ------------------------------------------------------------
SELECT
  CASE
    WHEN CAST("Ride Distance" AS REAL) < 5 THEN '0-5 km'
    WHEN CAST("Ride Distance" AS REAL) < 10 THEN '5-10 km'
    WHEN CAST("Ride Distance" AS REAL) < 20 THEN '10-20 km'
    WHEN CAST("Ride Distance" AS REAL) < 30 THEN '20-30 km'
    ELSE '30+ km'
  END AS distance_bucket,
  COUNT(*) AS trips,
  ROUND(AVG(CAST("Booking Value" AS REAL)), 2) AS avg_fare,
  ROUND(MIN(CAST("Booking Value" AS REAL)), 2) AS min_fare,
  ROUND(MAX(CAST("Booking Value" AS REAL)), 2) AS max_fare
FROM uber_data_analytics_clean_in_
WHERE "Booking Status" = 'Completed'
GROUP BY distance_bucket
ORDER BY MIN(CAST("Ride Distance" AS REAL));

-- ------------------------------------------------------------
-- Query 2c: Average fare and distance by vehicle type
-- Finding: fare and distance are nearly identical across all
-- vehicle types (Bike through Uber XL) - another sign fare is
-- not derived from real trip characteristics in this dataset.
-- ------------------------------------------------------------
SELECT
  "Vehicle Type",
  COUNT(*) AS trips,
  ROUND(AVG(CAST("Booking Value" AS REAL)), 2) AS avg_fare,
  ROUND(AVG(CAST("Ride Distance" AS REAL)), 2) AS avg_distance
FROM uber_data_analytics_clean_in_
WHERE "Booking Status" = 'Completed'
GROUP BY "Vehicle Type"
ORDER BY avg_fare DESC;


-- ------------------------------------------------------------
-- Query 3: Peak-hour demand, split by weekday vs weekend
-- Note: Date column is stored as M/D/YYYY text (e.g. "3/23/2024"),
-- which strftime() can't parse directly - rebuilt into ISO format
-- (YYYY-MM-DD) inline before passing to strftime('%w', ...).
-- Finding: peak hour is consistently 18:00 (6 PM) on both
-- weekdays and weekends.
-- ------------------------------------------------------------
SELECT
  hour_24,
  CASE
    WHEN strftime('%w',
      substr(Date, -4) || '-' ||
      substr('00' || substr(Date, 1, instr(Date,'/')-1), -2) || '-' ||
      substr('00' || substr(substr(Date, instr(Date,'/')+1), 1, instr(substr(Date, instr(Date,'/')+1),'/')-1), -2)
    ) IN ('0','6') THEN 'Weekend'
    ELSE 'Weekday'
  END AS day_type,
  COUNT(*) AS total_bookings,
  SUM(CASE WHEN "Booking Status" = 'Completed' THEN 1 ELSE 0 END) AS completed_trips
FROM (
  SELECT *,
    CASE
      WHEN Time LIKE '%AM' AND CAST(substr(Time, 1, instr(Time, ':') - 1) AS INTEGER) = 12 THEN 0
      WHEN Time LIKE '%AM' THEN CAST(substr(Time, 1, instr(Time, ':') - 1) AS INTEGER)
      WHEN Time LIKE '%PM' AND CAST(substr(Time, 1, instr(Time, ':') - 1) AS INTEGER) = 12 THEN 12
      WHEN Time LIKE '%PM' THEN CAST(substr(Time, 1, instr(Time, ':') - 1) AS INTEGER) + 12
    END AS hour_24
  FROM uber_data_analytics_clean_in_
)
GROUP BY hour_24, day_type
ORDER BY hour_24, day_type;


-- ------------------------------------------------------------
-- Query 4a: Booking status breakdown (% of total)
-- ------------------------------------------------------------
SELECT
  "Booking Status" AS status,
  COUNT(*) AS bookings,
  ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM uber_data_analytics_clean_in_), 2) AS pct_of_total
FROM uber_data_analytics_clean_in_
GROUP BY "Booking Status"
ORDER BY bookings DESC;

-- ------------------------------------------------------------
-- Query 4b: Cancellation rate - two definitions
-- narrow  = Cancelled by Driver + Cancelled by Customer only (25%)
-- broad   = narrow + No Driver Found (32%)
-- "Incomplete" (6%) excluded from both - different failure mode
-- (driver found, ride started but not finished).
-- ------------------------------------------------------------
SELECT
  ROUND(100.0 * SUM(CASE WHEN "Booking Status" IN ('Cancelled by Driver','Cancelled by Customer') THEN 1 ELSE 0 END) / COUNT(*), 2) AS cancel_rate_narrow,
  ROUND(100.0 * SUM(CASE WHEN "Booking Status" IN ('Cancelled by Driver','Cancelled by Customer','No Driver Found') THEN 1 ELSE 0 END) / COUNT(*), 2) AS cancel_rate_incl_no_driver
FROM uber_data_analytics_clean_in_;
