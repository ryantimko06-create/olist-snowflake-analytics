create or replace view staging.stg_sellers as
select
    seller_id,
    seller_zip_code_prefix as zip_prefix,
    seller_city            as city,
    upper(seller_state)    as state
from raw.sellers;
