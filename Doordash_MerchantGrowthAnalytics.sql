DROP TABLE IF EXISTS merchant_weekly;
DROP TABLE IF EXISTS merchants;

-- I have created a Merchant master table(200 merchants)
CREATE TABLE merchants(
merchant_id VARCHAR(10) PRIMARY KEY NOT NULL,
city VARCHAR(50),
category VARCHAR(50),
base_demand INT,
base_quality DECIMAL(4,3),      -- 0.60 to 0.95
ad_propensity DECIMAL(4,3)     -- 0.05 to 0.35
);

INSERT INTO merchants(
merchant_id, city, category, base_demand, base_quality, ad_propensity)
SELECT 
CONCAT ('M', LPAD(n, 4, '0')) AS merchant_id,
ELT(1 + (CRC32(CONCAT('city-', n)) % 10), 
	'New York', 'San Francisco', 'Chicago', 'Austin', 'Seattle',
	'Boston', 'Athlanta', 'Denver', 'Washington DC', 'Los Angeles') AS city,
ELT(1 + (CRC32(CONCAT('cat-', n)) % 6),
    'Restaurant', 'Grocery', 'Convenience', 'Cafe', 'Pharmacy', 'Retail') AS category,
-- base_demand: roughly 80 to 260 orders/week baseline
80 + (CRC32(CONCAT('demand-', n)) %181) AS base_demand,
-- base_quality: 0.65 to 0.95
ROUND(0.60 + ((CRC32(CONCAT('qual-', n)) % 351) / 1000.0), 3) AS base_qality,
-- ad_propensity: 0.05 to 0.35
ROUND(0.05 + ((CRC32(CONCAT('adprop-', n)) % 301) / 1000.0), 3) AS ad_propensity

FROM (
WITH RECURSIVE nums AS (
SELECT 1 AS n
UNION ALL 
SELECT n + 1 FROM nums WHERE n < 200
)
SELECT n FROM nums
) t;
SELECT COUNT(*) AS merchants_loaded FROM merchants;

-- Goal: Populate merchant_weekly with 8 weeks of synthetic data
--       for each merchant in the merchants table
CREATE TABLE merchant_weekly(
merchant_id VARCHAR(10),
week_start DATE,
city VARCHAR(50),
category VARCHAR(50),
orders INT,
revenue DECIMAL(12,2),
cancellations INT,
refunds INT,
prep_time_mins_avg DECIMAL(6,2),
rating_avg DECIMAL(12,2),
ad_spend DECIMAL(12,2),
ad_orders INT,
PRIMARY KEY(merchant_id, week_start)
);
 
INSERT INTO merchant_weekly (
merchant_id, week_start, city, category, orders, revenue,
cancellations, refunds,prep_time_mins_avg, rating_avg,
ad_spend, ad_orders
)
SELECT 
merchant_id, week_start, city, category,
  orders, revenue, cancellations, refunds,
  prep_time_mins_avg, rating_avg,
  ad_spend, ad_orders
