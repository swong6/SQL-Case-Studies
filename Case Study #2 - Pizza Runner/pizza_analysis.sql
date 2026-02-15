-- (1) Temp Table - customer_orders 
-- handling nulls w/ case when
DROP TABLE IF EXISTS customer_orders_temp;

CREATE TEMPORARY TABLE customer_orders_temp AS
SELECT order_id,
       customer_id,
       pizza_id,
       CASE
           WHEN exclusions = '' THEN NULL
           WHEN exclusions = 'null' THEN NULL
           ELSE exclusions
       END AS exclusions,
       CASE
           WHEN extras = '' THEN NULL
           WHEN extras = 'null' THEN NULL
           ELSE extras
       END AS extras,
       order_time
FROM customer_orders;

SELECT * FROM customer_orders_temp;
 
 -- (2) Temp Table - runner_orders 
-- nulls (pickup_time, distance, duration, cancellation)

DROP TABLE IF EXISTS runner_orders_temp;

CREATE TEMPORARY TABLE runner_orders_temp AS

SELECT order_id,
       runner_id,
       CASE
           WHEN pickup_time LIKE 'null' THEN NULL
           ELSE pickup_time
       END AS pickup_time,
       CASE
           WHEN distance LIKE 'null' THEN NULL
           ELSE CAST(regexp_replace(distance, '[a-z]+', '') AS FLOAT)
       END AS distance,
       CASE
           WHEN duration LIKE 'null' THEN NULL
           ELSE CAST(regexp_replace(duration, '[a-z]+', '') AS FLOAT)
       END AS duration,
       CASE
           WHEN cancellation LIKE '' THEN NULL
           WHEN cancellation LIKE 'null' THEN NULL
           ELSE cancellation
       END AS cancellation
FROM runner_orders;

SELECT * FROM runner_orders_temp;

-- A. Pizza Metrics
-- How many pizzas were ordered?
select	count(*) as pizza_count
from customer_orders_temp
;

-- How many unique customer orders were made?
select	count(distinct order_id) as unique_order_count
from customer_orders_temp
;
-- How many successful orders were delivered by each runner?

-- output -- runner_id | successful_count
-- successful_count = where cancellation is null

select	runner_id,
		count(*) as successful_count
from runner_orders_temp 
where cancellation is null
group by runner_id
;

-- How many of each type of pizza was delivered?

-- join customer_orders_temp, runner_orders_temp, pizza_names
-- output -- pizza_name | count

select 	c.pizza_id,
		p.pizza_name, 
		count(c.pizza_id) as pizza_count
from customer_orders_temp c 
inner join runner_orders_temp r 
on c.order_id = r.order_id
inner join pizza_names p 
on c.pizza_id = p.pizza_id
where cancellation is null
group by c.pizza_id, p.pizza_name
;

-- How many Vegetarian and Meatlovers were ordered by each customer?

-- output -- pizza name | order_count

select 	c.customer_id,
		p.pizza_name, 
		count(c.pizza_id) as pizza_count
from customer_orders_temp c 
inner join pizza_names p 
on c.pizza_id = p.pizza_id
group by c.customer_id, p.pizza_name
order by c.customer_id
;

-- What was the maximum number of pizzas delivered in a single order?
-- output -- c.order_id, max_pizza_ct

select	c.order_id,	
		count(c.pizza_id) as max_pizza_ct
from customer_orders_temp c 
inner join runner_orders_temp r 
where cancellation is null
group by c.order_id
order by c.order_id, max_pizza_ct desc
limit 1 
;

-- For each customer, how many delivered pizzas had at least 1 change and how many had no changes?

-- delivered = r.cancellation is null
-- 1_change = exclusion or extras is not null
-- no_change = exclusion and extras is null

-- output -- c.customer_id | count(1_change) | count(no_change)

select	c.customer_id,
		sum(case
        	when c.exclusions is not null
            	or c.extras is not null
            then 1 else 0 end) as one_change,
		sum(case
        	when c.exclusions is null 
            	and c.extras is null
            then 1 else 0 end) as no_change
from customer_orders_temp c 
inner join runner_orders_temp r 
on c.order_id = r.order_id
where r.cancellation is null
group by c.customer_id
order by c.customer_id
;

-- How many pizzas were delivered that had both exclusions and extras?

-- output | count(BOTH exclusions and extras is not null

select	c.customer_id,	
		sum(case
        	when c.exclusions is not null
            	and c.extras is not null
            then 1 else 0 end) as both_changes
from customer_orders_temp c 
inner join runner_orders_temp r 
on c.order_id = r.order_id
where r.cancellation is null
group by c.customer_id
;
-- What was the total volume of pizzas ordered for each hour of the day?

-- group by hour
-- total_volume = count(*)

select	hour(order_time) as hour_of_day,	
		count(*) as pizza_ct,
        round(100*count(*)/sum(count(*)) over(),2) as volume
from customer_orders_temp c 
group by hour_of_day
order by hour_of_day
;

-- What was the volume of orders for each day of the week?

select	dayname(order_time) as day_of_week,	
		count(*) as pizza_ct,
        round(100*count(*)/sum(count(*)) over(),2) as volume
from customer_orders_temp c 
group by day_of_week
order by day_of_week desc
