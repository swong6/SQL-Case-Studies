/* --------------------
   Case Study Questions
   --------------------*/
-- 1. What is the total amount each customer spent at the restaurant?
select customer_id, 
		sum(m.price) as spend_amount
from sales s 
inner join menu m 
on s.product_id = m.product_id
group by customer_id
order by customer_id
;


-- 2. How many days has each customer visited the restaurant?
select	customer_id, 
		count(order_date) as visit_count
from sales
group by customer_id
order by customer_id
;

-- 3. What was the first item from the menu purchased by each customer?
with cte as (
select *,
		row_number() over (partition by customer_id order by order_date asc) as ranking
from sales s 
inner join menu m 
on s.product_id = m.product_id
  )
select	customer_id, 
		product_name
from cte
where ranking = 1
order by customer_id
;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
select	product_name,
		count(*) as purchase_count
from sales s 
inner join menu m 
on s.product_id = m.product_id
group by product_name
order by purchase_count desc
limit 1 
;

-- 5. Which item was the most popular for each customer?
with cte as (
select	customer_id,
		product_name,
  		rank() over (partition by customer_id order by count(*) desc) as ranking 
from sales s 
inner join menu m 
on s.product_id = m.product_id
group by 1,2
 )
 
select	customer_id,
 		product_name
from cte
where ranking = 1 
;

-- 6. Which item was purchased first by the customer after they became a member?

-- first purchase = purchase after join_date
-- (1) sales join menu join members
-- (2) where order_date > join_date
-- (3) and ranking = 1

-- CTE: all purchases after join_date
-- outer: select purchase_name where ranking = 1
with cte as (
select	s.customer_id,
  		s.product_id,
  		m1.product_name,
		rank() over (partition by s.customer_id order by s.order_date asc) as ranking
from sales s 
inner join menu m1 
on s.product_id = m1.product_id
inner join members m2
on m2.customer_id = s.customer_id
where s.order_date > m2.join_date
)

select	customer_id,
		product_name
from cte
where ranking = 1 
;

-- 7. Which item was purchased just before the customer became a member?

-- purchase before member = first order_date < join_date
-- rank() over (partition by customer_id order by order_date desc)

with cte as (
select	s.customer_id,
  		s.product_id,
  		m1.product_name,
        join_date,
        order_date,
		rank() over (partition by s.customer_id order by s.order_date desc) as ranking
from sales s 
inner join menu m1 
on s.product_id = m1.product_id
inner join members m2
on m2.customer_id = s.customer_id
where s.order_date < m2.join_date
)

select	customer_id,
		product_name
from cte
where ranking = 1 
;
-- 8. What is the total items and amount spent for each member before they became a member?

-- total items = count(*)
-- spend amount = sum(product_id * price)
-- do this in the same cte 
-- where order date < join date

-- output -- customer_id, total_items, spend_amount
with cte as (
select	s.customer_id,
  		m1.price
from sales s 
inner join menu m1
on s.product_id = m1.product_id
inner join members m2
on m2.customer_id = s.customer_id
where s.order_date < m2.join_date
)

select	customer_id, 
		count(*) as total_items,
        sum(price) as spend_amount
from cte
group by customer_id
order by customer_id
;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
