use database olist;
use schema raw;

-- column order has to match the csv header order (COPY INTO loads by position)

create or replace table orders (
    order_id                        varchar,
    customer_id                     varchar,
    order_status                    varchar,
    order_purchase_timestamp        timestamp_ntz,
    order_approved_at               timestamp_ntz,
    order_delivered_carrier_date    timestamp_ntz,
    order_delivered_customer_date   timestamp_ntz,
    order_estimated_delivery_date   timestamp_ntz
);

create or replace table order_items (
    order_id             varchar,
    order_item_id        number,
    product_id           varchar,
    seller_id            varchar,
    shipping_limit_date  timestamp_ntz,
    price                number(10,2),
    freight_value        number(10,2)
);

create or replace table order_payments (
    order_id              varchar,
    payment_sequential    number,
    payment_type          varchar,
    payment_installments  number,
    payment_value         number(10,2)
);

create or replace table order_reviews (
    review_id                varchar,
    order_id                 varchar,
    review_score             number,
    review_comment_title     varchar,
    review_comment_message   varchar,
    review_creation_date     timestamp_ntz,
    review_answer_timestamp  timestamp_ntz
);

-- zip prefix is varchar on purpose, they have leading zeros
create or replace table customers (
    customer_id               varchar,
    customer_unique_id        varchar,
    customer_zip_code_prefix  varchar,
    customer_city             varchar,
    customer_state            varchar
);

-- "lenght" is how it's spelled in the source file... no idea why. fixed in staging
create or replace table products (
    product_id                  varchar,
    product_category_name       varchar,
    product_name_lenght         number,
    product_description_lenght  number,
    product_photos_qty          number,
    product_weight_g            number,
    product_length_cm           number,
    product_height_cm           number,
    product_width_cm            number
);

create or replace table sellers (
    seller_id               varchar,
    seller_zip_code_prefix  varchar,
    seller_city             varchar,
    seller_state            varchar
);

create or replace table category_translation (
    product_category_name          varchar,
    product_category_name_english  varchar
);


