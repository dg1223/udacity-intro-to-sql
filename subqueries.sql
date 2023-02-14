region      4
sales_reps  50
accounts    351
orders      6912
web_events  9073

1. Provide the name of the sales_rep in each region with the largest amount of total_amt_usd sales
>> Provide the name of the sales_rep in each region with the largest amount of [] sales

Trickle down effect
-------------------
One region    can have multiple sales_rep
One sales rep can have multiple accounts
One account   can have multiple orders
> One sales rep can have multiple orders
>> One region can have  multiple orders for each sales rep
>>> GROUP BY will show the results for the most granular element

SELECT 	name,
		region_name,
        max_sales
FROM
(
SELECT	r.id,
		r.name region_name,
        s.name,
        MAX(o.total_amt_usd) max_sales,
  		RANK() OVER (
          PARTITION BY r.name
          ORDER BY MAX(o.total_amt_usd) DESC) AS rank
FROM region r
JOIN sales_reps s ON s.region_id = r.id
JOIN accounts a ON a.sales_rep_id = s.id
JOIN orders o ON o.account_id = a.id
GROUP BY 1, 2, 3
) t1
WHERE rank = 1
ORDER BY max_sales DESC

1.5 Provide the name of the sales_rep in each region with the largest amount of total total_amt_usd sales
>> Provide the name of the sales_rep in each region with the largest amount of total [] sales

SELECT 	name,
		region_name,
        max_of_sum_of_sales
FROM
(
SELECT	r.id,
		r.name region_name,
        s.name,
        SUM(o.total_amt_usd) max_of_sum_of_sales,
  		RANK() OVER (
          PARTITION BY r.name
          ORDER BY SUM(o.total_amt_usd) DESC) AS rank
FROM region r
JOIN sales_reps s ON s.region_id = r.id
JOIN accounts a ON a.sales_rep_id = s.id
JOIN orders o ON o.account_id = a.id
GROUP BY 1, 2, 3
) t1
WHERE rank = 1
ORDER BY max_of_sum_of_sales DESC

1.5 Without RANK() >> absolutely horrible; zero readability

WITH t1 AS (
  SELECT  r.id,
          r.name region_name,
          s.name,
          SUM(o.total_amt_usd) sum_of_sales
  FROM region r
  JOIN sales_reps s ON s.region_id = r.id
  JOIN accounts a ON a.sales_rep_id = s.id
  JOIN orders o ON o.account_id = a.id
  GROUP BY 1, 2, 3
),
t2 AS (
  SELECT  id,
  		  s_region_id,
          region_name,
          MAX(sum_of_sales) max_sum_of_sales
  FROM
  (
    SELECT	r.id,
            r.name region_name,    		
            s.name,
    		s.region_id s_region_id,
            SUM(o.total_amt_usd) sum_of_sales
    FROM region r
    JOIN sales_reps s ON s.region_id = r.id
    JOIN accounts a ON a.sales_rep_id = s.id
    JOIN orders o ON o.account_id = a.id
    GROUP BY 1, 2, 3, 4
  ) t
  GROUP BY 1, 2, 3
)
SELECT t1.name, t2.region_name, t2.max_sum_of_sales
FROM t2
JOIN t1 ON t1.id = t2.s_region_id AND 
	 t1.sum_of_sales = t2.max_sum_of_sales


2. For the region with the largest (sum) of sales total_amt_usd, how many total (count) orders were placed? 
>> For the region with the largest sum of sales, how many orders were placed in total? 

WITH t1 AS
(
  SELECT  t.id,
  		  t.name,
          MAX(t.sum_of_sales) largest_sale
  FROM
  (
    SELECT 	r.id,
    		r.name,
            SUM(o.total_amt_usd) sum_of_sales
    FROM region r
    JOIN sales_reps s ON s.region_id = r.id
    JOIN accounts a ON a.sales_rep_id = s.id
    JOIN orders o ON o.account_id = a.id
    GROUP BY 1, 2
  ) t
  GROUP BY 1, 2
)

SELECT r.name, t1.name, COUNT(*) total_orders
FROM region r
JOIN sales_reps s ON s.region_id = r.id
JOIN accounts a ON a.sales_rep_id = s.id
JOIN orders o ON o.account_id = a.id
JOIN t1 ON t1.id = r.id
GROUP BY 1, 2
HAVING r.name = t1.name
ORDER BY total_orders DESC
LIMIT 1


3. How many accounts had more total purchases than the account name which has bought the most 
standard_qty paper throughout their lifetime as a customer?

-- Doesn't account for ties
WITH t1 AS
(
  SELECT  a.id,
          a.name,
          SUM(standard_qty) sum_std_qty,
          SUM(total) total_purchase
  FROM accounts a
  JOIN orders o ON o.account_id = a.id
  GROUP BY 1, 2
  ORDER BY sum_std_qty DESC
  LIMIT 1
),

t2 AS
(
  SELECT  a.id,
          a.name,
          SUM(total) total_purchase
  FROM accounts a
  JOIN orders o ON o.account_id = a.id
  GROUP BY 1, 2
)

SELECT COUNT(t2.name)
FROM t2
JOIN t1 ON t2.total_purchase > t1.total_purchase