FROM (
-- Generating week numbers using recursive CTES. This represents 8 weeks of data
WITH RECURSIVE weeks AS (
SELECT 0 AS w
UNION ALL
SELECT w + 1 FROM weeks WHERE w < 7
),
grid AS (
SELECT 
m.merchant_id, m.city, m.category, m.base_demand, m.base_quality, m.ad_propensity,
DATE_ADD('2025-11-17', INTERVAL(7 * w) DAY) AS week_start, w
FROM 
merchants m
JOIN weeks
),

-- Adding pseudo-randomness per merchant-week
-- r1 to r5: numbers from 0.000 to 0.999
-- seasonality: small wave so weeks aren't flat
-- prep_base: base prep time depends on category
calc AS(
SELECT g.*,
(CRC32(CONCAT(g.merchant_id, '-r1-', g.week_start)) % 1000) / 1000.0 AS r1,
(CRC32(CONCAT(g.merchant_id, '-r2-', g.week_start)) % 1000) / 1000.0 AS r2,
(CRC32(CONCAT(g.merchant_id, '-r3-', g.week_start)) % 1000) / 1000.0 AS r3,
(CRC32(CONCAT(g.merchant_id, '-r4-', g.week_start)) % 1000) / 1000.0 AS r4,
(CRC32(CONCAT(g.merchant_id, '-r5-', g.week_start)) % 1000) / 1000.0 AS r5,

-- Light seasonality: varies a little across weeks
(1.00 + 0.06 * SIN((g.w + 1) * 3.14159 / 4)) AS seasonality,
-- Category-based base prep time(minutes)
CASE g.category
  WHEN 'Restaurant'  THEN 22
  WHEN 'Grocery'     THEN 35
  WHEN 'Convenience' THEN 18
  WHEN 'Cafe'        THEN 16
  WHEN 'Pharmacy'    THEN 18
  ELSE 20
  END AS prep_base
FROM grid g
)

-- Computing business outcomes(orders, revenue etc)
-- Key idea:
--  * Higher base_quality -> fewer cancels/refunds, shorter prep time, higher rating
--  * ad_propensity + randomness -> ad_spend, ad_orders
--  * seasonality + randomness -> orders fluctuate week to week
SELECT c.merchant_id, c.week_start, c.city, c.category,

-- Orders: baseline demand adjusted by seasonality, randomness, and quality
--     - GREATEST(10, ..) ensures no merchant has zero/near-zero orders
GREATEST(
  10,
  FLOOR(
	c.base_demand 
    * c.seasonality 
    * (0.85 + 0.35 * c.r1)
    * (0.90 + 0.20 * c.base_quality)
   )
) AS orders,

-- Revenue: orders x AOV(average order value), varies by categories and randomness
ROUND(
(
  GREATEST(
    10,
    FLOOR(
	  c.base_demand 
      * c.seasonality 
      * (0.85 + 0.35 * c.r1)
      * (0.90 + 0.20 * c.base_quality)
     )
)
*
(
 CASE c.category
	WHEN 'Restaurant'  THEN 28
	WHEN 'Grocery'     THEN 45
	WHEN 'Convenience' THEN 18
	WHEN 'Cafe'        THEN 15
	WHEN 'Pharmacy'    THEN 32
	ELSE 22
	END
	* (0.85 + 0.30 * c.r2)
   )
  ),
  2
) AS revenue,

-- Cancellations: increases when quality is low + some category friction + randomness
--  - bounded between 0 and orders using LEAST(.., orders)
LEAST(
  GREATEST(
    0,
    FLOOR(
      (
        GREATEST(
          10,
          FLOOR(
			c.base_demand * c.seasonality * (0.85 + 0.35 * c.r1) * (0.90 + 0.20 * c.base_quality)
		  )
		)
	)
    *
    (
    0.015
    + (1.0 - c.base_quality) * 0.10
	+ (CASE c.category WHEN 'Grocery' THEN 0.015 WHEN 'Pharmacy' THEN 0.010 ELSE 0.000 END)
	+ 0.02 * c.r3
    )
  )
),
GREATEST(
  10,
  FLOOR(
    c.base_demand * c.seasonality * (0.85 + 0.35 *c.r1) * (0.90 + 0.20 * c.base_quality)
    )
  )
) AS cancellations,

-- Refunds: smaller than cancellations, but also increases when quality is low 
LEAST(
  GREATEST(
	0,
	FLOOR(
	  (
		GREATEST(
		  10,
		  FLOOR(
			c.base_demand * c.seasonality * (0.85 + 0.35 * c.r1) * (0.90 + 0.20 * c.base_quality)
		)
	  )
	)
	*
	(
	0.008
	+ (1.0 - c.base_quality) * 0.06
	+ 0.010 * c.r4
		)
	  )
	),
	GREATEST(
	  10,
	  FLOOR(
		c.base_demand * c.seasonality * (0.85 + 0.35 * c.r1) * (0.90 + 0.20 * c.base_quality)
	  )
	)
) AS refunds,

-- Prep time: category base + penalty for low quality + noise
ROUND(
  c.prep_base + (1.0 - c.base_quality) * 18 + (c.r5 * 10),
  2
) AS prep_time_mins_avg,

-- Rating: derived from quality, bounded between 3.00 and 5.00
ROUND(
  LEAST(5.00, GREATEST(3.00, 3.10 + (c.base_quality * 2.0) + (c.r2 - 0.5) * 0.5)),
  2
) AS rating_avg,

-- Ad spend: depends on ad_propensity, demand, and randomness */
ROUND(
  GREATEST(
	0,
	(c.ad_propensity * 150) * (0.50 + 1.20 * c.r1) * (c.base_demand / 150.0)
  ),
  2
) AS ad_spend,

-- Ad orders: share of total orders influenced by propensity + quality + randomness
--  - capped by LEAST(0.35, ..) so ads never exceed 35% of orders
GREATEST(
  0,
  FLOOR(
	(
	GREATEST(
		10,
		FLOOR(
			c.base_demand * c.seasonality * (0.85 + 0.35 * c.r1) * (0.90 + 0.20 * c.base_quality)
		)
	  )
	)
	*
	LEAST(
		0.35,
		(0.03 + 0.25 * c.ad_propensity + 0.08 * c.base_quality) * (0.60 + 0.80 * c.r3)
	)
  )
) AS ad_orders

FROM calc c
) x;

