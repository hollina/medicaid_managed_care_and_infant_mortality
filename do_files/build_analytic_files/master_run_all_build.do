/* /////////////////////////////////////////////////////////////////////////////
 Usage Notes: 
	1. The first time you run this program, set line 29 to one in order to 
		custom install stata files needed
	2. Set username on line 27
	3. In your home directory, you must have the following folder structure
		a. /vincent/a/username/care_source/do_files/
			i. /vincent/a/username/care_source/do_files/build_analytic_files
			ii./vincent/a/username/care_source/do_files/run_analysis
			ii./vincent/a/username/care_source/do_files/run_analysis
		b. /vincent/a/username/care_source/logs/
		c. /vincent/a/username/care_source/results/
		d. /vincent/a/username/care_source/stata/
		e. /vincent/a/username/care_source/temp/
		f. /vincent/a/username/care_source/data_for_analysis/
	4. Raw data is always kept in Ashley Kranz's folder
*/ /////////////////////////////////////////////////////////////////////////////

// Close any open log files
capture log close

// Clear Memorys
clear all

// Set Date
global date 21-June-2018

local username akranz // options are akranz; hollings

local install_stata_packages 1 // options are 0 (no) and 1 (yes)

//Set directory paths in vincent based on user
global file_path_for_raw_data "/vincent/a/akranz/From_CareSource05" 
global file_path_for_temp_results "/vincent/a/`username'/care_source/temp"
global file_path_for_results "/vincent/a/`username'/care_source/results"
global file_path_for_data_output "/vincent/a/`username'/care_source/data_for_analysis"
global file_path_for_do_files "/vincent/a/`username'/care_source/do_files/build_analytic_files"
global file_path_for_logs "/vincent/a/`username'/care_source/logs"

// Set a specific folder for storing custom stata programs
global file_path_for_stata "/vincent/a/`username'/care_source/stata"

// Download custom stata programs if needed

// Set Personal Path
net set ado "$file_path_for_stata"

// Install Packages if needed, if not, make a note of this
if `install_stata_packages'==1 {
	ssc install carryforward
	ssc install reghdfe
	ssc install sumup
	ssc install distinct
	ssc install missings
	ssc install estout
}
if `install_stata_packages'==0 {
	di "All packages up-to-date"
}

// Set font type
graph set window fontface "Helvetica"

// Set Graph Scheme
set scheme plotplainblind

// Allow the screen to move without having to click more
set more off

// Add Path to a directory that stata looks at for packages
adopath + "$file_path_for_stata"

// Create Baby File
do "$file_path_for_do_files/create_flat_file_baby.do"

// Create Mom File
do "$file_path_for_do_files/create_flat_file_mom.do"

// Combine the two and add community variables
do "$file_path_for_do_files/create_mom_baby_community_dataset.do"

