-- (1) Temp Table - Updating data types - customer_orders 
-- exclusions: varchar(4) --> INT
-- extras: varchar(4) --> INT
-- nulls: replaced with ' '

CREATE TEMP TABLE customer_orders_temp AS (
  select
  	order_id,
  	customer_id,
  	pizza_id,
  	case
  		when exclusions is null or 		exclusions like 'null' then ' '
 		else exclusions
  		end as exclusions,
  	case
  		when extras is null or extras like 'null' then ' '
  		else extras
  		end as extras,
  	order_time
	from pizza_runner.customer_orders
 )
 ;
 select * from customer_orders_temp
 ;
 
 -- (2) Temp Table - runner_orders 
-- nulls (pickup_time, distance, duration, cancellation): replaced with ' '
-- distance: replace 'km' with ' '
-- duration: replace 'minutes', 'min' with ' '