SELECT COUNT(*) AS rows_loaded
FROM merchant_weekly;

-- Sanity: check ranges
SELECT
MIN(orders) min_orders, MAX(orders) max_orders,
MIN(prep_time_mins_avg) min_prep, MAX(prep_time_mins_avg) max_prep,
MIN(rating_avg) min_rating, MAX(rating_avg) max_rating
FROM merchant_weekly;


DROP VIEW IF EXISTS merchant_smb_snapshot;

CREATE VIEW merchant_smb_snapshot AS
WITH

-- Compute core KPIs at the merchant-week level
base AS (
SELECT merchant_id, week_start, city, category, orders, revenue, cancellations, 
       refunds, prep_time_mins_avg, rating_avg, ad_spend, ad_orders,
       (cancellations * 1.0) / NULLIF(orders, 0) AS cancel_rate,
       (refunds * 1.0) / NULLIF(orders, 0) AS refund_rate,
       (ad_orders * 1.0) / NULLIF(orders, 0) AS ad_penetration,

-- ROAS proxy: (ad_orders * avg_order_value) / ad_spend
CASE
  WHEN ad_spend IS NULL OR ad_spend = 0 THEN NULL
  ELSE (ad_orders * 1.0 * (revenue / NULLIF(orders, 0))) / ad_spend
  END AS roas
FROM merchant_weekly
),

-- Add rolling 4-week order sums
--   - orders_last_4w = most recent 4 weeks
--   - orders_prev_4w = 4 weeks before that
trend AS (
SELECT
b.*,
SUM(orders) OVER (
	PARTITION BY merchant_id
	ORDER BY week_start
	ROWS BETWEEN 3 PRECEDING AND CURRENT ROW
) AS orders_last_4w,
SUM(orders) OVER (
	PARTITION BY merchant_id
	ORDER BY week_start
	ROWS BETWEEN 7 PRECEDING AND 4 PRECEDING
) AS orders_prev_4w
FROM base b
),

-- Keep only the latest week row per merchant
latest AS (
SELECT *
FROM (
    SELECT
      t.*,
      ROW_NUMBER() OVER (PARTITION BY merchant_id ORDER BY week_start DESC) AS rn
    FROM trend t
  ) x
WHERE rn = 1
),

-- Compute 4-week growth rate

enriched AS (
SELECT
l.*,
CASE
	WHEN orders_prev_4w IS NULL OR orders_prev_4w = 0 THEN NULL
	ELSE (orders_last_4w - orders_prev_4w) * 1.0 / orders_prev_4w
    END AS orders_growth_4w
FROM latest l
),


-- Percentile ranks (relative scoring)
--   Higher percentile = better for growth/rating/roas
--   Lower percentile = better for cancel/refund/prep time

scored AS (
SELECT
e.*,
PERCENT_RANK() OVER (ORDER BY orders_growth_4w) AS p_orders_growth,
PERCENT_RANK() OVER (ORDER BY rating_avg) AS p_rating,
PERCENT_RANK() OVER (ORDER BY roas) AS p_roas,

PERCENT_RANK() OVER (ORDER BY cancel_rate) AS p_cancel_rate,
PERCENT_RANK() OVER (ORDER BY refund_rate) AS p_refund_rate,
PERCENT_RANK() OVER (ORDER BY prep_time_mins_avg) AS p_prep_time,

PERCENT_RANK() OVER (ORDER BY ad_spend) AS p_ad_spend
FROM enriched e
),

--   STEP F: Health Score (0–100) with weights
 --  We flip "bad" metrics using (1 - percentile)
