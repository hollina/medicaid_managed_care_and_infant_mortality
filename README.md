# Replication code for "Care management reduced infant mortality for Medicaid managed care enrollees in Ohio"

This repository contains code to replicate the results of:

Hollingsworth, Alex., Kranz, Ashley., and Debbie Freund. 2020. Care management reduced infant mortality for Medicaid managed care enrollees in Ohio. American Journal of Managed Care. 26(3):294-298  <https://doi.org/10.37765/ajmc.2020.42637>


<figure style="float:center;">
<img src="https://github.com/hollina/medicaid_managed_care_and_infant_mortality/blob/master/output/exhibit_2.png"  width="800"  /> 
</figure>


## Abstract

**Objectives**: In 2012, the Ohio Department of Medicaid introduced requirements for enhanced care management to be delivered by Medicaid managed care organizations (MCOs). This study evaluated the impact of care management on reducing infant mortality in the largest Medicaid MCO in Ohio.
**Study Design**: Observational study using infant and maternal individual-level enrollment and claims data (2009-2015), which used a quasi-experimental research design built upon a sibling-comparison approach that controls for within-family confounders.
**Methods**: Using individual-level data from the largest MCO in Ohio, we estimated linear probability models to examine the effect of infant engagement in care management on infant mortality. We used a within-family fixed-effects research design to determine if care management reduced infant mortality and estimated models separately for healthy infants and non-healthy infants.
**Results**: Infant engagement in care management was associated with a 7.4 (p<.001) percentage point reduction in infant mortality among the most vulnerable infants, those identified as not well at birth (95\% confidence interval (CI)= -10.7, -4.1). This effect was larger in recent years and was likely driven by new statewide enhanced care management requirements. Infant mortality was unchanged for healthy infants engaged in care management (coefficient=0.03, 95\% CI= -0.01, 0.08). 
**Conclusions**: This study provides evidence that care management can be effective in reducing infant mortality among Medicaid MCO-enrollees, a population at high-risk of mortality. Few infants were engaged in care management, suggesting to policy makers that there is room for many additional infants to benefit from this intervention.

## Data Sources:
Data used were proprietary data provided by CareSource. Angela Snyder at CareSource created relevant data extracts for our analysis. We cannot share any data as per our data use agreement. 

## Software Used:
All analysis were done on unix machines using Stata SE 14.2. We use a number of user-written packages that should be outlined in the master.do file. We also use a number of shell commands from within stata (whenever the ! command is present). Most of these should still work on a non-unix system, but may need to be modified.

## License:
Replication code (this github repo): [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
