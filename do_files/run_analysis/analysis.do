 // Close any open log files
capture log close

// Clear Memory
clear all

// Set Date
*This is set in the master file

// Specify Screen Width for log files
set linesize 255

// Allow the screen to move without having to click more
set more off

// Drop everything in mata
matrix drop _all

// Set Project Details using local mactos
local project caresource_infant_mortality
local pgm create_jama_peds_graph
local dt $date
local task run regressions, store estimates, and plot them
local tag "`pgm'.do `username' `dt'"

// Start Log
log using "$file_path_for_logs/`pgm'", replace text
di "The file is: `tag'"
di "Task: `task'"
di "Project: `project'"

//Set max memory if necessary
*set max_memory 64g, perm

//Set max matsize if necessary
set matsize 10000

// Add Path to a directory that stata looks at for packages
adopath + "$file_path_for_stata"

********************************************************************************
// Open Baby-Mom-Community Dataset
use "$file_path_for_data_output/mom_and_infant_sample.dta", clear

//20 moms were born in 1900 or 1901. set their ages to missing
replace mom_age = . if mom_age>60

// Destring County ID
destring county_id, replace

// Length of Care
replace length_of_case=0 if missing(length_of_case)

// Community List
global super_list nv_pcp unemp_rate percent_in_poverty ///
	percent_non_white t_smoke 

// Create Mom List
global mom_list_fe mom_age mom_ever_substance_abuse_ind mom_ever_serious_mental_illness ///
	mom_multiple_birth_ind  mom_engaged_1

global mom_list_small mom_multiple_birth_ind  mom_engaged_1

// Create Baby List With Mom
global infant_list engaged_1 black hispanic other  ///
	male  well_ind

global infant_list_small engaged_1   ///
	male  well_ind

// Impute Mean for County Variables
foreach x in $super_list {
	bysort county_id: egen mean_`x' = mean(`x')
	bysort county_id: replace `x' = mean_`x' if missing(`x')
	drop mean_`x'
}

// Destring mother identifier
destring momm_id, replace

// Create a set of variables to store these results. 
capture drop low
capture drop high
capture drop order
capture drop coef

gen order = _n
gen low = .
gen high = . 
gen coef = .

local row_number = 1

////////////////////////////////////////////////////////////////////////////////
// Full sample of infants. Cross-sectional design
reghdfe died_under_1_1_1 $infant_list $super_list $mom_list_fe, absorb(FE_county_cs_full=i.county_id FE_byear_cs_full=i.birth_year) vce(cluster county_id)
	replace coef = _b[engaged_1] if order == `row_number'
	replace high = _b[engaged_1] + 1.96*_se[engaged_1] if order == `row_number'
	replace low  = _b[engaged_1] - 1.96*_se[engaged_1] if order == `row_number'
	local row_number = `row_number' + 1
	
	// Predict mortality status	
	predict yhat_cs_full, xbd
	
	gen IN_cs_full = 0 
	replace IN_cs_full = 1 if e(sample)
	
	// Save regression estimates 
	estadd local birth_county_fe "Yes"
	estadd local birth_year_fe "Yes"
	estadd local mother_fe "No"	
	estadd local years "All"
	estadd local infants_incl "All"

	eststo m_cs_full
	
	// Save summary stats from this regression	
	summarize died_under_1_1_1 $infant_list $super_list $mom_list_fe birth_year if e(sample)
	tab well_ind engaged_1 if e(sample)
	
	//Clear any stored estimates
	capture est sto clear

	
reghdfe died_under_1_1_1 $infant_list $super_list $mom_list_fe  if well_ind==1, a(FE_county_cs_well=i.county_id FE_byear_cs_well=i.birth_year) vce(cluster county_id)
	replace coef = _b[engaged_1] if order == `row_number'
	replace high = _b[engaged_1] + 1.96*_se[engaged_1] if order == `row_number'
	replace low  = _b[engaged_1] - 1.96*_se[engaged_1] if order == `row_number'
	local row_number = `row_number' + 1
	
	// Predict mortality status
	predict yhat_cs_well, xbd	
		
	gen IN_cs_well = 0 
	replace IN_cs_well = 1 if e(sample)
	
	// Save regression estimates 
	estadd local birth_county_fe "Yes"
	estadd local birth_year_fe "Yes"
	estadd local mother_fe "No"	
	estadd local years "All"
	estadd local infants_incl "Well"

	eststo m_cs_well
	
	// Save summary stats from this regression		
	summarize died_under_1_1_1 $infant_list $super_list $mom_list_fe birth_year if e(sample)
	tab well_ind engaged_1 if e(sample)
	
	//Clear any stored estimates
	capture est sto clear

	estpost tabstat died_under_1_1_1 $infant_list $super_list $mom_list_fe birth_year if e(sample) ///
		, by(ever_engaged) stats(mean count) columns(statistics) 

	esttab using "$file_path_for_results/all_years_well_infants.xls" ///
	, replace main(mean) aux(count) nostar unstack /// 
	noobs nonote nomtitle nonumber label	
	
reghdfe died_under_1_1_1 $infant_list $super_list $mom_list_fe  if well_ind==0, a(FE_county_cs_sick=i.county_id FE_byear_cs_sick=i.birth_year) vce(cluster county_id)
	replace coef = _b[engaged_1] if order == `row_number'
	replace high = _b[engaged_1] + 1.96*_se[engaged_1] if order == `row_number'
	replace low  = _b[engaged_1] - 1.96*_se[engaged_1] if order == `row_number'
	local row_number = `row_number' + 1
	local row_number = `row_number' + 1
	
	// Predict mortality status
	predict yhat_cs_sick, xbd
					
	gen IN_cs_sick = 0 
	replace IN_cs_sick = 1 if e(sample)
	
	// Save regression estimates 
	estadd local birth_county_fe "Yes"
	estadd local birth_year_fe "Yes"
	estadd local mother_fe "No"	
	estadd local years "All"
	estadd local infants_incl "Sick"

	eststo m_cs_sick
	
	// Save summary stats from this regression	
	summarize died_under_1_1_1 $infant_list $super_list $mom_list_fe birth_year if e(sample)
	tab well_ind engaged_1 if e(sample)
	
	//Clear any stored estimates
	capture est sto clear

	estpost tabstat died_under_1_1_1 $infant_list $super_list $mom_list_fe birth_year if e(sample) ///
		, by(ever_engaged) stats(mean count) columns(statistics) 

	esttab using "$file_path_for_results/all_years_sick_infants.xls" ///
	, replace main(mean) aux(count) nostar unstack /// 
	noobs nonote nomtitle nonumber label
	
////////////////////////////////////////////////////////////////////////////////
// Sample of infants with siblings. Within-family design

reghdfe died_under_1_1_1 $infant_list_small $super_list $mom_list_fe_small if  mom_member==1, absorb(FE_county_sib_full=i.county_id FE_byear_sib_full=i.birth_year FE_mom_sib_full=i.momm_id) vce(cluster county_id)
	replace coef = _b[engaged_1] if order == `row_number'
	replace high = _b[engaged_1] + 1.96*_se[engaged_1] if order == `row_number'
	replace low  = _b[engaged_1] - 1.96*_se[engaged_1] if order == `row_number'
	local row_number = `row_number' + 1
	
	// Predict mortality status
	predict yhat_sib_full, xbd
						
	gen IN_sib_full = 0 
	replace IN_sib_full = 1 if e(sample)
			
	// Save regression estimates 
	estadd local birth_county_fe "Yes"
	estadd local birth_year_fe "Yes"
	estadd local mother_fe "Yes"	
	estadd local years "All"
	estadd local infants_incl "All"

	eststo m_sib_full
	
	// Save summary stats from this regression	
	summarize died_under_1_1_1 $infant_list $super_list $mom_list_fe birth_year if e(sample)
	tab well_ind engaged_1 if e(sample)
	
	//Clear any stored estimates
	capture est sto clear

	estpost tabstat died_under_1_1_1 $infant_list $super_list $mom_list_fe birth_year if e(sample) ///
		, by(ever_engaged) stats(mean count) columns(statistics) 

	esttab using "$file_path_for_results/all_years_all_infants_with_siblings.xls" ///
	, replace main(mean) aux(count) nostar unstack /// 
	noobs nonote nomtitle nonumber label	
	