health AS (
SELECT
s.*,

ROUND(
	100 * (
	0.30 * COALESCE(p_orders_growth, 0.5) +
	0.20 * COALESCE((1 - p_cancel_rate), 0.5) +
	0.15 * COALESCE((1 - p_prep_time), 0.5) +
	0.15 * COALESCE((1 - p_refund_rate), 0.5) +
	0.10 * COALESCE(p_rating, 0.5) +
	0.10 * COALESCE(p_roas, 0.5)
	)
, 0
) AS health_score,

-- main driver label: what’s hurting the merchant most 
CASE
  WHEN p_cancel_rate >= 0.75 THEN 'High cancellations'
  WHEN p_prep_time >= 0.75 THEN 'Slow prep time'
  WHEN p_refund_rate >= 0.75 THEN 'High refunds'
  WHEN COALESCE(p_roas, 0.5) <= 0.25 AND ad_spend > 0 THEN 'Low ROAS'
  WHEN COALESCE(p_orders_growth, 0.5) <= 0.25 THEN 'Declining orders'
  ELSE 'Stable'
  END AS top_issue_driver
FROM scored s
),

-- Segment merchants into actionable buckets
segmented AS (
SELECT 
h.*,
CASE
	WHEN health_score < 40
	OR (orders_growth_4w <= -0.10 AND p_cancel_rate >= 0.70)
	THEN 'At Risk'

	WHEN (p_prep_time >= 0.75 OR p_cancel_rate >= 0.75)
	AND COALESCE(orders_growth_4w, 0) > -0.15
	THEN 'Ops Constrained'

	WHEN ad_spend > 0
	AND p_ad_spend >= 0.50
	AND COALESCE(p_roas, 0.5) <= 0.30
	THEN 'Ad Inefficient'

	WHEN COALESCE(p_rating, 0.5) >= 0.70
	AND COALESCE(p_cancel_rate, 0.5) <= 0.60
	AND COALESCE(ad_penetration, 0) < 0.15
	THEN 'High Potential'

	ELSE 'Core'
    END AS segment
FROM health h
)

SELECT
  merchant_id,
  week_start,
  city,
  category,
  orders,
  revenue,
  orders_last_4w,
  orders_growth_4w,
  cancel_rate,
  refund_rate,
  prep_time_mins_avg,
  rating_avg,
  ad_spend,
  ad_penetration,
  roas,
  health_score,
  top_issue_driver,
  segment,

-- recommended actions: these become your Excel "action list" 
  CASE segment
    WHEN 'At Risk' THEN 'Fix reliability drivers first, then run targeted promo to regain volume'
    WHEN 'Ops Constrained' THEN 'Reduce prep time and cancellations via menu availability and staffing playbook'
    WHEN 'Ad Inefficient' THEN 'Cap spend, tighten targeting, reset campaigns with ROAS guardrails'
    WHEN 'High Potential' THEN 'Upsell ads with a clear ROI story and onboarding checklist'
    ELSE 'Maintain baseline reporting and test small promos or ads'
  END AS recommended_action_1,

  CASE segment
    WHEN 'At Risk' THEN 'Sales outreach with a 2 week recovery plan and weekly monitoring'
    WHEN 'Ops Constrained' THEN 'Operational audit: hours, menu cleanup, fulfillment consistency'
    WHEN 'Ad Inefficient' THEN 'Shift budget to top items and retarget high intent customers'
    WHEN 'High Potential' THEN 'Launch starter ads package and track incremental orders weekly'
    ELSE 'Run a cohort test and compare lift vs control'
  END AS recommended_action_2,

  CASE segment
    WHEN 'At Risk' THEN 'Measure pre vs post lift: orders, cancellations, refunds, rating'
    WHEN 'Ops Constrained' THEN 'Track prep time change and cancel reduction week over week'
    WHEN 'Ad Inefficient' THEN 'Track ROAS lift and adoption efficiency weekly'
    WHEN 'High Potential' THEN 'Track adoption, spend, and repeat rate'
    ELSE 'Monitor KPIs and investigate outliers'
  END AS recommended_action_3

FROM segmented;

-- check
SELECT COUNT(*) AS merchants_in_snapshot FROM merchant_smb_snapshot;

-- Segment distributions
SELECT segment, COUNT(*) AS merchants, ROUND(AVG(health_score), 1) AS avg_health,
       ROUND(AVG(cancel_rate) * 100, 2) AS avg_cancel_pct, ROUND(AVG(roas), 2) AS avg_roas
FROM merchant_smb_snapshot
GROUP BY segment
ORDER BY merchants DESC;

-- Exporting the data
SELECT *
FROM merchant_smb_snapshot;












       

