-- =============================================================================
-- Excel Export Queries - Ready to Export
-- =============================================================================
-- Run each query and export to Excel for dashboard creation

-- =============================================================================
-- Export 1: Category Performance
-- =============================================================================
-- Export as: category_performance.xlsx
select p.category as category,
       round(
          sum(f.sales),
          2
       ) as total_sales,
       round(
          sum(f.profit),
          2
       ) as total_profit,
       round(
          sum(f.profit) / sum(f.sales) * 100,
          2
       ) as margin_percent,
       count(*) as transactions,
       sum(f.quantity) as units_sold
  from fact_sales f
  join dim_product p
on f.product_key = p.product_key
 group by p.category
 order by sum(f.sales) desc;

-- =============================================================================
-- Export 2: Regional Performance
-- =============================================================================
-- Export as: regional_performance.xlsx
select l.region as region,
       l.market as market,
       round(
          sum(f.sales),
          2
       ) as total_sales,
       round(
          sum(f.profit),
          2
       ) as total_profit,
       count(*) as transactions,
       round(
          avg(f.sales),
          2
       ) as avg_transaction
  from fact_sales f
  join dim_location l
on f.location_key = l.location_key
 group by l.region,
          l.market
 order by sum(f.sales) desc;

-- =============================================================================
-- Export 3: Monthly Sales Trend
-- =============================================================================
-- Export as: monthly_trend.xlsx
select t.year as year,
       t.month as month_num,
       t.month_name as month_name,
       to_char(
          t.full_date,
          'YYYY-MM'
       ) as year_month,
       round(
          sum(f.sales),
          2
       ) as monthly_sales,
       round(
          sum(f.profit),
          2
       ) as monthly_profit,
       count(*) as transactions
  from fact_sales f
  join dim_time t
on f.order_date_key = t.date_key
 group by t.year,
          t.month,
          t.month_name,
          to_char(
             t.full_date,
             'YYYY-MM'
          )
 order by t.year,
          t.month;

-- =============================================================================
-- Export 4: Customer Segment Analysis
-- =============================================================================
-- Export as: customer_segments.xlsx
select c.segment as segment,
       count(distinct c.customer_id) as num_customers,
       round(
          sum(f.sales),
          2
       ) as total_sales,
       round(
          sum(f.profit),
          2
       ) as total_profit,
       count(*) as transactions,
       round(
          sum(f.sales) / count(distinct c.customer_id),
          2
       ) as sales_per_customer,
       round(
          avg(f.sales),
          2
       ) as avg_transaction
  from fact_sales f
  join dim_customer c
on f.customer_key = c.customer_key
 group by c.segment
 order by sum(f.sales) desc;

-- =============================================================================
-- Export 5: Quarterly Performance
-- =============================================================================
-- Export as: quarterly_performance.xlsx
select t.year as year,
       t.quarter as quarter,
       'Q'
       || t.quarter
       || ' '
       || t.year as quarter_label,
       round(
          sum(f.sales),
          2
       ) as quarterly_sales,
       round(
          sum(f.profit),
          2
       ) as quarterly_profit,
       count(*) as transactions
  from fact_sales f
  join dim_time t
on f.order_date_key = t.date_key
 group by t.year,
          t.quarter
 order by t.year,
          t.quarter;

-- =============================================================================
-- Export 6: Top 20 Products
-- =============================================================================
-- Export as: top_products.xlsx
select *
  from (
   select p.product_name as product,
          p.category as category,
          p.sub_category as sub_category,
          round(
             sum(f.sales),
             2
          ) as total_sales,
          round(
             sum(f.profit),
             2
          ) as total_profit,
          sum(f.quantity) as units_sold,
          round(
             sum(f.profit) / sum(f.sales) * 100,
             2
          ) as margin_percent
     from fact_sales f
     join dim_product p
   on f.product_key = p.product_key
    group by p.product_name,
             p.category,
             p.sub_category
    order by sum(f.sales) desc
)
 where rownum <= 20;

-- =============================================================================
-- Export 7: Top 20 Customers
-- =============================================================================
-- Export as: top_customers.xlsx
select *
  from (
   select c.customer_name as customer,
          c.segment as segment,
          round(
             sum(f.sales),
             2
          ) as total_sales,
          round(
             sum(f.profit),
             2
          ) as total_profit,
          count(*) as num_orders,
          round(
             avg(f.sales),
             2
          ) as avg_order_value
     from fact_sales f
     join dim_customer c
   on f.customer_key = c.customer_key
    group by c.customer_name,
             c.segment
    order by sum(f.sales) desc
)
 where rownum <= 20;

-- =============================================================================
-- INSTRUCTIONS FOR EXPORT
-- =============================================================================
-- 1. Run each query one at a time
-- 2. Right-click on results grid
-- 3. Select "Export"
-- 4. Choose "Excel (.xlsx)" format
-- 5. Save with the suggested filename
-- 6. Open all files in Excel
-- 7. Create charts and dashboard