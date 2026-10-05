-- Business logic: is_winback_target can only contain churned customers. This test checks that no active customers are included in the segment.
-- Test will fail is any rows are returned.
select
    customer_id,
    subscription_status
from {{ ref('mart_audience_segments') }}
where is_winback_target = 1
  and subscription_status <> 'churned'