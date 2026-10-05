    with raw_consent_registry as (
    select * from {{ source('raw', 'consent_registry') }}
)

select
    'CUST_' || lpad(trim(cast(customer_id as varchar)), 6, '0') as customer_id,
    trim(purpose_code)                                          as purpose_code,
    try_cast(consent_ts as timestamp)                           as consent_ts
from raw_consent_registry
where customer_id is not null
  and purpose_code is not null