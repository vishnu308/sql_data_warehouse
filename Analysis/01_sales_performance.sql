-- =============================================================================
-- Analysis #1: Sales Performance Overview
-- =============================================================================
-- Business Question: What are our overall sales and profit metrics?
-- Technique: Basic aggregation (SUM, AVG, COUNT, MIN, MAX)

-- =============================================================================
-- Query 1.1: Overall Business Metrics
-- =============================================================================
select count(*) as total_transactions,
       count(distinct order_id) as total_orders,
       sum(sales) as total_revenue,
       sum(profit) as total_profit,
       sum(quantity) as total_units_sold,
       avg(sales) as avg_transaction_value,
       avg(profit) as avg_profit_per_transaction,
       min(sales) as smallest_sale,
       max(sales) as largest_sale,
       round(
          sum(profit) / sum(sales) * 100,
          2
       ) as profit_margin_pct
  from fact_sales;

-- =============================================================================
-- Query 1.2: Sales by Product Category
-- =============================================================================
select p.category,
       count(*) as num_transactions,
       sum(f.sales) as total_sales,
       sum(f.profit) as total_profit,
       sum(f.quantity) as units_sold,
       round(
          avg(f.sales),
          2
       ) as avg_sale,
       round(
          sum(f.profit) / sum(f.sales) * 100,
          2
       ) as profit_margin_pct
  from fact_sales f
  join dim_product p
on f.product_key = p.product_key
 group by p.category
 order by total_sales desc;

-- =============================================================================
-- Query 1.3: Sales by Region
-- =============================================================================
select l.region,
       count(*) as num_transactions,
       sum(f.sales) as total_sales,
       sum(f.profit) as total_profit,
       round(
          avg(f.sales),
          2
       ) as avg_sale,
       round(
          sum(f.profit) / sum(f.sales) * 100,
          2
       ) as profit_margin_pct,
    -- Calculate percentage of total sales
       round(
          sum(f.sales) /(
             select sum(sales)
               from fact_sales
          ) * 100,
          2
       ) as pct_of_total_sales
  from fact_sales f
  join dim_location l
on f.location_key = l.location_key
 group by l.region
 order by total_sales desc;

-- =============================================================================
-- Query 1.4: Sales by Customer Segment
-- =============================================================================
select c.segment,
       count(*) as num_transactions,
       count(distinct c.customer_id) as num_customers,
       sum(f.sales) as total_sales,
       sum(f.profit) as total_profit,
       round(
          avg(f.sales),
          2
       ) as avg_transaction,
       round(
          sum(f.sales) / count(distinct c.customer_id),
          2
       ) as sales_per_customer
  from fact_sales f
  join dim_customer c
on f.customer_key = c.customer_key
 group by c.segment
 order by total_sales desc;

-- =============================================================================
-- INSIGHTS TEMPLATE
-- =============================================================================