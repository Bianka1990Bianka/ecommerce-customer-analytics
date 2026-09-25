
# E-Commerce Customer Analytics

## Overview

This project analyzes more than **1 million e-commerce transaction records** to uncover insights into revenue performance, customer behavior, product sales, returns, seasonality, and geographic markets.

The analysis combines **Python, Pandas, Jupyter Notebook, SQL, and SQLite** to demonstrate an end-to-end analytics workflow: cleaning raw transactional data, validating data quality, engineering business metrics, querying the cleaned dataset with SQL, and translating the results into actionable business insights.

---

## Business Questions

The analysis focuses on several key business questions:

- How much revenue does the business generate?
- How significantly do returns and cancellations affect revenue?
- How does revenue change over time?
- Which products generate the most sales?
- Who are the highest-value customers?
- How can customers be segmented by purchasing behavior?
- Which geographic markets generate the most revenue?

---

## Tools & Technologies

- **Python**
- **Pandas**
- **NumPy**
- **Jupyter Notebook**
- **SQL**
- **SQLite**
- **Git & GitHub**

---

## Dataset

The cleaned dataset contains:

- **1,033,030 transaction records**
- **53,622 unique invoices**
- **5,942 identified customers**
- Transaction dates from **December 2009 through December 2011**
- Product, quantity, price, customer, country, and revenue information

A `Revenue` field was derived from transaction quantity and unit price for use throughout the analysis.

The processed CSV and SQLite database are intentionally excluded from the repository because of their file size. The notebook documents the cleaning and transformation workflow used to produce the analytical dataset.

---

## Data Preparation

The Python/Jupyter workflow includes:

- Initial data inspection
- Data type validation
- Missing-value analysis
- Duplicate analysis
- Transaction validation
- Revenue calculation
- Identification of returns and cancellations
- Preparation of cleaned data for SQL analysis

The resulting cleaned dataset contains more than **1.03 million records** and is exported locally for downstream SQL analysis.

---

# Key Business Findings

## Revenue Performance

SQL analysis identified:

| Metric | Result |
|---|---:|
| Gross Sales | **$20.47M** |
| Returns / Cancellations | **$1.46M** |
| Net Revenue | **$19.00M** |
| Return Impact | **7.15% of gross sales** |
| Positive-Sales Orders | **40,077** |
| Sales-Only Average Order Value | **$510.66** |

Returns and cancellations reduced gross sales by approximately **$1.46 million**, making return behavior an important component of overall revenue performance.

---

## Revenue Trends

Monthly revenue analysis shows a pronounced increase during the later months of the year.

For example:

- September 2011 net revenue: **$1.02M**
- October 2011 net revenue: **$1.07M**
- November 2011 net revenue: **$1.46M**

November 2011 increased approximately **36.17% month over month**, following a **46.96% increase in September**.

This pattern suggests meaningful year-end seasonality in purchasing activity.

> **Note:** December 2011 contains only partial-month data through December 9 and therefore should not be compared directly with complete months.

---

## Product Performance

After excluding non-merchandise entries such as postage and manual adjustments, the leading products by positive-sales revenue included:

| Product | Units Sold | Revenue |
|---|---:|---:|
| REGENCY CAKESTAND 3 TIER | 26,478 | **$330,590.32** |
| WHITE HANGING HEART T-LIGHT HOLDER | 94,142 | **$257,546.20** |
| PAPER CRAFT, LITTLE BIRDIE | 80,995 | **$168,469.60** |
| PARTY BUNTING | 28,200 | **$148,318.28** |
| JUMBO BAG RED RETROSPOT | 77,280 | **$145,961.83** |

The analysis also identified unusually large transactions, demonstrating the importance of reviewing outliers before interpreting product or order-level KPIs.

---

## Customer Analysis

Customer-level SQL aggregation was used to measure purchasing frequency, revenue contribution, and average order value.

The highest-revenue customer generated approximately **$580,987** across **145 positive-sales orders**.

The analysis also uncovered customers with unusually high average order values, highlighting the need to distinguish typical purchasing behavior from extreme transactions.

---

## Customer Segmentation

Customers were segmented using analyst-defined business rules based on purchase frequency and revenue.

| Segment | Customers | Revenue | Avg. Revenue per Customer |
|---|---:|---:|---:|
| High Value | 179 | **$7.11M** | **$39,704.25** |
| Loyal | 1,982 | **$7.48M** | **$3,773.81** |
| Repeat | 2,094 | **$2.23M** | **$1,063.88** |
| One-Time | 1,623 | **$560K** | **$345.21** |

