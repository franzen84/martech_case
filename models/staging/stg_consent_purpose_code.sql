select
    trim(purpose_code) as purpose_code,
    trim(name)         as purpose_name,
    trim(legal_ground) as legal_ground
from {{ source('raw', 'consent_purpose_code') }}