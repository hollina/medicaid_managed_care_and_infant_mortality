// Close any open log files
capture log close

// Clear Memory
clear all


// Specify Screen Width for log files
set linesize 255

// Allow the screen to move without having to click more
set more off

// Drop everything in mata
matrix drop _all

// Set Project Details using local mactos
local project caresource_infant_mortality
local pgm creat_flat_file_baby
local dt $date
local task create an analytic file for babies using the raw CareSource Data. The output file will have one row per baby
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

// Open baby member file
use "$file_path_for_raw_data/File_1_Baby_member.dta", clear

// Rename Baby ID
rename id baby_id

// Generate Death Year Month 
bysort baby_id: egen death= max(death_year_month)	
bysort baby_id: egen max_elig_at_birth= max(elig_at_birth)


gen one_year_eligibile = 0
replace one_year_eligibile = 1 if months_of_eligibility==12

//Make sure all observations have this
bysort baby_id: egen max_one_year_eligibile = max(one_year_eligibile)
drop one_year_eligibile
rename max_one_year_eligibile one_year_eligibile

// Turn Death into a binary
replace death = 0 if missing(death)
replace death = 1 if death!=0


// Identify the most recent year the baby is in the dataset
destring year , replace
bysort baby_id: egen max_year=max(year)
tostring year, replace

// Keep just the first observation
bysort baby_id: gen order=_n
keep if order ==1

// Generate Date for Birthday
tostring birth_year_month, replace
gen birthday = date(birth_year_month,"YM")
gen birth_year = year(birthday)
gen birth_month = month(birthday)

// Generate Date for Deathday
tostring death_year_month, replace
gen deathday = date(death_year_month,"YM")
gen death_year = year(deathday)
gen death_month = month(deathday)


//Calculate Length of Life in days assuming 1st and 1st
gen length_of_life_1_1 = deathday-birthday

// Gen number of days in month of birth
gen birth_month_days = .
replace birth_month_days = 31 if birth_month==1

// Accounting for leap years
replace birth_month_days = 29 if birth_month==2 & birth_year==2016
replace birth_month_days = 29 if birth_month==2 & birth_year==2012
replace birth_month_days = 29 if birth_month==2 & birth_year==2008
replace birth_month_days = 29 if birth_month==2 & birth_year==2004
replace birth_month_days = 29 if birth_month==2 & birth_year==2000
replace birth_month_days = 28 if birth_month==2 & birth_year!=2016 & birth_year!=2012 & birth_year!=2008 & birth_year!=2004  & birth_year!=2000

replace birth_month_days = 31 if birth_month==3
replace birth_month_days = 30 if birth_month==4
replace birth_month_days = 31 if birth_month==5
replace birth_month_days = 30 if birth_month==6
replace birth_month_days = 31 if birth_month==7
replace birth_month_days = 31 if birth_month==8
replace birth_month_days = 30 if birth_month==9
replace birth_month_days = 31 if birth_month==10
replace birth_month_days = 30 if birth_month==11
replace birth_month_days = 31 if birth_month==12

// Gen number of days in month of death
gen death_month_days = .
replace death_month_days = 31 if death_month==1

// Accounting for leap years
replace death_month_days = 29 if death_month==2 & death_year==2016
replace death_month_days = 29 if death_month==2 & death_year==2012
replace death_month_days = 29 if death_month==2 & death_year==2008
replace death_month_days = 29 if death_month==2 & death_year==2004
replace death_month_days = 29 if death_month==2 & death_year==2000

replace death_month_days = 28 if death_month==2  & death_year!=2016 & death_year!=2012 & death_year!=2008 & death_year!=2004  & death_year!=2000
replace death_month_days = 31 if death_month==3
replace death_month_days = 30 if death_month==4
replace death_month_days = 31 if death_month==5
replace death_month_days = 30 if death_month==6
replace death_month_days = 31 if death_month==7
replace death_month_days = 31 if death_month==8
replace death_month_days = 30 if death_month==9
replace death_month_days = 31 if death_month==10
replace death_month_days = 30 if death_month==11
replace death_month_days = 31 if death_month==12

//Calculate Length of Life in days assuming born on 1st and Died on the last day of the month
gen length_of_life_max = deathday-birthday +death_month_days-1

// Calculate Length of Life assuming born on last day and died on last day of the month
gen length_of_life_min = deathday-birthday - birth_month_days+1

// Clean up a problem varibale
drop if length_of_life_1_1 <0

