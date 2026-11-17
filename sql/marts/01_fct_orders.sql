-- one row per order with everything i keep needing joined on
create or replace table marts.fct_orders as
with items as (
    select
        order_id,
        count(*)                  as n_items,
        count(distinct seller_id) as n_sellers,
        sum(price)                as items_total,
        sum(freight_value)        as freight_total
    from staging.stg_order_items
    group by 1
),

payments as (
    select
        order_id,
        sum(payment_value)                    as payment_total,
        max(payment_installments)             as installments,
        max_by(payment_type, payment_value)   as main_payment_type
    from staging.stg_payments
    group by 1
)

select
    o.order_id,
    c.customer_unique_id,
    c.state                              as customer_state,
    o.order_status,
    o.purchased_at,
    date_trunc('month', o.purchased_at)  as order_month,
    o.delivered_at,
    o.estimated_delivery_at,

    coalesce(i.n_items, 0)               as n_items,
    i.n_sellers,
    i.items_total,
    i.freight_total,
    i.items_total + i.freight_total      as order_total,
    p.payment_total,
    p.main_payment_type,
    p.installments,

   
    datediff('day', o.purchased_at, o.delivered_at)           as days_to_deliver,
    datediff('day', o.purchased_at, o.estimated_delivery_at)  as days_promised,

    -- positive = late and negative = early
    datediff('day', o.estimated_delivery_at, o.delivered_at)  as days_late,
    case
        when o.delivered_at is null then null
        when cast(o.delivered_at as date) > cast(o.estimated_delivery_at as date) then true
        else false
    end                                  as is_late,

    r.review_score
from staging.stg_orders o
left join staging.stg_customers c on o.customer_id = c.customer_id
left join items i                 on o.order_id = i.order_id
left join payments p              on o.order_id = p.order_id
left join staging.stg_reviews r   on o.order_id = r.order_id;
