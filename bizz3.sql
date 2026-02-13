CREATE DATABASE IF NOT EXISTS retail_db;
USE retail_db;

CREATE TABLE orders (
    Invoice VARCHAR(20),
    StockCode VARCHAR(20),
    Description VARCHAR(255),
    Quantity INT,
    InvoiceDate DATETIME,
    Price DECIMAL(10,2),
    CustomerID VARCHAR(20),
    Country VARCHAR(100)
);

CREATE TABLE countries (
    code VARCHAR(10),
    name VARCHAR(100),
    latitude DECIMAL(10,6),
    longitude DECIMAL(10,6)
);

SELECT * FROM  countries;
SELECT  COUNT(*) FROM countries;

SELECT * FROM orders;
SELECT  COUNT(*) FROM orders;

####################################################################################################################
## Question 1 : What is the total gross revenue from all valid transactions? 
####################################################################################################################

WITH sales_cte AS (
    SELECT
        Quantity * Price AS revenue
    FROM orders
    WHERE Quantity > 0
      AND Price > 0
)
SELECT
    SUM(revenue) AS total_gross_revenue
FROM sales_cte;


#############################################################################################################################
### Question 2: What are the minimum and maximum revenue values per line item from valid transactions?
##############################################################################################################################

WITH sales_cte AS (
    SELECT
        Quantity * Price AS revenue
    FROM orders
    WHERE Quantity > 0
      AND Price > 0
)
SELECT
    MIN(revenue) AS min_line_revenue,
    MAX(revenue) AS max_line_revenue
FROM sales_cte;

####################################################################################################################################
## Question 3 : Which customers generate the highest total revenue, ranked from 1 to 10 with no ties?
###################################################################################################################################

WITH customer_revenue_cte AS (
    SELECT
        CustomerID,
        SUM(Quantity * Price) AS total_revenue
    FROM orders
    WHERE Quantity > 0
      AND Price > 0
      AND CustomerID IS NOT NULL
    GROUP BY CustomerID
),
ranked_customers_cte AS (
    SELECT
        CustomerID,
        total_revenue,
        ROW_NUMBER() OVER (ORDER BY total_revenue DESC) AS revenue_rank
    FROM customer_revenue_cte
)
SELECT
    CustomerID,
    total_revenue,
    revenue_rank
FROM ranked_customers_cte
WHERE revenue_rank <= 10
ORDER BY revenue_rank;


##############################################################################################################################
## Question 4: What percentage of total revenue is contributed by the top 20% of customers? (Pareto Analysis)
##############################################################################################################################


WITH customer_revenue_cte AS (
    SELECT
        CustomerID,
        SUM(Quantity * Price) AS total_revenue
    FROM orders
    WHERE Quantity > 0
      AND Price > 0
      AND CustomerID IS NOT NULL
    GROUP BY CustomerID
),
ranked_customers_cte AS (
    SELECT
        CustomerID,
        total_revenue,
        ROW_NUMBER() OVER (ORDER BY total_revenue DESC) AS revenue_rank,
        COUNT(*) OVER () AS total_customers,
        SUM(total_revenue) OVER (
            ORDER BY total_revenue DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_revenue,
        SUM(total_revenue) OVER () AS overall_revenue
    FROM customer_revenue_cte
),
pareto_cte AS (
    SELECT
        *,
        revenue_rank / total_customers * 100 AS customer_pct,
        cumulative_revenue / overall_revenue * 100 AS revenue_pct
    FROM ranked_customers_cte
)
SELECT
    MAX(revenue_pct) AS revenue_contributed_by_top_20pct_customers
FROM pareto_cte
WHERE customer_pct <= 20;

#############################################################################################################
## Question 5 : Which 10 invoices generated the highest total revenue, ranked from 1 to 10?
#############################################################################################################

WITH invoice_revenue_cte AS (
    SELECT
        Invoice,
        SUM(Quantity * Price) AS total_revenue
    FROM orders
    WHERE Quantity > 0
      AND Price > 0
    GROUP BY Invoice
),
ranked_invoices_cte AS (
    SELECT
        Invoice,
        total_revenue,
        ROW_NUMBER() OVER (ORDER BY total_revenue DESC) AS invoice_rank
    FROM invoice_revenue_cte
)
SELECT
    Invoice,
    total_revenue,
    invoice_rank
FROM ranked_invoices_cte
WHERE invoice_rank <= 10
ORDER BY invoice_rank;

############################################################################################################################################
### Question 6 : Which countries generate the most revenue after cleaning inconsistent country names?
#############################################################################################################################################

WITH normalized_orders AS (
    SELECT
        CASE
            WHEN Country IN ('USA', 'U.S.A', 'US') THEN 'United States'
            WHEN Country IN ('RSA', 'S.A.', 'South Africa') THEN 'South Africa'
            WHEN Country IS NULL OR Country = 'Unspecified' THEN 'Unknown'
            ELSE Country
        END AS country_name,
        Quantity,
        Price
    FROM orders
    WHERE Quantity > 0
      AND Price > 0
),
country_revenue_cte AS (
    SELECT
        country_name,
        SUM(Quantity * Price) AS total_revenue
    FROM normalized_orders
    GROUP BY country_name
),
ranked_countries_cte AS (
    SELECT
        country_name,
        total_revenue,
        RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank,
        SUM(total_revenue) OVER (
            ORDER BY total_revenue DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_revenue
    FROM country_revenue_cte
)
SELECT
    country_name,
    total_revenue,
    revenue_rank,
    cumulative_revenue
FROM ranked_countries_cte
ORDER BY revenue_rank;

########################################################################################################################################
## Question 7 : Which valid countries (from the dimension table) contribute most to revenue, enriched with geography?
########################################################################################################################################

WITH order_revenue_cte AS (
    SELECT
        Country,
        Quantity * Price AS revenue
    FROM orders
    WHERE Quantity > 0
      AND Price > 0
),
country_sales_cte AS (
    SELECT
        c.code AS country_code,
        c.name AS country_name,
        c.latitude,
        c.longitude,
        SUM(o.revenue) AS total_revenue
    FROM order_revenue_cte o
    JOIN countries c
        ON o.Country = c.name
    GROUP BY
        c.code,
        c.name,
        c.latitude,
        c.longitude
),
ranked_countries_cte AS (
    SELECT
        country_code,
        country_name,
        latitude,
        longitude,
        total_revenue,
        RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank,
        SUM(total_revenue) OVER (
            ORDER BY total_revenue DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_revenue
    FROM country_sales_cte
)
SELECT
    country_name,
    total_revenue,
    revenue_rank,
    cumulative_revenue
FROM ranked_countries_cte
ORDER BY revenue_rank;

 

