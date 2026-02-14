**Schema (PostgreSQL v13)**

    CREATE SCHEMA dannys_diner;
    SET search_path = dannys_diner;
    
    CREATE TABLE sales (
      "customer_id" VARCHAR(1),
      "order_date" DATE,
      "product_id" INTEGER
    );
    
    INSERT INTO sales
      ("customer_id", "order_date", "product_id")
    VALUES
      ('A', '2021-01-01', '1'),
      ('A', '2021-01-01', '2'),
      ('A', '2021-01-07', '2'),
      ('A', '2021-01-10', '3'),
      ('A', '2021-01-11', '3'),
      ('A', '2021-01-11', '3'),
      ('B', '2021-01-01', '2'),
      ('B', '2021-01-02', '2'),
      ('B', '2021-01-04', '1'),
      ('B', '2021-01-11', '1'),
      ('B', '2021-01-16', '3'),
      ('B', '2021-02-01', '3'),
      ('C', '2021-01-01', '3'),
      ('C', '2021-01-01', '3'),
      ('C', '2021-01-07', '3');
     
    
    CREATE TABLE menu (
      "product_id" INTEGER,
      "product_name" VARCHAR(5),
      "price" INTEGER
    );
    
    INSERT INTO menu
      ("product_id", "product_name", "price")
    VALUES
      ('1', 'sushi', '10'),
      ('2', 'curry', '15'),
      ('3', 'ramen', '12');
      
    
    CREATE TABLE members (
      "customer_id" VARCHAR(1),
      "join_date" DATE
    );
    
    INSERT INTO members
      ("customer_id", "join_date")
    VALUES
      ('A', '2021-01-07'),
      ('B', '2021-01-09');

---

**Query #1**

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

| customer_id | spend_amount |
| ----------- | ------------ |
| A           | 76           |
| B           | 74           |
| C           | 36           |

---
**Query #2**

    
    
    
    -- 2. How many days has each customer visited the restaurant?
    select	customer_id, 
    		count(distinct order_date) as visit_count
    from sales
    group by customer_id
    order by customer_id
    ;

| customer_id | visit_count |
| ----------- | ----------- |
| A           | 4           |
| B           | 6           |
| C           | 2           |

---
**Query #3**

    
    
    -- 3. What was the first item from the menu purchased by each customer?
    with cte as (
    select *,
    		rank() over (partition by customer_id order by order_date asc) as ranking
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

| customer_id | product_name |
| ----------- | ------------ |
| A           | curry        |
| A           | sushi        |
| B           | curry        |
| C           | ramen        |
| C           | ramen        |

---
**Query #4**

    
    
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

| product_name | purchase_count |
| ------------ | -------------- |
| ramen        | 8              |

---
**Query #5**

    
    
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

| customer_id | product_name |
| ----------- | ------------ |
| A           | ramen        |
| B           | ramen        |
| B           | curry        |
| B           | sushi        |
| C           | ramen        |

---
**Query #6**

    
    
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

| customer_id | product_name |
| ----------- | ------------ |
| A           | ramen        |
| B           | sushi        |

---
**Query #7**

    
    
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

| customer_id | product_name |
| ----------- | ------------ |
| A           | sushi        |
| A           | curry        |
| B           | sushi        |

---
**Query #8**

    
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

| customer_id | total_items | spend_amount |
| ----------- | ----------- | ------------ |
| A           | 2           | 25           |
| B           | 3           | 40           |

---
**Query #9**

    
    
    -- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
    
    -- points earned = price*10
    -- sushi points = price*10 where product_name = 'sushi'
    
    -- (1) case when s.product_id = 1 then price*20 
    --		else price*20
    --		end as points
    
    -- output -- customer_id, points
    with cte as (
    select s.customer_id,
      		s.product_id,
      		m1.price,
    		(case
            	when m1.product_name = 'sushi' then price*20 
            else price*10
    		end) as points
    from sales s 
    inner join menu m1
    on s.product_id = m1.product_id
    )
    select customer_id, 
    		sum(points) as total_points
    from cte
    group by customer_id
    order by customer_id
    ;

| customer_id | total_points |
| ----------- | ------------ |
| A           | 860          |
| B           | 940          |
| C           | 360          |

---
**Query #10**

    
    
    -- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
    
    with cte as (
    select s.customer_id,
    (case when 
    		s.order_date >= m2.join_date and 
     		s.order_date < join_date + interval '7 days'
    		then price*20
     	when
     		m1.product_name = 'sushi' then price*20
    	else price*10
     	end) as points
    from sales s 
    inner join menu m1
    on s.product_id = m1.product_id
    inner join members m2
    on m2.customer_id = s.customer_id
    where order_date >= '2021-01-01'
      	and order_date <= '2021-01-31'
      	and order_date >= join_date
    )
    
    select customer_id,
    		sum(points) as total_points
    from cte
    group by customer_id
    order by customer_id
    ;

| customer_id | total_points |
| ----------- | ------------ |
| A           | 1020         |
| B           | 320          |

---

[View on DB Fiddle](https://www.db-fiddle.com/f/2rM8RAnq7h5LLDTzZiRWcd/138)