// Clean up the minimum. 
replace length_of_life_min = 0 if length_of_life_min <0

// Create Indicator for Age at Death
//Under 2
gen died_under_2_1_1 = 0
replace died_under_2_1_1 = 1 if length_of_life_1_1<731

gen died_under_2_max = 0
replace died_under_2_max = 1 if length_of_life_max<731

gen died_under_2_min = 0
replace died_under_2_min = 1 if length_of_life_min<731

//Under 1
gen died_under_1_1_1 = 0
replace died_under_1_1_1 = 1 if length_of_life_1_1<366

gen died_under_1_max = 0
replace died_under_1_max = 1 if length_of_life_max<366

gen died_under_1_min = 0
replace died_under_1_min = 1 if length_of_life_min<366

// Under 6mon
gen died_under_6mo_1_1 = 0
replace died_under_6mo_1_1 = 1 if length_of_life_1_1<187

gen died_under_6mo_max = 0
replace died_under_6mo_max = 1 if length_of_life_max<187

gen died_under_6mo_min = 0
replace died_under_6mo_min = 1 if length_of_life_min<187

//3mo
gen died_under_3mo_1_1 = 0
replace died_under_3mo_1_1 = 1 if length_of_life_1_1<94

gen died_under_3mo_max = 0
replace died_under_3mo_max = 1 if length_of_life_max<94

gen died_under_3mo_min = 0
replace died_under_3mo_min = 1 if length_of_life_min<94

//1mo
gen died_under_1mo_1_1 = 0
replace died_under_1mo_1_1 = 1 if length_of_life_1_1<32

gen died_under_1mo_max = 0
replace died_under_1mo_max = 1 if length_of_life_max<32

gen died_under_1mo_min = 0
replace died_under_1mo_min = 1 if length_of_life_min<32

//1day
gen died_under_1day_1_1 = 0
replace died_under_1day_1_1 = 1 if length_of_life_1_1<1

drop if max_elig_at_birth==0

drop if one_year_eligibile ==0 & died_under_1_1_1==0

gen months_of_life =length_of_life_1_1/30
replace months_of_life = round(months_of_life,1)
drop if months_of_life>months_of_eligibility & died_under_1_1_1==1

// Drop those with unknown death status who are not yet 1 at the end of the last year we have data
drop if max_year==birth_year & died_under_1_1_1==0 & birth_month!=1

// Drop those with unknown death status who are not yet 1 at the end of the last year we have data
drop if max_year==birth_year & died_under_1_1_1==0 & birth_month!=1

// Drop those whose death date is before their birthdate
*Note: There are 7 babies that meet this criteria
gen odd = 0
replace odd =1 if deathday<birthday
drop if odd==1


// Save Temp Baby File
save "$file_path_for_temp_results/baby_temp.dta", replace

*******************************************************************************
// Add Healthy Birth To this

// Fix duplicate ID Issues in Birth Flags 
use "$file_path_for_raw_data/File_3_Birth_Flags_Baby_Update.dta", clear
duplicates drop id, force
rename id baby_id
save "$file_path_for_temp_results/file_3_edit.dta", replace


// Use Temp Baby File
use "$file_path_for_temp_results/baby_temp.dta", clear

// Merge the birth flags data with the 
merge 1:1 baby_id using  "$file_path_for_temp_results/file_3_edit.dta"
keep if _merge==3

// Erase now redudant file
erase "$file_path_for_temp_results/file_3_edit.dta"

// Generate Health Birthweight Binary 
gen healthy_bw = 0
replace healthy_bw = 1 if birth_weight>=2500
replace healthy_bw = . if birth_weight<=0 

//Generate a indicator for each variable
*Not sure why this is in here
gen number_born_in_year= 1

// Generate categorical variable for ethnicity
gen ethnicity=0
replace ethnicity = 1 if ethnic_group=="C"
replace ethnicity = 2 if ethnic_group=="B"
replace ethnicity = 3 if ethnic_group=="H"
replace ethnicity = 4 if ethnic_group=="7"	
replace ethnicity = 5 if ethnicity==0

// Create a binary for each ethnicity
gen white = 0
replace white = 1 if ethnicity==1
gen black =0 
replace black =1 if ethnicity==2
gen hispanic =0
replace hispanic=1 if ethnicity==3
gen other = 0 
replace other =1 if ethnicity >2

// Create a mother is care source member binary as well
gen mom_member=0
replace mom_member=1 if !missing(mom_id)


