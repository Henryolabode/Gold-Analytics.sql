# Data-Driven Growth: Transforming Transactional Noise into Executive Intelligence

**The Bottom Line:** I engineered a high-performance "Gold Layer" Data Warehouse that converts fragmented transactional data into a strategic revenue engine. This project identifies high-value customer segments, optimizes product inventory, and tracks real-time growth metrics to drive data-led executive decisions.

---

## High-Impact Business Insights

* **VIP Revenue Engine:** Identified a core segment of "VIP" customers (12+ month lifespan with $5,000+ spend) who drive disproportionate lifetime value.
* **Demographic Hotspots:** Automated age-grouping analysis that pinpointed the **50+ demographic** as the primary revenue driver, enabling hyper-targeted marketing.
* **Growth Forecasting:** Engineered a time-series analysis using SQL Window Functions to monitor **Running Total Sales** and **Moving Average Price** for accurate trend forecasting.

---

## Data Architecture: The Gold Standard
I implemented a Star Schema architecture designed for query speed and analytical clarity.

* **Fact Table (`gold.fact_sales`):** The central engine, optimized for rapid aggregation of sales volume, pricing, and quantities.
* **Dimension Tables (`dim_customers`, `dim_products`):** Enriched master data providing granular context on customer behavior and product performance.

---

## Logic and Segmentation Strategy
I used advanced SQL (Common Table Expressions and Case Logic) to categorize complex data into actionable business buckets:

### 1. Customer Performance Matrix
| Segment | Logic | Strategic Action |
| :--- | :--- | :--- |
| **VIP** | Lifespan >= 12mo AND Sales > $5,000 | **Retention:** Priority support and loyalty rewards. |
| **Regular** | Lifespan >= 12mo AND Sales <= $5,000 | **Upsell:** Increase Average Order Value (AOV). |
| **New** | Lifespan < 12mo | **Onboarding:** Focus on second-purchase conversion. |

### 2. Product Intelligence
The system automatically classifies inventory into performance tiers:
* **High-Performers:** Products with high sales frequency and stable margins (e.g., Mountain Bikes).
* **Underperformers:** Slow-moving stock identified for liquidation or marketing shifts.

---

## Technical Arsenal
* **Advanced SQL:** Recursive CTEs, Window Functions (`SUM() OVER`), and Complex Joins.
* **Data Modeling:** Star Schema Design and Medallion Architecture.
* **Analytics:** RFM (Recency, Frequency, Monetary) Analysis and Trend Tracking.

---

## Scalability and Integration
1.  **Automation:** The `gold analytics.sql` script creates views that update automatically as new transactions are ingested.
2.  **Visualization:** These tables are "BI-Ready," allowing for immediate connection to Power BI, Tableau, or Excel.
3.  **Efficiency:** Reduced complex cross-table reporting time from hours to milliseconds through pre-aggregated Gold views.

---

**Developed by Omoboyowa Henry**
*Specializing in high-performance data engineering and business intelligence.*
