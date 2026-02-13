# SQL Revenue & Customer Analytics (MySQL)

## Overview
Analyzed an online retail dataset in MySQL to uncover revenue drivers, customer concentration, invoice performance, and geographic revenue distribution.

## Key Questions Answered
- Total gross revenue from valid transactions (excludes returns/invalid prices)
- Top customers by revenue (deterministic ranking, no ties)
- Pareto analysis: revenue contribution of top 20% of customers
- Highest-value invoices
- Country-level revenue after normalizing inconsistent country values
- Revenue by valid countries using a country dimension table (geo-enriched)

## Techniques Used
- CTEs for layered transformations
- Window functions: ROW_NUMBER, RANK, SUM() OVER, COUNT() OVER
- Data cleansing filters (Quantity > 0, Price > 0)
- Fact-to-dimension joins for enrichment

## Files
- `bizz3.sql` — full SQL solution (tables + analysis queries)

## How to Run
1. Create the database and tables in MySQL
2. Load the dataset into `orders`
3. Run the queries in `bizz3.sql`
