/* /////////////////////////////////////////////////////////////////////////////
 Usage Notes: 
	1. The first time you run this program, set line 28 to one in order to 
		custom install stata files needed
	2. Set username on line 27
	3. In your home directory, you must have the following folder structure
		a. /vincent/a/username/care_source/do_files/
			i. /vincent/a/username/care_source/do_files/build_analytic_files
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

// Clear Memory
clear all

// Set Date
global date 26-August-2019

local username akranz
local install_stata_packages 1

//Set directory paths in vincent based on user
global file_path_for_raw_data "/vincent/a/akranz/From_CareSource05" 
global file_path_for_temp_results "/vincent/a/`username'/care_source/temp"
global file_path_for_results "/vincent/a/`username'/care_source/results"
global file_path_for_data_output "/vincent/a/`username'/care_source/data_for_analysis"
global file_path_for_do_files "/vincent/a/`username'/care_source/do_files/run_analysis"
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
	ssc install binscatter
	ssc install distinct
	ssc install missings
	ssc install estout
	
	// Install format table command
	ssc install http://www.stata-journal.com/software/sj12-4/sg97_5.pkg, replace all

}
if `install_stata_packages'==0 {
	di "All packages up-to-date"
}

// Set font type
graph set window fontface "Times New Roman"

// Set Graph Scheme
set scheme plotplainblind

// Allow the screen to move without having to click more
set more off

// Add Path to a directory that stata looks at for packages
adopath + "$file_path_for_stata"

// Create tables and coef plot of main results for jama submission
do "$file_path_for_do_files/analysis.do"
