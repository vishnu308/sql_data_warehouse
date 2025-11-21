-- =============================================================================
-- Visualization Queries - Ready for Charts
-- =============================================================================
-- These queries are optimized for creating visualizations
-- Run each query and use SQL Developer's Chart feature

-- =============================================================================
-- Chart 1: Category Performance (Grouped Bar Chart)
-- =============================================================================
select p.category as "Category",
       round(
          sum(f.sales) / 1000000,
          1
       ) as "Sales (Millions)",
       round(
          sum(f.profit) / 1000000,
          1
       ) as "Profit (Millions)",
       round(
          sum(f.profit) / sum(f.sales) * 100,
          1
       ) as "Margin %"
  from fact_sales f
  join dim_product p
on f.product_key = p.product_key
 group by p.category
 order by sum(f.sales) desc;

-- =============================================================================
-- Chart 2: Regional Sales Distribution (Horizontal Bar Chart)
-- =============================================================================
select l.region as "Region",
       round(
          sum(f.sales) / 1000000,
          1
       ) as "Revenue (M)",
       count(*) as "Transactions"
  from fact_sales f
  join dim_location l
on f.location_key = l.location_key
 group by l.region
 order by sum(f.sales) desc;

-- =============================================================================
-- Chart 3: Customer Segment Breakdown (Pie Chart)
-- =============================================================================
select c.segment as "Segment",
       round(
          sum(f.sales) / 1000000,
          1
       ) as "Sales (M)",
       round(
          sum(f.sales) /(
             select sum(sales)
               from fact_sales
          ) * 100,
          1
       ) as "% of Total"
  from fact_sales f
  join dim_customer c
on f.customer_key = c.customer_key
 group by c.segment
 order by sum(f.sales) desc;

-- =============================================================================
-- Chart 4: Monthly Sales Trend (Line Chart)
-- =============================================================================
select to_char(
   t.full_date,
   'YYYY-MM'
) as "Month",
       round(
          sum(f.sales) / 1000,
          1
       ) as "Sales (K)"
  from fact_sales f
  join dim_time t
on f.order_date_key = t.date_key
 group by to_char(
   t.full_date,
   'YYYY-MM'
)
 order by to_char(
   t.full_date,
   'YYYY-MM'
);

-- =============================================================================
-- Chart 5: Top 10 Products (Bar Chart) - Oracle 11g compatible
-- =============================================================================
select *
  from (
   select p.product_name as "Product",
          round(
             sum(f.sales) / 1000,
             1
          ) as "Revenue (K)",
          sum(f.quantity) as "Units Sold"
     from fact_sales f
     join dim_product p
   on f.product_key = p.product_key
    group by p.product_name
    order by sum(f.sales) desc
)
 where rownum <= 10;

-- =============================================================================
-- Chart 6: Profit Margin by Category (Column Chart)
-- =============================================================================
select p.category as "Category",
       round(
          sum(f.profit) / sum(f.sales) * 100,
          2
       ) as "Profit Margin %"
  from fact_sales f
  join dim_product p
on f.product_key = p.product_key
 group by p.category
 order by round(
   sum(f.profit) / sum(f.sales) * 100,
   2
) desc;

-- =============================================================================
-- Chart 7: Quarterly Sales Comparison (Grouped Column Chart)
-- =============================================================================
select t.year as "Year",
       t.quarter as "Quarter",
       round(
          sum(f.sales) / 1000000,
          2
       ) as "Sales (M)"
  from fact_sales f
  join dim_time t
on f.order_date_key = t.date_key
 group by t.year,
          t.quarter
 order by t.year,
          t.quarter;