reghdfe died_under_1_1_1 $infant_list_small $super_list $mom_list_fe_small if  mom_member==1 & well_ind==1, a(FE_county_sib_well=i.county_id FE_byear_sib_well=i.birth_year FE_mom_sib_well=i.momm_id) vce(cluster county_id)
	replace coef = _b[engaged_1] if order == `row_number'
	replace high = _b[engaged_1] + 1.96*_se[engaged_1] if order == `row_number'
	replace low  = _b[engaged_1] - 1.96*_se[engaged_1] if order == `row_number'
	local row_number = `row_number' + 1
	
	// Predict mortality status
	predict yhat_sib_well, xbd
							
	gen IN_sib_well = 0 
	replace IN_sib_well = 1 if e(sample)
			
	// Save regression estimates 
	estadd local birth_county_fe "Yes"
	estadd local birth_year_fe "Yes"
	estadd local mother_fe "Yes"	
	estadd local years "All"
	estadd local infants_incl "Well"

	eststo m_sib_well
	
	// Save summary stats from this regression		
	summarize died_under_1_1_1 $infant_list $super_list $mom_list_fe birth_year if e(sample)
	tab well_ind engaged_1 if e(sample)
	
	//Clear any stored estimates
	capture est sto clear

	estpost tabstat died_under_1_1_1 $infant_list $super_list $mom_list_fe birth_year if e(sample) ///
		, by(ever_engaged) stats(mean count) columns(statistics) 

	esttab using "$file_path_for_results/all_years_well_infants_with_siblings.xls" ///
	, replace main(mean) aux(count) nostar unstack /// 
	noobs nonote nomtitle nonumber label	
		
reghdfe died_under_1_1_1 $infant_list_small $super_list $mom_list_fe_small if  mom_member==1 & well_ind==0, a(FE_county_sib_sick=i.county_id FE_byear_sib_sick=i.birth_year FE_mom_sib_sick=i.momm_id) vce(cluster county_id)
	replace coef = _b[engaged_1] if order == `row_number'
	replace high = _b[engaged_1] + 1.96*_se[engaged_1] if order == `row_number'
	replace low  = _b[engaged_1] - 1.96*_se[engaged_1] if order == `row_number'
	local row_number = `row_number' + 1
	local row_number = `row_number' + 1
	
	// Predict mortality status
	predict yhat_sib_sick, xbd	
								
	gen IN_sib_sick = 0 
	replace IN_sib_sick = 1 if e(sample)
	
	// Save regression estimates 
	estadd local birth_county_fe "Yes"
	estadd local birth_year_fe "Yes"
	estadd local mother_fe "Yes"	
	estadd local years "All"
	estadd local infants_incl "Sick"

	eststo m_sib_sick
	
	// Save summary stats from this regression	
	summarize died_under_1_1_1 $infant_list $super_list $mom_list_fe birth_year if e(sample)
	tab well_ind engaged_1 if e(sample)
	
	//Clear any stored estimates
	capture est sto clear

	estpost tabstat died_under_1_1_1 $infant_list $super_list $mom_list_fe birth_year if e(sample) ///
		, by(ever_engaged) stats(mean count) columns(statistics) 

	esttab using "$file_path_for_results/all_years_sick_infants_with_siblings.xls" ///
	, replace main(mean) aux(count) nostar unstack /// 
	noobs nonote nomtitle nonumber label	
		
qui reghdfe died_under_1_1_1 $infant_list_small $super_list $mom_list_fe_small if  mom_member==1 & well_ind==0, a(FE_county_sib_sick=i.county_id FE_byear_sib_sick=i.birth_year FE_mom_sib_sick=i.momm_id) vce(cluster county_id) replace

////////////////////////////////////////////////////////////////////////////////
// What is the effect of care management on the probability of death?
gen yhat_sib_sick_no_cm = yhat_sib_sick - _b[engaged_1]*engaged_1

sum yhat_sib_sick yhat_sib_sick_no_cm
sum yhat_sib_sick yhat_sib_sick_no_cm if mom_member==1 & well_ind==0
sum yhat_sib_sick yhat_sib_sick_no_cm if mom_member==1 & well_ind==0 & engaged_1==1

////////////////////////////////////////////////////////////////////////////////
// Sample of infants with siblings. Within-family design. Pre-Enhanced Care Management

reghdfe died_under_1_1_1 $infant_list_small $super_list $mom_list_fe_small if  mom_member==1 & birth_year<=2012, a(county_id birth_year momm_id) vce(cluster county_id)
	replace coef = _b[engaged_1] if order == `row_number'
	replace high = _b[engaged_1] + 1.96*_se[engaged_1] if order == `row_number'
	replace low  = _b[engaged_1] - 1.96*_se[engaged_1] if order == `row_number'
	local row_number = `row_number' + 1
	
	// Save regression estimates 
	estadd local birth_county_fe "Yes"
	estadd local birth_year_fe "Yes"
	estadd local mother_fe "Yes"	
	estadd local years "\$\leq\$2012"
	estadd local infants_incl "All"

	eststo m_sib_full_early
		
	summarize died_under_1_1_1 $infant_list $super_list $mom_list_fe birth_year if e(sample)
	tab well_ind engaged_1 if e(sample)
	
	//Clear any stored estimates
	capture est sto clear

	estpost tabstat died_under_1_1_1 $infant_list $super_list $mom_list_fe birth_year if e(sample) ///
		, by(ever_engaged) stats(mean count) columns(statistics) 

	esttab using "$file_path_for_results/pre_years_all_infants_with_siblings.xls" ///
	, replace main(mean) aux(count) nostar unstack /// 
	noobs nonote nomtitle nonumber label	
		
reghdfe died_under_1_1_1 $infant_list_small $super_list $mom_list_fe_small if  mom_member==1 & well_ind==1 & birth_year<=2012, a(county_id birth_year momm_id) vce(cluster county_id)
	replace coef = _b[engaged_1] if order == `row_number'
	replace high = _b[engaged_1] + 1.96*_se[engaged_1] if order == `row_number'
	replace low  = _b[engaged_1] - 1.96*_se[engaged_1] if order == `row_number'
	local row_number = `row_number' + 1
	
	// Save regression estimates 
	estadd local birth_county_fe "Yes"
	estadd local birth_year_fe "Yes"
	estadd local mother_fe "Yes"	
	estadd local years "\$\leq\$2012"
	estadd local infants_incl "Well"

	eststo m_sib_well_early	
	
	summarize died_under_1_1_1 $infant_list $super_list $mom_list_fe birth_year if e(sample)
	tab well_ind engaged_1 if e(sample)
	
	//Clear any stored estimates
	capture est sto clear

	estpost tabstat died_under_1_1_1 $infant_list $super_list $mom_list_fe birth_year if e(sample) ///
		, by(ever_engaged) stats(mean count) columns(statistics) 

	esttab using "$file_path_for_results/pre_years_well_infants_with_siblings.xls" ///
	, replace main(mean) aux(count) nostar unstack /// 
	noobs nonote nomtitle nonumber label	
		
reghdfe died_under_1_1_1 $infant_list_small $super_list $mom_list_fe_small if  mom_member==1 & well_ind==0 & birth_year<=2012, a(county_id birth_year momm_id) vce(cluster county_id)
	replace coef = _b[engaged_1] if order == `row_number'
	replace high = _b[engaged_1] + 1.96*_se[engaged_1] if order == `row_number'
	replace low  = _b[engaged_1] - 1.96*_se[engaged_1] if order == `row_number'
	local row_number = `row_number' + 1
	local row_number = `row_number' + 1
	
	// Save regression estimates 
	estadd local birth_county_fe "Yes"
	estadd local birth_year_fe "Yes"
	estadd local mother_fe "Yes"	
	estadd local years "\$\leq\$2012"
	estadd local infants_incl "Sick"

	eststo m_sib_sick_early		
	
	summarize died_under_1_1_1 $infant_list $super_list $mom_list_fe birth_year if e(sample)
	tab well_ind engaged_1 if e(sample)
	
	//Clear any stored estimates
	capture est sto clear

	estpost tabstat died_under_1_1_1 $infant_list $super_list $mom_list_fe birth_year if e(sample) ///
		, by(ever_engaged) stats(mean count) columns(statistics) 

	esttab using "$file_path_for_results/pre_years_sick_infants_with_siblings.xls" ///
	, replace main(mean) aux(count) nostar unstack /// 
	noobs nonote nomtitle nonumber label	
		

////////////////////////////////////////////////////////////////////////////////
// Sample of infants with siblings. Within-family design. Post-Enhanced Care Management

