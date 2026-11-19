-- Some general data questions + answers


-- Q1: how concentrated is revenue across sellers? (pareto)
with seller_rev as (
    select seller_id, sum(price) as revenue
    from marts.fct_order_items
    where order_status not in ('canceled', 'unavailable')
    group by 1
),

ranked as (
    select
        seller_id,
        revenue,
        ntile(10) over (order by revenue desc) as decile     -- 1 = top 10% of sellers
    from seller_rev
)

select
    decile,
    count(*)                                            as sellers,
    round(sum(revenue), 0)                              as revenue,
    round(100.0 * sum(revenue) / sum(sum(revenue)) over (), 1) as pct_of_revenue
from ranked
group by 1
order by 1;


-- Q2: which sellers with real volume have a lateness / review problem?
-- order level, so a 5 item order doesn't count 5 times
with seller_orders as (
    select distinct
        seller_id,
        seller_state,
        order_id,
        is_late,
        review_score
    from marts.fct_order_items
    where order_status = 'delivered'
)

select
    seller_id,
    seller_state,
    count(*)                                              as orders,
    round(100.0 * count_if(is_late) / count(*), 1)        as late_pct,
    round(avg(review_score), 2)                           as avg_review
from seller_orders
group by 1, 2
having count(*) >= 50
order by avg_review asc
limit 25;


-- Q3: categories - revenue, and how heavy freight is relative to price
select
    category,
    count(*)                                        as items_sold,
    round(sum(price), 0)                            as revenue,
    round(avg(price), 2)                            as avg_price,
    round(100.0 * sum(freight_value) / sum(price), 1) as freight_pct_of_price
from marts.fct_order_items
where order_status not in ('canceled', 'unavailable')
group by 1
having count(*) >= 500
order by revenue desc;


-- Q4: does shipping within the same state help?
select
    same_state,
    count(distinct order_id)             as orders,
    round(avg(freight_value), 2)         as avg_freight_per_item,
    round(100.0 * count_if(is_late) / count(*), 1) as late_pct   -- item level, close enough
from marts.fct_order_items
where order_status = 'delivered'
  and same_state is not null
group by 1;