-- Account for ties
WITH t1 AS
(
  WITH t AS
  (
    SELECT  a.id,
            a.name,
            SUM(standard_qty) sum_std_qty,
            SUM(total) total_purchase
    FROM accounts a
    JOIN orders o ON o.account_id = a.id
    GROUP BY 1, 2
  ),
  tt AS
  (
    SELECT	id,
            name,
            total_purchase,
            RANK() OVER (
            ORDER BY sum_std_qty DESC) AS rank
    FROM t
  )

  SELECT	id, name, total_purchase
  FROM tt
  WHERE rank = 1
),

t2 AS
(
  SELECT  a.id,
          a.name,
          SUM(total) total_purchase
  FROM accounts a
  JOIN orders o ON o.account_id = a.id
  GROUP BY 1, 2
)

SELECT COUNT(t2.name)
FROM t2
JOIN t1 ON t2.total_purchase > t1.total_purchase


-- WITH clauses only
WITH t AS
(
  SELECT  a.id,
          a.name,
          SUM(standard_qty) sum_std_qty,
          SUM(total) total_purchase
  FROM accounts a
  JOIN orders o ON o.account_id = a.id
  GROUP BY 1, 2
),
tt AS
(
  SELECT	id,
          name,
          total_purchase,
          RANK() OVER (
          ORDER BY sum_std_qty DESC) AS rank
  FROM t
)

SELECT	id, name, total_purchase
FROM tt
WHERE rank = 1




4. For the customer that spent the most (in total over their lifetime as a customer) total_amt_usd, 
how many web_events did they have for each channel?
>> For the customer that spent the most, how many web_events did they have for each channel?

-- Find the customer that spent the most; account for ties
SELECT id, name, total_spent
FROM 
(
  SELECT  id,
          name,
          total_spent,
          RANK() OVER (
            ORDER BY total_spent DESC) AS rank
  FROM
  (
    SELECT	a.id,
            a.name,
            SUM(o.total_amt_usd) total_spent
    FROM accounts a
    JOIN orders o ON o.account_id = a.id
    GROUP BY 1, 2
  ) t1
) t2
WHERE rank = 1


WITH t1 AS
(
  SELECT  a.id,
          a.name,
          SUM(o.total_amt_usd) total_spent
  FROM accounts a
  JOIN orders o ON o.account_id = a.id
  GROUP BY 1, 2
),
t2 AS
(
SELECT  id,
        name,
        total_spent,
        RANK() OVER (
          ORDER BY total_spent DESC) AS rank
FROM t1
)

SELECT id, name, total_spent
FROM t2
WHERE rank = 1
-----------------

WITH top_customer AS
(
  WITH t1 AS
  (
    SELECT  a.id,
            a.name,
            SUM(o.total_amt_usd) total_spent
    FROM accounts a
    JOIN orders o ON o.account_id = a.id
    GROUP BY 1, 2
  ),
  t2 AS
  (
    SELECT  id,
            name,
            total_spent,
            RANK() OVER (
              ORDER BY total_spent DESC) AS rank
    FROM t1
  )

  SELECT id, name, total_spent
  FROM t2
  WHERE rank = 1
)

SELECT 	t.id,
		t.name,
        w.channel,
        COUNT(*)
FROM top_customer t
JOIN web_events w ON w.account_id = t.id
GROUP BY 1, 2, 3

5. What is the lifetime average amount spent in terms of total_amt_usd for the top 10 total spending accounts?
>> Ambiguous question

5.1 Avg spent for each account in the top 10 list
-- account for ties
WITH t1 AS
(
  SELECT	a.id,
          a.name,
          AVG(o.total_amt_usd) avg_spent
  FROM accounts a
  JOIN orders o ON o.account_id = a.id
  GROUP BY 1, 2
),
t2 AS
(
SELECT  id,
        name,
        avg_spent,
        RANK() OVER (
          ORDER BY avg_spent DESC) AS rank
FROM t1
)

SELECT id, name, avg_spent
FROM t2
WHERE rank <= 10



5.2 Avg spent by the top 10 account in the list
WITH t1 AS
(
  SELECT  a.id,
          a.name,
          SUM(o.total_amt_usd) total_spent
  FROM accounts a
  JOIN orders o ON o.account_id = a.id
  GROUP BY 1, 2
),
t2 AS
(
  SELECT  id,
           name,
           total_spent,
           RANK() OVER (
             ORDER BY total_spent DESC) AS rank
  FROM t1
)

SELECT AVG(total_spent)
FROM t2
WHERE rank <= 10

6. What is the lifetime average amount spent in terms of total_amt_usd, including only the companies 
that spent more per order, on average, than the average of all orders?
>> This is the triple average mashup

WITH t1 AS
(
  SELECT AVG(total_amt_usd) avg_amt_usd
  FROM accounts a
  JOIN orders o ON o.account_id = a.id
),
t2 AS
(
  SELECT	a.id,
  			a.name,
  			AVG(total_amt_usd) avg_amt_usd
  FROM accounts a
  JOIN orders o ON o.account_id = a.id
  GROUP BY 1, 2
),
t3 AS
(
  SELECT  t2.name,
          t2.avg_amt_usd
  FROM t1
  JOIN t2 ON t2.avg_amt_usd > t1.avg_amt_usd
)

SELECT AVG(t3.avg_amt_usd)
FROM t3