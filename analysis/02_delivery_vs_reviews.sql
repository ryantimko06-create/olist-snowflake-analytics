-- Q: how much does late delivery hurt review scores?
-- only delivered orders that have a review

select
    case
        when days_late <= -7 then '1. 7+ days early'
        when days_late <   0 then '2. 1-6 days early'
        when days_late =   0 then '3. on the day'
        when days_late <=  3 then '4. 1-3 days late'
        when days_late <=  7 then '5. 4-7 days late'
        else                      '6. 8+ days late'
    end                                             as delivery_bucket,
    count(*)                                        as orders,
    round(avg(review_score), 2)                     as avg_review,
    round(100.0 * count_if(review_score = 1) / count(*), 1) as pct_1_star,
    round(100.0 * count_if(review_score = 5) / count(*), 1) as pct_5_star
from marts.fct_orders
where order_status = 'delivered'
  and delivered_at is not null
  and review_score is not null
group by 1
order by 1;


-- same idea but by customer state: where is delivery slowest, and is that where reviews are worst?
select
    customer_state,
    count(*)                                        as orders,
    round(avg(days_to_deliver), 1)                  as avg_days_to_deliver,
    round(100.0 * count_if(is_late) / count(*), 1)  as late_pct,
    round(avg(review_score), 2)                     as avg_review
from marts.fct_orders
where order_status = 'delivered'
  and delivered_at is not null
group by 1
having count(*) >= 200      -- skip the tiny states
order by avg_days_to_deliver desc;
