# Merchant Growth Analytics

## Executive Summary
Small and mid-sized merchants can decline due to operational friction (cancellations, refunds, slow prep time) or inefficient marketing spend. This project builds a **portfolio-level merchant health system** to answer:

**Which merchants are at risk of churn, why are they declining, and what actions should we take next?**

**Output:** Merchant segmentation + Opportunity Score ranking + Tableau dashboards + prioritized action list.

---

## Problem Statement
Merchant performance drops often go unnoticed until the revenue impact becomes significant. The goal of this project is to:

- **Detect early churn risk**
- **Diagnose the drivers of decline**
- **Prioritize the most recoverable merchants** using a repeatable analytics workflow

---

## Dataset and Metrics Definitions
The dataset contains merchant performance across **cities and categories**, focused on growth, reliability, and efficiency.

### Core Metrics Used
- **Revenue:** total merchant revenue (impact sizing)  
- **Orders:** completed orders  
- **Orders Growth 4W (%):** 4-week order trend *(negative = churn signal)*  
- **Cancel Rate (%):** reliability risk *(high cancellations reduce conversion)*  
- **Refund %:** quality risk *(high refunds indicate fulfillment issues)*  
- **Avg Prep Time (mins):** operational friction *(impacts cancellations + CX)*  
- **Rating:** customer satisfaction signal  
- **ROAS:** ad efficiency *(low ROAS = inefficient spend)*  

---

## Segment Logic (Merchant Risk Categories)
Merchants are grouped into actionable segments for Ops and Sales prioritization.

### Segment Definitions
- **At Risk:** negative growth + high cancels/refunds/prep issues → immediate recovery plan  
- **Ops Constrained:** demand exists, but ops bottlenecks limit growth → fix fulfillment first  
- **Ad Inefficient:** low ROAS + weak growth → reset campaigns before scaling spend  
- **High Potential:** healthy fundamentals + room to scale → upsell and growth programs  
- **Core:** stable merchants → monitor + light experimentation  

---

## Opportunity Score (Prioritization Model)
To avoid treating every merchant equally, merchants are ranked using an **Opportunity Score** based on:

1. **Revenue impact**  
2. **Growth headroom**  
3. **Fixability of issues**  

### Formula
**Opportunity Score = Revenue Weight × (0.6 × Headroom + 0.4 × Fixability)**

### Definitions
- **Revenue Weight:** higher-revenue merchants receive higher priority  
- **Headroom:** recoverable decline potential  
  - `IF Orders Growth 4W < 0 THEN ABS(Orders Growth 4W) ELSE 0`
- **Fixability:** how actionable reliability issues are  
  - `Cancel Rate + Refund %`

---

## Tableau Dashboards and Views
This project includes a full Tableau workflow with portfolio views and drilldowns.

### 1) Portfolio Performance Snapshot  
High-level health view across revenue, growth, and reliability.

<img width="2336" height="1161" alt="Portfolio Performance Snapshot" src="https://github.com/user-attachments/assets/361dfa89-00e8-4a2d-9218-f173c3a3deb7" />

---

### 2) Revenue vs Growth Quadrants  
Merchant prioritization buckets:

- **High Revenue + Negative Growth → High Priority**
- **Low Revenue + Negative Growth → Fix Later**
- **High Revenue + Positive Growth → Protect**
- **Low Revenue + Positive Growth → Monitor**

<img width="1117" height="1049" alt="Revenue vs Growth" src="https://github.com/user-attachments/assets/4f9d6a47-7563-4416-8900-28b36235bdc5" />

---

### 3) Revenue at Risk by Driver  
Identifies the biggest contributors to decline (cancellations, refunds, prep time, demand drop).

<img width="1117" height="240" alt="Revenue at Risk by Driver" src="https://github.com/user-attachments/assets/01785213-084d-494d-9764-e5c085baeab6" />

---

### 4) Priority Merchant Action List  
Ranks merchants by Opportunity Score with recommended actions.

<img width="1526" height="579" alt="Priority Merchant Action List" src="https://github.com/user-attachments/assets/53eef66b-bb5b-4a5f-b9aa-f7888ce09e39" />

---

### 5) Opportunity Heatmap (City × Category)  
Shows where opportunity and risk clusters exist geographically.

<img width="1117" height="640" alt="Opportunity Heatmap (City × Category)" src="https://github.com/user-attachments/assets/ac48c9d9-61fa-4802-a27a-e4ca2fd03ec6" />

---

## Key Insights
### 1) Risk is concentrated in merchants with negative growth  
Portfolio-level order growth trends downward, indicating broad churn risk and urgency.

### 2) High Revenue + Negative Growth is the highest priority zone  
Most revenue is concentrated in the **High Priority** quadrant, meaning retention efforts should begin with top-revenue merchants losing demand.

### 3) Ops issues drive churn more than marketing in many cases  
Merchants with high cancellations, refunds, or prep time issues decline even when demand exists. Promotions without fixing ops first can waste spend and worsen customer experience.

### 4) A subset of merchants have inefficient marketing spend  
Low ROAS merchants require campaign resets, spend controls, and targeting cleanup before increasing budgets.

### 5) High-Potential merchants are best candidates for scaling  
Strong health signals + stable performance make them ideal for ads onboarding, upsell programs, and controlled growth experiments.

---

## Recommendations (What to Do Next)

### At Risk → Fix reliability first, then regain volume
- Reduce cancels and refunds  
- Improve prep time stability  
- Run targeted promos only after ops stabilizes  
**Track:** orders, growth, cancellations, refunds, rating  

### Ops Constrained → Operational stabilization sprint
- Staffing and hours audit  
- Menu simplification and availability improvements  
**Track:** prep time trend, cancellation drop  

### Ad Inefficient → Spend control + campaign reset
- Cap spend temporarily  
- Tighten targeting and use ROAS guardrails  
**Track:** ROAS improvement, incremental orders  

### Core → Protect + monitor
- Prevent drift into churn with baseline monitoring  
- Run small controlled experiments  
**Track:** growth stability, reliability metrics  

### High Potential → Scale intelligently
- Upsell ads and promos with ROI story  
- Track uplift after adoption  
**Track:** incremental lift, repeat orders  
