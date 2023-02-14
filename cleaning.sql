--1. 1, 1, 349 
SELECT domain, COUNT(*)
FROM (
SELECT RIGHT(website, 3) AS domain
FROM accounts) t1
GROUP BY 1

--2. C:37
SELECT first_letter, COUNT(*)
FROM (
SELECT LEFT(name, 1) AS first_letter
FROM accounts) t1
GROUP BY 1
ORDER BY 2 DESC

--3.
SELECT (CAST(SUM(first_character) AS DECIMAL)/COUNT(*))*100 proportion
FROM (
SELECT 
  CASE 
    WHEN LEFT(name, 1) NOT IN ('1','2','3','4','5','6','7','8','9','0') THEN 1 ELSE 0 
    END AS first_character
FROM accounts) t1

WITH t1 AS (
  SELECT 
    CASE 
      WHEN LEFT(name, 1) NOT IN ('1','2','3','4','5','6','7','8','9','0') THEN 1 ELSE 0 
      END AS first_character
  FROM accounts
)
SELECT (CAST(SUM(t1.first_character) AS DECIMAL)/COUNT(*))*100 proportion
FROM t1

--4.
WITH t1 AS (
  SELECT 
    CASE 
      WHEN LEFT(LOWER(name), 1) IN ('a','e','i','o','u') THEN 1 ELSE 0 
      END AS vowel
  FROM accounts
),
t2 AS (
SELECT (CAST(SUM(t1.vowel) AS DECIMAL)/COUNT(*))*100 percent_vowel
FROM t1
)
SELECT t2.percent_vowel,
       (100-t2.percent_vowel) percent_not_vowel
FROM t2