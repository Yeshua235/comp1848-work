-- Q1. Top 5 Editions by Gross Margin per Region (first quarter of 2024)
-- “Edition” = product edition;
-- Product details are stored in dim_product (edid and typ), and DC region in dim_dc.region.#
-- Gross margin is computed from the fact column gross_margin_pct.


WITH q AS (
  SELECT
    d.region,
    p.edid,
    p.title,
    AVG(f.gross_margin_pct) AS avg_gm
  FROM fact_production_sales f
  JOIN dim_time t   ON t.time_id   = f.time_id
  JOIN dim_dc d     ON d.dc_id     = f.dc_id
  JOIN dim_product p ON p.product_id = f.product_id
  WHERE t.year_no = 2024
    AND t.quarter_no = 1
    AND f.gross_margin_pct IS NOT NULL
  GROUP BY d.region, p.edid, p.title
)
SELECT region, edid, title, avg_gm
FROM (
  SELECT q.*, ROW_NUMBER() OVER (PARTITION BY region ORDER BY avg_gm DESC) AS rn
  FROM q
)
WHERE rn <= 5
ORDER BY region, avg_gm DESC;


-- Result: For each region, we have the list of the five editions with the highest average gross margin in Q1‑2024.
