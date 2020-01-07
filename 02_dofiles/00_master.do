*******************************************************************************
** 	TITLE: 00_master.do
**
**	PURPOSE: Master do file
**				
**	AUTHOR: 
**
**	VERSION: 
**
**	NOTES:
*******************************************************************************
* 0. Setting directories and locals
* 1. Run do files


clear all
cap log close

version 14.2
set maxvar 10000
set more off
pause on



****************************************
*	0. Setting directories and locals  *
****************************************
*A. Run locals
*B. Working directories
*C. General locals for file
*D. User-written programs to the ado path
*E. User-written programs for the DMS
*F. Set seeds
*G. Set download macros


**A. Run locals
	loc import 			0 // turn to 1 if import and prep files should be run
	loc bc 				0 // turn to 1 if back check data do files should be run
	loc checks 			0 // turn to 1 if you want to run high-frequency and back checks
	loc download 		0 // turn to 1 if you want to download the data using surveycto_api

	*Working environemnt
	loc ipa_environ 	0 // turn to 0 if you do NOT want to use standard IPA working environemnt norms NOT RECOMMENDED
	loc stata_version 	15.0 // for use in ipa_environ set


**B. Install user-written commands
	*Set content directory relatively based on location of do file
	/*
		If you are using Boxcryptor, this directory should
		reference the Boxcryptor directory, not the Box Sync directory.
		Usually this filepath begins with "X:\" in Windows

		To check your username in Stata, run the following
		command from the command line:
			di "`c(username)'"
	*/
	if "`c(username)'" == "USERNAME" {
		loc cdloc = "FILEPATH"
	}

	else {
		loc cdloc = subinstr("`c(pwd)'", "\", "/" ,.)
		loc cdloc = subinstr("`cdloc'", "/02_dofiles/", "")
	}


**C. Globals
	*HFC globals 
	/* /!\ Do not edit /!\ */
	gl cwd 					"`cdloc'"
	gl dir_xls				"${cwd}/01_instruments/03_xls"
	gl dir_logs 			"${cwd}/02_dofiles/02_log"
	gl dir_ados 			"${cwd}/02_dofiles/01_ado"
	gl dir_do				"${cwd}/02_dofiles" 
	gl dir_track_inp		"${cwd}/03_tracking/01_inputs"
	gl dir_track_out		"${cwd}/03_tracking/02_outputs"
	gl dir_inp				"${cwd}/04_checks/01_inputs"	
	gl dir_out				"${cwd}/04_checks/02_outputs"
	gl dir_survey			"${cwd}/05_data/02_survey"
	gl dir_bc				"${cwd}/05_data/03_bc"
	gl dir_mon				"${cwd}/05_data/04_monitoring"
	gl dir_media			"${cwd}/06_media_encrypted/06_media"
	/* /!\ Do not edit /!\ */

	* project backup folder
	gl dir_backup 	""

	* variables to change to string
	gl strvars 		""

	* variables to destring
	gl numvars 		""

	* import globals from hfc_inputs -- adjust filename if hfc_inputs file renamed
	if $checks ipacheckimport using "${dir_inp}/hfc_inputs.xlsm"


**D. Add user-written programs
	*install packages to the project folder for version control
	net set ado "${dir_ados}"
	foreach package in PACKAGES {
		qui {
			loc letter = substr("`package'",1,1)
			cap conf file "${dir_ados}/`letter'/`package'.ado"
			if _rc == 601 ssc install `package'
		}
	}

	*Set stata ado preferneces to use ados downloaded for project files
	adopath++ "${dir_ados}"


**E. Add user written programs for HFCs
	qui{
		*install ipacheck, from("https://raw.githubusercontent.com/PovertyAction/high-frequency-checks/master/ado")	replace
		capture which ipacheck
		if _rc == 111 & `checks' == 1 {
			dis as err "Install ipacheck to run checks."
			error 111
		}
		// end if _rc == 111 & `checks' == 1

		*install bcstats, from("https://raw.githubusercontent.com/PovertyAction/bcstats/master/ado") replace			
		capture which ipabcstats
		if _rc == 111 & `bc' == 1 		dis as err "Install bcstats to run back checks."

		capture which surveycto_api 
		if _rc == 111 & `download' == 1 dis as err "Install surveycto_api to import data."
		
	}
	// end qui{


**F. Set up Stata enviornemnt
	set sortseed 	123456789 	
	set seed 		SEED 		// use random.org 1-9999999

	*Set other environment choices
	if `ipa_environ' ipadoheader, version(`stata_version')


**G. Download data using surveycto_api
	if `download' {
		*set locals of server settings
		local user ""
		local server ""
		local formid  ""
		local mediavars
		local url "https://`server'.surveycto.com/api/v1/forms/data/wide/csv"

		nois di _newline "Downloading form data:"

		surveycto_api `formid', ///
			server(`server') user(`user') ///
			csvpath("../05_data/02_survey/`formid'_WIDE.csv") ///
			mediapath("../06_media") media(`mediavars') replace
	}
	


***************************************
* 	01. Run do files				  *
***************************************
*A. Import survey SurveyCTO csv file into dta and add value/variable labels
*B. Import SurveyCTO back check csv file into dta and add value/variable labels
*C. Basic cleaning to prepare data for checks
*D.	Basic cleaning to prepare back check data for checks 
*E. Run high-frequency checks and back checks


**A. Import survey SurveyCTO csv file into dta and add value/variable labels
	/*
	**	PURPOSE: Load in raw survey data from SurveyCTO and include variable and 
				 value labels 
	**	INPUTS:	
	**			
	**	OUTPUTS: 			
	*/
	if `import' qui do "$dir_do/01_import.do"

		
**B. Import back check SurveyCTO csv file into dta and add value/variable labels (not done)
	/*
	**	PURPOSE: Load in raw survey data from SurveyCTO and include variable and 
				 value labels 
	**	INPUTS:	 
	**			
	**	OUTPUTS: 			
	*/

	if `bc' qui do "$dir_do/02_import_bc.do"	
	

**C. Basic cleaning to prepare data for checks
	/*
	**	PURPOSE: Add value labels for select_multiple questions, remove 
				 unnecessary variables and destring calculated variables
	**	INPUTS:	 
	**	OUTPUTS: 
	*/
	if `import' qui do "$dir_do/03_prep.do"


**D. Basic cleaning to prepare back check data for checks (not done)
	/*
	**	PURPOSE: Adjusted 02_prep for back check data to do cleaning before running back check analysis
	**	INPUTS:	 
	**	OUTPUTS: 
	*/

	if `bc' do "$dir_do/03_prep_bc.do"

	
**E. Run high-frequency checks and back checks
	/*
	**	PURPOSE: Run checks on data, make replacements
	**	INPUTS:	 
	**			 
	**	OUTPUTS: 			 
	*/
	if `checks' do "$dir_do/04_master_check.do"
	
	
**END**

