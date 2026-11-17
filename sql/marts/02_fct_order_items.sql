-- item level, for category and seller questions
create or replace table marts.fct_order_items as
select
    i.order_id,
    i.item_number,
    i.product_id,
    p.category,
    i.seller_id,
    s.state          as seller_state,
    o.customer_state,
    s.state = o.customer_state as same_state,
    o.order_status,
    o.purchased_at,
    o.order_month,
    i.price,
    i.freight_value,
    o.is_late,
    o.review_score          -- order level score!! repeated on every item, don't average this without thinking
from staging.stg_order_items i
join marts.fct_orders o           on i.order_id = o.order_id
left join staging.stg_products p  on i.product_id = p.product_id
left join staging.stg_sellers s   on i.seller_id = s.seller_id;
