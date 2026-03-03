-- A. Customer Nodes Exploration
-- How many unique nodes are there on the Data Bank system?

select count(distinct node_id)
from customer_nodes
;

-- What is the number of nodes per region?   
-- output -- region_id | node_ct

select region_id,
		count(node_id) as region_ct
from customer_nodes
group by region_id
order by region_id
;

-- How many customers are allocated to each region?

-- output -- region_id | customer_ct
-- customer_ct = count(distinct customer_id)

select	region_id,
		count(distinct customer_id) as customer_ct
from customer_nodes
group by region_id
order by region_id
;

-- How many days on average are customers reallocated to a different node?
-- reallocation days = avg(end_date - start_date)
-- output -- node | avg(days)

select	round(AVG(DATEDIFF(end_date, start_date)),2) AS difference
from customer_nodes
where end_date != '9999-12-31'
;

-- What is the median, 80th and 95th percentile for this same reallocation days metric for each region?

-- output -- region_id | median(difference) | 80th(difference) | 95th(difference)

WITH base AS (
  SELECT
    cn.region_id,
    r.region_name,
    DATEDIFF(cn.end_date, cn.start_date) AS difference
  FROM customer_nodes cn
  JOIN regions r USING (region_id)
  WHERE cn.end_date <> '9999-12-31'
),
ranked AS (
  SELECT
    *,
    CUME_DIST() OVER (PARTITION BY region_id ORDER BY difference) AS cd
  FROM base
)
SELECT
  region_id,
  region_name,
  MIN(difference) AS p95_cutoff
FROM ranked
WHERE cd >= 0.95
GROUP BY region_id, region_name
ORDER BY region_id;


-- B. Customer Transactions
-- What is the unique count and total amount for each transaction type?

-- output -- txn_type | ct | total_amount
-- ct = count(txn_type)
-- total_amount = sum(txn_amount)

select	txn_type,
		count(txn_type) as ct,
        sum(txn_amount) as total_amount
from customer_transactions
group by txn_type
;

-- What is the average total historical deposit counts and amounts for all customers?

-- output -- customer_id | deposit_ct | deposit_amt
-- deposit_ct = count(*)
-- deposit_amt = sum(txn_amount)
-- where txn_type = deposit

with cte as (
select	customer_id,
		count(customer_id) as deposit_ct,
		sum(txn_amount) as deposit_amt
from customer_transactions
where txn_type = 'deposit'
group by customer_id
)
select	round(avg(deposit_ct),2) as avg_ct,
		round(avg(deposit_amt),2) as avg_amt
from cte
;     

-- For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?

-- output -- month | ct(deposit more than one) | ct(1 purchse or 1 withdrawal)

-- cte (cts of each txn_type)
-- outer -- month | cts 
-- where conditions
-- group by month

with cte as (
select	customer_id,
		date_format(txn_date, '%Y-%m-01') as monthly,
        sum(txn_type = 'deposit') as deposit_ct,
        sum(txn_type = 'purchase') as purchase_ct,
        sum(txn_type = 'withdrawal') as withdrawal_ct
from customer_transactions
group by customer_id, monthly

  )
  
select	monthly,
		count(*) as customer_ct
from cte
where deposit_ct > 1
		and (purchase_ct >= 1 or withdrawal_ct >= 1)
group by monthly
order by monthly
;

-- What is the closing balance for each customer at the end of the month?

-- output -- customer_id | end_of_month | closing_balance
-- beginning_of_month = date_format(txn_date, '%Y-%m-01')
-- net_change = (deposit - purchase - withdrawal)
-- cumulative net change = sum(net) over (partition by customer_id order by beginning_of_month) as cumulative_net

-- cte -- customer_id, sum(deposit, purchase, withdrawals), beginning_of_month, net change
-- outer -- customer_id, month, cumulative_net as closing_balance
with cte as (
select	customer_id,
		date_format(txn_date, '%Y-%m-01') as month,
        sum(case 
            	when txn_type = 'deposit' then +txn_amount
                when txn_type = 'purchase' then -txn_amount
                when txn_type = 'withdrawal' then -txn_amount
           end) as net_change
from customer_transactions
group by customer_id, month
  )

select	customer_id,
		month,
        net_change,
        sum(net_change) over (partition by customer_id order by month) as closing_balance
from cte
;

-- What is the percentage of customers who increase their closing balance by more than 5%?

-- MoM increase > 5%
-- current closing_balance/ previous > 1.05
-- previous = lag(closing_balance) over (partition by customer_id, order by month)

with cte as (
select	customer_id,
		date_format(txn_date, '%Y-%m-01') as month,
        sum(case 
            	when txn_type = 'deposit' then +txn_amount
                when txn_type = 'purchase' then -txn_amount
                when txn_type = 'withdrawal' then -txn_amount
           end) as net_change
from customer_transactions
group by customer_id, month
  ), 
closing_cte as (

select	customer_id,
		month,
        net_change,
        sum(net_change) over (partition by customer_id order by month) as closing_balance
from cte
  ), 
cte3 as (
select	customer_id,
		month,
        net_change,
        lag(closing_balance) over (partition by customer_id order by month) as prev_balance,
        closing_balance
from closing_cte
 )

select	count(distinct customer_id)*100/
        (select count(distinct customer_id) from customer_transactions) as qualify_pct
from cte3
where prev_balance > 0
		and (closing_balance/prev_balance) > 1.05
;

-- C. Data Allocation Challenge
-- To test out a few different hypotheses - the Data Bank team wants to run an experiment where different groups of customers would be allocated data using 3 different options:

-- Option 1: data is allocated based off the amount of money at the end of the previous month
-- Option 2: data is allocated on the average amount of money kept in the account in the previous 30 days
-- Option 3: data is updated real-time
-- For this multi-part challenge question - you have been requested to generate the following data elements to help the Data Bank team estimate how much data will need to be provisioned for each option:

-- running customer balance column that includes the impact each transaction

with cte as (
select	customer_id,
		txn_date,
        sum(case 
        	when txn_type = 'deposit' 
            then txn_amount 
            else -txn_amount end) as balance
from customer_transactions
group by 1,2
order by 1,2
 )
 
select	customer_id,
		txn_date,
        balance,
        sum(balance) over (partition by customer_id order by txn_date) as running_balance
from cte
group by customer_id, txn_date

;


-- customer balance at the end of each month

with cte as (
select	customer_id,
		date_format(txn_date, '%Y-%m-01') as month_beginning,
        sum(case 
        	when txn_type = 'deposit' 
            then txn_amount 
            else -txn_amount end) as balance
from customer_transactions
group by 1,2
 )
 
select	customer_id,
		month_beginning,
        sum(balance) over (partition by customer_id order by month_beginning) as eom_balance
from cte
;


-- minimum, average and maximum values of the running balance for each customer
with cte as (
select	customer_id,
		date_format(txn_date, '%Y-%m-01') as month_beginning,
        sum(case 
        	when txn_type = 'deposit' 
            then txn_amount 
            else -txn_amount end) as balance
from customer_transactions
group by 1,2
 ),
 cte2 as ( 
select	customer_id,
		month_beginning,
        sum(balance) over (partition by customer_id order by month_beginning) as eom_balance
from cte
)

select	customer_id,
		min(eom_balance) as min_balance,
        avg(eom_balance) as avg_balance,
        max(eom_balance) as max_balance
from cte2
group by customer_id
;
