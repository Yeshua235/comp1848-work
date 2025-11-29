-- Q3. Channel Mix by Edition (percentage of total units sold)
-- For each product edition (edid), what share of units were sold by each channel?


WITH totals AS (
  SELECT p.edid, SUM(f.units_sold) AS total_units
  FROM fact_production_sales f
  JOIN dim_product p ON p.product_id = f.product_id
  GROUP BY p.edid
),
by_channel AS (
  SELECT p.edid, c.channel_code, SUM(f.units_sold) AS units_by_channel
  FROM fact_production_sales f
  JOIN dim_product p  ON p.product_id  = f.product_id
  JOIN dim_channel c  ON c.channel_id  = f.channel_id
  GROUP BY p.edid, c.channel_code
)
SELECT
  bc.edid,
  bc.channel_code,
  bc.units_by_channel,
  t.total_units,
  ROUND( (bc.units_by_channel / NULLIF(t.total_units,0)) * 100, 2 ) AS pct_of_total_units
FROM by_channel bc
JOIN totals t ON t.edid = bc.edid
ORDER BY bc.edid, pct_of_total_units DESC;


-- Result:
-- For each edition, we get the percentage distribution of sales across channels.
