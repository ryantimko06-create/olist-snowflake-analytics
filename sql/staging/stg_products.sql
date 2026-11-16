-- english category names + fixing the lenght typo
-- some products have no category at all, and a couple of categories are missing from the translation file
create or replace view staging.stg_products as
select
    p.product_id,
    coalesce(t.product_category_name_english, p.product_category_name, 'unknown') as category,
    p.product_name_lenght         as name_length,
    p.product_description_lenght  as description_length,
    p.product_photos_qty          as photos_qty,
    p.product_weight_g            as weight_g,
    p.product_length_cm * p.product_height_cm * p.product_width_cm as volume_cm3
from raw.products p
left join raw.category_translation t
    on p.product_category_name = t.product_category_name;
