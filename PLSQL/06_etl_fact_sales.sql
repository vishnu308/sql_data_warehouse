-- =============================================================================
-- ETL Script 3: Populate FACT_SALES
-- =============================================================================
-- This script loads the fact table by joining staging data with dimension tables
-- to look up surrogate keys and converting data types.

-- First, recreate the fact table (in case it was dropped)
begin
   execute immediate 'DROP TABLE fact_sales CASCADE CONSTRAINTS';
exception
   when others then
      if sqlcode != -942 then
         raise;
      end if;
end;
/

begin
   execute immediate 'DROP SEQUENCE seq_sales_key';
exception
   when others then
      if sqlcode != -2289 then
         raise;
      end if;
end;
/

create table fact_sales (
   sales_key      number primary key,
   customer_key   number not null,
   product_key    number not null,
   location_key   number not null,
   order_date_key number not null,
   ship_date_key  number not null,
   sales          number(10,2),
   quantity       number,
   discount       number(5,4),
   profit         number(10,2),
   shipping_cost  number(10,2),
   order_id       varchar2(50),
   load_date      date default sysdate,
   constraint fk_customer foreign key ( customer_key )
      references dim_customer ( customer_key ),
   constraint fk_product foreign key ( product_key )
      references dim_product ( product_key ),
   constraint fk_location foreign key ( location_key )
      references dim_location ( location_key ),
   constraint fk_order_date foreign key ( order_date_key )
      references dim_time ( date_key ),
   constraint fk_ship_date foreign key ( ship_date_key )
      references dim_time ( date_key )
);

create sequence seq_sales_key start with 1 increment by 1;

-- =============================================================================
-- Populate FACT_SALES
-- =============================================================================
insert into fact_sales (
   sales_key,
   customer_key,
   product_key,
   location_key,
   order_date_key,
   ship_date_key,
   sales,
   quantity,
   discount,
   profit,
   shipping_cost,
   order_id
)
   select seq_sales_key.nextval,
          c.customer_key,
          p.product_key,
          l.location_key,
          t_order.date_key,
          t_ship.date_key,
          to_number(s.sales),
          to_number(s.quantity),
          to_number(s.discount),
          to_number(s.profit),
          to_number(s.shipping_cost),
          s.order_id
     from staging_superstore s
-- Join to look up customer_key
     join dim_customer c
   on s.customer_id = c.customer_id
-- Join to look up product_key
     join dim_product p
   on s.product_id = p.product_id
-- Join to look up location_key (composite match)
     join dim_location l
   on ( s.city = l.city
      and s.state = l.state
      and s.country = l.country )
-- Join to look up order_date_key
     join dim_time t_order
   on to_date(s.order_date,
        'MM/DD/YYYY') = t_order.full_date
-- Join to look up ship_date_key
     join dim_time t_ship
   on to_date(s.ship_date,
        'MM/DD/YYYY') = t_ship.full_date
    where s.customer_id is not null
      and s.product_id is not null
      and s.city is not null
      and s.order_date is not null
      and s.ship_date is not null;

commit;

-- =============================================================================
-- Verification
-- =============================================================================
-- Check row counts
select 'FACT_SALES' as table_name,
       count(*) as row_count
  from fact_sales;

-- Sample data
select *
  from fact_sales
 where rownum <= 5;

-- Verify foreign keys work (join back to dimensions)
select f.sales_key,
       c.customer_name,
       p.product_name,
       l.city,
       t.full_date as order_date,
       f.sales,
       f.profit
  from fact_sales f
  join dim_customer c
on f.customer_key = c.customer_key
  join dim_product p
on f.product_key = p.product_key
  join dim_location l
on f.location_key = l.location_key
  join dim_time t
on f.order_date_key = t.date_key
 where rownum <= 10;