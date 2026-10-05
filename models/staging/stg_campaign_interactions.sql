with raw_campaign_interactions as (
    select * from {{ source('raw', 'campaign_interactions') }}
)

select
    interaction_id,
    upper(trim(customer_id))                      as customer_id,
    campaign_id,
    lower(trim(channel))                          as channel,
    lower(trim(interaction_type))                 as interaction_type,
    try_cast(interaction_ts as timestamp)         as interaction_ts,
    cast(try_cast(interaction_ts as timestamp) as date) as interaction_date
from raw_campaign_interactions
where interaction_id is not null
  and customer_id is not null
  and try_cast(interaction_ts as timestamp) is not null
qualify row_number() over (partition by interaction_id order by interaction_ts) = 1