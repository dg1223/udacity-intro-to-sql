
    Provide the name of the sales_rep in each region with the largest amount of total_amt_usd sales.

-- My solution 1
WITH region_max_cte AS (
  SELECT r.id, MAX(o.total_amt_usd) amount
  FROM orders o
  JOIN accounts a ON a.id = o.account_id
  JOIN sales_reps s ON s.id = a.sales_rep_id
  JOIN region r ON r.id = s.region_id
  GROUP BY r.id
)
SELECT 	s.name sales_rep, 
		r.name region_name,
        o.total_amt_usd total_sales
FROM sales_reps s
JOIN region r ON r.id = s.region_id
JOIN accounts a ON a.sales_rep_id = s.id
JOIN orders o ON o.account_id = a.id
JOIN region_max_cte m ON m.id = r.id AND m.amount = o.total_amt_usd


    For the region with the largest (sum) of sales total_amt_usd, how many total (count) orders were placed?

-- My solution 2
WITH region_max_cte AS (
  SELECT r.id, SUM(o.total_amt_usd) amount
  FROM orders o
  JOIN accounts a ON a.id = o.account_id
  JOIN sales_reps s ON s.id = a.sales_rep_id
  JOIN region r ON r.id = s.region_id
  GROUP BY r.id
  ORDER BY amount DESC
  LIMIT 1
)
SELECT  r.name region_name,
        --o.total_amt_usd max_sales_amt,
        COUNT(o.total) num_orders
FROM sales_reps s
JOIN region r ON r.id = s.region_id
JOIN accounts a ON a.sales_rep_id = s.id
JOIN orders o ON o.account_id = a.id
JOIN region_max_cte m ON m.id = r.id
GROUP BY r.name

    How many accounts had more total purchases than the account name which has bought the most standard_qty paper throughout their lifetime as a customer?

-- My solution 3 v1
SELECT COUNT(*)
FROM (
  SELECT  a.id, 
        SUM(o.total) total
  FROM accounts a
  JOIN orders o ON a.id = o.account_id
  GROUP BY 1) t2
  WHERE total > (
    SELECT t1.total 
    FROM (
    SELECT a.id, 
         SUM(o.total) total, 
         SUM(o.standard_qty) std_amount
    FROM accounts a
    JOIN orders o ON a.id = o.account_id
    GROUP BY 1
    ORDER BY 3 DESC
    LIMIT 1) t1
    )


-- My solution 3 v2
SELECT COUNT(*)
FROM (
  SELECT  a.id, 
        SUM(o.total) total
  FROM accounts a
  JOIN orders o ON a.id = o.account_id
  GROUP BY 1
  HAVING SUM(o.total)  > (
    SELECT t1.total 
    FROM (
    SELECT a.id, 
         SUM(o.total) total, 
         SUM(o.standard_qty) std_amount
    FROM accounts a
    JOIN orders o ON a.id = o.account_id
    GROUP BY 1
    ORDER BY 3 DESC
    LIMIT 1) t1
    )
  ) t2

-- My solution 3 v3 WITH clause
WITH t1 AS (
  SELECT  a.id, 
          SUM(o.total) total, 
          SUM(o.standard_qty) std_amount
      FROM accounts a
      JOIN orders o ON a.id = o.account_id
      GROUP BY 1
      ORDER BY 3 DESC
      LIMIT 1
),
t2 AS (
  SELECT  a.id, 
          SUM(o.total) total
    FROM accounts a
    JOIN orders o ON a.id = o.account_id
    GROUP BY 1
    HAVING SUM(o.total) > (SELECT t1.total FROM t1)
)
SELECT COUNT(*)
FROM t2



    For the customer that spent the most (in total over their lifetime as a customer) total_amt_usd, how many web_events did they have for each channel?

-- My solution 4 v1
SELECT  t2.name,
        t2.channel,
        t2.num_events
FROM (
  SELECT  a.id,
          a.name,
          w.channel,
          COUNT(*) num_events
  FROM web_events w
  JOIN accounts a ON a.id = w.account_id
  GROUP BY 1, 2, 3) t2
  WHERE t2.id = (
    SELECT t1.id
    FROM (
      SELECT  a.id,
      SUM(o.total_amt_usd) total_amt_usd
      FROM accounts a
      JOIN orders o ON o.account_id = a.id
      GROUP BY 1
      ORDER BY 2 DESC
      LIMIT 1) t1
      )
ORDER BY t2.num_events DESC

-- My solution 4 v2
SELECT  t2.name,
        t2.channel,
        t2.num_events
