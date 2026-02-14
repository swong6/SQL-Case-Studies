/* --------------------
   Case Study Questions
   --------------------*/
-- 1. What is the total amount each customer spent at the restaurant?

-- (1) product_id * price = purchase amount
-- (2) inner join sales with menu 
-- (3) sum(purchase amounts)
-- output -- customer_id | spend_amount

select customer_id, 
		sum(s.product_id * m.price) as spend_amount
from sales s 
inner join menu m 
on s.product_id = m.product_id
group by customer_id
order by customer_id
;


-- 2. How many days has each customer visited the restaurant?

-- (1) visit_count = count(order_date)
-- output -- customer_id | visit_count

select	customer_id, 
		count(order_date) as visit_count
from sales
group by customer_id
order by customer_id
;

-- 3. What was the first item from the menu purchased by each customer?

-- rank() over (partition by customer_id order by order_date asc)
-- output -- customer_id | first_product

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

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?



-- 5. Which item was the most popular for each customer?
-- 6. Which item was purchased first by the customer after they became a member?
-- 7. Which item was purchased just before the customer became a member?
-- 8. What is the total items and amount spent for each member before they became a member?
-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
