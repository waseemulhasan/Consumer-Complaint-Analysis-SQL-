Create database Consumer_Comp;
Use Consumer_Comp;

## Creating consumer table
Create table CONSUMER_COMPLAINTS(
	  DATE_RECEIVED date,
      PRODUCT_NAME VARCHAR(50), 
	  SUB_PRODUCT VARCHAR(40), 
	  ISSUE VARCHAR(100), 
      SUB_ISSUE VARCHAR(100),
      CONSUMER_COMPLAINT_NARRATIVE VARCHAR(100),
      Company_Public_Response VARCHAR(100),
      Company VARCHAR(30),
      State_Name CHAR(4),
      Zip_Code INTEGER,
      Tags VARCHAR(10),
      Consumer_Consent_Provided CHAR(6),
	  Submitted_via VARCHAR(100),
      Date_Sent_to_Company VARCHAR(100),
     Company_Response_to_Consumer VARCHAR(2),
     Timely_Response CHAR(4),
     CONSUMER_DISPUTED CHAR(4),
     COMPLAINT_ID int NOT NULL PRIMARY KEY
);
alter table CONSUMER_COMPLAINTS
modify column Consumer_Consent_Provided CHAR(20) ;
Select * from CONSUMER_COMPLAINTS;
desc CONSUMER_COMPLAINTS;

Load data infile
'C:/ConsumerComplaints.csv'
into table CONSUMER_COMPLAINTS
fields terminated by ','
enclosed by '"'
lines terminated by'\n'
ignore 1 rows;

Select count(*) from CONSUMER_COMPLAINTS;
SELECT COUNT(DISTINCT COMPLAINT_ID) FROM CONSUMER_COMPLAINTS;
SELECT MIN(DATE_RECEIVED), MAX(DATE_RECEIVED) FROM CONSUMER_COMPLAINTS;

##NULL / blank check on key columns
SELECT
  SUM(PRODUCT_NAME IS NULL OR PRODUCT_NAME = '')   AS missing_product,
  SUM(Company IS NULL OR Company = '')             AS missing_company,
  SUM(State_Name IS NULL OR State_Name = '')       AS missing_state,
  SUM(CONSUMER_COMPLAINT_NARRATIVE IS NULL OR CONSUMER_COMPLAINT_NARRATIVE = '') AS missing_narrative,
  SUM(CONSUMER_DISPUTED IS NULL OR CONSUMER_DISPUTED = '') AS missing_disputed
FROM CONSUMER_COMPLAINTS;
##Check distinct values of categorical columns
SELECT DISTINCT Timely_Response FROM CONSUMER_COMPLAINTS;
SELECT DISTINCT CONSUMER_DISPUTED FROM CONSUMER_COMPLAINTS;
SELECT DISTINCT Submitted_via FROM CONSUMER_COMPLAINTS;

##Replace blanks with NULL
UPDATE CONSUMER_COMPLAINTS SET Tags = NULL WHERE Tags = '';
UPDATE complaints_clean SET CONSUMER_DISPUTED = NULL WHERE CONSUMER_DISPUTED = '';

## Changed datatype string to date
alter table CONSUMER_COMPLAINTS modify Date_Sent_to_Company date;

## New feature columns
alter table CONSUMER_COMPLAINTS
	ADD column Response_days int,
    ADD column Complaint_year int,
    ADD column Narrative tinyint;
    
Update CONSUMER_COMPLAINTS
SET Response_days = datediff(Date_Sent_to_Company, Date_Received),
	Complaint_year = year(Date_Received),
    Narrative = IF(CONSUMER_COMPLAINT_NARRATIVE IS NULL OR CONSUMER_COMPLAINT_NARRATIVE = '', 0, 1);
Select * from Consumer_Complaints;

##Complaints per year with Year_over_year growth
with Yearly as	(select complaint_year, count(*) as total
	from Consumer_Complaints
	group by complaint_year)
select Complaint_year, total,
	lag(total) over(order by complaint_year) as prv_yr,
    ROUND(100.0 * (total - LAG(total) OVER (ORDER BY complaint_year))
             / LAG(total) OVER (ORDER BY complaint_year), 2) AS yoy_growth_pct
FROM yearly
ORDER BY complaint_year;

## Monthly treand with month over month change
with Monthly as(
select date_format(Date_Received , "%Y-%m") as yn, count(*) as cnt
from consumer_complaints
group by yn)
select yn, cnt, 
cnt-	lag(cnt) over(order by yn) as change_vs_prev
from monthly
order by yn ;

