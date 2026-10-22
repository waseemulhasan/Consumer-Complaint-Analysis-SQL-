# Consumer-Complaint-Analysis-SQL-
Analyze consumer complaints against financial companies to find trends, company performance gaps, and resolution patterns.
## Dataset
[TOTAL_ROWS] complaints, 18 columns (product, issue, company, state, channel, response, timeliness, dispute status, narrative).

## Tools
MySQL 8

## Skills Demonstrated
CTEs, window functions (RANK, LAG, ROW_NUMBER), CASE, views, indexes, data cleaning, feature engineering, text search with LIKE.

## Project Structure
01_setup.sql | 02_trends.sql | 03_companies.sql
04_geo_channel.sql | 05_text.sql | 06_view.sql

## Approach
1. Loaded raw data and ran quality checks (NULLs, duplicates, date range).
2. Cleaned trimmed text, standardized states,converted dates, added `response_days`, `complaint_year`, `has_narrative`.
3. Analyzed trends, products, companies, geography, channels, segments,and narrative text.

## Key Insights
- 2014 is the peak year with about 37K complaints.
- Mortgage is the top product (about 18K complaints, 29% of the total).
- Residential Credit Solutions has the lowest timely-response rate (62% across 103 complaints) among companies with 100+ complaints.
- Timely responses were disputed more often (20.22% vs 11.53%), likely due to data availability and complaint mix, not causation.
- California is the top state (about 9K complaints), consistent with its population size.
- Timely-response rates are high across all channels (97.4% to 100%). Email is best at 100%; Web, the largest channel, is lowest at 97.4%.
- Only 2,614 complaints include a consumer narrative. "Fraud" is the most mentioned keyword (11.1%), followed by harassment (5.4%),
  "never received" (4.8%), and late fees (3.8%).
