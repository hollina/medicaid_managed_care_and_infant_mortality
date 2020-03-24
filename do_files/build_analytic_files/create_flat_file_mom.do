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
local pgm creat_flat_file_mom
local dt $date
local task create an analytic file for moms using the raw CareSource Data. The output file will have one row per mom
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

*******************************************************************************
// Open annual mother file
use "$file_path_for_raw_data/File_4_Mom_Ind_by_Year.dta", clear

// Destring Year and rename to child birth year for future merge compatibility
destring year, replace
rename year birth_year

// Rename ID mom_id for future merge compatibility
rename id mom_id

// Create a numeric mother id and another numeric id for each birth
egen numeric_id = group(mom_id)
egen group_id = group(numeric_id birth_year)

//Drop duplicates
gsort mom_id -multiple_birth_ind 
duplicates drop group_id, force 

// Make sure that data are set as panel data
xtset numeric_id birth_year
drop group_id

// Make a list of mother conditions of interest
global list_to_loop drug_poisoning opioid_overdose heroin_overdose opioid_use ///
	mat_indicator opiate_user_ind serious_mental_illness ///
	substance_abuse_ind behavioral_health_ind

// Generate An indicator if condition present before birthyear for specified issues

// First sort data or it may not work correctly
sort numeric_id birth_year

// Loop through for indicator
foreach x in $list_to_loop  {
	bysort numeric_id: egen ever_`x' =  max(`x')
	gen lag_`x' = L.`x'
}

// Rename mother id, year, and drop any mention of merge for merge compatibility
rename mom_id id
rename birth_year year
capture drop _merge

// Save as a temp file 
save "$file_path_for_temp_results/mom_temp.dta", replace

*******************************************************************************
//Open Serious Conditions Files
use "$file_path_for_raw_data/File_6_Mom_EDC_MEDC_Cond_Final.dta", clear

// Destring year
destring year, replace

// Create numeric group id
egen group_id = group(id year)

// Drop duplicates

duplicates drop group_id, force
drop group_id

// Merge with previous temp file
merge 1:1 id year using "$file_path_for_temp_results/mom_temp.dta"

// Drop merge variable
capture drop _merge

// Save as a temp file 
save "$file_path_for_temp_results/mom_temp.dta", replace

*******************************************************************************
// Open Mother Member file (should be one row per mom)
use "$file_path_for_raw_data/File_2_Mom_member.dta"

// Drop duplicates
duplicates drop id year, force

// Make a list of mother variables of interest
keep id year birth_year_month death_year_month months_of_eligibility ///
	line_of_business ethnic_group zip_id county_id census_tract_id ///
	address_count homeless

// Destring year
destring year, replace

// Calculate Age
tostring birth_year_month, gen(string_year)
replace string_year = substr(string_year,1,4)
destring string_year, replace
gen age = year-string_year
drop string_year

// Create Categorical Ethnicity Variable
gen ethnicity = 0
replace ethnicity = 1 if ethnic_group=="C"
replace ethnicity = 2 if ethnic_group=="B"
replace ethnicity = 3 if ethnic_group=="H"
replace ethnicity = 4 if ethnic_group=="7"
replace ethnicity = 5 if ethnicity==0

// Create Ethnicity Binaries
gen white = 0
replace white = 1 if ethnicity==1
gen black =0 
replace black =1 if ethnicity==2
gen hispanic =0
replace hispanic=1 if ethnicity==3
gen other = 0 
replace other =1 if ethnicity >2

// Merge with previous temp file
merge 1:1 id year using "$file_path_for_temp_results/mom_temp.dta"

// Drop merge variable
capture drop _merge

// Save as a temp file 
save "$file_path_for_temp_results/mom_temp.dta", replace

*******************************************************************************
// Open mother case files
use "$file_path_for_raw_data/File_8_Mom_Cases_Flags.dta", clear

// Generate length of case
gen length_of_case = (case_close_date-case_open_date)

// Censor Case Lengths at 365
replace length_of_case = 365 if length_of_case>365

// Collapse into an annual file
collapse (sum) length_of_case (max) engaged care_plan care_manager, by(id year)

// Destring year
destring year, replace

//merge with mom data
merge 1:m id year using "$file_path_for_temp_results/mom_temp.dta"

// Drop merge variable
drop _merge

// Turn engaged into a categorical case management engagement variable
replace engaged = 2 if engaged==0
replace engaged = 3 if missing(engaged)

// Create correct binaries for other case management engagement variables
replace care_plan = 0 if missing(care_plan)
replace care_manager= 0 if missing(care_manager)


// Generae engagement binaries
gen engaged_1 = 0
replace engaged_1 =1 if engaged==1
gen engaged_2 = 0
replace engaged_2 =1 if engaged==2
gen engaged_3 = 0
replace engaged_3 =1 if engaged==3

// Set up for merge with baby files
rename year birth_year

// This is not needed as they are always mothers
drop relation

// Add a prefix to each variable so we know it is from mothers
ds birth_year, not
foreach x in `r(varlist)'{
	rename `x' mom_`x'
}

// Save mother annual file
save "$file_path_for_data_output/mom_file_by_birth_year.dta", replace

// Erase temp file
erase "$file_path_for_temp_results/mom_temp.dta"

//Close log file
log close
*******************************************************************************



