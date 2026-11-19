-- RFM segmentation
-- "today" = day after the last order in the data, since it's a historical extract
--
-- frequency is awkward here because almost everyone has exactly 1 order, so ntile on
-- n_orders would split identical customers into different buckets at random.
-- using a simple 1 / 2 / 3+ rule for F instead of ntile.

with base as (
    select
        customer_unique_id,
        datediff('day', last_order_at, (select max(purchased_at) from marts.fct_orders)) + 1 as recency_days,
        n_orders,
        total_spent
    from marts.dim_customers
    where total_spent is not null
),

scored as (
    select
        *,
        ntile(5) over (order by recency_days desc) as r,     -- 5 = most recent
        case when n_orders >= 3 then 3 when n_orders = 2 then 2 else 1 end as f,
        ntile(5) over (order by total_spent)       as m      -- 5 = biggest spenders
    from base
),

segmented as (
    select
        *,
        case
            when f >= 2 and r >= 4            then 'loyal'
            when f >= 2                       then 'repeat, gone quiet'
            when r >= 4 and m >= 4            then 'new high value'
            when r >= 4                       then 'new'
            when r <= 2 and m >= 4            then 'lost high value'
            when r <= 2                       then 'lost'
            else                                   'cooling off'
        end as segment
    from scored
)

select
    segment,
    count(*)                                              as customers,
    round(100.0 * count(*) / sum(count(*)) over (), 1)    as pct_customers,
    round(sum(total_spent), 0)                            as revenue,
    round(100.0 * sum(total_spent) / sum(sum(total_spent)) over (), 1) as pct_revenue,
    round(avg(total_spent), 2)                            as avg_spent,
    round(avg(recency_days), 0)                           as avg_recency_days
from segmented
group by 1
order by revenue desc;
