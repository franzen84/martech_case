with raw_campaign_interactions as (
    select * from {{ source('raw', 'campaign_interactions') }}
)

select
    upper(trim(interaction_id)) as interaction_id,
    upper(trim(customer_id)) as customer_id,
    upper(trim(campaign_id)) as campaign_id,
    lower(trim(channel)) as channel,
    lower(trim(interaction_type)) as interaction_type,
    try_cast(interaction_ts as timestamp) as interaction_timestamp,
from raw_campaign_interactions
where interaction_id is not null
    and customer_id is not null
    and try_cast(interaction_ts as timestamp) is not null
    --and customer_id = 'CUST_000305'
qualify row_number() over (partition by interaction_id order by interaction_ts) = 1