FROM (
  SELECT  a.id,
          a.name,
          w.channel,
          COUNT(*) num_events
  FROM web_events w
  JOIN accounts a ON a.id = w.account_id
  GROUP BY 1, 2, 3
  HAVING a.id = (
    SELECT t1.id
    FROM (
      SELECT  a.id,
      SUM(o.total_amt_usd) total_amt_usd
      FROM accounts a
      JOIN orders o ON o.account_id = a.id
      GROUP BY 1
      ORDER BY 2 DESC
      LIMIT 1) t1
      )
    ) t2
ORDER BY t2.num_events DESC

SELECT ...
FROM (
  SELECT ...
  FROM ...
  JOIN ... ON ... = ...
  GROUP BY ...
  HAVING ... = (
    SELECT ...
    FROM (
      SELECT ...
      FROM ...
      JOIN ...
      GROUP BY ...
      ORDER BY ...
      LIMIT ...
      ) t1
  )
) t2

-- My solution 4 v3 WITH clause
WITH t1 AS (
  SELECT  a.id,
        SUM(o.total_amt_usd) total_amt_usd
        FROM accounts a
        JOIN orders o ON o.account_id = a.id
        GROUP BY 1
        ORDER BY 2 DESC
        LIMIT 1
),
t2 AS (
  SELECT  a.id,
            a.name,
            w.channel,
            COUNT(*) num_events
    FROM web_events w
    JOIN accounts a ON a.id = w.account_id
    GROUP BY 1, 2, 3
    HAVING a.id = (SELECT t1.id FROM t1)
)
SELECT  t2.name,
        t2.channel,
        t2.num_events
FROM t2
ORDER BY t2.num_events DESC

WITH t1 AS (

),
t2 AS (
...
...
WHERE / HAVING ... [=, <, >] (SELECT t1.[] FROM t1)
)
SELECT
FROM
ORDER BY


    What is the lifetime average amount spent in terms of total_amt_usd for the top 10 total spending accounts?

-- My solution 5
SELECT ROUND(AVG(t1.total_spent), 2) avg_spent
FROM (
SELECT  a.id,
        a.name,
        SUM(o.total_amt_usd) total_spent
FROM accounts a
JOIN orders o ON o.account_id = a.id
GROUP BY 1, 2
ORDER BY 3 DESC
LIMIT 10) t1
ORDER BY avg_spent DESC


WITH t1 AS (
  SELECT  a.id,
          a.name,
          SUM(o.total_amt_usd) total_spent
  FROM accounts a
  JOIN orders o ON o.account_id = a.id
  GROUP BY 1, 2
  ORDER BY 3 DESC
  LIMIT 10
)
SELECT ROUND(AVG(t1.total_spent), 2) avg_spent
FROM t1
ORDER BY avg_spent DESC



    What is the lifetime average amount spent in terms of total_amt_usd, including only the companies that spent more per order, on average, than the average of all orders?

-- My solution 6 v1
SELECT ROUND(AVG(t2.avg_spent), 2) avg_spent
FROM (
  SELECT  t1.avg_spent avg_spent
  FROM (
    SELECT  a.id,
            a.name,
            AVG(o.total_amt_usd) avg_spent
    FROM accounts a
    JOIN orders o ON o.account_id = a.id
    GROUP BY 1, 2) t1
  WHERE avg_spent > 
    (
    SELECT AVG(o.total_amt_usd) avg_all_orders
    FROM orders o
    )
  ) t2

-- My solution 6 v2
SELECT ROUND(AVG(t1.avg_spent), 2) avg_spent
FROM (
  SELECT  a.id,
          a.name,
          AVG(o.total_amt_usd) avg_spent
  FROM accounts a
  JOIN orders o ON o.account_id = a.id
  GROUP BY 1, 2
  HAVING AVG(o.total_amt_usd) > 
  (
    SELECT AVG(o.total_amt_usd) avg_all_orders
    FROM orders o
  )
) t1


WITH t1 AS (
  SELECT AVG(o.total_amt_usd) avg_all_orders
  FROM orders o
),
t2 AS (
  SELECT  a.id,
          a.name,
          AVG(o.total_amt_usd) avg_spent
  FROM accounts a
  JOIN orders o ON o.account_id = a.id
  GROUP BY 1, 2
  HAVING AVG(o.total_amt_usd) > (SELECT t1.avg_all_orders FROM t1)
)
SELECT ROUND(AVG(t2.avg_spent), 2) avg_spent
FROM t2