-- Q4. Author Performance: Total Revenue vs. Average Discount (revenue > 50,000)
-- Product is mapped to author (product → author) via dim_product.author_id; then we filter on total revenue and compute average discount.


SELECT
  a.author_id,
  a.first_name,
  a.last_name,
  SUM(f.revenue) AS total_revenue,
  ROUND(AVG(f.discount), 4) AS avg_discount
FROM fact_production_sales f
JOIN dim_product p ON p.product_id = f.product_id
LEFT JOIN dim_author a ON a.author_id = p.author_id
GROUP BY a.author_id, a.first_name, a.last_name
HAVING SUM(f.revenue) > 50000
ORDER BY total_revenue DESC;


-- Result:
-- Authors crossing 50k total revenue, with typical discount applied.
