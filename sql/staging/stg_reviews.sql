-- review_id is NOT unique in the source, and some orders have more than one review.
-- keeping the most recent review per order so joins to orders don't fan out.
create or replace view staging.stg_reviews as
select
    review_id,
    order_id,
    review_score,
    review_comment_message is not null as has_comment,
    review_creation_date    as review_created_at,
    review_answer_timestamp as review_answered_at
from raw.order_reviews
qualify row_number() over (
    partition by order_id
    order by review_answer_timestamp desc, review_id
) = 1;
