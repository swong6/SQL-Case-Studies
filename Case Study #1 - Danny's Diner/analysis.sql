/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?
SELECT	s.customer_id,
		sum(m.price) AS total_sales
FROM sales s
JOIN menu m ON s.product_id = m.product_id
GROUP BY s.customer_id
ORDER BY s.customer_id ASC
;
-- 2. How many days has each customer visited the restaurant?
SELECT	customer_id,
		count(distinct order_date) AS total_visits
FROM sales
GROUP BY customer_id
ORDER BY customer_id ASC
;

-- 3. What was the first item from the menu purchased by each customer?
WITH ordered_sales AS (
SELECT 	s.customer_id,
		s.order_date, 
        m.product_name,
        DENSE_RANK() OVER (
			PARTITION BY s.customer_id
            ORDER BY s.order_date) as purchase_rank
FROM sales s 
INNER JOIN menu m 
	ON s.product_id = m.product_id
)

SELECT	customer_id,
		product_name
FROM ordered_sales
WHERE purchase_rank = 1
;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT	product_name,
		count(*) AS purchase_count
FROM sales s
JOIN menu m ON s.product_id = m.product_id
GROUP BY m.product_name
ORDER BY purchase_count DESC 
LIMIT 1
;

-- 5. Which item was the most popular for each customer?
 WITH purchases AS (
	SELECT	s.customer_id,
			m.product_name,
            COUNT(*) AS purchase_count
	FROM sales s
	INNER JOIN menu m 
		ON s.product_id = m.product_id
	GROUP BY s.customer_id, m.product_name
) 
SELECT	customer_id,
		product_name,
        purchase_count
FROM  (
	SELECT	customer_id,
			product_name,
			purchase_count,
			DENSE_RANK() OVER (
						PARTITION BY customer_id
						ORDER BY purchase_count DESC
						) as purchase_rank
			FROM purchases
	) as ranked_purchases
WHERE purchase_rank = 1
;

-- 6. Which item was purchased first by the customer after they became a member?
WITH JoinDateSales AS (
	SELECT	s.customer_id,
			m.product_name,
			m2.join_date,
			s.order_date
	FROM sales s
	INNER JOIN members m2
		ON s.customer_id = m2.customer_id
	INNER JOIN menu m 
		ON s.product_id = m.product_id
	WHERE s.order_date > m2.join_date
) 
SELECT	customer_id,
		product_name, 
		join_date,
		order_date
FROM  (
	SELECT	customer_id,
			product_name,
            join_date,
			order_date,
			DENSE_RANK() OVER (
						PARTITION BY customer_id
						ORDER BY order_date ASC
						) as purchase_rank
			FROM JoinDateSales
	) as ranked_purchases
WHERE purchase_rank = 1;

-- 7. Which item was purchased just before the customer became a member?
WITH BeforeJoinDateSales AS (
	SELECT	s.customer_id,
			m.product_name,
			m2.join_date,
			s.order_date
	FROM sales s
	INNER JOIN members m2
		ON s.customer_id = m2.customer_id
	INNER JOIN menu m 
		ON s.product_id = m.product_id
	WHERE s.order_date < m2.join_date
) 
SELECT	customer_id,
		product_name, 
		join_date,
		order_date
FROM  (
	SELECT	customer_id,
			product_name,
            join_date,
			order_date,
			ROW_NUMBER() OVER (
						PARTITION BY customer_id
						ORDER BY order_date DESC
						) as purchase_rank
			FROM BeforeJoinDateSales
	) as ranked_purchases
WHERE purchase_rank = 1
GROUP BY customer_id, product_name, join_date, order_date;

-- 8. What is the total items and amount spent for each member before they became a member?
WITH BeforeJoinDateSales AS (
	SELECT	s.customer_id,
			m.product_name,
			m2.join_date,
			s.order_date,
            m.price
	FROM sales s
	INNER JOIN members m2
		ON s.customer_id = m2.customer_id
	INNER JOIN menu m 
		ON s.product_id = m.product_id
	WHERE s.order_date < m2.join_date
) 
SELECT	customer_id,
		count(*) as total_items,
        sum(price) as total_spent
FROM BeforeJoinDateSales
GROUP BY customer_id
ORDER BY customer_id;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
WITH CustomerSpending AS (
	SELECT	s.customer_id,
			m.product_name,
			m.price,
            CASE 
				WHEN m.product_name = 'sushi' THEN m.price*20 
                ELSE m.price*10
			END AS points	
	FROM sales s 
	INNER JOIN menu m 
		ON s.product_id = m.product_id
)
SELECT	customer_id,
		sum(points) as total_points
FROM CustomerSpending
GROUP BY customer_id;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
WITH FirstWeekSales AS (
	SELECT	s.customer_id,
			m.product_name,
			m2.join_date,
			s.order_date,
            m.price
	FROM sales s
	INNER JOIN members m2
		ON s.customer_id = m2.customer_id
	INNER JOIN menu m 
		ON s.product_id = m.product_id
	WHERE s.order_date BETWEEN m2.join_date AND DATE_ADD(m2.join_date, INTERVAL 7 DAY)
) 
SELECT	customer_id,
        sum(price*20) as total_points
FROM FirstWeekSales
WHERE order_date BETWEEN '2021-01-01' AND '2021-01-31' AND customer_id IN ('A', 'B')
GROUP BY customer_id
ORDER BY customer_id;