reghdfe died_under_1_1_1 $infant_list_small $super_list $mom_list_fe_small if  mom_member==1 & birth_year>2012, a(county_id birth_year momm_id) vce(cluster county_id)
	replace coef = _b[engaged_1] if order == `row_number'
	replace high = _b[engaged_1] + 1.96*_se[engaged_1] if order == `row_number'
	replace low  = _b[engaged_1] - 1.96*_se[engaged_1] if order == `row_number'
	local row_number = `row_number' + 1
	
	// Save regression estimates 
	estadd local birth_county_fe "Yes"
	estadd local birth_year_fe "Yes"
	estadd local mother_fe "Yes"	
	estadd local years "\$\geq\$2013"
	estadd local infants_incl "All"

	eststo m_sib_full_late
	
	summarize died_under_1_1_1 $infant_list $super_list $mom_list_fe birth_year if e(sample)
	tab well_ind engaged_1 if e(sample)
	
	//Clear any stored estimates
	capture est sto clear

	estpost tabstat died_under_1_1_1 $infant_list $super_list $mom_list_fe birth_year if e(sample) ///
		, by(ever_engaged) stats(mean count) columns(statistics) 

	esttab using "$file_path_for_results/post_years_all_infants_with_siblings.xls" ///
	, replace main(mean) aux(count) nostar unstack /// 
	noobs nonote nomtitle nonumber label	
	
reghdfe died_under_1_1_1 $infant_list_small $super_list $mom_list_fe_small if  mom_member==1 & well_ind==1 & birth_year>2012, a(county_id birth_year momm_id) vce(cluster county_id)
	replace coef = _b[engaged_1] if order == `row_number'
	replace high = _b[engaged_1] + 1.96*_se[engaged_1] if order == `row_number'
	replace low  = _b[engaged_1] - 1.96*_se[engaged_1] if order == `row_number'
	local row_number = `row_number' + 1
	
	// Save regression estimates 
	estadd local birth_county_fe "Yes"
	estadd local birth_year_fe "Yes"
	estadd local mother_fe "Yes"	
	estadd local years "\$\geq\$2013"
	estadd local infants_incl "Well"

	eststo m_sib_well_late	
	
	summarize died_under_1_1_1 $infant_list $super_list $mom_list_fe birth_year if e(sample)
	tab well_ind engaged_1 if e(sample)
	
	//Clear any stored estimates
	capture est sto clear

	estpost tabstat died_under_1_1_1 $infant_list $super_list $mom_list_fe birth_year if e(sample) ///
		, by(ever_engaged) stats(mean count) columns(statistics) 

	esttab using "$file_path_for_results/post_years_well_infants_with_siblings.xls" ///
	, replace main(mean) aux(count) nostar unstack /// 
	noobs nonote nomtitle nonumber label	
		
reghdfe died_under_1_1_1 $infant_list_small $super_list $mom_list_fe_small if  mom_member==1 & well_ind==0 & birth_year>2012, a(county_id birth_year momm_id) vce(cluster county_id)
	replace coef = _b[engaged_1] if order == `row_number'
	replace high = _b[engaged_1] + 1.96*_se[engaged_1] if order == `row_number'
	replace low  = _b[engaged_1] - 1.96*_se[engaged_1] if order == `row_number'
	local row_number = `row_number' + 1
	
	// Save regression estimates 
	estadd local birth_county_fe "Yes"
	estadd local birth_year_fe "Yes"
	estadd local mother_fe "Yes"	
	estadd local years "\$\geq\$2013"
	estadd local infants_incl "Sick"

	eststo m_sib_sick_late		
	
	summarize died_under_1_1_1 $infant_list $super_list $mom_list_fe birth_year if e(sample)
	tab well_ind engaged_1 if e(sample)
	//Clear any stored estimates
	capture est sto clear

	estpost tabstat died_under_1_1_1 $infant_list $super_list $mom_list_fe birth_year if e(sample) ///
		, by(ever_engaged) stats(mean count) columns(statistics) 

	esttab using "$file_path_for_results/post_years_sick_infants_with_siblings.xls" ///
	, replace main(mean) aux(count) nostar unstack /// 
	noobs nonote nomtitle nonumber label	
	
////////////////////////////////////////////////////////////////////////////////
// Export latex table

esttab ///
	m_cs_full m_cs_well m_cs_sick ///
	m_sib_full m_sib_well m_sib_sick ///
	m_sib_full_early m_sib_well_early m_sib_sick_early ///
	m_sib_full_late m_sib_well_late m_sib_sick_late ///
		using "$file_path_for_results/full_regression_results.tex" ///
		,star(* 0.10 ** 0.05 *** .01) ///
		stats(birth_county_fe birth_year_fe mother_fe years infants_incl N, ///
			fmt(%3.2f  0 0 0 0 0) ///
			layout("\multicolumn{1}{c}{@}" "\multicolumn{1}{c}{@}" "\multicolumn{1}{c}{@}" "\multicolumn{1}{c}{@}" ///
				"\multicolumn{1}{c}{@}" "\multicolumn{1}{c}{@}") ///
			label("Birth county fixed-effects" "Birth year fixed-effects" "Mother fixed-effects" "Years included" ///
				"Infants included" ///
				"\hline Observations") ///
		) ///
		se ///
		b(%9.3f) ///
		booktabs ///
		f replace  ///
		nomtitles ///
		keep($infant_list $super_list $mom_list_fe) ///
		substitute(\_ _) ///
		label ///
		coeflabel( ///
			nv_pcp "PCP per 100k" ///
			unemp_rate "Unemp. rate" ///
			percent_in_poverty "\% in poverty" ///
			percent_non_white "\% non-white" ///
			t_smoke "\% smokers" ///
			mom_age "Maternal age" ///
			mom_ever_substance_abuse_ind "Mom, even SUD" ///
			mom_ever_serious_mental_illness "Mom, ever SMI" ///
			mom_multiple_birth_ind "Multiple birth indicator" ///
			mom_engaged_1 "Mom in care management" ///
			engaged_1 "Care management" ///
			black "Black" ///
			hispanic "Hispanic" ///
			other "Other" ///
			male "Male" ///
			mom_member "Mother member" ///
			well_ind "Well at birth" ///
		)
		
////////////////////////////////////////////////////////////////////////////////
// Export top part of Exhibit 1
	/*
	IN_cs_full IN_cs_well IN_cs_sick
	IN_sib_full IN_sib_well IN_sib_sick
	*/
	

// Make a list of binary variables by group
global infant_binary_list ///
	died_under_1_1_1 black hispanic other ///
	male well_ind mom_multiple_birth_ind
	
global maternal_binary_list ///
	mom_ever_substance_abuse_ind mom_ever_serious_mental_illness ///
	mom_engaged_1  
	
// Make a list of continuous variables by group
global maternal_continuous_list mom_age
global community_continuous_list ///
	nv_pcp unemp_rate percent_in_poverty ///
	percent_non_white t_smoke 


// The columns should look like this
// Label  All&T=0  All&T=1  D=0&T=0  D=0&T=1	D=1&T=0  D=1&T=1  


// The rows should look like this
// Broad groups:	All		Healthy	Sick
// Subgroups:	Not-treated		Treated
// N for each subgroup
// Header for baby characteristics
// mortality 
// birth_weight
// Header for maternal characteristics
// opioid_abuse
// maternal_age_at_birth

// Extra caveat. When it's a binary variable. Label, No. (%) but when it's a continuous variable Label, Mean (S.D.)

// Going to try this with the format table command

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
// Top- All infants with maternal characteristics
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
// First summarize the infant characteristics for all infants

////////////////////////////////////////////////////////////////////////////////
// All 
matrix mean_sd = J(8,12,.)

