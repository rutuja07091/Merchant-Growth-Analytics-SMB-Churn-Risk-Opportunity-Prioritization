**Merchant Growth Analytics: SMB Churn Risk + Opportunity Prioritization**

**Executive Summary**

Small and mid-sized merchants can decline due to operational friction (cancellations, refunds, slow prep time) or inefficient marketing spend. This project builds **a portfolio-level merchant health system** to answer:

**Which merchants are at risk of churn, why are they declining, and what actions should we take next?**

_Output:_ Merchant segmentation + Opportunity Score ranking + Tableau dashboards + prioritized action list.


**Problem Statement**

Merchant performance drops often go unnoticed until the revenue impact becomes significant. The goal of this project is **to detect early churn risk, diagnose the driver of decline,** and **prioritize the most recoverable merchants** using a repeatable analytics workflow.


**Dataset and Metrics Definitions**

The dataset contains merchant performance across **cities and categories**, focused on growth, reliability, and efficiency.

**Core Metrics Used**

	•	**Revenue**: total merchant revenue (impact sizing)
    
	•	**Orders**: completed orders
    
	•	**Orders Growth 4W (%)**: 4-week order trend (negative = churn signal)
    
	•	**Cancel Rate (%)**: reliability risk (high cancellations reduce conversion)
    
	•	**Refund %**: quality risk (high refunds indicate fulfillment issues)
    
	•	**Avg Prep Time (mins)**: operational friction (impacts cancellations + CX)
    
	•	**Rating**: customer satisfaction signal
    
	•	**ROAS**: ad efficiency (low ROAS = inefficient spend)


**Segment Logic (Merchant Risk Categories**)

Merchants are grouped into actionable segments for Ops and Sales prioritization.

**Segment Definitions**

	•	**At Risk**: negative growth + high cancels/refunds/prep issues → immediate recovery plan
	
	•	**Ops Constrained**: demand exists, but ops bottlenecks limit growth → fix fulfillment first
	
	•	**Ad Inefficient**: low ROAS + weak growth → reset campaigns before scaling spend
	
	•	**High Potential**: healthy fundamentals + room to scale → upsell and growth programs
	
	•	**Core**: stable merchants → monitor + light experimentation


**Opportunity Score (Prioritization Model)**

To avoid treating every merchant equally, merchants are ranked using an **Opportunity Score** based on:

	1.	**Revenue impact**
	
	2.	**Growth headroom**
	
	3.	**Fixability of issues**

**Formula** - **Opportunity Score = Revenue Weight × (0.6 × Headroom + 0.4 × Fixability)**

**Definitions**

	•	**Revenue Weight**: higher-revenue merchants receive higher priority
	•	**Headroom**: recoverable decline potential
	     •	IF Orders Growth 4W < 0 THEN ABS(Orders Growth 4W) ELSE 0
	•	**Fixability**: how actionable reliability issues are
	     •	Cancel Rate + Refund %


**Tableau Dashboards and Views**

This project includes a full Tableau workflow with portfolio views + drilldowns.

**1) Portfolio Performance Snapshot**

High-level health view across revenue, growth, and reliability.

📌 /screenshots/Portfolio_Performance_Snapshot.png

**2) Revenue vs Growth Quadrants**

Merchant prioritization buckets:
	•	High Revenue + Negative Growth → High Priority
	•	Low Revenue + Negative Growth → Fix Later
	•	High Revenue + Positive Growth → Protect
	•	Low Revenue + Positive Growth → Monitor

📌 /screenshots/Revenue_vs_Growth_Quadrants.png

**3) Revenue at Risk by Driver**

Identifies the biggest contributors to decline (cancels, refunds, prep time, demand drop).

📌 /screenshots/Revenue_At_Risk_By_Driver.png

**4) Priority Merchant Action List**

Ranks merchants by Opportunity Score with recommended actions.

📌 /screenshots/Priority_Merchant_Action_List.png

**5) Opportunity Heatmap (City × Category)**

Shows where opportunity and risk clusters exist geographically.

📌 /screenshots/Opportunity_Heatmap.png


**Key Insights**

**Insight 1: Risk is concentrated in merchants with negative growth**

Portfolio-level order growth trends downward, indicating broad churn risk and urgency.

**Insight 2: High Revenue + Negative Growth is the highest priority zone**

Most revenue is concentrated in the High Priority quadrant, meaning retention efforts should begin with top-revenue merchants losing demand.

**Insight 3: Ops issues drive churn more than marketing in many cases**

Merchants with high cancellations, refunds, or prep time issues decline even when demand exists. Promotions without fixing ops first can waste spend and worsen customer experience.

**Insight 4: A subset of merchants have inefficient marketing spend**

Low ROAS merchants require campaign resets, spend controls, and targeting cleanup before increasing budgets.

**Insight 5: High Potential merchants are the best candidates for scaling**

Strong health signals + stable performance make them ideal for ads onboarding, upsell programs, and controlled growth experiments.


**Recommendations (What to do next)**

**At Risk → Fix reliability first, then regain volume**
	•	reduce cancels + refunds
	•	improve prep time stability
	•	run targeted promos only after ops stabilizes
**Track**: orders, growth, cancellations, refunds, rating

**Ops Constrained → Operational stabilization sprin**t
	•	staffing + hours audit
	•	menu simplification/availability improvements
**Track**: prep time trend + cancellation drop

**Ad Inefficient → Spend control + campaign reset**
	•	cap spend temporarily
	•	tighten targeting + use ROAS guardrails
**Track**: ROAS improvement + incremental orders

**Core → Protect + monitor**
	•	prevent drift into churn with baseline monitoring
	•	run small controlled experiments
**Track**: growth stability + reliability metrics

**High Potential → Scale intelligently**
	•	upsell ads and promos with ROI story
	•	track uplift after adoption
**Track**: incremental lift + repeat orders
