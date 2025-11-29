-- Q2. Vendor Cost Trend with 12‑month rolling average
-- Binding cost per vendor per month with rolling 12‑month average.

-- Taking Month buckets from dim_time (year_no, month_no).


WITH base AS (
  SELECT
    v.vendor_id,
    v.vendor_name,
    t.year_no,
    t.month_no,
    SUM(f.binding_cost) AS binding_cost_month
  FROM fact_production_sales f
  JOIN dim_time t ON t.time_id = f.time_id
  LEFT JOIN dim_vendor v ON v.vendor_id = f.vendor_id
  GROUP BY v.vendor_id, v.vendor_name, t.year_no, t.month_no
),
ordered AS (
  SELECT
    vendor_id,
    vendor_name,
    TO_DATE(TO_CHAR(year_no)||'-'||LPAD(month_no,2,'0'),'YYYY-MM') AS ym,
    binding_cost_month
  FROM base
)
SELECT
  vendor_id,
  vendor_name,
  ym,
  binding_cost_month,
  AVG(binding_cost_month) OVER (
    PARTITION BY vendor_id
    ORDER BY ym
    ROWS BETWEEN 11 PRECEDING AND CURRENT ROW
  ) AS binding_cost_rolling_12m
FROM ordered
ORDER BY vendor_id, ym;


-- Result:
-- A time series per vendor
-- The last column is the 12‑month rolling average of binding cost.
