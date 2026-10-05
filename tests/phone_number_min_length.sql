select customer_id, phone_number
from {{ ref('stg_customers') }}
where phone_number is not null
  and length(phone_number) < 8