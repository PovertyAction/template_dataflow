********************************************************************************
** 	TITLE: 02_globals.do
**
**	PURPOSE: Specify globals for files, folders and variables
**				
**	AUTHOR: 
**
**	CREATED: 
********************************************************************************


* project backup folder
gl dir_backup ""

* gl Directories: DO NOT EDIT

gl dir_xls				"$cwd/01_instruments/03_xls"
gl dir_do				"$cwd/02_dofiles" 
gl dir_inp				"$cwd/04_checks/01_inputs"	
gl dir_out				"$cwd/04_checks/02_outputs"
gl dir_track_inp		"$cwd/03_tracking/01_inputs"
gl dir_track_out		"$cwd/03_tracking/02_outputs"
gl dir_survey			"$cwd/05_data/02_survey"
gl dir_bc				"$cwd/05_data/03_bc"
gl dir_mon				"$cwd/05_data/04_monitoring"
gl dir_media			"$cwd/06_media_encrypted/06_media"


* variables to change to string
gl strvars 		""

* variables to destring
gl numvars 		""

* import globals from hfc_inputs -- adjust filename if hfc_inputs file renamed
if $checks ipacheckimport using "$dir_inp/hfc_inputs.xlsm"
