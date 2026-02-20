# Risk Assessment

## When to Use
When evaluating a property or deal for financial risk and investment viability.

## Process

### 1. Financial Health Score
- **NOI Trend:** Is Net Operating Income growing, flat, or declining over 3 years?
- **Occupancy Rate:** Current vs. market average. Below 85% = red flag.
- **Rent Collections:** What % of billed rent is actually collected?
- **Expense Ratio:** Operating expenses as % of gross income. Above 55% = investigate.

### 2. Debt Service Analysis
- Calculate DSCR (Debt Service Coverage Ratio): NOI / Annual Debt Service
- DSCR > 1.25 = healthy. DSCR < 1.10 = high risk. DSCR < 1.0 = deal killer.
- Stress test at +200bps on interest rate — does DSCR still hold?

### 3. Market Risk
- Local vacancy trends (rising = caution)
- Comparable rent growth vs. subject property
- New supply pipeline within 3-mile radius
- Employment and population trends in MSA

### 4. Property-Specific Risk
- Deferred maintenance estimates
- Environmental concerns (Phase I/II needed?)
- Tenant concentration — any single tenant > 25% of income?
- Lease rollover schedule — any cliff years?

### 5. Risk Rating
Assign a rating based on aggregate findings:
- **A (Low Risk):** Strong NOI growth, high occupancy, DSCR > 1.4, stable market
- **B (Moderate Risk):** Stable NOI, average occupancy, DSCR 1.2-1.4
- **C (Elevated Risk):** Declining NOI or occupancy, DSCR 1.1-1.2, market headwinds
- **D (High Risk):** Multiple red flags, DSCR < 1.1, significant deferred maintenance
- **F (Do Not Proceed):** Deal-killing issues identified

### 6. Output
Write risk assessment to `reports/risk-assessment-[property].md` with:
- Summary rating and recommendation
- Key risk factors with supporting data
- Mitigants (if any)
- Conditions for proceeding (if applicable)
