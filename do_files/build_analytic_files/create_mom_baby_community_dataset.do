// Close any open log files
capture log close

// Clear Memory
clear all

// Set Date
*This is set in master_run_all_build.do

// Specify Screen Width for log files
set linesize 255

// Allow the screen to move without having to click more
set more off

// Drop everything in mata
matrix drop _all

// Set Project Details using local mactos
local project caresource_infant_mortality
local pgm create_mom_baby_community_dataset
local dt $date
local task create a combined analytic file for babies, moms, and community variables  using the raw CareSource Data. The output file will have one row per baby
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

// Put Global Macro Here So I don't have to scroll down each time 
global super_list   f04538 ///
	f04542  f08746 f08930 f09619 f09787 f11181 ///
	f11603 f11685 f11705 f11948  f12492 f12553 ///
	f12557 f12567 f12564 f12573 f12580 f12642 f13218 ///
	f13221 f13320 f13321 f13322 f13513 f13606 f13614 ///
	f14084 f14100 f14111 f14116 f14199 f14200 f14480 ///
	f14771 f15253 unemp_rate median_income percent_in_poverty ///
	pop_total percent_non_white percent_hispanic rate_vlnt  ///
	rate_vlntprop doc_access nv_birthwgt nv_chld_mort nv_exercise ///
	nv_hiv nv_hlthfood nv_hvydrink nv_inft_mort nv_ment_unhealth nv_mhp ///
	 nv_pcp t_smoke nv_tn_birth t_fairpoor_health
	
global per_capita_list  f08930 f09619 f11181 ///
	f11603 f11685 f11705 f11948  f12553 ///
	f12557 f12567 f12564 f12573 f12580 f12642 f13218 ///
	f13221 f13320  f13606 f13614 ///
	f14084 f14100 f14111 f14116 f14199 f14200 f14480 ///
	 nv_birthwgt  nv_exercise ///
	 nv_hlthfood nv_hvydrink  nv_ment_unhealth  

global factor_list f00020 ever_engaged

*******************************************************************************
// Open Baby Dataset
use "$file_path_for_data_output/baby_file_by_birth_year.dta", clear


*******************************************************************************
// Add Census Tract  Info

// drop year in case it is incorrectly merged in
capture drop year

// Make birth year, year for merge
rename birth_year year

// Merge into census tract 
merge m:m census_tract_id year using "$file_path_for_raw_data/ACS_5Y_05_15_TRACT_deident.dta"

// Drop the tracts that we don't have any infants in
drop if missing(baby_id)

// Drop merge variable
drop _merge

*******************************************************************************
// Add County Characteristics

//Put state to string so merge will work
tostring state, replace

// Merge with county characteristics
merge m:m county_id  year using "$file_path_for_raw_data/County_Data_Deident.dta"

//Rename year back to birth year
rename year birth_year

//Drop counties where we have no infants
drop if missing(baby_id)	

// Drop merge variable
drop _merge

// Drop duplicates
duplicates drop baby_id, force

// Carryforward Population When Missing
set seed 1234
gsort county_id birth_year
bysort county_id: carryforward pop_total, replace

// Turn Per Capitas
foreach x in $per_capita_list {
	replace `x' = (`x'/pop_total)*1000

}

// Generate rural binaries
forvalues t = 1(1)8 {
	gen rural_`t' =0
	replace rural_`t' = 1 if f00020==`t'
}

*******************************************************************************
merge m:1 mom_id birth_year using "$file_path_for_data_output/mom_file_by_birth_year.dta"

// Change this id so that the ds command below doesn't pick up the id variable for mom_id
rename mom_id momm_id

// Create Both Engaged in Care Management Binary
gen both_engaged_1=0
replace both_engaged = 1 if mom_engaged_1==1 & engaged_1==1

// First make a full list of mom variables and store as a global 
ds mom_*, has(type numeric)
global mom_var_list `r(varlist)'

// Replace mom variables = 0 if missing
foreach x in $mom_var_list {
	replace `x' =0 if missing(`x') & mom_member==1

}

// Save dataset 
save "$file_path_for_data_output/mom_and_infant_sample.dta", replace
********************************************************************************
