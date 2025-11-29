-- A quick row counts by table

SELECT 'dim_time' table_name, COUNT(*) row_count FROM dim_time
UNION ALL SELECT 'dim_dc', COUNT(*) FROM dim_dc
UNION ALL SELECT 'dim_author', COUNT(*) FROM dim_author
UNION ALL SELECT 'dim_product', COUNT(*) FROM dim_product
UNION ALL SELECT 'dim_channel', COUNT(*) FROM dim_channel
UNION ALL SELECT 'dim_vendor', COUNT(*) FROM dim_vendor
UNION ALL SELECT 'fact_production_sales', COUNT(*) FROM fact_production_sales;


-- Null checks on NOT NULL foreign keys in the fact
-- Expected output: All should be zero

SELECT
  SUM(CASE WHEN time_id     IS NULL THEN 1 ELSE 0 END) AS null_time_id,
  SUM(CASE WHEN dc_id       IS NULL THEN 1 ELSE 0 END) AS null_dc_id,
  SUM(CASE WHEN product_id  IS NULL THEN 1 ELSE 0 END) AS null_product_id,
  SUM(CASE WHEN channel_id  IS NULL THEN 1 ELSE 0 END) AS null_channel_id
FROM fact_production_sales;


-- Reference checks
-- Any fact rows whose FK doesn’t exist in the dim?
-- Expected output: All should be zero

SELECT COUNT(*) AS bad_time_fk
FROM fact_production_sales f
LEFT JOIN dim_time t ON t.time_id = f.time_id
WHERE t.time_id IS NULL;

SELECT COUNT(*) AS bad_dc_fk
FROM fact_production_sales f
LEFT JOIN dim_dc d ON d.dc_id = f.dc_id
WHERE d.dc_id IS NULL;

SELECT COUNT(*) AS bad_product_fk
FROM fact_production_sales f
LEFT JOIN dim_product p ON p.product_id = f.product_id
WHERE p.product_id IS NULL;

SELECT COUNT(*) AS bad_channel_fk
FROM fact_production_sales f
LEFT JOIN dim_channel c ON c.channel_id = f.channel_id
WHERE c.channel_id IS NULL;

SELECT COUNT(*) AS bad_vendor_fk
FROM fact_production_sales f
LEFT JOIN dim_vendor v ON v.vendor_id = f.vendor_id
WHERE v.vendor_id IS NULL AND f.vendor_id IS NOT NULL;


-- Fact grain uniqueness check (daily grain constraint)
-- Expected output: This should return no rows

SELECT time_id, dc_id, product_id, channel_id, vendor_id, COUNT(*) dup_count
FROM fact_production_sales
GROUP BY time_id, dc_id, product_id, channel_id, vendor_id
HAVING COUNT(*) > 1;
