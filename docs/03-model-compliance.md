# FinArk Lesson: Model Compliance Validation (Window Functions vs. GROUP BY)

## The Core Business Concept
In professional wealth management, a model portfolio blueprint must allocate exactly 100% (1.0000) of its total space to its underlying component assets. If a portfolio designer accidentally builds a target mix that adds up to 98% or 105%, the model is broken and completely out of compliance.

This module introduces students to advanced SQL analytics by showing two completely distinct architectural methods to evaluate this metric sum, highlighting critical data visibility tradeoffs.

---

## The Two Analytical Options

### Option A: The Window Function Approach ("The Preserver")
The Window Function utilizes an OVER(PARTITION BY...) clause to compute the aggregate sum of the asset weights inline:
SUM(mi.weight) OVER(PARTITION BY mi.model_id)

* How it Works: It tells the relational database engine to segregate portfolios into context buckets, calculate the mathematical sum, but then attach that summary calculation back onto every single granular row.
* Pedagogical Value: The dataset never shrinks. Students retain full visibility into which exact instrument tickers make up the model while viewing the total running sum simultaneously. If an error happens, they can pinpoint the exact asset causing the imbalance.

### Option B: The CTE + GROUP BY Approach ("The Collapser")
This method uses a standard GROUP BY block wrapped inside a Common Table Expression (CTE) to aggregate target sums.

* How it Works: GROUP BY acts like a trash compactor. It smashes all individual asset rows down into a single consolidated row per model portfolio.
* Pedagogical Value: It is perfect for clean, high-level executive summaries. However, granular details are completely erased. If a model is flagged as 'OUT OF COMPLIANCE', you lose sight of which underlying instruments caused the issue without writing an entirely separate query.