// Treated
local i = 2
foreach v in $infant_binary_list {

	summarize `v' if engaged_1==1 & IN_cs_full == 1
	matrix mean_sd[`i',1] = r(sum)
	matrix mean_sd[`i',2] = (r(sum)/r(N))*100
	local i = `i' + 1
}
foreach v in $infant_continuous_list {

	summarize `v' if engaged_1==1 & IN_cs_full == 1
	matrix mean_sd[`i',1] = r(mean)
	matrix mean_sd[`i',2] = r(sd)
	local i = `i' + 1
}

// UnTreated
local i = 2
foreach v in $infant_binary_list {

	summarize `v' if engaged_1==0 & IN_cs_full == 1
	matrix mean_sd[`i',3] = r(sum)
	matrix mean_sd[`i',4] = (r(sum)/r(N))*100
	local i = `i' + 1
}
foreach v in $infant_continuous_list {
	summarize `v' if engaged_1==0 & IN_cs_full == 1
	matrix mean_sd[`i',3] = r(mean)
	matrix mean_sd[`i',4] = r(sd)
	local i = `i' + 1
}

////////////////////////////////////////////////////////////////////////////////
// healthy 

// treated
local i = 2
foreach v in $infant_binary_list {

	summarize `v' if IN_cs_well==1 & engaged_1==1
	matrix mean_sd[`i',5] = r(sum)
	matrix mean_sd[`i',6] = (r(sum)/r(N))*100
	local i = `i' + 1
}
foreach v in $infant_continuous_list {
	summarize `v' if IN_cs_well==1 & engaged_1==1
	matrix mean_sd[`i',5] = r(mean)
	matrix mean_sd[`i',6] = r(sd)
	local i = `i' + 1
}

// UNTreated
local i = 2
foreach v in $infant_binary_list {

	summarize `v' if IN_cs_well==1 & engaged_1==0
	matrix mean_sd[`i',7] = r(sum)
	matrix mean_sd[`i',8] = (r(sum)/r(N))*100
	local i = `i' + 1
}
foreach v in $infant_continuous_list {
	summarize `v' if IN_cs_well==1 & engaged_1==0
	matrix mean_sd[`i',7] = r(mean)
	matrix mean_sd[`i',8] = r(sd)
	local i = `i' + 1
}

////////////////////////////////////////////////////////////////////////////////
// sick 

// treated
local i = 2
foreach v in $infant_binary_list {

	summarize `v' if IN_cs_sick==1 & engaged_1==1
	matrix mean_sd[`i',9] = r(sum)
	matrix mean_sd[`i',10] = (r(sum)/r(N))*100
	local i = `i' + 1
}
foreach v in $infant_continuous_list {
	summarize `v' if IN_cs_sick==1 & engaged_1==1
	matrix mean_sd[`i',9] = r(mean)
	matrix mean_sd[`i',10] = r(sd)
	local i = `i' + 1
}

// UNTreated
local i = 2
foreach v in $infant_binary_list {

	summarize `v' if IN_cs_sick==1 & engaged_1==0
	matrix mean_sd[`i',11] = r(sum)
	matrix mean_sd[`i',12] = (r(sum)/r(N))*100
	local i = `i' + 1
}
foreach v in $infant_continuous_list {
	summarize `v' if IN_cs_sick==1 & engaged_1==0
	matrix mean_sd[`i',11] = r(mean)
	matrix mean_sd[`i',12] = r(sd)
	local i = `i' + 1
}
////////////////////////////////////////////////////////////////////////////////
// Get counts by group
count if engaged_1==0 & IN_cs_full==1
local all_untreated = r(N)

count if engaged_1==1 & IN_cs_full==1
local all_treated = r(N)

count if engaged_1==0 & IN_cs_well==1
local healthy_untreated = r(N)

count if engaged_1==1 & IN_cs_well==1
local healthy_treated = r(N)

count if engaged_1==0 & IN_cs_sick==1
local sick_untreated = r(N)

count if engaged_1==1 & IN_cs_sick==1
local sick_treated = r(N)

////////////////////////////////////////////////////////////////////////////////
// Set up for output

matrix dbl = (0,1,0,1,0,1,0,1,0,1,0,1)
mat list mean_sd
mat list dbl
matrix rownames mean_sd = "{\i Infant Characteristics} " ///
						   "\~\~\~ Died in first year of life, No. (%)" ///
						   "\~\~\~ Black, No. (%)" ///
						   "\~\~\~ Hispanic, No. (%)" ///
						   "\~\~\~ Other race, No. (%)" ///
						   "\~\~\~ Male, No. (%)" ///
						   "\~\~\~ Multiple birth indicator, No. (%)" 
						   

////////////////////////////////////////////////////////////////////////////////
// Export the table

frmttable using "$file_path_for_results/exhibit_1_part_a", ///
	statmat(mean_sd) doubles(dbl) varlabels dbldiv(", (") ///
	 replace  ///
    ctitles("", "{\b All infants with siblings}", "", "{\b Those healthy at birth}", "", "{\b Those sick at birth}", "" \   ///
		   "", "In care", "Not in care", "In care", "Not in care", "In care", "Not in care" \   ///
		   "", "{\ul management \~\~\~ management}", "", "{\ul management \~\~\~ management}", "", "{\ul management \~\~\~ management}", "" \   ///
		   "", "N=`all_treated'", "N=`all_untreated'", "N=`healthy_treated'", "N=`healthy_untreated'", "N=`sick_treated'", "N=`sick_untreated'") ///
    multicol( ///
		1,2,2;1,4,2;1,6,2; ///
		3,2,2;3,4,2;3,6,2) ///
	basefont(fs8 roman)	///
colwidth(50 15 15 15 15 15 15)
	

////////////////////////////////////////////////////////////////////////////////
// Second summarize the maternal characteristics

////////////////////////////////////////////////////////////////////////////////
// All 
matrix mean_sd = J(5,12,.)

// treated
local i = 2
foreach v in $maternal_binary_list {

	summarize `v' if engaged_1==1 & IN_cs_full==1
	matrix mean_sd[`i',1] = r(sum)
	matrix mean_sd[`i',2] = (r(sum)/r(N))*100
	local i = `i' + 1
}
foreach v in $maternal_continuous_list {

	summarize `v' if engaged_1==1 & IN_cs_full==1
	matrix mean_sd[`i',1] = r(mean)
	matrix mean_sd[`i',2] = r(sd)
	local i = `i' + 1
}

// UnTreated
local i = 2
foreach v in $maternal_binary_list {

	summarize `v' if engaged_1==0 & IN_cs_full==1
	matrix mean_sd[`i',3] = r(sum)
	matrix mean_sd[`i',4] = (r(sum)/r(N))*100
	local i = `i' + 1
}
foreach v in $maternal_continuous_list {
	summarize `v' if engaged_1==0 & IN_cs_full==1
	matrix mean_sd[`i',3] = r(mean)
	matrix mean_sd[`i',4] = r(sd)
	local i = `i' + 1
}

////////////////////////////////////////////////////////////////////////////////
// Healthy 

// treated
local i = 2
foreach v in $maternal_binary_list {

	summarize `v' if IN_cs_well==1 & engaged_1==1
	matrix mean_sd[`i',5] = r(sum)
	matrix mean_sd[`i',6] = (r(sum)/r(N))*100
	local i = `i' + 1
}
foreach v in $maternal_continuous_list {
	summarize `v' if IN_cs_well==1 & engaged_1==1
	matrix mean_sd[`i',5] = r(mean)
	matrix mean_sd[`i',6] = r(sd)
	local i = `i' + 1
}

// UNTreated
local i = 2
foreach v in $maternal_binary_list {

	summarize `v' if IN_cs_well==1 & engaged_1==0
	matrix mean_sd[`i',7] = r(sum)
	matrix mean_sd[`i',8] = (r(sum)/r(N))*100
	local i = `i' + 1
}
foreach v in $maternal_continuous_list {
	summarize `v' if IN_cs_well==1 & engaged_1==0
	matrix mean_sd[`i',7] = r(mean)
	matrix mean_sd[`i',8] = r(sd)
	local i = `i' + 1
}

////////////////////////////////////////////////////////////////////////////////
// Sick 

// treated
local i = 2
foreach v in $maternal_binary_list {

	summarize `v' if IN_cs_sick==1 & engaged_1==1
	matrix mean_sd[`i',9] = r(sum)
	matrix mean_sd[`i',10] = (r(sum)/r(N))*100
	local i = `i' + 1
}
foreach v in $maternal_continuous_list {
	summarize `v' if IN_cs_sick==1 & engaged_1==1
	matrix mean_sd[`i',9] = r(mean)
	matrix mean_sd[`i',10] = r(sd)
	local i = `i' + 1
}

// UNTreated
local i = 2
foreach v in $maternal_binary_list {

	summarize `v' if IN_cs_sick==1 & engaged_1==0
	matrix mean_sd[`i',11] = r(sum)
	matrix mean_sd[`i',12] = (r(sum)/r(N))*100
	local i = `i' + 1
}
foreach v in $maternal_continuous_list {
	summarize `v' if IN_cs_sick==1 & engaged_1==0
	matrix mean_sd[`i',11] = r(mean)
	matrix mean_sd[`i',12] = r(sd)
	local i = `i' + 1
}

////////////////////////////////////////////////////////////////////////////////
// Set up for output

matrix dbl = (0,1,0,1,0,1,0,1,0,1,0,1)
mat list mean_sd
mat list dbl
matrix rownames mean_sd = "{\i Maternal Characteristics} " ///
						  "\~\~\~ Ever SUD, No. (%)" ///
						  "\~\~\~ Ever SMI, No. (%)" ///
						  "\~\~\~ Ever engaged in care management, No. (%)" ///						  
						  "\~\~\~ Age at birth, mean (SD)" 

////////////////////////////////////////////////////////////////////////////////
// Export the table

frmttable using "$file_path_for_results/exhibit_1_part_a", ///
	statmat(mean_sd) doubles(dbl) varlabels dbldiv(", (") ///
	 append     ///
    ctitles("", "{\b All infants with siblings}", "", "{\b Those healthy at birth}", "", "{\b Those sick at birth}", "" \   ///
		   "", "In care", "Not in care", "In care", "Not in care", "In care", "Not in care" \   ///
		   "", "{\ul management \~\~\~ management}", "", "{\ul management \~\~\~ management}", "", "{\ul management \~\~\~ management}", "" \   ///
		   "", "N=`all_treated'", "N=`all_untreated'", "N=`healthy_treated'", "N=`healthy_untreated'", "N=`sick_treated'", "N=`sick_untreated'") ///
    multicol( ///
		1,2,2;1,4,2;1,6,2; ///
		3,2,2;3,4,2;3,6,2) ///
	basefont(fs8 roman)	///
colwidth(50 15 15 15 15 15 15)

////////////////////////////////////////////////////////////////////////////////
// Third summarize the community characteristics

////////////////////////////////////////////////////////////////////////////////
// All 
matrix mean_sd = J(6,12,.)

// treated
local i = 2
foreach v in $community_binary_list {

	summarize `v' if engaged_1==1 & IN_cs_full == 1
	matrix mean_sd[`i',1] = r(sum)
	matrix mean_sd[`i',2] = (r(sum)/r(N))*100
	local i = `i' + 1
}
foreach v in $community_continuous_list {

	summarize `v' if engaged_1==1 & IN_cs_full == 1
	matrix mean_sd[`i',1] = r(mean)
	matrix mean_sd[`i',2] = r(sd)
	local i = `i' + 1
}

// UNTreated
local i = 2
foreach v in $community_binary_list {

	summarize `v' if engaged_1==0 & IN_cs_full == 1
	matrix mean_sd[`i',3] = r(sum)
	matrix mean_sd[`i',4] = (r(sum)/r(N))*100
	local i = `i' + 1
}
foreach v in $community_continuous_list {
	summarize `v' if engaged_1==0 & IN_cs_full == 1
	matrix mean_sd[`i',3] = r(mean)
	matrix mean_sd[`i',4] = r(sd)
	local i = `i' + 1
}

////////////////////////////////////////////////////////////////////////////////
// Healthy 

// treated
local i = 2
foreach v in $community_binary_list {

	summarize `v' if IN_cs_well==1 & engaged_1==1
	matrix mean_sd[`i',5] = r(sum)
	matrix mean_sd[`i',6] = (r(sum)/r(N))*100
	local i = `i' + 1
}
foreach v in $community_continuous_list {
	summarize `v' if IN_cs_well==1 & engaged_1==1
	matrix mean_sd[`i',5] = r(mean)
	matrix mean_sd[`i',6] = r(sd)
	local i = `i' + 1
}

// UNTreated
local i = 2
foreach v in $community_binary_list {

	summarize `v' if IN_cs_well==1 & engaged_1==0
	matrix mean_sd[`i',7] = r(sum)
	matrix mean_sd[`i',8] = (r(sum)/r(N))*100
	local i = `i' + 1
}
foreach v in $community_continuous_list {
	summarize `v' if IN_cs_well==1 & engaged_1==0
	matrix mean_sd[`i',7] = r(mean)
	matrix mean_sd[`i',8] = r(sd)
	local i = `i' + 1
}

////////////////////////////////////////////////////////////////////////////////
// Sick 

// treated
local i = 2
foreach v in $community_binary_list {

	summarize `v' if IN_cs_sick==1 & engaged_1==1
	matrix mean_sd[`i',9] = r(sum)
	matrix mean_sd[`i',10] = (r(sum)/r(N))*100
	local i = `i' + 1
}
foreach v in $community_continuous_list {
	summarize `v' if IN_cs_sick==1 & engaged_1==1
	matrix mean_sd[`i',9] = r(mean)
	matrix mean_sd[`i',10] = r(sd)
	local i = `i' + 1
}

// UNTreated
local i = 2
foreach v in $community_binary_list {

	summarize `v' if IN_cs_sick==1 & engaged_1==0
	matrix mean_sd[`i',11] = r(sum)
	matrix mean_sd[`i',12] = (r(sum)/r(N))*100
	local i = `i' + 1
}
foreach v in $community_continuous_list {
	summarize `v' if IN_cs_sick==1 & engaged_1==0
	matrix mean_sd[`i',11] = r(mean)
	matrix mean_sd[`i',12] = r(sd)
	local i = `i' + 1
}

////////////////////////////////////////////////////////////////////////////////
// Set up for output

matrix dbl = (0,1,0,1,0,1,0,1,0,1,0,1)
mat list mean_sd
mat list dbl
matrix rownames mean_sd = "{\i Community Characteristics} " ///
						  "\~\~\~ PCP per 100k, mean (SD)" ///
						  "\~\~\~ Unemp. rate, mean (SD)" ///
						  "\~\~\~ % in poverty, mean (SD)" ///
						  "\~\~\~ % non-white, mean (SD)" ///
						  "\~\~\~ % smokers, mean (SD)" 

////////////////////////////////////////////////////////////////////////////////
// Export the table

frmttable using "$file_path_for_results/exhibit_1_part_a", ///
	statmat(mean_sd) doubles(dbl) varlabels dbldiv(", (") ///
	 append   ///
    ctitles("", "{\b All infants with siblings}", "", "{\b Those healthy at birth}", "", "{\b Those sick at birth}", "" \   ///
		   "", "In care", "Not in care", "In care", "Not in care", "In care", "Not in care" \   ///
		   "", "{\ul management \~\~\~ management}", "", "{\ul management \~\~\~ management}", "", "{\ul management \~\~\~ management}", "" \   ///
		   "", "N=`all_treated'", "N=`all_untreated'", "N=`healthy_treated'", "N=`healthy_untreated'", "N=`sick_treated'", "N=`sick_untreated'") ///
    multicol( ///
		1,2,2;1,4,2;1,6,2; ///
		3,2,2;3,4,2;3,6,2) ///
	basefont(fs8 roman)	///
colwidth(50 15 15 15 15 15 15) ///
note("Source: Author calculations using claims data.") ///
title("Exhibit 1: Maternal and infant characteristics for infants enrolled in care management since birth")

// Things remaining to fix manually
*1. Add ) to right side of (SD) or (%). I cannot figure out how to do this!
*2. Delete .00 decimal places after those that are numbers (i.e. count of those that died)
*3. Add commas to the thousands place for the N= at the top
*4. Adjust any rows that are too wide or too narrow.
*5. Left justify source note.

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
// Bottom- All infants with siblings 
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////
// First summarize the infant characteristics for all infants

////////////////////////////////////////////////////////////////////////////////
// All 
matrix mean_sd = J(8,12,.)

// Treated
local i = 2
foreach v in $infant_binary_list {

	summarize `v' if engaged_1==1 & IN_sib_full == 1
	matrix mean_sd[`i',1] = r(sum)
	matrix mean_sd[`i',2] = (r(sum)/r(N))*100
	local i = `i' + 1
}
foreach v in $infant_continuous_list {

	summarize `v' if engaged_1==1 & IN_sib_full == 1
	matrix mean_sd[`i',1] = r(mean)
	matrix mean_sd[`i',2] = r(sd)
	local i = `i' + 1
}

// UnTreated
local i = 2
foreach v in $infant_binary_list {

	summarize `v' if engaged_1==0 & IN_sib_full == 1
	matrix mean_sd[`i',3] = r(sum)
	matrix mean_sd[`i',4] = (r(sum)/r(N))*100
	local i = `i' + 1
}
foreach v in $infant_continuous_list {
	summarize `v' if engaged_1==0 & IN_sib_full == 1
	matrix mean_sd[`i',3] = r(mean)
	matrix mean_sd[`i',4] = r(sd)
	local i = `i' + 1
}

////////////////////////////////////////////////////////////////////////////////
// healthy 

// treated
local i = 2
foreach v in $infant_binary_list {

	summarize `v' if IN_sib_well==1 & engaged_1==1
	matrix mean_sd[`i',5] = r(sum)
	matrix mean_sd[`i',6] = (r(sum)/r(N))*100
	local i = `i' + 1
}
foreach v in $infant_continuous_list {
	summarize `v' if IN_sib_well==1 & engaged_1==1
	matrix mean_sd[`i',5] = r(mean)
	matrix mean_sd[`i',6] = r(sd)
	local i = `i' + 1
}

// UNTreated
local i = 2
foreach v in $infant_binary_list {

	summarize `v' if IN_sib_well==1 & engaged_1==0
	matrix mean_sd[`i',7] = r(sum)
	matrix mean_sd[`i',8] = (r(sum)/r(N))*100
	local i = `i' + 1
}
foreach v in $infant_continuous_list {
	summarize `v' if IN_sib_well==1 & engaged_1==0
	matrix mean_sd[`i',7] = r(mean)
	matrix mean_sd[`i',8] = r(sd)
	local i = `i' + 1
}

////////////////////////////////////////////////////////////////////////////////
// sick 

// treated
local i = 2
foreach v in $infant_binary_list {

	summarize `v' if IN_sib_sick==1 & engaged_1==1
	matrix mean_sd[`i',9] = r(sum)
	matrix mean_sd[`i',10] = (r(sum)/r(N))*100
	local i = `i' + 1
}
foreach v in $infant_continuous_list {
	summarize `v' if IN_sib_sick==1 & engaged_1==1
	matrix mean_sd[`i',9] = r(mean)
	matrix mean_sd[`i',10] = r(sd)
	local i = `i' + 1
}

// UNTreated
local i = 2
foreach v in $infant_binary_list {

	summarize `v' if IN_sib_sick==1 & engaged_1==0
	matrix mean_sd[`i',11] = r(sum)
	matrix mean_sd[`i',12] = (r(sum)/r(N))*100
	local i = `i' + 1
}
foreach v in $infant_continuous_list {
	summarize `v' if IN_sib_sick==1 & engaged_1==0
	matrix mean_sd[`i',11] = r(mean)
	matrix mean_sd[`i',12] = r(sd)
	local i = `i' + 1
}
////////////////////////////////////////////////////////////////////////////////
// Get counts by group
count if engaged_1==0 & IN_sib_full==1
local all_untreated = r(N)

count if engaged_1==1 & IN_sib_full==1
local all_treated = r(N)

count if engaged_1==0 & IN_sib_well==1
local healthy_untreated = r(N)

count if engaged_1==1 & IN_sib_well==1
local healthy_treated = r(N)

count if engaged_1==0 & IN_sib_sick==1
local sick_untreated = r(N)

count if engaged_1==1 & IN_sib_sick==1
local sick_treated = r(N)

////////////////////////////////////////////////////////////////////////////////
// Set up for output

matrix dbl = (0,1,0,1,0,1,0,1,0,1,0,1)
mat list mean_sd
mat list dbl
matrix rownames mean_sd = "{\i Infant Characteristics} " ///
						   "\~\~\~ Died in first year of life, No. (%)" ///
						   "\~\~\~ Black, No. (%)" ///
						   "\~\~\~ Hispanic, No. (%)" ///
						   "\~\~\~ Other race, No. (%)" ///
						   "\~\~\~ Male, No. (%)" ///
						   "\~\~\~ Multiple birth indicator, No. (%)" 
						   

////////////////////////////////////////////////////////////////////////////////
// Export the table

frmttable using "$file_path_for_results/exhibit_1_part_b", ///
	statmat(mean_sd) doubles(dbl) varlabels dbldiv(", (") ///
	 replace  ///
    ctitles("", "{\b All infants with siblings}", "", "{\b Those healthy at birth}", "", "{\b Those sick at birth}", "" \   ///
		   "", "In care", "Not in care", "In care", "Not in care", "In care", "Not in care" \   ///
		   "", "{\ul management \~\~\~ management}", "", "{\ul management \~\~\~ management}", "", "{\ul management \~\~\~ management}", "" \   ///
		   "", "N=`all_treated'", "N=`all_untreated'", "N=`healthy_treated'", "N=`healthy_untreated'", "N=`sick_treated'", "N=`sick_untreated'") ///
    multicol( ///
		1,2,2;1,4,2;1,6,2; ///
		3,2,2;3,4,2;3,6,2) ///
	basefont(fs8 roman)	///
colwidth(50 15 15 15 15 15 15)
	

////////////////////////////////////////////////////////////////////////////////
// Second summarize the maternal characteristics

////////////////////////////////////////////////////////////////////////////////
// All 
matrix mean_sd = J(5,12,.)

// treated
local i = 2
foreach v in $maternal_binary_list {

	summarize `v' if engaged_1==1 & IN_sib_full==1
	matrix mean_sd[`i',1] = r(sum)
	matrix mean_sd[`i',2] = (r(sum)/r(N))*100
	local i = `i' + 1
}
foreach v in $maternal_continuous_list {

	summarize `v' if engaged_1==1 & IN_sib_full==1
	matrix mean_sd[`i',1] = r(mean)
	matrix mean_sd[`i',2] = r(sd)
	local i = `i' + 1
}

// UnTreated
local i = 2
foreach v in $maternal_binary_list {

	summarize `v' if engaged_1==0 & IN_sib_full==1
	matrix mean_sd[`i',3] = r(sum)
	matrix mean_sd[`i',4] = (r(sum)/r(N))*100
	local i = `i' + 1
}
foreach v in $maternal_continuous_list {
	summarize `v' if engaged_1==0 & IN_sib_full==1
	matrix mean_sd[`i',3] = r(mean)
	matrix mean_sd[`i',4] = r(sd)
	local i = `i' + 1
}

////////////////////////////////////////////////////////////////////////////////
// Healthy 

// treated
local i = 2
foreach v in $maternal_binary_list {

	summarize `v' if IN_sib_well==1 & engaged_1==1
	matrix mean_sd[`i',5] = r(sum)
	matrix mean_sd[`i',6] = (r(sum)/r(N))*100
	local i = `i' + 1
}
foreach v in $maternal_continuous_list {
	summarize `v' if IN_sib_well==1 & engaged_1==1
	matrix mean_sd[`i',5] = r(mean)
	matrix mean_sd[`i',6] = r(sd)
	local i = `i' + 1
}

// UNTreated
local i = 2
foreach v in $maternal_binary_list {

	summarize `v' if IN_sib_well==1 & engaged_1==0
	matrix mean_sd[`i',7] = r(sum)
	matrix mean_sd[`i',8] = (r(sum)/r(N))*100
	local i = `i' + 1
}
foreach v in $maternal_continuous_list {
	summarize `v' if IN_sib_well==1 & engaged_1==0
	matrix mean_sd[`i',7] = r(mean)
	matrix mean_sd[`i',8] = r(sd)
	local i = `i' + 1
}

////////////////////////////////////////////////////////////////////////////////
// Sick 

// treated
local i = 2
foreach v in $maternal_binary_list {

	summarize `v' if IN_sib_sick==1 & engaged_1==1
	matrix mean_sd[`i',9] = r(sum)
	matrix mean_sd[`i',10] = (r(sum)/r(N))*100
	local i = `i' + 1
}
foreach v in $maternal_continuous_list {
	summarize `v' if IN_sib_sick==1 & engaged_1==1
	matrix mean_sd[`i',9] = r(mean)
	matrix mean_sd[`i',10] = r(sd)
	local i = `i' + 1
}

// UNTreated
local i = 2
foreach v in $maternal_binary_list {

	summarize `v' if IN_sib_sick==1 & engaged_1==0
	matrix mean_sd[`i',11] = r(sum)
	matrix mean_sd[`i',12] = (r(sum)/r(N))*100
	local i = `i' + 1
}
foreach v in $maternal_continuous_list {
	summarize `v' if IN_sib_sick==1 & engaged_1==0
	matrix mean_sd[`i',11] = r(mean)
	matrix mean_sd[`i',12] = r(sd)
	local i = `i' + 1
}

////////////////////////////////////////////////////////////////////////////////
// Set up for output

matrix dbl = (0,1,0,1,0,1,0,1,0,1,0,1)
mat list mean_sd
mat list dbl
matrix rownames mean_sd = "{\i Maternal Characteristics} " ///
						  "\~\~\~ Ever SUD, No. (%)" ///
						  "\~\~\~ Ever SMI, No. (%)" ///
						  "\~\~\~ Ever engaged in care management, No. (%)" ///						  
						  "\~\~\~ Age at birth, mean (SD)" 

////////////////////////////////////////////////////////////////////////////////
// Export the table

frmttable using "$file_path_for_results/exhibit_1_part_b", ///
	statmat(mean_sd) doubles(dbl) varlabels dbldiv(", (") ///
	 append     ///
    ctitles("", "{\b All infants with siblings}", "", "{\b Those healthy at birth}", "", "{\b Those sick at birth}", "" \   ///
		   "", "In care", "Not in care", "In care", "Not in care", "In care", "Not in care" \   ///
		   "", "{\ul management \~\~\~ management}", "", "{\ul management \~\~\~ management}", "", "{\ul management \~\~\~ management}", "" \   ///
		   "", "N=`all_treated'", "N=`all_untreated'", "N=`healthy_treated'", "N=`healthy_untreated'", "N=`sick_treated'", "N=`sick_untreated'") ///
    multicol( ///
		1,2,2;1,4,2;1,6,2; ///
		3,2,2;3,4,2;3,6,2) ///
	basefont(fs8 roman)	///
colwidth(50 15 15 15 15 15 15)

////////////////////////////////////////////////////////////////////////////////
// Third summarize the community characteristics

////////////////////////////////////////////////////////////////////////////////
// All 
matrix mean_sd = J(6,12,.)

// treated
local i = 2
foreach v in $community_binary_list {

	summarize `v' if engaged_1==1 & IN_sib_full == 1
	matrix mean_sd[`i',1] = r(sum)
	matrix mean_sd[`i',2] = (r(sum)/r(N))*100
	local i = `i' + 1
}
foreach v in $community_continuous_list {

	summarize `v' if engaged_1==1 & IN_sib_full == 1
	matrix mean_sd[`i',1] = r(mean)
	matrix mean_sd[`i',2] = r(sd)
	local i = `i' + 1
}

// UNTreated
local i = 2
foreach v in $community_binary_list {

	summarize `v' if engaged_1==0 & IN_sib_full == 1
	matrix mean_sd[`i',3] = r(sum)
	matrix mean_sd[`i',4] = (r(sum)/r(N))*100
	local i = `i' + 1
}
foreach v in $community_continuous_list {
	summarize `v' if engaged_1==0 & IN_sib_full == 1
	matrix mean_sd[`i',3] = r(mean)
	matrix mean_sd[`i',4] = r(sd)
	local i = `i' + 1
}

////////////////////////////////////////////////////////////////////////////////
// Healthy 

// treated
local i = 2
foreach v in $community_binary_list {

	summarize `v' if IN_sib_well==1 & engaged_1==1
	matrix mean_sd[`i',5] = r(sum)
	matrix mean_sd[`i',6] = (r(sum)/r(N))*100
	local i = `i' + 1
}
foreach v in $community_continuous_list {
	summarize `v' if IN_sib_well==1 & engaged_1==1
	matrix mean_sd[`i',5] = r(mean)
	matrix mean_sd[`i',6] = r(sd)
	local i = `i' + 1
}

// UNTreated
local i = 2
foreach v in $community_binary_list {

	summarize `v' if IN_sib_well==1 & engaged_1==0
	matrix mean_sd[`i',7] = r(sum)
	matrix mean_sd[`i',8] = (r(sum)/r(N))*100
	local i = `i' + 1
}
foreach v in $community_continuous_list {
	summarize `v' if IN_sib_well==1 & engaged_1==0
	matrix mean_sd[`i',7] = r(mean)
	matrix mean_sd[`i',8] = r(sd)
	local i = `i' + 1
}

////////////////////////////////////////////////////////////////////////////////
// Sick 

// treated
local i = 2
foreach v in $community_binary_list {

	summarize `v' if IN_sib_sick==1 & engaged_1==1
	matrix mean_sd[`i',9] = r(sum)
	matrix mean_sd[`i',10] = (r(sum)/r(N))*100
	local i = `i' + 1
}
foreach v in $community_continuous_list {
	summarize `v' if IN_sib_sick==1 & engaged_1==1
	matrix mean_sd[`i',9] = r(mean)
	matrix mean_sd[`i',10] = r(sd)
	local i = `i' + 1
}

// UNTreated
local i = 2
foreach v in $community_binary_list {

	summarize `v' if IN_sib_sick==1 & engaged_1==0
	matrix mean_sd[`i',11] = r(sum)
	matrix mean_sd[`i',12] = (r(sum)/r(N))*100
	local i = `i' + 1
}
foreach v in $community_continuous_list {
	summarize `v' if IN_sib_sick==1 & engaged_1==0
	matrix mean_sd[`i',11] = r(mean)
	matrix mean_sd[`i',12] = r(sd)
	local i = `i' + 1
}

////////////////////////////////////////////////////////////////////////////////
// Set up for output

matrix dbl = (0,1,0,1,0,1,0,1,0,1,0,1)
mat list mean_sd
mat list dbl
matrix rownames mean_sd = "{\i Community Characteristics} " ///
						  "\~\~\~ PCP per 100k, mean (SD)" ///
						  "\~\~\~ Unemp. rate, mean (SD)" ///
						  "\~\~\~ % in poverty, mean (SD)" ///
						  "\~\~\~ % non-white, mean (SD)" ///
						  "\~\~\~ % smokers, mean (SD)" 

////////////////////////////////////////////////////////////////////////////////
// Export the table

frmttable using "$file_path_for_results/exhibit_1_part_b", ///
	statmat(mean_sd) doubles(dbl) varlabels dbldiv(", (") ///
	 append   ///
    ctitles("", "{\b All infants with siblings}", "", "{\b Those healthy at birth}", "", "{\b Those sick at birth}", "" \   ///
		   "", "In care", "Not in care", "In care", "Not in care", "In care", "Not in care" \   ///
		   "", "{\ul management \~\~\~ management}", "", "{\ul management \~\~\~ management}", "", "{\ul management \~\~\~ management}", "" \   ///
		   "", "N=`all_treated'", "N=`all_untreated'", "N=`healthy_treated'", "N=`healthy_untreated'", "N=`sick_treated'", "N=`sick_untreated'") ///
    multicol( ///
		1,2,2;1,4,2;1,6,2; ///
		3,2,2;3,4,2;3,6,2) ///
	basefont(fs8 roman)	///
colwidth(50 15 15 15 15 15 15) ///
note("Source: Author calculations using claims data.") ///
title("Exhibit 1: Maternal and infant characteristics for infants enrolled in care management since birth with siblings")

// Things remaining to fix manually
*1. Add ) to right side of (SD) or (%). I cannot figure out how to do this!
*2. Delete .00 decimal places after those that are numbers (i.e. count of those that died)
*3. Add commas to the thousands place for the N= at the top
*4. Adjust any rows that are too wide or too narrow.
*5. Left justify source note.

////////////////////////////////////////////////////////////////////////////////
// Set up labels for graph

gen subset = ""
replace subset = "all"  if order ==1 | order ==5 | order== 9  | order == 13
replace subset = "well" if order ==2 | order ==6 | order== 10 | order == 14
replace subset = "sick" if order ==3 | order ==7 | order== 11 | order == 15

///////////////////////////////////////////////////////////
// Set up labels for graph
/*
// Add one more observation
local one_more = _N + 1
set obs `one_more' 

// Make that obs 13
replace order = 13 if missing(order)
sort order 
*/
gen year_label = ""
gen year_label_pos = .
local label_location_list 2 6 10 13
foreach x in `label_location_list' {
	replace year_label = " " if order == `x'
	replace year_label_pos = -.22 if order == `x'
	replace year_label_pos = -.22 if order == `x'
	replace year_label_pos = -.22 if order == `x'
	replace year_label_pos = -.22 if order == `x' 
}

gen county_label = ""
gen county_label_pos = .
foreach x in `label_location_list' {
	replace county_label = " " if order == `x'
	replace county_label_pos = -.23 if order == `x'
	replace county_label_pos = -.23 if order == `x'
	replace county_label_pos = -.23 if order == `x'
	replace county_label_pos = -.23 if order == `x' 
}

gen sibling_label = ""
gen sibling_label_pos = .
local label_location_list  2

foreach x in `label_location_list' {
	replace sibling_label = "Cross-sectional design" if order == `x'
	replace sibling_label_pos = -.28 if order == `x'
	replace sibling_label_pos = -.28 if order == `x'
	replace sibling_label_pos = -.28 if order == `x'
	replace sibling_label_pos = -.28 if order == `x' 
}
local label_location_list  6 10 13

foreach x in `label_location_list' {
	replace sibling_label = "Within-family design" if order == `x'
	replace sibling_label_pos = -.28 if order == `x'
	replace sibling_label_pos = -.28 if order == `x'
	replace sibling_label_pos = -.28 if order == `x'
	replace sibling_label_pos = -.28 if order == `x' 
}
gen sibling_label2 = ""
gen sibling_label_pos2 = .
local label_location_list  6 10 13

foreach x in `label_location_list' {
	replace sibling_label2 = "" if order == `x'
	replace sibling_label_pos2 = -.25 if order == `x'
	replace sibling_label_pos2 = -.25 if order == `x'
	replace sibling_label_pos2 = -.25 if order == `x'
	replace sibling_label_pos2 = -.25 if order == `x' 
}
gen sibling_label3 = ""
gen sibling_label_pos3 = .
local label_location_list   6 10 13

foreach x in `label_location_list' {
	replace sibling_label3 = "" if order == `x'
	replace sibling_label_pos3 = -.26 if order == `x'
	replace sibling_label_pos3 = -.26 if order == `x'
	replace sibling_label_pos3 = -.26 if order == `x'
	replace sibling_label_pos3 = -.26 if order == `x' 
}
gen time_label = ""
gen time_label_pos = .

local label_location_list 2 6

foreach x in `label_location_list' {
	replace time_label = "Full study period" if order == `x'
	replace time_label_pos = -.295 if order == `x'
	replace time_label_pos = -.295 if order == `x'
	replace time_label_pos = -.295 if order == `x'
	replace time_label_pos = -.295 if order == `x' 
}
local label_location_list  10 

foreach x in `label_location_list' {
	replace time_label = "Before enhanced" if order == `x'
	replace time_label_pos = -.295 if order == `x'
	replace time_label_pos = -.295 if order == `x'
	replace time_label_pos = -.295 if order == `x'
	replace time_label_pos = -.295 if order == `x' 
}
local label_location_list  13

foreach x in `label_location_list' {
	replace time_label = "After enhanced" if order == `x'
	replace time_label_pos = -.295 if order == `x'
	replace time_label_pos = -.295 if order == `x'
	replace time_label_pos = -.295 if order == `x'
	replace time_label_pos = -.295 if order == `x' 
}
gen time_label2 = ""
gen time_label_pos2 = .

local label_location_list 10  13
foreach x in `label_location_list' {
	replace time_label2 = "care management" if order == `x'
	replace time_label_pos2 = -.305 if order == `x'
	replace time_label_pos2 = -.305 if order == `x'
	replace time_label_pos2 = -.305 if order == `x'
	replace time_label_pos2 = -.305 if order == `x' 
}
*drop if missing(coef)

////////////////////////////////////////////////////////////////////////////////
// Plot the results
twoway rcap low high order if subset=="all", lcolor(turquoise)  msize(1.5) ///
	||  scatter coef order if subset=="all", msymbol(D) mcolor(turquoise) msize(1.5)  ///
	|| rcap low high order if subset=="well",  lcolor(vermillion) msize(1.5)  ///
	||  scatter coef order if subset=="well", msymbol(O) mcolor(vermillion)  msize(1.5) ///
	||  rcap low high order if subset=="sick",  lcolor(sea)  msize(1.5) ///
	||  scatter coef order if subset=="sick", msymbol(S) mcolor(sea)  msize(1.5) ///
	||  connected year_label_pos order if order <13,  lcolor(none) msymbol(none) mcolor(black) mlabcolor(black) mlabel(year_label) mlabsize(2.5) mlabpos(0) mlabgap(0) ///
	||  connected county_label_pos order if order <13,  lcolor(none) msymbol(none) mcolor(black) mlabcolor(black) mlabel(county_label) mlabsize(2.5) mlabpos(0) mlabgap(0)  ///
	||  connected sibling_label_pos order if order <13,  lcolor(none) msymbol(none) mcolor(black) mlabcolor(black) mlabel(sibling_label) mlabsize(2.5) mlabpos(0) mlabgap(0)  ///
	||  connected sibling_label_pos2 order if order <13,  lcolor(none) msymbol(none) mcolor(black) mlabcolor(black) mlabel(sibling_label2) mlabsize(2.5) mlabpos(0) mlabgap(0)  ///
	||  connected sibling_label_pos3 order if order <13,  lcolor(none) msymbol(none) mcolor(black) mlabcolor(black) mlabel(sibling_label3) mlabsize(2.5) mlabpos(0) mlabgap(0)  ///
	||  connected time_label_pos order if order <13 ,  lcolor(none) msymbol(none) mcolor(black) mlabcolor(black) mlabel(time_label) mlabsize(2.5) mlabpos(0)  mlabgap(0) ///
	||  connected time_label_pos2 order if order <13 ,  lcolor(none) msymbol(none) mcolor(black) mlabcolor(black) mlabel(time_label2) mlabsize(2.5) mlabpos(0)  mlabgap(0) ///
	||  connected year_label_pos order if order>=13,  lcolor(none) msymbol(none) mcolor(black) mlabcolor(black) mlabel(year_label) mlabsize(2.5) mlabpos(3) mlabgap(-6) ///
	||  connected county_label_pos order if order>=13,  lcolor(none) msymbol(none) mcolor(black) mlabcolor(black) mlabel(county_label) mlabsize(2.5) mlabpos(3) mlabgap(-6)  ///
	||  connected sibling_label_pos order if order>=13,  lcolor(none) msymbol(none) mcolor(black) mlabcolor(black) mlabel(sibling_label) mlabsize(2.5) mlabpos(3) mlabgap(-6)  ///
	||  connected sibling_label_pos2 order if order>=13,  lcolor(none) msymbol(none) mcolor(black) mlabcolor(black) mlabel(sibling_label2) mlabsize(2.5) mlabpos(3) mlabgap(-6)  ///
	||  connected sibling_label_pos3 order if order>=13,  lcolor(none) msymbol(none) mcolor(black) mlabcolor(black) mlabel(sibling_label3) mlabsize(2.5) mlabpos(3) mlabgap(-6)  ///
	||  connected time_label_pos order if order>=13 ,  lcolor(none) msymbol(none) mcolor(black) mlabcolor(black) mlabel(time_label) mlabsize(2.5) mlabpos(3)  mlabgap(-6) ///
	||  connected time_label_pos2 order if order>=13 ,  lcolor(none) msymbol(none) mcolor(black) mlabcolor(black) mlabel(time_label2) mlabsize(2.5) mlabpos(3)  mlabgap(-6) ///
	yline(0) 	///
	legend(size(3.5) pos(6) cols(3) order(2 4 6) label(2 "All births") label(4 "Well at birth" ) label(6 "Not well at birth")) ///
	xtitle("") ytitle("Percentage point change in likelihood of infant mortality", size(2.5)) xscale(lcolor(white)) ///
	ylabel(-.25(.05).05, gmin gmax) ///
	title("Care management reduced infant mortality for high risk infants for a large Managed Medicaid Organization in Ohio", size(3)) ///
	xlabel(none , nogrid notick  axis(off)) ///
	graphregion(margin(r+10)) ///
	note("Note: All point estimates and 95% confidence intervals (reported in brackets) come from separate regressions. The cross-sectional regression" ///
		"include all infants whose mother is an MCO member. The within-family design includes all infants with siblings whose mother is an MCO member." ///
		"Results are robust to changing the sample to include all observed infants regardless of sibling or maternal MCO membership. The cross-sectional design" ///
		"includes controls for time invariant county-level confounders and birth-year invariant confounders. The cross-sectional design also controls for infant," ///
		"maternal and community characteristics reported in Exhibit 1. The within-family design includes all of the controls from the cross-sectional design and" ///
		"additionally controls for family-invariant characteristics (e.g., genetic predisposition, parental education, and health behaviors). Standard errors were" ///
		"clustered at the birth county-level. The first two sets of results use data from all years available, 2009 to 2015. The last two sets of results examine" ///
		"two different sets of years; 2009-2011, which is the period before the enhanced care management program was introduced and 2013-2015, which is the" ///
		"time period after enhanced care management was introduced. Well at birth is a designation based on diagnosis-related groups that indicates" ///
		"the infant was considered well when discharged from the hospital after birth." ///
		, size(2) )
		// Save the graph

graph export "exhibit_2.png", replace 
graph save "exhibit_2.gph", replace 

// Save the point estimates, 95% confidence intervals, and p-values
keep order high low coef subset
save "$file_path_for_results/point_estimates_for_exhibit_2.dta", replace

// Log Close
log close