## Which calendar month is busiest overall (Seasonality)
select monthname(Date_Received) as Month_name,
		month(Date_Received) as Month_No,
        count(*) as total
from Consumer_Complaints
group by Month_name, Month_No
order by Month_no;

##Top products with share of total and dispute rate
SELECT PRODUCT_NAME,
       COUNT(*) AS total_complaints,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_total,
       ROUND(100.0 * SUM(CASE WHEN CONSUMER_DISPUTED = 'Yes' THEN 1 ELSE 0 END)
             / COUNT(*), 2) AS dispute_rate_pct
FROM Consumer_Complaints
GROUP BY PRODUCT_NAME
ORDER BY total_complaints DESC;

## Top 10 issues overall
Select issue, count(*) as total from Consumer_Complaints
group by issue
order by total desc
limit 10;

## Top 3 issues per product
select * from 
	(select product_name, issue, count(*) as total,
	row_number() over(PARTITION by product_name order by count(*) Desc) as rn
	from consumer_complaints
	group by product_name, issue) t
where rn <3 
order by product_name,rn;

## Top companies by volume and response
select Company, count(*) as Total_complaints,
	sum(Timely_Response = 'Yes') as Timely_count,
	round(100.0* (Timely_Response = 'Yes')/count(*), 2) as Timely_Pct
from CONSUMER_COMPLAINTS 
group by company
order by Total_complaints desc
limit 15;

SELECT Company,
       COUNT(*) AS total_complaints,
       SUM(CONSUMER_DISPUTED = 'Yes') AS disputed,
       ROUND(100.0 * SUM(CONSUMER_DISPUTED = 'Yes') / COUNT(*), 2) AS dispute_rate_pct
FROM CONSUMER_COMPLAINTS
WHERE CONSUMER_DISPUTED IS NOT NULL
GROUP BY Company
HAVING COUNT(*) >= 100
ORDER BY dispute_rate_pct DESC
LIMIT 15;

## Using windows function to ranking a companies
With company_status as (select company, count(*) as total,
	round(100.0*sum(Timely_Response = 'Yes')/count(*),2) as timely_pct,
    round(100.0*sum(Consumer_Disputed = 'Yes')/count(*),2) as dispute_pct
from CONSUMER_COMPLAINTS
GROUP BY Company
having count(*) >= 100)
select company, total, timely_pct, dispute_pct,
rank() over(order by total desc) as Volume_rank,
rank() over(order by timely_pct) as Low_timeliness_rank,
rank() over(order by dispute_pct) as Low_dispute_rank
from company_status
order by Volume_rank;

## Calculating How companies response to consumer complaints.
select Company_response_to_consumer, count(*) as total
from CONSUMER_COMPLAINTS
group by Company_response_to_consumer
order by total desc;

## Finding Timely response to Consumer
select Timely_response, count(*) as total,
round(100.0 * sum(Consumer_Disputed = 'Yes')/count(*),2) as pct
from CONSUMER_COMPLAINTS
WHERE Consumer_disputed is  not null
group by timely_response;

## Top 10 states by volume
select State_name, count(*) as total_complaint,
round(100.0* count(*)/sum(count(*)) over(),2) as pct_total 
from CONSUMER_COMPLAINTS
group by State_name
order by total_complaint desc
limit 10;

##Top issue in each state.
select state_name, issue, total
from 
	(select state_name, issue, count(*) as total,
    rank() over(partition by state_name order by count(*) desc) as rnk
    from Consumer_Complaints 
    where state_name is not null and state_name <>''
    group by state_name, issue)t
    where rnk =1
    order by total desc;
## Channel analysis volume & outcone
Select Submitted_via, count(*) as total,
	round(100.0 * count(*)/sum(count(*)) over(),2) AS pct_total,
    round(100.0 * SUM(Timely_Response = 'Yes') / COUNT(*), 2) AS timely_pct,
    round(Avg(response_days), 2) as Avg_days_to_company
from consumer_complaints
group by Submitted_via
order by total desc;

##Responses receive analysis
Select Submitted_via, Company_Response_to_Consumer,
       count(*) AS total,
       round(100.0 * Count(*) / sum(count(*)) over (partition BY Submitted_via), 2) AS pct_within_channel
