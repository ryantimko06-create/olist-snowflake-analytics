-- one row per item in an order. order_item_id is just 1,2,3.. within the order
-- (no quantity column - 3 of the same product = 3 rows)
create or replace view staging.stg_order_items as
select
    order_id,
    order_item_id   as item_number,
    product_id,
    seller_id,
    shipping_limit_date as shipping_limit_at,
    price,
    freight_value
from raw.order_items;
