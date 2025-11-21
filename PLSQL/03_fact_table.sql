-- =============================================================================
-- FACT TABLE - The Central Table of the Star Schema
-- =============================================================================
-- This table stores the measurements (sales, profit, etc.) and connects to
-- all dimension tables via foreign keys.

-- Drop if exists
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
    
    -- Foreign Keys (connect to dimensions)
   customer_key   number not null,
   product_key    number not null,
   location_key   number not null,
   order_date_key number not null,
   ship_date_key  number not null,
    
    -- Measures (the numbers we analyze)
   sales          number(10,2),
   quantity       number,
   discount       number(5,4),
   profit         number(10,2),
   shipping_cost  number(10,2),
    
    -- Metadata
   order_id       varchar2(50),
   load_date      date default sysdate,
    
    -- Foreign Key Constraints (ensure referential integrity)
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

-- Sequence to auto-generate sales_key values
create sequence seq_sales_key start with 1 increment by 1;