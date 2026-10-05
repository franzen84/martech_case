with raw_product_events as (
    select * from {{ source('raw', 'product_events') }}
)

select
    event_id,
    upper(trim(customer_id)) as customer_id,
    lower(trim(event_type)) as event_type,
    try_cast(event_ts as timestamp) as event_timestamp,
    event_properties
from raw_product_events
where event_id is not null
    and customer_id is not null
    and try_cast(event_ts as timestamp) is not null
qualify row_number() over (partition by event_id order by event_ts) = 1