A relatively small group of **179 High Value customers generated approximately $7.1 million in positive-sales revenue**, illustrating substantial revenue concentration among the most valuable customers.

These segments could support differentiated retention, loyalty, and re-engagement strategies.

---

## Geographic Performance

The United Kingdom represents the dominant market in the dataset.

| Country | Orders | Identified Customers | Gross Sales |
|---|---:|---:|---:|
| United Kingdom | 36,535 | 5,350 | **$17.40M** |
| EIRE | 626 | 5 | **$658.77K** |
| Netherlands | 228 | 22 | **$554.04K** |
| Germany | 789 | 107 | **$425.02K** |
| France | 622 | 95 | **$350.46K** |

The results show a strong concentration of sales in the United Kingdom while also identifying several international markets with meaningful revenue contribution.

---

# SQL Analysis

The SQL portion of the project demonstrates:

- Business KPI calculations
- Conditional aggregation
- `CASE` statements
- Common Table Expressions (**CTEs**)
- Multi-level aggregation
- Window functions
- `LAG()` for month-over-month analysis
- `DENSE_RANK()` for customer ranking
- Customer segmentation
- Product performance analysis
- Geographic analysis

The complete SQL analysis is available in:

`sql/01_business_analysis.sql`

---

## Example SQL: Customer Value Analysis

```sql
WITH customer_orders AS (
    SELECT
        "Customer ID" AS customer_id,
        Invoice,
        SUM(Revenue) AS order_revenue
    FROM transactions
    WHERE Revenue > 0
        AND "Customer ID" IS NOT NULL
    GROUP BY "Customer ID", Invoice
),

customer_metrics AS (
    SELECT
        customer_id,
        COUNT(*) AS total_orders,
        SUM(order_revenue) AS customer_revenue,
        AVG(order_revenue) AS customer_aov
    FROM customer_orders
    GROUP BY customer_id
)

SELECT
    customer_id,
    total_orders,
    ROUND(customer_revenue, 2) AS customer_revenue,
    ROUND(customer_aov, 2) AS average_order_value,
    DENSE_RANK() OVER (
        ORDER BY customer_revenue DESC
    ) AS revenue_rank
FROM customer_metrics
ORDER BY customer_revenue DESC
LIMIT 10;
```

---

# Business Recommendations

Based on the analysis, the business could:

1. **Prioritize high-value customer retention**  
   A small group of high-value customers contributes a disproportionate amount of revenue, making retention and relationship-building especially important.

2. **Investigate return and cancellation drivers**  
   Returns and cancellations represent approximately **7.15% of gross sales**, creating a meaningful opportunity to protect net revenue.

3. **Prepare for year-end demand**  
   Revenue increases substantially during the later months of the year, suggesting opportunities for inventory planning, marketing campaigns, and operational preparation ahead of peak periods.

4. **Protect top-performing product categories**  
   High-revenue merchandise should be monitored for inventory availability and incorporated into merchandising and promotional decisions.

5. **Develop international markets selectively**  
   Markets such as the Netherlands, Germany, France, and EIRE show meaningful revenue outside the dominant UK customer base.

---

# Repository Structure

```text
ecommerce-customer-analytics/
│
├── data/
│   ├── raw/
│   └── processed/          # Generated files excluded from Git
│
├── notebooks/
│   └── 01_data_quality_and_cleaning.ipynb
│
├── sql/
│   └── 01_business_analysis.sql
│
├── images/
├── dashboard/
├── .gitignore
├── LICENSE
└── README.md
```

---

# Skills Demonstrated

This project demonstrates practical experience with:

**Python • Pandas • NumPy • SQL • SQLite • Jupyter Notebook • Data Cleaning • Data Validation • Exploratory Data Analysis • KPI Development • Revenue Analysis • Customer Analytics • Customer Segmentation • Product Analysis • Window Functions • CTEs • Business Insight Generation • Git • GitHub**

---

## Project Takeaway

This project demonstrates how raw transactional data can be transformed into a structured business analysis by combining **Python-based data preparation with SQL-based analytical querying**.

Rather than focusing only on technical outputs, the analysis connects transaction-level data to business questions involving **revenue, customers, products, returns, seasonality, and geographic markets**.