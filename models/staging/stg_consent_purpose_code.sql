with raw_consent_purpose_code as (
    select * from {{ source('raw', 'consent_purpose_code') }}
)

select
    upper(trim(purpose_code)) as purpose_code,
    trim(name) as purpose_name,
    trim(legal_ground) as legal_ground
from raw_consent_purpose_code
where purpose_code is not null