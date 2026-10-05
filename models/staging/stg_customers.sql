with raw_customers as (
    select
        *
    from {{ source('raw', 'customers') }}
),


phone_cleaning as (
    select
        *,  
        regexp_replace(replace(trim(split_part(phone_number, '/', 1)), '+', '00'), '[^0-9]', '', 'g') as phone_1,
        regexp_replace(replace(trim(split_part(phone_number, '/', 2)), '+', '00'), '[^0-9]', '', 'g') as phone_2
    from raw_customers
)


select
    upper(trim(customer_id)) as customer_id,
    lower(trim(email)) as email,
    case when length(phone_1) >= 8 then phone_1 end as phone_number,
    case when length(phone_2) >= 8 then phone_2 end as phone_number_secondary,
    try_cast(signup_date as date) as signup_date,
    lower(trim(subscription_plan)) as subscription_plan,
    lower(trim(subscription_status)) as subscription_status,
    try_cast(status_change_date as date) as status_change_date
from phone_cleaning
where customer_id is not null
qualify row_number() over (partition by customer_id order by status_change_date desc) = 1