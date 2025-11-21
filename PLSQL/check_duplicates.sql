SELECT product_id, COUNT(*) as cnt, 
       COUNT(DISTINCT product_name) as name_variations,
       COUNT(DISTINCT category) as cat_variations
FROM staging_superstore 
WHERE product_id IS NOT NULL
GROUP BY product_id
HAVING COUNT(*) > 1
FETCH FIRST 5 ROWS ONLY;