from Consumer_Complaints
group by Submitted_via, Company_Response_to_Consumer
order by Submitted_via, total DESC;

Select Narrative, count(*) as total,
round(100.0 * count(*)/sum(count(*)) over(), 2) as pct_total
from CONSUMER_COMPLAINTS
group by Narrative;

SELECT
  SUM(CONSUMER_COMPLAINT_NARRATIVE LIKE '%fraud%')            AS fraud,
  SUM(CONSUMER_COMPLAINT_NARRATIVE LIKE '%identity theft%')   AS identity_theft,
  SUM(CONSUMER_COMPLAINT_NARRATIVE LIKE '%late fee%')         AS late_fee,
  SUM(CONSUMER_COMPLAINT_NARRATIVE LIKE '%harass%')           AS harassment,
  SUM(CONSUMER_COMPLAINT_NARRATIVE LIKE '%scam%')             AS scam,
  SUM(CONSUMER_COMPLAINT_NARRATIVE LIKE '%unauthorized%')     AS unauthorized,
  SUM(CONSUMER_COMPLAINT_NARRATIVE LIKE '%never received%')   AS never_received,
  COUNT(*) AS total_narratives
FROM Consumer_Complaints
WHERE narrative = 1;

SELECT PRODUCT_NAME,
       COUNT(*) AS narratives,
       ROUND(100.0 * SUM(CONSUMER_COMPLAINT_NARRATIVE LIKE '%fraud%') / COUNT(*), 2) AS fraud_pct,
       ROUND(100.0 * SUM(CONSUMER_COMPLAINT_NARRATIVE LIKE '%harass%') / COUNT(*), 2) AS harassment_pct,
       ROUND(100.0 * SUM(CONSUMER_COMPLAINT_NARRATIVE LIKE '%late fee%') / COUNT(*), 2) AS late_fee_pct
FROM consumer_complaints
WHERE narrative = 1
GROUP BY PRODUCT_NAME
HAVING COUNT(*) >= 100
ORDER BY fraud_pct DESC;

## Creating a view on flat table
CREATE VIEW vw_complaint_summary AS
SELECT COMPLAINT_ID, DATE_RECEIVED, complaint_year,
       PRODUCT_NAME, Company, State_Name, Submitted_via,
       ISSUE, Company_Response_to_Consumer,
       Timely_Response, CONSUMER_DISPUTED, response_days
FROM Consumer_complaints;

CREATE INDEX idx_date    ON Consumer_complaints(DATE_RECEIVED);
CREATE INDEX idx_company ON Consumer_complaints(Company);
CREATE INDEX idx_product ON Consumer_complaints(PRODUCT_NAME);

SELECT * FROM vw_complaint_summary LIMIT 10;

## Peak year
SELECT complaint_year, COUNT(*) AS total FROM vw_complaint_summary
GROUP BY complaint_year ORDER BY total DESC LIMIT 1;

## Top product
SELECT PRODUCT_NAME, COUNT(*) AS total,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct
FROM vw_complaint_summary GROUP BY PRODUCT_NAME ORDER BY total DESC LIMIT 1;

## Worst timely rate (100+ complaints)
SELECT Company, COUNT(*) AS total,
       ROUND(100.0 * SUM(Timely_Response = 'Yes') / COUNT(*), 2) AS timely_pct
FROM vw_complaint_summary GROUP BY Company
HAVING COUNT(*) >= 100 ORDER BY timely_pct ASC LIMIT 1;

## Top state
SELECT State_Name, COUNT(*) AS total FROM vw_complaint_summary
WHERE State_Name IS NOT NULL AND State_Name <> ''
GROUP BY State_Name ORDER BY total DESC LIMIT 1;

## Channels by timely %
SELECT Submitted_via,
       ROUND(100.0 * SUM(Timely_Response = 'Yes') / COUNT(*), 2) AS timely_pct
FROM vw_complaint_summary GROUP BY Submitted_via ORDER BY timely_pct DESC;

SELECT complaint_year, COUNT(*) AS total, MIN(DATE_RECEIVED), MAX(DATE_RECEIVED)
FROM consumer_complaints
GROUP BY complaint_year
ORDER BY complaint_year;

SELECT Submitted_via, COUNT(*) AS total,
       ROUND(100.0 * SUM(Timely_Response = 'Yes') / COUNT(*), 2) AS timely_pct
FROM consumer_complaints
GROUP BY Submitted_via
ORDER BY total DESC;