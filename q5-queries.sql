-- Q5. Detect “hot” DCs (high return rates & low profit)
-- Return rate > 5% and low margin < 15%.
--Fact has returns_count, units_sold, gross_margin_pct.


SELECT
  d.dc_id,
  d.name AS dc_name,
  d.region,
  SUM(f.units_sold)      AS units_sold,
  SUM(f.returns_count)   AS returns_count,
  ROUND( (SUM(f.returns_count) / NULLIF(SUM(f.units_sold),0)) * 100, 2 ) AS returns_pct,
  ROUND( AVG(f.gross_margin_pct), 2 ) AS avg_margin_pct
FROM fact_production_sales f
JOIN dim_dc d    ON d.dc_id     = f.dc_id
GROUP BY d.dc_id, d.name, d.region
HAVING (SUM(f.returns_count) / NULLIF(SUM(f.units_sold),0)) * 100 > 5
   AND AVG(f.gross_margin_pct) < 15
ORDER BY returns_pct DESC, avg_margin_pct ASC;


-- Result:
-- DCs with unusually high return rates and weak margins—prime candidates for investigation.