// Create a Gender Binary
gen male = 0 
replace male = 1 if gender_code=="M"

// Binary for Died in first year
gen fdl = 1
replace fdl = 2 if died_under_1_1_1 ==1
replace fdl = 3 if  died_under_1_1_1==0

// Save Temp File
save "$file_path_for_temp_results/baby_row.dta", replace

*******************************************************************************
// Open Baby Case Management File
use "$file_path_for_raw_data/File_11_Baby_Cases_Flags.dta", clear

// Rename baby id for merge
rename id baby_id

// Generate case management variables (if ever involved)
bysort baby_id: egen ever_engaged=max(engaged)
bysort baby_id: egen ever_complete=max(care_plan)
bysort baby_id: egen ever_have_manager=max(care_manager)

gen length_of_case = case_close_date-case_open_date

replace length_of_case = 365 if length_of_case>365

// Keep only the first observation of each baby
bysort baby_id: gen order=_n
keep if order==1

// Keep only the new variables we've created
keep baby_id ever* length_of_case

// Merge back with temporary baby file
merge 1:1 baby_id using "$file_path_for_temp_results/baby_row.dta"

// Drop new merge variable
drop _merge

// Generate categorical engagement variable
replace ever_engaged = 2 if ever_engaged==0
replace ever_engaged = 3 if missing(ever_engaged)

// Correct binaries for other engagement variables
replace ever_complete = 0 if missing(ever_complete)
replace ever_have_manager = 0 if missing(ever_have_manager)

// Generae engagement binaries
gen engaged_1 = 0
replace engaged_1 =1 if ever_engaged==1
gen engaged_2 = 0
replace engaged_2 =1 if ever_engaged==2
gen engaged_3 = 0
replace engaged_3 =1 if ever_engaged==3

// Save new temp file
save "$file_path_for_temp_results/baby_row.dta", replace

*******************************************************************************
// Open Baby Month Flags Dataset
use "$file_path_for_raw_data/File_3a_Baby_Month_Flags.dta", clear

// Rename baby id
rename id baby_id

// Generate eligibility date
tostring eligibility_yr_mth, replace
gen current_date = date(eligibility_yr_mth,"YM")

// Drop Any Merge Variables
capture drop _merge

// Merge with temp file
merge m:1 baby_id  using "$file_path_for_temp_results/baby_row.dta"

// Generate days since birth
gen days_since_birth = current_date-birthday
bysort baby_id: egen max_days_since_birth_obs = max(days_since_birth)

// Generate Counts of events that are flagged by time frame
sort baby_id current_date

local x_list nicu nicu_days er_count ambulance_count ip_count inpatient_days ///
	outpatient_count  well_visit_count health_clinic_count

local time_list 1 32 94 187 386 731 
 
foreach x in `x_list' {
	foreach t in `time_list' {
		bysort baby_id: egen `x'_`t'_days = sum(`x') if days_since_birth <= `t'
		replace `x'_`t'_days = 0 if missing(`x'_`t'_days)
		replace `x'_`t'_days = . if days_since_birth<0 | `x'_`t'_days<0
	}
	drop `x'
}

//Keep only the first observation now that we've created a total variable
capture drop order
bysort baby_id: gen order = _n
keep if order==1

// Keep only what we need
drop order eligibility_yr_mth current_date
capture drop _merge
keep baby_id *_days max_days_*

// Merge This Again With Baby Row File
merge m:1 baby_id  using "$file_path_for_temp_results/baby_row.dta"

// Drop Merge indicator
drop _merge

// Save temp file
save "$file_path_for_temp_results/baby_row.dta", replace

******************************************************************************
// Add EDC/MEDC Cond Ever
use "$file_path_for_raw_data/File_5_Baby_EDC_MEDC_Cond_Final", clear

// Rename baby id
rename id baby_id

// Generate Ever Variable for all conditions
ds baby_id relation year, not
foreach x in `r(varlist)' {
	bysort baby_id: egen ever_`x' = max(`x')
	drop `x'
}

// Keep only the first observation
bysort baby_id: gen order = _n
keep if order==1

// Keep only what we need
keep baby_id ever_*

// Merge with baby row file
merge 1:1 baby_id using "$file_path_for_temp_results/baby_row.dta"

// Drop the merge variable
drop _merge

// Save baby annual file
save "$file_path_for_data_output/baby_file_by_birth_year.dta", replace

// Erase temp file
erase "$file_path_for_temp_results/baby_row.dta"



//Close log file
log close
*******************************************************************************

