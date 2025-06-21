*! version 1.7.1  21jun2025 Gunther Bensch
* remember to also keep -local repframe_vs- updated at the beginning of PART 1

/*
*** PURPOSE:	
	This Stata do-file contains the program repframe to calculate, tabulate and visualize Reproducibility and Replicability Indicators based on multiverse analyses.
	repframe requires version 14.0 of Stata or newer.

	
*** OUTLINE:	PART 1.  INITIATE PROGRAM REPFRAME
			
				PART 2.  OPTIONS, AUXILIARY VARIABLE GENERATION, AND MAIN LOCALS

				PART 3.  INDICATOR DEFINITIONS BY RESULT/ STUDY AND ACROSS RESULTS/ STUDIES
						 incl. 3.B COEFFICIENT AND CONTRIBUTION PLOTS
				
				PART 4.  INDICATOR DATASET AT STUDY LEVEL
				
				PART 5.  ROBUSTNESS DASHBOARD VISUALIZATION
				
				PART 6.  COMPILE REPRODUCIBILITY AND REPLICABILITY INDICATORS

					
***  AUTHOR:	Gunther Bensch, RWI - Leibniz Institute for Economic Research, gunther.bensch@rwi-essen.de



*** Syntax components used in the following
	_all  - across results (studies)
	_d    - dummy variable
	_i    - level of individual analysis paths
	_j    - result (study) level
	_k    - study (across study) level 
	_N    - running number
	_N	  - total number
	_orig - original study
	atF	  - any F-related adjustment, i.e. tF or VtF
	iva   - weak-IV adjusted 
	oa    - original analyis OR original author(s)
	osig  - significant in original study
	onsig - insignificant in original study
	ra    - reproducibility or replicability analysis
	RF    - Reproducibility and replicability Framework indicators
	rslt  - result level
	stud  - study level
	tF	  - Lee at al. (2022, AER) tF adjustment
	vrd   - varied
	vrt   - variation
	VtF   - Lee at al. (2023, WP) VtF adjustment
	x_    - temporary variables, dropped after sections
	x2_   - temporary variables, shorter-term, dropped within loops, for example 
*/	




********************************************************************************
*****  PART 1  INITIATE PROGRAM REPFRAME
********************************************************************************


cap prog drop repframe
prog def repframe, sortpreserve


#delimit ;
	
syntax varlist(numeric max=1) [if] [in], 
[ 
beta(varname numeric)  siglevel(numlist max=1 integer >=0 <=100) siglevel_orig(numlist max=1 integer >=0 <=100)  origpath(varname numeric) shortref(string) 
se(varname numeric)  pval(varname numeric)  zscore(varname numeric) 
STUDYPOOLing(numlist max=1 integer >=0 <=1) decisions(varlist)
df(varname numeric)  mean(varname numeric)  sameunits(varname numeric) 
filepath(string) FILEIDentifier(string)  IVARWeight(numlist max=1 integer >=0 <=1)  orig_in_multiverse(varname numeric)  prefpath(varname numeric) 
tabfmt(string)  shelvedind(numlist max=1 integer >=0 <=1) 
beta2(varname numeric)  se2(varname numeric)  pval2(varname numeric)  zscore2(varname numeric) 
DASHboard(numlist max=1 integer >=0 <=1)  vshortref_orig(string)  customindicators(string) aggregation(numlist max=1 integer >=0 <=1)  graphfmt(string) tFinput(string asis) pval_ar(varname numeric) signfirst(varname numeric)
];

#delimit cr


qui {

*** Record the version of the repframe package
	local repframe_vs  "version 1.7.1  21jun2025"

*** Preserve initial dataset 
	tempfile inputdata   // -tempfile- used instead of command -preserve- because -repframe- would require multiple -preserve- (which is not possible) as different datasets will be used for the table of Indicators and for the Robustness Dashboard
	save `inputdata'
	
*** Syntax components that have to be defined early on in PART 1
	if "`dashboard'"=="" {
		local dashboard = 1
	}
	if "`studypooling'"=="" {
		local studypooling = 0 
	}
	
	if "`tFinput'"!="" & `studypooling'==0 {		
		// split the tFinput for -keep- command below ...
		// (1) retrieve the information whether the input relates to the tF or VtF adjustment
		local ivadjust: word 1 of `tFinput'
		// (2) retrieve the name of the variable that contains either the first-stage F-Stat (tF) or the VtF critical value (VtF) 
		local atFvar : word 2 of `tFinput'   	

		if "`atFvar'"=="" {
			noi dis "{red: Option {opt tFinput()} must specify two parameters: (1) whether the input relates to the tF or VtF adjustment, and (2) the first-stage F-Stat (tF) or the VtF critical value (VtF) (e.g., {opt tFinput(VtF VtF_critval)}).}"
			use `inputdata', clear
			exit
		}
	}

*** Install user-written packages from SSC, mainly required for the Robustness Dashboard
	capture which labmask
	if _rc == 111 {                 
		noi dis as text "Installing labutil"
		ssc install labutil, replace
	}
	
	if `dashboard'==1 {
		capture which colrspace.sthlp 
		if _rc == 111 {                 
			noi dis as text "Installing colrspace"
			ssc install colrspace, replace
		}
		capture which colorpalette
		if _rc == 111 {                 
			noi dis as text "Installing palettes"
			ssc install palettes, replace
		}
		capture which schemepack.sthlp
		if _rc == 111 {                 
			noi dis as text "Installing schemepack"
			ssc install schemepack, replace
		}
	}

	if "`decisions'"!="" {	
		capture which labren
		if _rc == 111 {                 
			noi dis as text "Installing labutil2"
			ssc install labutil2, replace
		}
	
		capture which coefplot
		if _rc == 111 {                 
			noi dis as text "Installing coefplot"
			ssc install coefplot, replace
		}	
	}
	
*** Implement [if] and [in] condition
	marksample to_use
	keep if `to_use' == 1
  
*** Keep required variables and check for missings
	if `studypooling'==0 {
		keep              `varlist' `beta'   `origpath'   `se' `pval' `zscore'   `decisions'   `df' `mean'   `sameunits'   `orig_in_multiverse'   `prefpath'   `beta2' `se2' `pval2' `zscore2'  `atFvar' `pval_ar' `signfirst' 

		noi misstable sum `varlist' `beta'   `origpath'   `se' `pval' `zscore'   `decisions'   `df' `mean'   `sameunits'   `orig_in_multiverse'   `prefpath'   `beta2' `se2' `pval2' `zscore2'  `atFvar' `pval_ar' `signfirst'
		if `r(N_eq_dot)'!=. | `r(N_gt_dot)'!=. {
			noi dis as text _newline(1) "The table above shows missing values in the data. The dataset should not contain these missings to ensure that the indicators are calculated correctly."
		}
	}
	// if studypooling==1: the repframe command creates datasets as input to studypooling==1 that are already tailored to the set of required variables
		
	



********************************************************************************
*****  PART 2  OPTIONS, AUXILIARY VARIABLE GENERATION, AND MAIN LOCALS
********************************************************************************			

************************************************************
***  PART 2.A  MAINVAR AND COMMAND OPTIONS
************************************************************

*** mainvar
	decode `varlist', gen(mainvar_str)
	egen mainvar = group(`varlist')
	labmask mainvar, values(mainvar_str)  	// make sure that mainvar is numbered consecutively
	drop `varlist'
	order mainvar mainvar_str				// mainvar will also be required in string format in the dashboard

	qui tab mainvar 
	local N_results = `r(r)'

*** Option studypooling
	// already defined early on in PART 1
	// additionally check options that are not compatible with studypooling==1 
	foreach option in beta origpath   se pval zscore   decisions   df mean sameunits   orig_in_multiverse prefpath   beta2 se2 pval2 zscore2   pval_ar {
		if `studypooling'==1 & "``option''"!="" {
			noi dis as text "-repframe- ignores the input to the option {opt `option'()} when {opt studypooling(1)} is specified, because {opt `option'()} requires input data at the level of individual analysis paths, whereas {opt studypooling(1)} requires study-level input data."
		}
	}
	// -repframe- returns more specific error messages for other options that are not compatible with studypooling==1, namely siglevel, siglevel_orig, shortref, ivarweight, vshortref_orig, tFinput, and aggregation. 
	// accordingly, parameters allowed to be used with studypooling are filepath, fileidentifier, tabfmt, dashboard, customindicators, and graphfmt as well as shelvedind and signfirst.

*** Options beta, se, pval, zscore (& df), origpath, shortref
	if `studypooling'==0 {	
		if "`beta'"=="" & "`shortref'"=="" { 
			noi dis "{red: Unless {opt studypooling(1)} is specified, both {opt beta()} and {opt shortref()} has to be specified.}"	
			use `inputdata', clear
			exit
		}			
		if "`beta'"=="" { 
			noi dis "{red: Unless {opt studypooling(1)} is specified, {opt beta()} has to be specified.}"
			use `inputdata', clear
			exit	
		}

		if "`origpath'"=="" { 
			noi dis "{red: Unless {opt studypooling(1)} is specified, {opt origpath()} has to be specified.}"	
			use `inputdata', clear
			exit
		}
		else {
			gen origpath_i        =  `origpath'	
			drop `origpath'
					
			local origpaths_notone = 0
			forval rsltvar = 1/`N_results' {
				 gen x2_origpaths_rslt_d  = (origpath_i==1 & mainvar==`rsltvar')
				egen x2_origpaths_rslt_N = total(x2_origpaths_rslt_d)
				if x2_origpaths_rslt_N!=1 {
					local origpaths_notone = `origpaths_notone' + 1
				}
				drop x2_*
			}
			if  `origpaths_notone' > 0 {
				noi dis "{red: Please include one, and only one original path per result via {opt origpath()}. This is not yet the case for a total of `origpaths_notone' results.}"
				use `inputdata', clear
				exit
			}
		}

		if "`shortref'"=="" { 
			noi dis "{red: Unless {opt studypooling(1)} is specified, {opt shortref()} has to be specified.}"	
			use `inputdata', clear
			exit
		}

		** variables required in options that account for the two-coefficient case below
		gen beta_dir_i      = (`beta'>=0)
		recode beta_dir_i (0 = -1)
		if "`beta2'"!="" {
			gen beta2_dir_i     = (`beta2'>=0)
			recode beta2_dir_i (0 = -1)
		}    
		else {
			gen beta2_dir_i     = .
		}
	
		if ("`se'"=="" | "`pval'"=="") {
			noi dis as text _newline(1) "It is recommended to specify both {opt se()} and {opt pval()}. The command {cmd:repframe} otherwise determines the non-specified variables based on the {it:t}-test formula assuming normality, which may not be appropriate in all cases, e.g. when having few degrees of freedom because {opt svy:} is used in the original estimations."
		}

		if "`se'"=="" & "`zscore'"=="" & "`df'"=="" {
			noi dis as text "{opt pval()} is specified. Note that it is assumed that these p-values are derived from two-sided t-tests."
			gen     se_i   	= abs(`beta'/invnormal(`pval'/2))	
		}
		if "`se'"=="" & "`zscore'"=="" & "`df'"!="" {
			gen     se_i   	= abs(`beta'/invt(`df', `pval'/2))
		}
		if "`se'"=="" & "`zscore'"!="" {
			gen     se_i   	= `beta'/`zscore'			
		}
		if "`se'"!="" {
			gen se_i        =  `se'	
			drop `se'
		}	

		if "`zscore'"=="" {
			gen zscore_i        = `beta'/se_i
		}
		else {
			gen zscore_i        = `zscore'
			drop `zscore'
		}
		
		if "`pval'"=="" {
			local pval_provided = 0
			if "`df'"=="" {
				gen pval_i = 2*(1 - normal(abs(`beta'/se_i)))
			}
			if "`df'"!="" {	
				gen pval_i = 2*ttail(`df', abs(`beta'/se_i))
			}
		}
		else {
			local pval_provided = 1
			gen pval_i = `pval'
			drop `pval'
		}
	}
	else {
		local pval_provided = .
	}
	if `studypooling'==1 & "`shortref'"!="" { 
		noi dis "{red: If {opt studypooling(1)} is specified, {opt shortref()} will be retrieved from the input data so that ({opt shortref()}) is not meant to be used together with option {opt studypooling(1)}.}"	
		use `inputdata', clear
		exit
	}

*** Options siglevel, siglevel_orig
	if `studypooling'==1 {
		if "`siglevel'"!="" | "`siglevel_orig'"!="" {
			noi dis "{red: If {opt studypooling(1)}, significance levels will be retrieved from the input data so that ({opt siglevel()}) and ({opt siglevel_orig()}) are not meant to be used together with option {opt studypooling(1)}.}"
			use `inputdata', clear
			exit
		}
		foreach set in oa ra { 
			sum siglevel_`set'_stud
			if (`r(min)'==`r(max)') {
				local signum_`set' = `r(min)'
			} 
			if (`r(min)'!=`r(max)') {
				local signum_`set' = 999      
			}
		}
	}
	else {
		if "`siglevel'"=="" & "`siglevel_orig'"=="" { 
			noi dis "{red: Unless {opt studypooling(1)} is specified, both {opt siglevel()} and {opt siglevel_orig()} has to be specified.}"	
			use `inputdata', clear
			exit
		}			
			
		if "`siglevel'"=="" { 
			noi dis "{red: Unless {opt studypooling(1)} is specified, {opt siglevel()} has to be specified.}"	
			use `inputdata', clear
			exit
		}		
		else {
			local signum_ra = "`siglevel'"
		}
		
		if "`siglevel_orig'"=="" { 
			noi dis "{red: Unless {opt studypooling(1)} is specified, {opt siglevel_orig()} has to be specified. If the orginal study does not specify any significance level, it is recommended to set {opt siglevel_orig()} equal to {opt siglevel()}.}"	
			use `inputdata', clear
			exit
		}
		else {
			local signum_oa = "`siglevel_orig'"
		}
	}
	if `signum_ra'<10 {
		local sigdigits_ra 0`signum_ra'
	}
	if `signum_ra'<1 {
		noi dis "{red: Please specify a significance level ({opt siglevel()}) above 1 (i.e. above the 1% level).}"	
		use `inputdata', clear
		exit
	}
	if `signum_ra'>=10 {
		local sigdigits_ra `signum_ra'
	}

	if `signum_oa'<10 {
		local sigdigits_oa 0`signum_oa'
	}
	if `signum_oa'>=10 {
		local sigdigits_oa `signum_oa'
	}

*** Option decisions
	if `studypooling'==0 & "`decisions'"!="" {		
		duplicates tag mainvar `decisions', generate(x_anapaths_dupl)
		egen x_anapaths_dupl_max = max(x_anapaths_dupl)
		if x_anapaths_dupl_max>0 {
			noi dis "{red: Please revise the input dataset so that each analysis path defined by the combination of {it:mainvar} and the variables included in {opt decisions()} is only included once.}"
			use `inputdata', clear
			exit	
		}

		local d = 1
		local dvar_labmissings = 0
		local ch = 1
		local chval_orig_nonzeros = 0
		local chval_labmissings = 0
		foreach dvar of local decisions {
			clonevar decision_`d'x = `dvar'	// generate consecutively numbered decision variables
			capture label list `dvar'
			if _rc == 111 {
				noi dis "{red: When labelling the choices of {it:`dvar'}, please also call the label {it:`dvar'}, i.e. -label define {it:`dvar'} ...- before running the {it:repframe} command.}"
				use `inputdata', clear
				exit
			}
			labren `dvar' decision_`d'

			local decision_`d'_name: variable label `dvar'
			if "`decision_`d'_name'"=="" {
				local dvar_labmissings = `dvar_labmissings' + 1
			}
			
			gen decision_`d'_name = "`decision_`d'_name'"

			forval rsltvar = 1/`N_results' {
				gen x2_chval_orig_nonzero_d  = (origpath_i==1 & `dvar'!=0 & mainvar==`rsltvar')
				egen x2_chval_orig_nonzero = max(x2_chval_orig_nonzero_d)
				if x2_chval_orig_nonzero==1 {
					local chval_orig_nonzeros = `chval_orig_nonzeros' + 1			// count of original specification decisions that do not carry the value zero
				}
				drop x2_*
			}
			
			levelsof `dvar', local(dvar_val)
			foreach chval of local dvar_val {
				local chval_lab: label (`dvar') `chval', strict		// retrieve label value in order to check whether value is labelled
				if missing(`"`chval_lab'"') {
					local chval_labmissings = `chval_labmissings' + 1
				}
				gen decision_`d'_ch`chval' = "`chval_lab'"
				local ch = `ch' + 1
			}
			local d = `d' + 1
		}
		local d_count  = `d' - 1   // # of decision variables; required below
		local ch_count = `ch' - 1  // # of individual decision choice values; required below

		if  `dvar_labmissings' > 0 {
			noi dis "{red: Please label all variables included in {opt decisions()} before running the {it:repframe} command. This is not yet the case for a total of `dvar_labmissings' decision variables.}"
			use `inputdata', clear
			exit
		}

		if  `chval_orig_nonzeros' > 0 {
			noi dis "{red: Please define the values of all variables included in {opt decisions()} in a way that the choices in the original specification, the observation with {it:origpathvariable==1}, are all set to zero as the reference case. This is not yet the case for a total of `chval_orig_nonzeros' decision variables.}"
			use `inputdata', clear
			exit
		}
		if  `chval_labmissings' > 0 {
			noi dis "{red: Please label the variables included in {opt decisions()} before running the {it:repframe} command. A total of `chval_labmissings' values are not labelled.}"
			use `inputdata', clear
			exit
		}
		drop `decisions'
	}

*** Option sameunits
	if `studypooling'==0 {	
		if "`sameunits'"=="" {
			gen sameunits_i = 1
		}
		else {
			gen sameunits_i = `sameunits'
			drop `sameunits'
		}
	}

*** Options filepath, fileidentifier
	if "`filepath'"=="" {
		if c(os)=="Windows" {
			local filepath "C:/Users/`c(username)'/Downloads" 
		}
		else {
			local filepath "~/Downloads"
		}
	}
	
	if "`fileidentifier'"=="" {
		local fileidentifier = string( d(`c(current_date)'), "%dCY-N-D" )
	}
	
*** Options ivarweight, mean, orig_in_multiverse, prefpath
	if `studypooling'==1 {
		if "`ivarweight'"=="1" {
			noi dis "{red: The option {opt ivarweight(1)} cannot be used together with the option {opt studypooling(1)}. The input data should instead include a variable {it:ivarweight_stud_d} containing information on inverse variance weighting at study level.}"
			use `inputdata', clear
			exit
		}
		local ivarweight = 0 
	}
	else {
		if "`ivarweight'"=="" {
			local ivarweight = 0
		}
		if `ivarweight'==1 & "`mean'"=="" {
			noi dis "{red: The option {opt ivarweight(1)} requires that the option {opt mean()} is also defined.}"
			use `inputdata', clear
			exit
		}

		if "`orig_in_multiverse'"=="" {
			gen orig_in_multiverse_i = 0
			noi dis as text "Note that, because the option {opt orig_in_multiverse()} was not specified, the {it:repframe} command adopts for all results the default of 0 (=original specification is not included in multiverse analysis)."
		}
		else {
			gen orig_in_multiverse_i = `orig_in_multiverse'
			drop `orig_in_multiverse'
		}

		if "`prefpath'"!="" { 
			if "`mean'"=="" {
				noi dis "{red: The option {opt prefpath()} requires that the option {opt mean()} is also defined, since the coefficient plot using the information from {opt prefpath()} standardizes coefficients based on {opt mean()}.}"
				use `inputdata', clear
				exit
			}

			// prefpath_i is only created if `prefpath' is defined 
			gen prefpath_i        =  `prefpath'	
			drop `prefpath'
					
			local prefpaths_notone = 0
			forval rsltvar = 1/`N_results' {
				 gen x2_prefpaths_rslt_d  = (prefpath_i==1 & mainvar==`rsltvar')
				egen x2_prefpaths_rslt_N = total(x2_prefpaths_rslt_d)
				if x2_prefpaths_rslt_N!=1 {
					local prefpaths_notone = `prefpaths_notone' + 1
				}
				drop x2_*
			}
			if  `prefpaths_notone' > 0 {
				noi dis "{red: Please include one, and only one preferred path per result via {opt prefpath()}. This is not yet the case for a total of `prefpaths_notone' results.}"
				use `inputdata', clear
				exit
			}	
		}

		if "`mean'"!="" {
			gen mean_j = `mean'
			drop `mean'
		}
		else {
			gen mean_j = .
		}
	}

*** Options tabfmt and shelvedind  
	if ("`tabfmt'"!="" & "`tabfmt'"!="csv" & "`tabfmt'"!="xlsx") {
		noi dis "{red: If {opt tabfmt()} is defined, it needs to take on the string csv or xlsx.}"	
		use `inputdata', clear
		exit
	}
	if "`tabfmt'"=="" {
		local tabfmt "csv"
	}

	if "`shelvedind'"=="" {
		local shelvedind = 0
	}

*** Options beta2, se2, se2_orig, pval2, pval2_orig, zscore2, zscore2_orig
	if `studypooling'==0 {
		if ("`beta2'"!="" & ("`se2'"=="" & "`pval2'"=="" & "`zscore2'"=="")) {
			noi dis "{red: If {opt beta2()} is specified, please also specify either {opt se2()}, {opt pval2()}, or {opt zscore2()}.}"	
			use `inputdata', clear
			exit
		}	
		
		if "`se2'"=="" & "`zscore2'"=="" & "`df'"=="" & "`beta2'"!="" & "`pval2'"!="" {
			gen     se2_i   = abs(`beta2'/invnormal(`pval2'/2))	
		}
		if "`se2'"=="" & "`zscore2'"=="" & "`df'"!="" & "`beta2'"!="" & "`pval2'"!="" {
			gen     se2_i   = abs(`beta2'/invt(`df', `pval2'/2))
		}
		if "`se2'"=="" & "`zscore2'"!="" {
			gen     se2_i   = `beta2'/`zscore2'			
		}
		if "`se2'"!="" {
			gen se2_i       =  `se2'	
			drop `se2'
		}	
		if "`beta2'"!="" {
			if "`zscore2'"=="" {
				gen zscore2_i     = `beta2'/se2_i
			}
			if "`zscore2'"!="" {
				gen zscore2_i     = `zscore2'
				drop `zscore2'
			}
			// further variable transformation below after _orig variables are generated
		}
				
		if "`pval2'"!="" {
			gen pval2_i = `pval2'
			drop `pval2'
		}
		else {
			if "`beta2'"!="" {
				if "`df'"=="" { 
					gen pval2_i = 2*(1 - normal(abs(`beta2'/se2_i)))
				}
				if "`df'"!="" {	
					gen pval2_i = 2*ttail(`df', abs(`beta2'/se2_i))
				}
			}
			else {
				gen pval2_i = .   	// pval2_i and beta2_i are generated irrespective of whether a second coefficient is included, both are used under PART 3.A
			}
		}
				
		if "`beta2'"!="" {
			gen beta2_i = `beta2'
			drop `beta2'
		}
		else {
			gen beta2_i = .			// beta2_i and pval2_i are generated irrespective of whether a second coefficient is included, both are used under PART 3.A
		}

*** Option dashboard
		if beta2_i!=. {
			local dashboard = 0
			noi dis as text "If {opt beta2()} is specified, no Robustness Dashboard is prepared."	
		}
	}
 
*** Options vshortref_orig, customindicators, aggregation, graphfmt, tFinput, pval_ar, signfirst
	// check options that are not meant to be used with dashboard==0
	foreach option in vshortref_orig customindicators aggregation graphfmt tFinput pval_ar signfirst {
		if `dashboard'==0 & "``option''"!="" {
			noi dis as text "-repframe- ignores the input to the option {opt `option'()} when {opt dashboard(0)} is specified, because {opt `option'()} is only used to generate the Robustnes Dashboard."
		}
	}
	if "`tFinput'"!="" & `studypooling'==1 {
		noi dis as text "-repframe- ignores the input to the option {opt tFinput()} when {opt studypooling(1)} is specified, because this input is only used to generate the Robustness Dashboard. When {opt studypooling(1)} is selected, the dashboard is limited to using Anderson–Rubin p-values as a weak-IV-robust adjustment method (see {opt pval_ar()})."
	}

	if `dashboard'==1 {
		if "`vshortref_orig'"!="" {
			local ytitle_row0 `vshortref_orig'
		}
		else {
			local ytitle_row0 "original estimate"			
		}

		if ("`customindicators'"!="" & "`customindicators'"!="default" & "`customindicators'"!="SIGagronly" & "`customindicators'"!="SIGswitch") {
			noi dis "{red: If {opt customindicators()} is defined, it needs to take on either -default-, -SIGagronly- or -SIGswitch-.}"	
			use `inputdata', clear
			exit
		}
		if "`customindicators'"=="" {
			local customindicators "default"
		}
			
		if "`aggregation'"=="1" & `studypooling'==0 & `N_results'==1 {
			noi dis as text "The option {opt aggregation(1)} is not meant to be used with only one result and is therefore replaced by {opt aggregation(0)}."
			local aggregation = 0	
		}
		if "`aggregation'"=="" & `studypooling'==0 {
			local aggregation = 0
		}
		if `studypooling'==1 {
			if "`aggregation'"=="0" { 
				noi dis as text "The option {opt aggregation(0)} is not meant to be used together with the option {opt studypooling(1)} and is therefore replaced by {opt aggregation(1)}. Use the option {opt aggregation(1)} at the study level."	
			}
			local aggregation = 1

			if "`vshortref_orig'"!="" {
				noi dis as text "The option {opt vshortref_orig()} is only considered for {opt aggregation(0)}, which is not meant to be used together with the option {opt studypooling(1)}. It is therefore not considered."	
			}
		}

		if "`graphfmt'"=="" {
			if c(os)=="Windows" {
				local graphfmt emf
			}
			else {
				local graphfmt tif
			}
		}

		if "`ivadjust'"=="tf" {
			local ivadjust "tF"
		}
		if "`ivadjust'"=="vtf" {
			local ivadjust "VtF"
		}
		if "`ivadjust'"=="VtF" {
			noi dis as text "If {opt tFinput(VtF [varname])} is selected, the Robustness Dashboard expects that [varname], i.e. the variable with the VtF critical value, is derived at the 5% (1%) significance level if the significance level applied to robustness tests, {opt siglevel()}, is above 1% (equal to 1%)."	
		}

		if "`tFinput'"!="" & "`ivadjust'"!="0" & "`ivadjust'"!="tF" & "`ivadjust'"!="VtF" {
			noi dis "{red: The first parameter for the option {opt tFinput()} must be either tF or VtF (spelling them tf or vtf is also allowed).}"
			use `inputdata', clear
			exit	
		}

		if "`tFinput'"=="" & "`pval_ar'"=="" & `studypooling'==0 {
			local ivadjust 0
		}
		// see also above for "`tFinput'"!="" & `studypooling'==0, which had to be processed already in PART 1 by splitting it into VtFvar and VtFlevel
		if "`tFinput'"!=""  & "`pval_ar'"!="" & `studypooling'==0 {
			noi dis "{red: Choose either the option {opt tFinput()} or the option {opt pval_ar()} as weak-IV-robust adjustment method. Both should not be specified simultaneously.}"
			use `inputdata', clear
			exit
		}
		
 		if "`pval_ar'"!="" & `studypooling'==0 {
			local ivadjust AR

			gen pval_ar_i = `pval_ar'
			drop `pval_ar'
		}

		if "`pval_ar'"=="" & `studypooling'==1 {
			capture confirm variable RF2_SIGagr_05iva_osig_ra_all, exact   // check if variable is part of dataset across studies 
			if !_rc {
				local ivadjust AR
			}
			else {
				local ivadjust 0
			}
			capture confirm variable RF2_SIGagr_01iva_osig_ra_all, exact   // check if variable is part of dataset across studies 
			if !_rc {
				local ivadjust AR
			}
		}
		
		** tF Standard Error Adjustment presented in Robustness Dashboard - based on lookup Table from Lee et al. (2022)
		if "`ivadjust'"=="tF" & `studypooling'==0 {		
			matrix tF_c05 = (4,4.008,4.015,4.023,4.031,4.04,4.049,4.059,4.068,4.079,4.09,4.101,4.113,4.125,4.138,4.151,4.166,4.18,4.196,4.212,4.229,4.247,4.265,4.285,4.305,4.326,4.349,4.372,4.396,4.422,4.449,4.477,4.507,4.538,4.57,4.604,4.64,4.678,4.717,4.759,4.803,4.849,4.897,4.948,5.002,5.059,5.119,5.182,5.248,5.319,5.393,5.472,5.556,5.644,5.738,5.838,5.944,6.056,6.176,6.304,6.44,6.585,6.741,6.907,7.085,7.276,7482,7.702,7.94,8.196,8.473,8.773,9.098,9.451,9.835,10.253,10.711,11.214,11.766,12.374,13.048,13.796,14.631,15.566,16.618,17.81,19.167,20.721,22.516,24.605,27.058,29.967,33.457,37.699,42.93,49.495,57.902,68.93,83.823,104.68,100000\9.519,9.305,9.095,8.891,8.691,8.495,8.304,8.117,7.934,7.756,7.581,7.411,7.244,7.081,6.922,6.766,6.614,6.465,6.319,6.177,6.038,5.902,5.77,5.64,5.513,5.389,5.268,5.149,5.033,4.92,4.809,4.701,4.595,4.492,4.391,4.292,4.195,4.101,4.009,3.919,3.83,3.744,3.66,3.578,3.497,3.418,3.341,3.266,3.193,3.121,3.051,2.982,2.915,2.849,2.785,2.723,2.661,2.602,2.543,2.486,2.43,2.375,2.322,2.27,2.218,2.169,2.12,2.072,2.025,1.98,1.935,1.892,1.849,1.808,1.767,1.727,1.688,1.65,1.613,1.577,1.542,1.507,1.473,1.44,1.407,1.376,1.345,1.315,1.285,1.256,1.228,1.2,1.173,1.147,1.121,1.096,1.071,1.047,1.024,1,1)

			matrix tF_c01 = (6.670,6.673,6.676,6.679,6.682,6.685,6.689,6.693,6.697,6.701,6.706,6.711,6.717,6.723,6.729,6.736,6.743,6.751,6.759,6.768,6.778,6.788,6.799,6.811,6.824,6.837,6.852,6.867,6.884,6.901,6.920,6.941,6.963,6.986,7.011,7.038,7.066,7.097,7.129,7.164,7.202,7.242,7.285,7.331,7.380,7.432,7.489,7.549,7.614,7.683,7.757,7.836,7.922,8.013,8.111,8.216,8.329,8.451,8.581,8.721,8.872,9.035,9.210,9.399,9.603,9.824,10.062,10.320,10.600,10.904,11.235,11.595,11.988,12.418,12.889,13.407,13.979,14.610,15.312,16.094,16.969,17.953,19.067,20.333,21.783,23.455,25.399,27.680,30.383,33.624,37.560,42.416,48.511,56.324,66.592,80.502,100.069,128.950,174.370,252.342,100000\35.366,34.135,32.946,31.798,30.691,29.622,28.591,27.595,26.634,25.706,24.811,23.947,23.113,22.308,21.531,20.781,20.058,19.359,18.685,18.034,17.406,16.800,16.215,15.650,15.105,14.579,14.072,13.581,13.109,12.652,12.211,11.786,11.376,10.980,10.597,10.228,9.872,9.528,9.196,8.876,8.567,8.269,7.981,7.703,7.435,7.176,6.926,6.685,6.452,6.227,6.010,5.801,5.599,5.404,5.216,5.034,4.859,4.690,4.526,4.369,4.217,4.070,3.928,3.791,3.659,3.532,3.409,3.290,3.176,3.065,2.958,2.855,2.756,2.660,2.567,2.478,2.392,2.308,2.228,2.150,2.076,2.003,1.934,1.866,1.801,1.739,1.678,1.620,1.563,1.509,1.456,1.406,1.357,1.309,1.264,1.220,1.177,1.136,1.097,1.059,1.059)
			// for simplicity, values from lookup tables from LEe et al. (2022) are used instead of the user-written command -tF-, see https://irs.princeton.edu/davidlee-supplementarytF

			forval p2 = 5(-4)1 {
				foreach b in lo hi {
					gen IVF0`p2'_`b' = .
					gen adj0`p2'_`b' = .
				}
				forval i = 1(1)100 {
					local j = `i'+1
					qui replace IVF0`p2'_lo = tF_c0`p2'[1,`i'] if `atFvar' >= tF_c0`p2'[1,`i'] & `atFvar' < tF_c0`p2'[1,`j']
					qui replace IVF0`p2'_hi = tF_c0`p2'[1,`j'] if `atFvar' >= tF_c0`p2'[1,`i'] & `atFvar' < tF_c0`p2'[1,`j']
					qui replace adj0`p2'_hi = tF_c0`p2'[2,`i'] if `atFvar' >= tF_c0`p2'[1,`i'] & `atFvar' < tF_c0`p2'[1,`j']
					qui replace adj0`p2'_lo = tF_c0`p2'[2,`j'] if `atFvar' >= tF_c0`p2'[1,`i'] & `atFvar' < tF_c0`p2'[1,`j']
				}
				local IVF05_inf = 4 // to be precise, this value - the threshold where the standard error adjustment factor turns infinite - should be First-stage F-Stat(=atFvar)=3.8416, but the matrix from Lee et al. only delivers adjustment values up to 4  ("tends to infinity as F approaches 3.84")
				local IVF01_inf = 6.67 // to be precise, this value - the threshold where the standard error adjustment factor turns infinite - should be First-stage F-Stat(=atFvar)=6.635776 (2.576^2), but the matrix from Lee et al. only delivers adjustment values up to 6.670
				
				gen     tF0`p2'_adj = adj0`p2'_lo + (IVF0`p2'_hi  - `atFvar')/(IVF0`p2'_hi  - IVF0`p2'_lo)  * (adj0`p2'_hi - adj0`p2'_lo)  //  "tF Standard Error Adjustment value, according to Lee et al. (2022)" 		
				label var tF0`p2'_adj "tF Standard Error Adjustment value (`p2'% level), according to Lee et al. (2022)"						
							
				** tF-adjusted SE and p-val
				gen     se_0`p2'tF_i = se_i*tF0`p2'_adj
									
				gen     pval_0`p2'tF_i = 2*(1 - normal(abs(`beta'/se_0`p2'tF_i)))
				replace pval_0`p2'tF_i = 1 if `atFvar'<`IVF0`p2'_inf' 
				drop IVF0`p2'_* adj0`p2'_* tF0`p2'_adj se_0`p2'tF_i
			}
		}
		
		** different indicators to be shown in Robustness Dashboard depending on whether IV adjustment is made
		local check_05_osig_all = 1
		if `studypooling'==1 {
			capture confirm variable RF2_SIGagr_05_osig_ra_all, exact   // check if variable is part of dataset across studies 
    		if !_rc {
				local check_05_osig_all = 1
			}
			else {
				local check_05_osig_all = 0
			}
		}
		if "`ivadjust'"!="0" {		
			** case 1 - 3: weak-IV adjustment
			** case 1, siglevel>5%: add SIGagr for 5% and 5% weak-IV adjusted (be it tF,VtF, or AR) 	
			if `signum_ra'>5 {
				local RF2_SIGagr_xx        			RF2_SIGagr_05        		RF2_SIGagr_05iva
				local RF2_SIGagr_xx_j      			RF2_SIGagr_05_j      		RF2_SIGagr_05iva_j
				local RF2_SIGagr_xx_osig    		RF2_SIGagr_05_osig 			RF2_SIGagr_05iva_osig
				local RF2_SIGagr_xx_onsig    		RF2_SIGagr_05_onsig 		RF2_SIGagr_05iva_onsig

				// for pooled results (*_all), the dashboard considers - for simplicity - only AR p-values, not the (V)tF-adjusted values
				if "`ivadjust'"=="AR" {
					local RF2_SIGagr_xx_osig_ra_all 	RF2_SIGagr_05_osig_ra_all 	RF2_SIGagr_05iva_osig_ra_all
					local RF2_SIGagr_xx_onsig_ra_all 	RF2_SIGagr_05_onsig_ra_all 	RF2_SIGagr_05iva_onsig_ra_all
				}
				else {
					local RF2_SIGagr_xx_osig_ra_all 	RF2_SIGagr_05_osig_ra_all 	
					local RF2_SIGagr_xx_onsig_ra_all 	RF2_SIGagr_05_onsig_ra_all	
				}
			}
			** case 2, siglevel 5%>=X>1%: SIGagr for X% already shown in bubble, only add SIGagr for 5% weak-IV adjusted (be it tF,VtF, or AR) 
			if `signum_ra'<=5 & `signum_ra'>1  {
				local RF2_SIGagr_xx       			RF2_SIGagr_10				RF2_SIGagr_05iva
				local RF2_SIGagr_xx_j      			RF2_SIGagr_10_j				RF2_SIGagr_05iva_j
				local RF2_SIGagr_xx_osig    		RF2_SIGagr_10_osig			RF2_SIGagr_05iva_osig
				local RF2_SIGagr_xx_onsig    		RF2_SIGagr_10_onsig			RF2_SIGagr_05iva_onsig

				if "`ivadjust'"=="AR" {
					local RF2_SIGagr_xx_osig_ra_all 	RF2_SIGagr_10_osig_ra_all	RF2_SIGagr_05iva_osig_ra_all
					local RF2_SIGagr_xx_onsig_ra_all	RF2_SIGagr_10_onsig_ra_all	RF2_SIGagr_05iva_onsig_ra_all
				}
				else {
					local RF2_SIGagr_xx_osig_ra_all 								
					local RF2_SIGagr_xx_onsig_ra_all 								
				}
			}
			** case 3, siglevel=1%: SIGagr for 1% already shown in bubble, only add SIGagr for 1% weak-IV adjusted (be it tF,VtF, or AR)   
			if `signum_ra'==1  {
				local RF2_SIGagr_xx       			RF2_SIGagr_10				RF2_SIGagr_01iva
				local RF2_SIGagr_xx_j      			RF2_SIGagr_10_j				RF2_SIGagr_01iva_j
				local RF2_SIGagr_xx_osig    		RF2_SIGagr_10_osig			RF2_SIGagr_01iva_osig
				local RF2_SIGagr_xx_onsig    		RF2_SIGagr_10_onsig			RF2_SIGagr_01iva_onsig

				if "`ivadjust'"=="AR" {
					local RF2_SIGagr_xx_osig_ra_all 	RF2_SIGagr_10_osig_ra_all	RF2_SIGagr_01iva_osig_ra_all
					local RF2_SIGagr_xx_onsig_ra_all	RF2_SIGagr_10_onsig_ra_all	RF2_SIGagr_01iva_onsig_ra_all
				}
				else {
					local RF2_SIGagr_xx_osig_ra_all 	RF2_SIGagr_10_osig_ra_all								
					local RF2_SIGagr_xx_onsig_ra_all 	RF2_SIGagr_10_onsig_ra_all							
				}
			}
		}
		** case 4 - 5: no weak-IV adjustment
		** case 4, siglevel>5%: add SIGagr for 5%, only when siglevel>5%
		if "`ivadjust'"=="0" & `signum_ra'>5 {
			local RF2_SIGagr_xx        			RF2_SIGagr_05
			local RF2_SIGagr_xx_j      			RF2_SIGagr_05_j
			local RF2_SIGagr_xx_osig   			RF2_SIGagr_05_osig
			local RF2_SIGagr_xx_onsig  			RF2_SIGagr_05_onsig
			local RF2_SIGagr_xx_osig_ra_all 	RF2_SIGagr_05_osig_ra_all
			local RF2_SIGagr_xx_onsig_ra_all 	RF2_SIGagr_05_onsig_ra_all
		}
		** case 5, siglevel<=5% OR pooled study data without RF2_SIGagr_05_osig_ra_all: no additional statistics
		if ("`ivadjust'"=="0" & `signum_ra'<=5) | `check_05_osig_all'==0 {
			local RF2_SIGagr_xx        			RF2_SIGagr_10
			local RF2_SIGagr_xx_j      			RF2_SIGagr_10_j
			local RF2_SIGagr_xx_osig			RF2_SIGagr_10_osig
			local RF2_SIGagr_xx_onsig    		RF2_SIGagr_10_onsig
			local RF2_SIGagr_xx_osig_ra_all		RF2_SIGagr_10_osig_ra_all
			local RF2_SIGagr_xx_onsig_ra_all	RF2_SIGagr_10_onsig_ra_all
		}
	}



************************************************************
***  PART 2.B  ADDITIONAL VARIABLE GENERATION AND MAIN LOCALS
************************************************************

*** Additional variable generation, e.g. on the original estimates and the effect direction and the relative effect size based on the raw data	
	if `studypooling'==0 {
		** variables on the original estimates
		clonevar beta_i = `beta'
		clonevar mean_i = mean_j
		foreach var in beta se pval zscore  mean  beta_dir   beta2 se2 pval2 zscore2  beta2_dir {
			capture confirm variable `var'_i, exact
			if !_rc {
				               gen x_`var'_orig_j = `var'_i if origpath_i==1
				bysort mainvar: egen `var'_orig_j = min(x_`var'_orig_j)
			}
		}
		local pval_iva_orig_j // empty local
		if "`ivadjust'"!="0" {	
			if  `signum_ra'>1 {
				local iva_level = 5
			}
			if  `signum_ra'==1 { 
				local iva_level = 1
			}
		}
		if "`ivadjust'"=="tF" {
			               gen x_pval_0`iva_level'iva_orig_j = pval_0`iva_level'tF_i if origpath_i==1
			bysort mainvar: egen pval_0`iva_level'iva_orig_j = min(x_pval_0`iva_level'iva_orig_j)
			local pval_iva_orig_j   pval_0`iva_level'iva_orig_j
		}
		if "`ivadjust'"=="AR" {
			               gen x_pval_0`iva_level'iva_orig_j = pval_ar_i if origpath_i==1
			bysort mainvar: egen pval_0`iva_level'iva_orig_j = min(x_pval_0`iva_level'iva_orig_j)
			local pval_iva_orig_j   pval_0`iva_level'iva_orig_j
		}
		drop beta_i mean_i

		rename beta_dir_orig_j  beta_orig_dir_j
		capture rename beta2_dir_orig_j beta2_orig_dir_j

		** further variable transformations based on _orig variables 
		capture confirm variable zscore2_i, exact
		if !_rc {
			replace zscore_i  = zscore_i*-1  if origpath_i!=1 & beta_orig_dir_j==-1 // if two coefficients in a reproducability or replicability analysis, t/z-value for each must be assigned a positive (negative) sign if coefficient is in the same (opposite) direction as the original coefficient (assumes that there is only one original coefficient)
			replace zscore2_i = zscore2_i*-1 if origpath_i!=1 & beta_orig_dir_j==-1	
			replace zscore_i = (zscore_i+zscore2_i)/2  			// if two coefficients in a reproducability or replicability analysis, zscore should be calculated as average of two zscores		
			replace zscore_i = (abs(zscore_i)+abs(zscore2_i))/2 if orig_path==1 & ((zscore_i>=0 & zscore2_i<0) | (zscore_i<0 & zscore2_i>=0))  // if one original coefficient is positive and one negative, the two original t/z-values must both be assigned positive signs
		}

 		replace mean_j = mean_orig_j if mean_j==.	// if mean is not specified for analysis paths of robustness tests, it is assumed to be equal to the mean in the original study

		** additional variable generation
		gen beta_rel_i      = `beta'/mean_j*100
		gen se_rel_i        = se_i/mean_j
		
		gen beta_rel_orig_j = beta_orig_j/mean_orig_j*100
		gen se_rel_orig_j   = se_orig_j/mean_orig_j

		gen x_beta_abs_orig_p`sigdigits_ra'_j =  se_orig_j*invnormal(1-0.`sigdigits_ra'/2)
		gen x_se_orig_p`sigdigits_ra'_j       =  abs(beta_orig_j)/invnormal(1-0.`sigdigits_ra'/2)
		foreach var in beta_abs se {
				bysort mainvar: egen `var'_orig_p`sigdigits_ra'_j = min(x_`var'_orig_p`sigdigits_ra'_j)
		}	

		gen     include_in_multiverse = 1
		replace include_in_multiverse = 0 if origpath_i==1 & orig_in_multiverse_i==0
	
*** Information on share of results with originally sig./ insig. estimates
	// definition of whether orginal results is statistically significant may differ by whether level of stat. sig. from original study (_oa) or rep. analysis (_ra) is applied
	// hence four different locals each for number (`origs'_`set'_rslt_N) and share (`origs'_`set'_rslt_share)	
		bysort mainvar: gen x_n_j = _n
		foreach set in oa ra {
		 	 gen x_osig_`set'_d_rslt    = (pval_orig_j<=0.`sigdigits_`set'') if x_n_j==1    
			 gen x_onsig_`set'_d_rslt   = (pval_orig_j>0.`sigdigits_`set'')  if x_n_j==1	
			foreach origs in osig onsig {
				egen x_`origs'_`set'_rslt_N  = total(x_`origs'_`set'_d_rslt)
				local  `origs'_`set'_rslt_N  = x_`origs'_`set'_rslt_N
			}
			local osig_`set'_rslt_share  "`: display x_osig_`set'_rslt_N  "`=char(47)'"  `N_results' '"
		}
		
		foreach set in oa ra {
			local onsig_`set'_rslt_share "`: display x_onsig_`set'_rslt_N  "`=char(47)'"  `N_results' '"
		}
			
*** Information on the number of analysis paths 
		clonevar mainvar_in = mainvar    // create mainvar restricted to analysis paths included in robustness analysis
		replace  mainvar_in = . if include_in_multiverse==0 

		bysort mainvar_in: gen x_N_specs_by_result2 = _N
		replace x_N_specs_by_result2 = . if mainvar_in==.
		bysort mainvar:   egen x_N_specs_by_result  = min(x_N_specs_by_result2)
		qui sum x_N_specs_by_result
		local N_specs_min = `r(min)'
		local N_specs_max = `r(max)'
		foreach x in min max {				
			egen x_N_results_`x'2 = group(mainvar) if x_N_specs_by_result==`N_specs_`x''
			egen x_N_results_`x' = max(x_N_results_`x'2)
			gen x_spec_`x'_result = mainvar_str if x_N_specs_by_result==`N_specs_`x''
			gsort -x_spec_`x'_result
			local spec_`x' = x_spec_`x'_result
			if x_N_results_`x'>1 {
				local spec_`x' "multiple results"
			}	
		}
	}
	
	if `studypooling'==1 {
*** Information on share of results/ studies etc for `studypooling'==1, i.e. at the study level
		** studies
		qui tab mainvar 
		local N_studies = `r(r)'
		foreach set in oa ra {
			foreach origs in osig onsig {
				 gen x_`origs'_`set'_d_stud = (`origs'_`set'_rslt_N>0)   
				egen x_`origs'_`set'_stud_N = total(x_`origs'_`set'_d_stud)
			}
			local osig_`set'_stud_share "`: display x_osig_`set'_stud_N  "`=char(47)'"  `N_studies' '"
		}
		egen x_ivarweight_stud_N = total(ivarweight_stud_d)
		local ivarweight_stud_N = x_ivarweight_stud_N 
				
		egen x_siglevel_o05_r05_N = total(siglevel_oa_stud==5  & siglevel_ra_stud==5)
		egen x_siglevel_o10_r05_N = total(siglevel_oa_stud==10 & siglevel_ra_stud==5)
		egen x_siglevel_o05_r10_N = total(siglevel_oa_stud==5  & siglevel_ra_stud==10)
		egen x_siglevel_o10_r10_N = total(siglevel_oa_stud==10 & siglevel_ra_stud==10)
		foreach olevel in 05 10 {
			foreach rlevel in 05 10 {
				local siglevel_o`olevel'_r`rlevel'_N = x_siglevel_o`olevel'_r`rlevel'_N
			}
		}

		** results
		bysort mainvar: gen x_n_j = _n
		foreach ovar in results osig_oa_rslt onsig_oa_rslt osig_ra_rslt onsig_ra_rslt {
			egen x_`ovar'_N2 = total(`ovar'_N) if x_n_j==1
			egen  x_`ovar'_N = min(x_`ovar'_N2)
		}
		local N_results = x_results_N
		foreach set in oa ra {
			foreach origs in osig onsig {
				local `origs'_`set'_rslt_N   = x_`origs'_`set'_rslt_N
			}
			local osig_`set'_rslt_share  "`: display x_osig_`set'_rslt_N  "`=char(47)'"  `N_results' '"
		}
		
		foreach set in oa ra {	
			local onsig_`set'_rslt_share  "`: display x_onsig_`set'_rslt_N  "`=char(47)'"  `N_results' '"
			local onsig_`set'_stud_share "`: display x_onsig_`set'_stud_N  "`=char(47)'"  `N_studies' '"
		}
		qui sum analysispaths_min_N
		local N_specs_min = `r(min)'
		qui sum analysispaths_max_N
		local N_specs_max = `r(max)'
		foreach x in min max {				
			egen x_N_studies_`x'2 = group(mainvar) if analysispaths_`x'_N==`N_specs_`x''
			egen x_N_studies_`x' = max(x_N_studies_`x'2)
			gen x_spec_`x'_study = mainvar_str if analysispaths_`x'_N==`N_specs_`x''
			gsort -x_spec_`x'_study
			local spec_`x' = x_spec_`x'_study
			if x_N_studies_`x'>1 {
				local spec_`x' "multiple studies"
			}
		}
		drop results_N siglevel_ra_stud siglevel_oa_stud osig_oa_rslt_N onsig_oa_rslt_N osig_ra_rslt_N  onsig_ra_rslt_N   analysispaths_min_N analysispaths_max_N  ivarweight_stud_d  // information transferred to locals	
		drop pval_orig_*   // drop variables not required for the Indicator construction
		capture drop __000000 __000001   // sometimes temporary variables are created by marksample command above
	}
	
	drop x_*
	
	
	


********************************************************************************
*****  PART 3  INDICATOR DEFINITIONS BY RESULT AND ACROSS RESULTS/ STUDIES
********************************************************************************
	// for verbal description of indicators, see the readme on GitHub

************************************************************
***  PART 3.A  INDICATORS BY RESULT
************************************************************
	
	local RF_list_j				RF_SIGagr_j RF_ESrel_j  RF_SIGrel_j RF_ESvar_j RF_SIGvar_j
	local RF_list_osig_oa_k  	RF_SIGagr_osig_oa_all  RF_ESrel_osig_oa_all  RF_SIGrel_osig_oa_all  RF_ESvar_osig_oa_all  RF_SIGvar_osig_oa_all
	local RF_list_onsig_oa_k  	RF_SIGagr_onsig_oa_all RF_ESrel_onsig_oa_all RF_SIGrel_onsig_oa_all RF_ESvar_onsig_oa_all RF_SIGvar_onsig_oa_all
	if `shelvedind'==1 {
		local RF_list_osig_oa_k  	`RF_list_osig_oa_k'  RF_robratio_A_osig_oa_all  RF_robratio_B_osig_oa_all  RF_pooledH_A_osig_oa_all  RF_pooledH_B_osig_oa_all
		local RF_list_onsig_oa_k  	`RF_list_onsig_oa_k' RF_robratio_A_onsig_oa_all RF_robratio_B_onsig_oa_all RF_pooledH_A_onsig_oa_all RF_pooledH_B_onsig_oa_all
	}
	local RF_list_nosfx 	RF_SIGagr RF_ESrel RF_SIGrel RF_ESvar RF_SIGvar
	if `shelvedind'==1 {
		local RF_list_nosfx  	`RF_list_nosfx'  RF_robratio_A RF_robratio_B RF_pooledH_A RF_pooledH_B
	}
	
	local RF2_list_j 			RF2_SIGagr_j 		  	`RF2_SIGagr_xx_j' 			 RF2_SIGagr_ndir_j  			RF2_ESrel_j           RF2_ESvar_j 			RF2_SIGvar_nsig_j   		 RF2_SIGvar_sig_j  				RF2_ESagr_j				RF2_SIGagr_sigdef_j 	       RF2_SIGcfm_oas_j 		   RF2_SIGcfm_oan_j  								    	RF2_SIGsw_btonsig_j 			RF2_SIGsw_btosig_j  			RF2_SIGsw_setonsig_j 	RF2_SIGsw_setosig_j      
	local RF2_list_osig_ra_k	RF2_SIGagr_osig_ra_all  `RF2_SIGagr_xx_osig_ra_all'  RF2_SIGagr_ndir_osig_ra_all    RF2_ESrel_osig_ra_all RF2_ESvar_osig_ra_all RF2_SIGvar_nsig_osig_ra_all									RF2_ESagr_osig_ra_all   RF2_SIGagr_sigdef_osig_ra_all  RF2_SIGcfm_oas_osig_ra_all  RF2_SIGcfm_oan_osig_ra_all  RF2_SIGcfm_uni_osig_ra_all	RF2_SIGsw_btonsig_osig_ra_all 									RF2_SIGsw_setonsig_osig_ra_all 
	local RF2_list_onsig_ra_k	RF2_SIGagr_onsig_ra_all `RF2_SIGagr_xx_onsig_ra_all' RF2_SIGagr_ndir_onsig_ra_all   											RF2_SIGvar_nsig_onsig_ra_all RF2_SIGvar_sig_onsig_ra_all							RF2_SIGagr_sigdef_onsig_ra_all RF2_SIGcfm_oas_onsig_ra_all RF2_SIGcfm_oan_onsig_ra_all RF2_SIGcfm_uni_onsig_ra_all  								RF2_SIGsw_btosig_onsig_ra_all 							RF2_SIGsw_setosig_onsig_ra_all 
	local RF2_osig_list_nosfx 	RF2_SIGagr `RF2_SIGagr_xx' RF2_SIGagr_ndir  RF2_ESrel RF2_ESvar  RF2_SIGvar_nsig                 RF2_SIGagr_sigdef RF2_SIGcfm_uni RF2_SIGcfm_oas RF2_SIGcfm_oan  RF2_ESagr  RF2_SIGsw_btonsig RF2_SIGsw_setonsig 		 	 
	local RF2_onsig_list_nosfx	RF2_SIGagr `RF2_SIGagr_xx' RF2_SIGagr_ndir                       RF2_SIGvar_nsig RF2_SIGvar_sig  RF2_SIGagr_sigdef RF2_SIGcfm_uni RF2_SIGcfm_oas RF2_SIGcfm_oan             RF2_SIGsw_btosig  RF2_SIGsw_setosig  			 					


	if `studypooling'==0 {
		** (1.) Significance agreement
					    gen x_RF_SIGagr_i = (pval_i<=0.`sigdigits_ra' ///
											  & beta_dir_i==beta_orig_dir_j)		if pval_orig_j<=0.`sigdigits_oa' & beta2_i==.
					replace x_RF_SIGagr_i = (pval_i>0.`sigdigits_ra')				if pval_orig_j>0.`sigdigits_oa'  & beta2_i==.
					   		// if one orig. coefficient and one rep. coefficient & 
							// if two orig. coefficients and one rep. coefficient, rep. coefficient needs to be in the same direction as the first orig. coefficient
					   
					replace x_RF_SIGagr_i = (pval_i<=0.`sigdigits_ra' ///
											  & beta_dir_i==beta_orig_dir_j ///
											  & pval2_i<=0.`sigdigits_ra' ///
											  & beta2_dir_i==beta_orig_dir_j)		if pval_orig_j<=0.`sigdigits_oa' & beta2_orig_j==. & beta2_i!=.
						   // if one orig. coefficient and two rep. coefficients and if the orig. results was significant, both rep. coefficients need to be significant in the orig. direction  

					replace x_RF_SIGagr_i = (pval_i<=0.`sigdigits_ra' ///
											  & beta_dir_i==beta_orig_dir_j ///
											  & pval2_i<=0.`sigdigits_ra' ///
											  & beta2_dir_i==beta2_orig_dir_j)		if pval_orig_j<=0.`sigdigits_oa' & pval2_orig_j<=0.`sigdigits_oa' & beta2_orig_j!=. & beta2_i!=.
						   // if two orig. coefficient and two rep. coefficients and if both orig. coefficients were significant, both rep. coefficients need to be significant in the orig. directions  

					replace x_RF_SIGagr_i = (pval_i>0.`sigdigits_ra' | (pval2_i>0.`sigdigits_ra' & pval2_i<.))		if pval_orig_j>0.`sigdigits_oa' & beta2_orig_j==. & beta2_i!=.  
						   // if one orig. coefficient and two rep. coefficients and if the orig. result was a null result, at least one of the two rep. coefficients need to be insignificant    
					   
					replace x_RF_SIGagr_i = (pval_i>0.`sigdigits_ra' | (pval2_i>0.`sigdigits_ra' & pval2_i<.))		if (pval_orig_j>0.`sigdigits_oa' | pval2_orig_j>0.`sigdigits_oa') & beta2_orig_j!=. & beta2_i!=.  
						   // if two orig. coefficients and two rep. coefficients and if at least one of the orig. coefficients was insig., at least one of the two rep. coefficients need to be insignificant 

					replace x_RF_SIGagr_i = . if origpath_i==1

		bysort mainvar:  egen RF_SIGagr_j = mean(x_RF_SIGagr_i) 						  	 
				
			
		** (1') Significance agreement - alternative indicator set	
			// not for beta2_orig_j==1 | beta2_i==1
					     gen x_RF2_SIGagr_i				= (pval_i<=0.`sigdigits_ra' & beta_dir_i==beta_orig_dir_j)*100	if beta2_orig_j==. & beta2_i==. & origpath_i!=1
		bysort mainvar: egen   RF2_SIGagr_j    			= mean(x_RF2_SIGagr_i) 


		if "`ivadjust'"=="tF" {
						 gen x_RF2_SIGagr_0`iva_level'iva_i	= (pval_0`iva_level'tF_i<=0.0`iva_level' & beta_dir_i==beta_orig_dir_j)*100 	if beta2_orig_j==. & beta2_i==. & origpath_i!=1 & pval_0`iva_level'tF_i!=.
		bysort mainvar: egen   RF2_SIGagr_0`iva_level'iva_j 	= mean(x_RF2_SIGagr_0`iva_level'iva_i)	
		}
		if "`ivadjust'"=="VtF" {
			             gen x_RF2_SIGagr_0`iva_level'iva_i = (abs(`beta'/se_i) > `atFvar' & beta_dir_i==beta_orig_dir_j)*100 				if beta2_orig_j==. & beta2_i==. & origpath_i!=1
		bysort mainvar: egen   RF2_SIGagr_0`iva_level'iva_j 	= mean(x_RF2_SIGagr_0`iva_level'iva_i)
		}
		if "`ivadjust'"=="AR" {
						 gen x_RF2_SIGagr_0`iva_level'iva_i	= (pval_ar_i<=0.0`iva_level' & beta_dir_i==beta_orig_dir_j)*100 				if beta2_orig_j==. & beta2_i==. & origpath_i!=1 & pval_ar_i!=.
		bysort mainvar: egen   RF2_SIGagr_0`iva_level'iva_j 	= mean(x_RF2_SIGagr_0`iva_level'iva_i)	
		}

		if `signum_ra'!=5  {
						 gen x_RF2_SIGagr_05_i		= (pval_i<0.05  & beta_dir_i==beta_orig_dir_j)*100	 				if beta2_orig_j==. & beta2_i==. & origpath_i!=1
		bysort mainvar: egen   RF2_SIGagr_05_j  	= mean(x_RF2_SIGagr_05_i)
		}
		if `signum_ra'!=10  {
						 gen x_RF2_SIGagr_10_i		= (pval_i<0.10  & beta_dir_i==beta_orig_dir_j)*100	 				if beta2_orig_j==. & beta2_i==. & origpath_i!=1
		bysort mainvar: egen   RF2_SIGagr_10_j  	= mean(x_RF2_SIGagr_10_i)
		}
		
			// - opposite direction -
			// not for beta2_orig_j==1 | beta2_i==1
					     gen x_RF2_SIGagr_ndir_i	= (pval_i<=0.`sigdigits_ra' ///
												    & beta_dir_i!=beta_orig_dir_j)*100	if beta2_orig_j==. & beta2_i==.	& origpath_i!=1									
		bysort mainvar: egen   RF2_SIGagr_ndir_j	= mean(x_RF2_SIGagr_ndir_i) 


		** (6') Indicator on non-agreement due to significance classification Significance agreement - alternative indicator set
			// - insig. [sig.] only because of less [more] stringent OA significance classification -
			// not for beta2_orig_j==1 | beta2_i==1
		   	 		     gen x_RF2_SIGagr_sigdef_i 	= (pval_i>0.`sigdigits_ra' & pval_i<=0.`sigdigits_oa')*100		if pval_orig_j>0.`sigdigits_ra'  & beta2_orig_j==. & beta2_i==. & pval_orig_j<=0.`sigdigits_oa' & origpath_i!=1 
					 replace x_RF2_SIGagr_sigdef_i 	= (pval_i<=0.`sigdigits_ra' & pval_i>0.`sigdigits_oa')*100		if pval_orig_j<=0.`sigdigits_ra' & beta2_orig_j==. & beta2_i==. & pval_orig_j>0.`sigdigits_oa'  & origpath_i!=1

		bysort mainvar: egen   RF2_SIGagr_sigdef_j 	= mean(x_RF2_SIGagr_sigdef_i)
		
			// set indicator to zero for other results so that aggregated indicator later takes the correct mean 
					 egen x_RF2_SIGagr_sigdef_j_any = min(RF2_SIGagr_sigdef_j)
					  gen       RF2_SIGagr_sigde2_j = .
		if `signum_ra'<`signum_oa' {
					  replace   RF2_SIGagr_sigde2_j = RF2_SIGagr_sigdef_j											if x_RF2_SIGagr_sigdef_j_any>0 & x_RF2_SIGagr_sigdef_j_any<.
					  replace   RF2_SIGagr_sigde2_j = 0 															if x_RF2_SIGagr_sigdef_j_any>0 & x_RF2_SIGagr_sigdef_j_any<. & pval_orig_j>0.`sigdigits_ra'  & beta2_orig_j==. & beta2_i==. & pval_orig_j>0.`sigdigits_oa'  & RF2_SIGagr_sigde2_j==.
		}
		if `signum_ra'>`signum_oa' {
					  replace   RF2_SIGagr_sigde2_j = RF2_SIGagr_sigdef_j											if x_RF2_SIGagr_sigdef_j_any>0 & x_RF2_SIGagr_sigdef_j_any<.
					  replace   RF2_SIGagr_sigde2_j = 0 															if x_RF2_SIGagr_sigdef_j_any>0 & x_RF2_SIGagr_sigdef_j_any<. & pval_orig_j<=0.`sigdigits_ra' & beta2_orig_j==. & beta2_i==. & pval_orig_j<=0.`sigdigits_oa' & RF2_SIGagr_sigde2_j==.
		}


		** (2.) Relative effect size 
			// only for original results reported as statistically significant at the 0.`sigdigits_oa' level
			// only for sameunits_i==1 and not for beta2_orig_j==1 | beta2_i==1
		bysort mainvar: egen x_RF_ESrel_j = mean(`beta')   					if (pval_orig_j<=0.`sigdigits_oa') & sameunits_i==1 & beta2_orig_j==. & beta2_i==. & origpath_i!=1
						 gen   RF_ESrel_j = x_RF_ESrel_j/beta_orig_j


		** (2'). Relative effect size - alternative indicator set
				// only for original results reported as statistically significant at the 0.`sigdigits_ra' level
				// + only for analysis paths of reproducability or replicability analyses reported as statistically significant at the 0.`sigdigits_ra' level
				// only for sameunits_i==1 and not for beta2_orig_j==1 | beta2_i==1
		bysort mainvar: egen x_RF2_ESrel_j2 = median(`beta')	 			if pval_i<=0.`sigdigits_ra' & beta_dir_i==beta_orig_dir_j & pval_orig_j<=0.`sigdigits_ra' & sameunits_i==1 & beta2_orig_j==. & beta2_i==. & origpath_i!=1						
						 gen x_RF2_ESrel_j 	= x_RF2_ESrel_j2/beta_orig_j 
						 gen   RF2_ESrel_j 	= ((x_RF2_ESrel_j) - 1)*100

			   
		** (3.) Relative significance
			// only for original results reported as statistically significant at the 0.`sigdigits_oa' level
			// zscore already averaged above for cases where there are two coefficients
						 gen x_RF_SIGrel_i = zscore_i/zscore_orig_j			if origpath_i!=1
		bysort mainvar: egen   RF_SIGrel_j = mean(x_RF_SIGrel_i)   			if pval_orig_j<=0.`sigdigits_oa'
		

		// preparation for Variation Indicators 4, 3' and 5: allow for original estimate as additional observation if included as one analysis path in reproducability or replicability analysis
		bysort mainvar: egen x_RF2_ESrel_j3 = median(`beta')	 				if pval_i<=0.`sigdigits_ra' & beta_dir_i==beta_orig_dir_j & pval_orig_j<=0.`sigdigits_ra' & sameunits_i==1 & beta2_orig_j==. & beta2_i==. & include_in_multiverse==1  // redo x_RF2_ESrel_j2
		replace x_RF2_ESrel_j2 = x_RF2_ESrel_j3 
		
		
		** (4.) Effect sizes variation
			// only for sameunits_i==1 and not for beta2_orig_j==1 | beta2_i==1
		bysort mainvar: egen x_RF_ESvar_j = sd(`beta')							if sameunits_i==1 & beta2_orig_j==. & beta2_i==. & include_in_multiverse==1
						 gen   RF_ESvar_j = x_RF_ESvar_j/se_orig_j        
		
		
		** (3') Effect sizes variation - alternative indicator set
			// only for original results reported as statistically significant at the 0.`sigdigits_ra' level
			// + only for analysis paths of reproducability or replicability analyses reported as statistically significant at the 0.`sigdigits_ra' level
			// only for sameunits_i==1 and not for beta2_orig_j==1 | beta2_i==1
						 gen x_RF2_ESvar_i = abs(`beta'-x_RF2_ESrel_j2) 	    	
		bysort mainvar: egen x_RF2_ESvar_j = mean(x_RF2_ESvar_i)     			if pval_i<=0.`sigdigits_ra' & beta_dir_i==beta_orig_dir_j & pval_orig_j<=0.`sigdigits_ra' & sameunits_i==1 & beta2_orig_j==. & beta2_i==. & include_in_multiverse==1
						 gen   RF2_ESvar_j = (x_RF2_ESvar_j/abs(beta_orig_j))*100
		
		
		** (5.) Significance variation
			// zscore already averaged above for cases where there are two coefficients
		bysort mainvar: egen   RF_SIGvar_j = sd(zscore_i)						if include_in_multiverse==1

		
		** (4') Significance variation - alternative indicator set
			// not for beta2_orig_j==1 | beta2_i==1
						 gen x_RF2_SIGvar_nsig_i = abs(pval_i-pval_orig_j)	if pval_i>0.`sigdigits_ra' &  beta2_orig_j==. & beta2_i==. & origpath_i!=1
		bysort mainvar: egen   RF2_SIGvar_nsig_j = mean(x_RF2_SIGvar_nsig_i)

						 gen x_RF2_SIGvar_sig_i  = abs(pval_i-pval_orig_j)	if pval_i<=0.`sigdigits_ra' & beta2_orig_j==. & beta2_i==. & origpath_i!=1
		bysort mainvar: egen   RF2_SIGvar_sig_j  = mean(x_RF2_SIGvar_sig_i)


		** (5') Effect size agreement - alternative indicator set
			// only for sameunits_i==1 and not for beta2_orig_j==1 | beta2_i==1
		if "`df'"=="" {
			gen x_z_crit = abs(invnormal(0.`sigdigits_ra'/2))
		}
		else {
			gen x_z_crit = abs(invt(`df', 0.`sigdigits_ra'/2))
		}
			
		gen x_RF2_ESagr_ci_up_`signum_ra' = beta_orig_j + x_z_crit*se_orig_j   
		gen x_RF2_ESagr_ci_lo_`signum_ra' = beta_orig_j - x_z_crit*se_orig_j

		                 gen x_RF2_ESagr_i  = (`beta'>=x_RF2_ESagr_ci_lo_`signum_ra' & `beta'<=x_RF2_ESagr_ci_up_`signum_ra')  if sameunits_i==1 & beta2_orig_j==. & beta2_i==. & origpath_i!=1
		bysort mainvar: egen   RF2_ESagr_j  = mean(x_RF2_ESagr_i)     		if pval_i>0.`sigdigits_ra'
		              replace  RF2_ESagr_j  = RF2_ESagr_j*100

		/*
		// alternative definition: original estimate in CI of robustness estimates
		gen x_RF2_ESagr_ci_up_`signum_ra' = `beta' + x_z_crit*se_i   
		gen x_RF2_ESagr_ci_lo_`signum_ra' = `beta' - x_z_crit*se_i

		                 gen x_RF2_ESagr_i  = (beta_orig_j>=x_RF2_ESagr_ci_lo_`signum_ra' & beta_orig_j<=x_RF2_ESagr_ci_up_`signum_ra')  if sameunits_i==1 & beta2_orig_j==. & beta2_i==. & origpath_i!=1
		bysort mainvar: egen   RF2_ESagr_j  = mean(x_RF2_ESagr_i)     		if pval_i>0.`sigdigits_ra'
		              replace  RF2_ESagr_j  = RF2_ESagr_j*100
		*/
		

		** (7') Significance classification agreement (applying UNIform alpha as used in Reproducability or Replicability Analyses OR OAs alpha to original results)
			// these indicators (uni & oa) will eventually only be included as study and across-study totals (*_all)  
				gen RF2_SIGcfm_uni_j = 100 - RF2_SIGagr_j - RF2_SIGagr_ndir_j   if pval_orig_j>0.`sigdigits_ra'  			
			replace RF2_SIGcfm_uni_j =       RF2_SIGagr_j                       if pval_orig_j<=0.`sigdigits_ra'	

				gen RF2_SIGcfm_oa_j  = 100 - RF2_SIGagr_j - RF2_SIGagr_ndir_j   if pval_orig_j>0.`sigdigits_oa'  			
		    replace RF2_SIGcfm_oa_j  =       RF2_SIGagr_j                       if pval_orig_j<=0.`sigdigits_oa'
			replace RF2_SIGcfm_oa_j  = RF2_SIGcfm_oa_j + RF2_SIGagr_sigdef_j 	if RF2_SIGagr_sigdef_j!=.

			// for presentation in the Dashboards, the oa indicator additionally needs to be differentiated by sig (oas) an insig (oan) reproducability or replicability analyses
			    gen RF2_SIGcfm_oas_j = 0 
			replace RF2_SIGcfm_oas_j =       RF2_SIGagr_j                       if pval_orig_j<=0.`sigdigits_oa'
			replace RF2_SIGcfm_oas_j = RF2_SIGagr_sigdef_j   					if pval_orig_j>0.`sigdigits_oa' & RF2_SIGagr_sigdef_j!=.
				gen RF2_SIGcfm_oan_j = 0  
			replace RF2_SIGcfm_oan_j = 100 - RF2_SIGagr_j - RF2_SIGagr_ndir_j   if pval_orig_j>0.`sigdigits_oa' 
			replace RF2_SIGcfm_oan_j = RF2_SIGagr_sigdef_j   					if pval_orig_j<=0.`sigdigits_oa' & RF2_SIGagr_sigdef_j!=.


		** (8' & 9') Significance switch - alternative indicator set
			// only for sameunits_i==1 and not for beta2_orig_j==1 | beta2_i==1	
						 gen x_RF2_SIGsw_btonsig_i  = (abs(`beta')<=beta_abs_orig_p`sigdigits_ra'_j)*100	if pval_i>0.`sigdigits_ra' & sameunits_i==1 & beta2_orig_j==. & beta2_i==. & origpath_i!=1	// multiples of 0.1 cannot be held exactly in binary in Stata -> shares converted to range from 1/100, not from 0.01 to 1.00
					     gen x_RF2_SIGsw_setonsig_i = (se_i>=se_orig_p`sigdigits_ra'_j)*100				if pval_i>0.`sigdigits_ra' & sameunits_i==1 & beta2_orig_j==. & beta2_i==. & origpath_i!=1
		bysort mainvar: egen   RF2_SIGsw_btonsig_j  = mean(x_RF2_SIGsw_btonsig_i)
		bysort mainvar: egen   RF2_SIGsw_setonsig_j = mean(x_RF2_SIGsw_setonsig_i)
				
						 gen x_RF2_SIGsw_btosig_i  = (abs(`beta')>beta_abs_orig_p`sigdigits_ra'_j)*100		if pval_i<=0.`sigdigits_ra' & beta_dir_i==beta_orig_dir_j & sameunits_i==1 & beta2_orig_j==. & beta2_i==. & origpath_i!=1
						 gen x_RF2_SIGsw_setosig_i = (se_i<se_orig_p`sigdigits_ra'_j)*100					if pval_i<=0.`sigdigits_ra' & beta_dir_i==beta_orig_dir_j & sameunits_i==1 & beta2_orig_j==. & beta2_i==. & origpath_i!=1
		bysort mainvar: egen   RF2_SIGsw_btosig_j  = mean(x_RF2_SIGsw_btosig_i)
		bysort mainvar: egen   RF2_SIGsw_setosig_j = mean(x_RF2_SIGsw_setosig_i)


		local collapselast  RF2_SIGsw_setosig_j
		
		
		** shelved indicators					  
		if `shelvedind'==1 {
								   gen x_RF_robratio_A_i = (`beta'-beta_orig_j)^2 		if sameunits_i==1 & beta2_orig_j==. & beta2_i==. & origpath_i!=1
								   gen x_RF_robratio_B_i = (zscore_i-zscore_orig_j)^2   if                  beta2_orig_j==. & beta2_i==. & origpath_i!=1   	
			
			
			foreach approach in A B {
				bysort mainvar: egen x_RF_robratio_`approach'_j  = mean(x_RF_robratio_`approach'_i) if origpath_i!=1
			}
								   gen RF_robratio_A_j = sqrt(x_RF_robratio_A_j)/se_orig_j
								   gen RF_robratio_B_j = sqrt(x_RF_robratio_B_j)
			
			bysort mainvar: egen x_RF_pooledH_A_j1 	= mean(`beta')					if beta2_orig_j==. & beta2_i==. & origpath_i!=1
			bysort mainvar: egen x_RF_pooledH_A_j2 	= mean(se_i^2)					if beta2_orig_j==. & beta2_i==. & origpath_i!=1
						     gen   RF_pooledH_A_j 	= x_RF_pooledH_A_j1/sqrt(x_RF_pooledH_A_j2)
						   replace RF_pooledH_A_j 	= -1*RF_pooledH_A_j 			if beta_orig_dir_j==-1	
			
			bysort mainvar: egen   RF_pooledH_B_j 	= mean(zscore_i)			 	if beta2_orig_j==. & beta2_i==. & origpath_i!=1
						   replace RF_pooledH_B_j 	= -1*RF_pooledH_B_j  			if beta_orig_dir_j==-1
		}
				
		
		** Weights for inverse-variance weighting 
		if `ivarweight'==1 {
			bysort mainvar: egen x_se_rel_mean_j = mean(se_rel_i) if origpath_i!=1
							 gen        weight_j = 1/(x_se_rel_mean_j^2)

							 gen   weight_orig_j = 1/(se_rel_orig_j^2)
		}

		
		** make sure that _j information, which should be always the same by mainvar, is included in all observations
		ds RF_*_j RF2_*_j   
		foreach var in `r(varlist)' {
			bysort mainvar: egen c`var' = min(`var') 
			drop `var'
			rename c`var' `var'
		}
				


************************************************************
***  PART 3.B  COEFFICIENT AND CONTRIBUTION PLOTS
************************************************************

		** derive plot comparing original estimate with preferred estimate of robustness test
		capture confirm variable prefpath_i, exact   // check if variable with preferred paths was defined 
		if !_rc {
			matrix      M = J(`N_results', 11, .)
			matrix coln M = mainvar_n  beta_oa ll95_oa ul95_oa ll90_oa ul90_oa  beta_ra ll95_ra ul95_ra ll90_ra ul90_ra 

			if "`df'"=="" {
				gen x_z_crit95 = abs(invnormal(0.05/2))
				gen x_z_crit90 = abs(invnormal(0.10/2))
		 	}
		 	else {
				gen x_z_crit95 = abs(invt(`df', 0.05/2))
				gen x_z_crit90 = abs(invt(`df', 0.10/2))
			}

			local coeflab  // empty local
			local res = 1  // result index
			forval rsltvar = 1/`N_results' {
				local rsltval_lab: label (mainvar) `rsltvar', strict
				local coeflab `coeflab' r`rsltvar'="`rsltval_lab'"

				matrix M[`res',1] = `rsltvar'
				gen x2_Mcol2 = beta_rel_orig_j 						 	 			if mainvar==`rsltvar' & origpath_i==1
				gen x2_Mcol3 = (beta_orig_j - x_z_crit95*se_orig_j)/mean_orig_j*100	if mainvar==`rsltvar' & origpath_i==1
				gen x2_Mcol4 = (beta_orig_j + x_z_crit95*se_orig_j)/mean_orig_j*100 if mainvar==`rsltvar' & origpath_i==1
				gen x2_Mcol5 = (beta_orig_j - x_z_crit90*se_orig_j)/mean_orig_j*100 if mainvar==`rsltvar' & origpath_i==1
				gen x2_Mcol6 = (beta_orig_j + x_z_crit90*se_orig_j)/mean_orig_j*100 if mainvar==`rsltvar' & origpath_i==1

			    gen x2_Mcol7  = beta_rel_i      				 		if mainvar==`rsltvar' & prefpath_i==1
				gen x2_Mcol8  = (`beta' - x_z_crit95*se_i)/mean_j*100 	if mainvar==`rsltvar' & prefpath_i==1
				gen x2_Mcol9  = (`beta' + x_z_crit95*se_i)/mean_j*100 	if mainvar==`rsltvar' & prefpath_i==1
				gen x2_Mcol10 = (`beta' - x_z_crit90*se_i)/mean_j*100	if mainvar==`rsltvar' & prefpath_i==1
				gen x2_Mcol11 = (`beta' + x_z_crit90*se_i)/mean_j*100	if mainvar==`rsltvar' & prefpath_i==1

				forval Mc = 2/11 {
					egen x2_Mcol`Mc'b = min(x2_Mcol`Mc')	// copy information from single obs to all obs
					local Mcol`Mc' = x2_Mcol`Mc'b			// transfer information to local that can be fed into matrix
					matrix M[`res',`Mc'] = `Mcol`Mc''
				}
				drop x2_*
				local res = `res' + 1
			}
			coefplot    (matrix(M[,2]), ci((M[,3] M[,4])   (M[,5] M[,6]))  ciopts(recast(rcap) color(navy navy))    	mcolor(navy) 	mlabcolor(navy)   	label(Original Estimate)) ///
						(matrix(M[,7]), ci((M[,8] M[,9]) (M[,10] M[,11]))  ciopts(recast(rcap) color(navy*.6 navy*.6)) 	mcolor(navy*.6) mlabcolor(navy*.6)  label(Preferred Estimate)) ///
						, xtitle("estimate as % of outcome mean") xline(0) citop legend(rows(1) pos(6)) coeflabels(`coeflab') 

			graph export  "`filepath'/repframe_fig_mainestimates_`fileidentifier'.`graphfmt'", replace as(`graphfmt')
		}

		
		capture confirm variable decision_1x, exact   // check if `decisions' was defined by whether there is at least a variable callled decision_1 generated above
		if !_rc {

			noi dis as text _newline(1) "** Three plots showing the contributions of individual decisions to deviations in indicator values"
			noi dis as text "(1) Single-Choice Deviation Plot (ch_deviation): A plot showing the change in a robustness indicator due to fixing a single decision to an alternative choice that deviates from the original specification, while all other decisions are allowed to vary according to the multiverse analysis."
			noi dis as text "(2) Stepwise Deviation Plot (stepwise): A plot illustrating the cumulative change in a robustness indicator as an increasing number of decisions deviate simultaneously from the original specification, while all other decisions are fixed to their original specification choices." 
			noi dis as text "(3) Single-Decision Reversion Plot (dec_reversion): A plot showing the change in a robustness indicator due to fixing a single decision to its original specification choice, while all other decisions are allowed to vary according to the multiverse analysis."
			noi dis _newline(1) 


			gen x_rslt_osig_ra = (pval_orig_j<=0.`sigdigits_ra')		// bin. indicator on whether results are originally significant
			// run subsequent loop over ESrel only if any result was originally significant
			if `osig_ra_rslt_N'>0 {
				local I_list  SIGagr ESrel
			}
			else {
				local I_list  SIGagr
			}

			foreach I in `I_list' {  	
				** identify results to be shown in contribution plots
				if "`I'"=="SIGagr" {
					local N_results_cplot = `N_results'
					levelsof mainvar, local(mainvars_cplot)
				}
				if "`I'"=="ESrel" {
					local N_results_cplot = `osig_ra_rslt_N' // ESrel only calculated for stat. significant original estimates
					levelsof mainvar if x_rslt_osig_ra==1, local(mainvars_cplot)
				}

				** define matrix that will include the values relevant for the contribution plots
				local vrts_matrix_N = 39
				matrix      D = J(`N_results_cplot', 6+`ch_count'*2+`vrts_matrix_N'+`d_count'*2, .)   // number of columns = (1) result  +  (3) mean indicators by outcome, expressed as deviation, one for each plot  +  (2) reference indicator values of ch_deviation and dec_reversion plot  +  (#) choices (deviations, for ch_deviation plot)  +  (#) choices (share of specifications in which choice is varied, for ch_deviation plot)  +  (39) max number decision variations (for stepwise plot; those entries not needed will remain empty)  +  (#) decisions (deviations, for dec_reversion plot)  +  (#) decisions (share of specifications in which decision choice corresponds to original specification choice, for dec_reversion plot) 
				//				  			   	   = 6+`ch_count'*2+      39       +`d_count'*2
				ds decision_*_ch*
				local chlistx `r(varlist)' 
				local chlist    = subinstr("`chlistx'", "decision_", "dec", .)
				local chvpclist = subinstr("`chlistx'", "decision_", "vpcdec", .)     // share of all specifications for the respective outcome with this choice variation
				ds decision_*x
				local declistx `r(varlist)'
				local dcnlist    = subinstr("`declistx'", "decision_", "dcn", .) 
				local dcnvpclist = subinstr("`declistx'", "decision_", "vpcdcn", .)   // share of all specifications for the respective outcome with this decision variation

				local vrtlist 
				forval v = 1/`vrts_matrix_N' {
					local vrtlist `vrtlist' vrts`v'
				}
				matrix coln D = mainvar_n  `I'_ch_deviation_mn `I'_stepwise_mn `I'_dec_reversion_mn `I'_ch_deviation_ref `I'_dec_reversion_ref   `chlist' `chvpclist'  `vrtlist'  `dcnlist' `dcnvpclist'
				
				local hbar_ylab  % change

				local res = 1  // result index
				local chlevels_N_max = 1   	// maximum number of choice levels for an individual decision
				local vrts_N_max = 0		// maximum number of variations of decision choices
				foreach rsltvar of local mainvars_cplot {
					
					** set -norm-, the value representing the original specification as reference (e.g. 100%), depending on the indicator and result
					if "`I'"=="SIGagr" {
						local norm = 100   
						count if x_rslt_osig_ra==0 & mainvar==`rsltvar'
						if `r(N)'>0 {
							local norm = 0
						}
					}
					if "`I'"=="ESrel" {
						local norm = 0   
					}

					** first matrix entry: result 
					matrix D[`res',1] = `rsltvar'	
					
					** identify decisions to be considered separately 
					// those decisions that deviate from (I) "vrdincl" (choice is varied and original choice is included in any robustness analysis path)
					// (a) bvrdnincl: binary decisions for which choice is varied, but choice from original specification is not included in any robustness analysis path -> different reference case in ch_deviation plot      
					// (b) nvrdincl: decisions for which choice is not varied, but choice from original specification is included in any robustness analysis path
					// the combination of (a) and (b) is vrdorincl (which is currently not further used)
					// (c) cvrdnincl: categorical decisions (i.e. decisions with more than two choices applied to the respective result) for which choice is varied, but choice from original specification is not included in any robustness analysis path
					// -> these are not treated separately by repframe (even though one could set the reference indicator - for which this distinction is made - to one of the category values)
					// --> instead, a list of these variables is provided in the note to the ch_deviation plot
					// (d) nvrdnincl: not varied + not included;  given that there should be no missings for decision_`d'x, there should in principle be no such cases, as it should mean that the result was not studied if both -not varied- and -not included- applies
					// (e) another case to be considered is pvrd, that is categorical decisions for which different categories are only partially included for the respective results (which are hence not nvrd like (c), but also do not consider only the varied choices like (a) and (b))  			 
					foreach dtype in bvrdnincl cvrdnincl {
						local d_`dtype'_N = 0 						// number of such decisions
						local r`rsltvar'_`dtype'_name_list			// name list of these decisions by rsltvar, as it will be used in the graph after looping over all results
					}
					gen x_r`rsltvar'_vrt_N = 0	//   number of variations, differentiated by rsltvar
					
					forval d = 1/`d_count' {
						levelsof decision_`d'x
						local chlevels_N: word count `r(levels)'
						gen x2_chlevels_N = `chlevels_N'    // number of decision choice levels, irrespective of result
						*gen x2_chlevels_N   = `r(r)'   	// alternative approach, only applicable for newer versions of Stata, as `r(r)' has not always been stored by -levelsof-
						levelsof decision_`d'x if mainvar==`rsltvar', local(chlevels_rslt)   // number of choices effectively varied, including the original choice even if it is not included in the multiverse 
						gen x2_chlevels_rslt   = "`chlevels_rslt'"
						gen x2_chlevels_rslt_N = wordcount(x2_chlevels_rslt) 
		
						if x2_chlevels_rslt_N>`chlevels_N_max' {
							local chlevels_N_max = x2_chlevels_rslt_N		// max. number of choice levels assessed for a single decision
						}
						
						 gen x2_d`d'_pcat = (x2_chlevels_N>2) 		// identify potentially categorical decisions, that is decisions with in total more than two choice options, considering all mainvars 
						 gen x2_d`d'_ecat = (x2_chlevels_rslt_N>2) 	// identify effectively categorical decisions, that is decisions with more than two choice options for the respective mainvar
						 gen x2_vrd_d  = (decision_`d'x!=0)	if mainvar==`rsltvar'   					// binary indicator on whether decision_`d'x was varied from the original specification in the analysis path for the respective mainvar
						 gen x2_incl_d = (decision_`d'x==0)	if mainvar==`rsltvar'  & origpath_i!=1  	// binary indicator on whether choice on decision_`d'x from the original specification is included in any robustness analysis path
						egen x2_vrd_N  = total(x2_vrd_d) 			// # of analysis paths for which vrd is the case
						egen x2_incl_N = total(x2_incl_d)	
						
						local d`d'_cvrdnincl_d  = (x2_vrd_N>1  & x2_incl_N==0 & x2_d`d'_ecat==1)	// bin. indicator that cvrdnincl applies to decision `d'
						local d`d'_bvrdnincl_d  = (x2_vrd_N>1  & x2_incl_N==0 & x2_d`d'_ecat==0)	// bin. indicator that bvrdnincl applies to decision `d' 
						local d`d'_nvrdincl_d   = (x2_vrd_N==0 & x2_incl_N>1)						// bin. indicator that  nvrdincl applies to decision `d'			
						local d`d'_nvrdnincl_d  = (x2_vrd_N==0 & x2_incl_N==0)						// bin. indicator that nvrdnincl applies to decision `d'
						
						local d`d'_pvrd_d = (x2_vrd_N>1  & x2_d`d'_pcat==1 & x2_chlevels_rslt_N<x2_chlevels_N)		// binary indicator that pvrd applies to decision `d'

						local d`d'_vrd_d  = (x2_vrd_N>1)		// bin. indicator required for dec_reversion plot

						replace x_r`rsltvar'_vrt_N  = x_r`rsltvar'_vrt_N + x2_vrd_d  // number of varied decisions
						
						foreach dtype in bvrdnincl cvrdnincl {
							if `d`d'_`dtype'_d'==1 {			
								local d_`dtype'_N   = `d_`dtype'_N' + `d`d'_`dtype'_d'   //  increment by 1 if local generated above is 1
								// populate decision names for which bvrdnincl, nvrdincl or cvrdnincl applies, depending on whether it is the first name or a consecutive one 
								if "`r`rsltvar'_`dtype'_name_list'"=="" {
									local r`rsltvar'_`dtype'_name_list      "`decision_`d'_name'"
								}
								else {
									local r`rsltvar'_`dtype'_name_list      `r`rsltvar'_`dtype'_name_list' & `decision_`d'_name'
								}
							}
						}
						drop x2_*
					}

					** set reference values of indicator to -norm-, separately for the first two contribution plots
					local RF2_`I'_ch_deviation_ref 	= `norm'
					local RF2_`I'_stepwise_ref 		= `norm'
					local RF2_`I'_dec_reversion_ref = `norm'

					   
					** adjust the ch_deviation indicator reference value to the indicator mean if bvrdnincl decisions are to be filtered
					local ch_deviation_r`rsltvar'_adj = 0 
					if `d_bvrdnincl_N'>0 {
						local filter_bvrdnincl  `" mainvar==`rsltvar' & origpath_i!=1 "' 
						forval d = 1/`d_count' {
							if `d`d'_bvrdnincl_d'==0 {
								local filter_bvrdnincl `" `filter_bvrdnincl' & decision_`d'x==0 "'
							}
						} 
						count if `filter_bvrdnincl'
						if `r(N)'==1 {
							if "`I'"=="SIGagr" {
								sum x_RF2_`I'_i if `filter_bvrdnincl'
								local RF2_`I'_ch_deviation_ref = round(`r(mean)')
							}
							if "`I'"=="ESrel" {
								// ESrel indicator needs to be re-calculated first for the respective subgroup of analysis paths
								egen x2_RF2_ESrel_j2 = median(`beta')	 			if pval_i<=0.`sigdigits_ra' & beta_dir_i==beta_orig_dir_j & pval_orig_j<=0.`sigdigits_ra' & sameunits_i==1 & beta2_orig_j==. & beta2_i==. & origpath_i!=1 ///
																				   & `filter_bvrdnincl'					
								gen x2_RF2_ESrel_jb = x2_RF2_ESrel_j2/beta_orig_j							
								gen x2_RF2_ESrel_j  = ((x2_RF2_ESrel_jb) - 1)*100

								sum x2_RF2_ESrel_j
								if `r(N)'>0 {			// adjust if mean can be calculated
									local RF2_`I'_ch_deviation_ref = round(`r(mean)')
								}
							}
							local ch_deviation_r`rsltvar'_adj = 1
						}	
					}
					

					** indicator mean expressed as deviation, separately for the three plots, ch_deviation, stepwise, and dec_reversion, to be included as second and third matrix entry, by mainvar
					local k = 2
					foreach plot in ch_deviation stepwise dec_reversion {
						gen   x2_RF2_`I'_rslt2 = RF2_`I'_j - `RF2_`I'_`plot'_ref' if mainvar==`rsltvar' 
						egen  x2_RF2_`I'_rslt  = min(x2_RF2_`I'_rslt2)
						local RF2_`I'_rslt  = x2_RF2_`I'_rslt
						local RF2_`I'_rslt  = round(`RF2_`I'_rslt')
						if `RF2_`I'_rslt'==0 {
							if `norm'==100 {
								local RF2_`I'_rslt = -0.5   // make sure that bar is visible in the plot 
							}	
							if `norm'==0 {
								local RF2_`I'_rslt = 0.5
							}
						}			
						matrix D[`res',`k'] = `RF2_`I'_rslt'
						local k = `k' + 1
						drop x2_*
					}

					** add ch_deviation reference expressed as deviation as fifth matrix entry, by mainvar
					matrix D[`res',5] = `RF2_`I'_ch_deviation_ref' 
	
					** add dec_reversion reference expressed as deviation as sixth matrix entry, by mainvar
					matrix D[`res',6] = `norm'

					** populate the matrix with values for the ch_deviation plot
					// these are `deviation_ch' and `ch_pc' generated below
					local ch = 1        // choice index
					local paths_total = 0   // set paths total to zero as default
					forval d = 1/`d_count' {
						levelsof decision_`d'x, local(chlevels)
						local decision_name = decision_`d'_name

						// skip bvrdnincl, nvrdincl and nvrdnincl decisions
						if (`d`d'_bvrdnincl_d' == 1 | `d`d'_nvrdincl_d'== 1 | `d`d'_nvrdnincl_d'==1) {
							foreach choice of local chlevels {
								local ch = `ch' + 1
							}
						}
						else {
							foreach choice of local chlevels {
								// skip original choice as reference case OR choice levels of categorical variables that are not included 
								sum decision_`d'x if mainvar==`rsltvar' & decision_`d'x==`choice'
								local decision_ch_N =  `r(N)'
								if (`choice' == 0 | (`d`d'_pvrd_d'==1 & `decision_ch_N'==0)) {
									local ch = `ch' + 1
								}
								else {
									// calculate the mean target value for the modified rob. choice value and the deviation from RF2_`I'_ch_deviation_ref

									if "`I'"=="ESrel" {
										// ESrel indicator needs to be re-calculated first for the respective subgroup of analysis paths
										egen x2_RF2_ESrel_j2 = median(`beta')	 			if pval_i<=0.`sigdigits_ra' & beta_dir_i==beta_orig_dir_j & pval_orig_j<=0.`sigdigits_ra' & sameunits_i==1 & beta2_orig_j==. & beta2_i==. & origpath_i!=1 ///
																				   & mainvar==`rsltvar' & include_in_multiverse==1	
										gen x2_RF2_ESrel_jb = x2_RF2_ESrel_j2/beta_orig_j							
										gen  x_RF2_ESrel_i  = ((x2_RF2_ESrel_jb) - 1)*100    // now the variable needs to be called *_i (even though it is actually an *_j variable, i.e. identical across outcome j)	
									}											   					
									sum x_RF2_`I'_i if mainvar==`rsltvar' & include_in_multiverse==1  // retrieve # of analysis paths with mainvar
									if `r(N)'>0 {	// make sure that indicator can be derived for this subgroup
										local paths_total = `r(N)'

										if "`I'"=="ESrel" {							   
										// ESrel indicator again needs to be re-calculated first for the respective subgroup of analysis paths
											drop x2_* x_RF2_ESrel_i
											egen x2_RF2_ESrel_j2 = median(`beta')	 			if pval_i<=0.`sigdigits_ra' & beta_dir_i==beta_orig_dir_j & pval_orig_j<=0.`sigdigits_ra' & sameunits_i==1 & beta2_orig_j==. & beta2_i==. & origpath_i!=1 ///
																					& mainvar==`rsltvar' & decision_`d'x == `choice'					
											gen x2_RF2_ESrel_jb = x2_RF2_ESrel_j2/beta_orig_j							
											gen  x_RF2_ESrel_i  = ((x2_RF2_ESrel_jb) - 1)*100    // now the variable needs to be called *_i (even though it is actually an *_j variable, i.e. identical across outcome j)
										}

										sum x_RF2_`I'_i if mainvar==`rsltvar' & decision_`d'x == `choice'  // implies: & include_in_multiverse==1, since `choice'!=0
										if `r(N)'>0 {
											local paths_combi = `r(N)'

											local mean_target_ch = `r(mean)'
											local ch_pc = round(`paths_combi'/`paths_total'*100)
											local deviation_ch = `mean_target_ch' - `RF2_`I'_ch_deviation_ref' 
										}
										else {
											local ch_pc = .
											local deviation_ch = . 
										}	
									}
									else {
										local ch_pc = .
										local deviation_ch = . 
									}	
								
									if "`I'"=="ESrel" {
										drop x2_* x_RF2_ESrel_i     	// drop again to avoid misinterpretation of this variable 
									}


									// store the result in the matrix for use in the ch_deviation plot
									if `deviation_ch'==0 {
										if `norm'==100 {
											local deviation_ch = -0.5   // make sure that bar is visible in the plot 
										}	
										if `norm'==0 {
											local deviation_ch = 0.5  
										}
									}
									matrix D[`res',6+`ch'] = `deviation_ch'
									matrix D[`res',6+`ch_count'+`ch'] = `ch_pc'  
									local ch = `ch' + 1
								}		
							}
						}
					}
	
					** populate the matrix with the values `deviation_vrt' for the stepwise plot
					sum x_r`rsltvar'_vrt_N
					local r_vrts_N_max = `r(max)'
					if `r_vrts_N_max'>`vrts_N_max' { 
						local vrts_N_max = `r_vrts_N_max'  	// conditional change of maximum number of decision variations
					}
					if `r_vrts_N_max' > `vrts_matrix_N' {
						local r_vrts_N_max == `vrts_matrix_N'	// truncating r_vrt_N_max, because plot allows showing up to `vrts_matrix_N' decision variations
					}
					
					forval vrt = 1/`r_vrts_N_max' {
						count if x_r`rsltvar'_vrt_N==`vrt'   // check if indeed more than zero analysis paths feature `vrt' variations  
						if `r(N)'>0 {
							if "`I'"=="SIGagr" {
								sum x_RF2_`I'_i if x_r`rsltvar'_vrt_N==`vrt'
							}
							if "`I'"=="ESrel" {
								// ESrel indicator needs to be re-calculated first for the respective subgroup of analysis paths
								egen x2_RF2_ESrel_j2 = median(`beta')	 			if pval_i<=0.`sigdigits_ra' & beta_dir_i==beta_orig_dir_j & pval_orig_j<=0.`sigdigits_ra' & sameunits_i==1 & beta2_orig_j==. & beta2_i==. & origpath_i!=1 ///
																				       & x_r`rsltvar'_vrt_N==`vrt'				
								gen x2_RF2_ESrel_jb = x2_RF2_ESrel_j2/beta_orig_j							
								gen x2_RF2_ESrel_j  = ((x2_RF2_ESrel_jb) - 1)*100

								sum x2_RF2_ESrel_j
							}

							if `r(N)'>0 {			// adjust if mean can be calculated
								local mean_target_vrt = `r(mean)'	
								local deviation_vrt =  `mean_target_vrt' - `norm'
								if `deviation_vrt'==0 {
									if `norm'==100 {
										local deviation_vrt = -0.5   // make sure that bar is visible in the plot 
									}	
									if `norm'==0 {
										local deviation_vrt = 0.5  
									}
								}
							}
							else {
								local deviation_vrt = 0
							}
							capture drop x2_*   // should not be dropped after -sum x2_RF2_ESrel_j-, because later Stata versions store results after the command drop so that the subsequent `r(N)' cannot be retrieved anymore from the -sum- command

							matrix D[`res',6+`ch_count'*2+`vrt'] = `deviation_vrt'
						}
						else {
							matrix D[`res',6+`ch_count'*2+`vrt'] = .
						}
					}


					** populate the matrix with the dec_reversion values
					// recycle and slightly adjust code from above under - calculate the mean target value [...] from RF2_`I'_ch_deviation_ref -
					
					forval d = 1/`d_count' {
						if "`paths_total'"!="0" {	// make sure that indicator can be derived for this subgroup
							if "`I'"=="ESrel" {							   
								// ESrel indicator again needs to be re-calculated first for the respective subgroup of analysis paths
								egen x2_RF2_ESrel_j2 = median(`beta')	 			if pval_i<=0.`sigdigits_ra' & beta_dir_i==beta_orig_dir_j & pval_orig_j<=0.`sigdigits_ra' & sameunits_i==1 & beta2_orig_j==. & beta2_i==. & origpath_i!=1 ///
																					& mainvar==`rsltvar' & decision_`d'x == 0		// decision_`d'x == 0 instead of   == `choice'	 			
								gen x2_RF2_ESrel_jb = x2_RF2_ESrel_j2/beta_orig_j							
								gen  x_RF2_ESrel_i  = ((x2_RF2_ESrel_jb) - 1)*100    // now the variable needs to be called *_i (even though it is actually an *_j variable, i.e. identical across outcome j)
							}

							sum x_RF2_`I'_i if mainvar==`rsltvar' & include_in_multiverse==1 & decision_`d'x == 0 
							if `r(N)'>0 {
								local paths_combi = `r(N)'

								local mean_target_d = `r(mean)'
								local d_pc = round(`paths_combi'/`paths_total'*100)
								local deviation_d = `mean_target_d' - `norm' 
							}
							else {
								local d_pc = .
								local deviation_d = . 
							}

							if "`I'"=="ESrel" {
								drop x2_* x_RF2_ESrel_i     	// drop again to avoid misinterpretation of this variable 
							}			
						}
						else {
							local d_pc = .
							local deviation_d = . 
						}

						// store the result in the matrix for use in the dec_reversion plot
						if `deviation_d'==0 {
							if `norm'==100 {
								local deviation_d = -0.5   // make sure that bar is visible in the plot 
							}	
							if `norm'==0 {
								local deviation_d = 0.5  
							}
						}

						matrix D[`res',6+`ch_count'*2+`vrts_matrix_N'+`d'] 			 = `deviation_d'
						matrix D[`res',6+`ch_count'*2+`vrts_matrix_N'+`d_count'+`d'] = `d_pc'  
						local d = `d' + 1
					}

					drop x_r`rsltvar'_vrt_N   // needs to be dropped when running loop over multiple indicators

					local res = `res' + 1
				}


				** show note that contribution plots would involve too many decisions and/ or decision choices and/ or decision variations
				if (`chlevels_N_max'>99 | `d_count'>99) {
					if "`I'"=="SIGagr" {		// show note in results window only once (not for "`I'"=="ESrel")
						noi dis as text "The analyis involves a huge number of decisions and/ or decision choices (100 or more). The Contribution Plots are therefore not produced. Consider creating individual Contribution Plots by running the {it:repframe} command separately for individual results, or alternatively check whether choices treated as separate decisions do not effectively belong to the same decision dimension." 
					}
				}
				else{
					if "`I'"=="SIGagr" {		// show note in results window only once (not for "`I'"=="ESrel")
						if (`chlevels_N_max'>9 | `d_count'>9) {
							noi dis as text "The analyis involves many decisions and/ or decision choices (10 or more). The Contribution Plots may therefore not be presented in a nice way. Consider creating individual Contribution Plots by running the {it:repframe} command separately for individual results, or alternatively check whether choices treated as separate decisions do not effectively belong to the same decision dimension." 
						}
						if `vrts_N_max'>`vrts_matrix_N' {
							noi dis as text "Note that the analyis involves `vrts_N_max' decision variations for at least one of the results. The Contribution Plot by the number of variations will only show values for up to `vrts_matrix_N' variations." 
						}
					}


					** visualization of contributions in the three contribution plots

					*** dec_reversion legend needs to be created before svmat, since it requires var label information
					local hbar3_leglab  `"label(1 "overall mean by result") "'
					forval d = 1/`d_count' {
						local dlabname : variable label  decision_`d'x
						local dplus1 = `d' + 1
						local hbar3_leglab `" `hbar3_leglab' label(`dplus1' "`dlabname'") "' 
					}


					preserve
						drop _all
						svmat D, names(col)
						label val mainvar_n mainvar

						** define legend labels				
						*** for hbar1 (ch_deviation) 
						local dandclist_forhbar1
						local hbar1_j      = 2   //  running number of type of hbar1, 1 is overall mean by result
						local hbar1_leglab  `"label(1 "overall mean by result") "'
						gen x_add11_str = `" label("'
						gen x_add12_str = `" ""'
						gen x_add13_str = `"") "'	
						ds dec*
						foreach dandc in `r(varlist)' {
							egen x2_forhbar1_N = count(`dandc')
							local forhbar1_N = x2_forhbar1_N
							if `forhbar1_N'!=0 {
								local dandclist_forhbar1 `dandclist_forhbar1' `dandc'				
								local ch_nx  = substr("`dandc'", -2,2)
								local dec_nx = substr("`dandc'", 4,2)	
								local ch_n  = subinstr("`ch_nx'", "h", "", .)   // remove strings from one-digit choice numbers
								local dec_n = subinstr("`dec_nx'", "_", "", .)
							
								local ch_label: label decision_`dec_n' `ch_n'
								gen x2_ch_label = "`ch_label'"
								gen x2_hbar1_j = `hbar1_j'
								egen x2_ch_label_fmt = concat(x_add11_str x2_hbar1_j x_add12_str x2_ch_label x_add13_str) 
								local x_ch_label_fmt = x2_ch_label_fmt
									
								local hbar1_leglab `hbar1_leglab' `x_ch_label_fmt'

								local hbar1_j = `hbar1_j' + 1 
							}
							drop x2_*
						}
						local hbar1_types_N = `hbar1_j' - 1   // number of bar types shown in the hbar1 graph

						*** for hbar2 (stepwise)
						local vrtlist_forhbar2
						local hbar2_type_n = 2		//  running number of types, with 1 again being the overall mean by result

						forval vrtval = 1/1 {
							egen x2_vrts`vrtval'_min = min(vrts`vrtval')
							if x2_vrts`vrtval'_min!=. {
								local vrtlist_forhbar2 `vrtlist_forhbar2' vrts`vrtval'
								local hbar2_leglab  `"label(1 "overall mean by result") label(2 "1 decision varied") "'
								local hbar2_type_n = `hbar2_type_n' + 1
							}
							else {
								local hbar2_leglab  `"label(1 "overall mean by result") "'
							}
						}				
						forval vrtval = 2/9 {
							egen x2_vrts`vrtval'_min = min(vrts`vrtval')
							if x2_vrts`vrtval'_min!=. {
								local vrtlist_forhbar2 `vrtlist_forhbar2' vrts`vrtval'
								local hbar2_leglab `" `hbar2_leglab' label(`hbar2_type_n' "`vrtval' decisions varied") "' 
								local hbar2_type_n = `hbar2_type_n' + 1
							}
						}
						forval vrtval = 10/`vrts_matrix_N' {
							egen x2_vrts`vrtval'_min = min(vrts`vrtval')
							if x2_vrts`vrtval'_min!=. {
								local vrtlist_forhbar2 `vrtlist_forhbar2' vrts`vrtval'
								local hbar2_leglab `" `hbar2_leglab' label(`hbar2_type_n' "`vrtval' decisions varied") "' 
								local hbar2_type_n = `hbar2_type_n' + 1
							}
						}
						drop x2_*
				
						local hbar2_types_N = `hbar2_type_n' - 1

						*** for hbar3 (dec_reversion)
						* local hbar3_leglab already created above
						local hbar3_types_N = `d_count' + 1  // +1 for overall mean by result


						** main set of hbars to show in plots
						local hbar1_main `I'_ch_deviation_mn `dandclist_forhbar1'
						local hbar2_main `I'_stepwise_mn `vrtlist_forhbar2'
						local hbar3_main `I'_dec_reversion_mn `dcnlist'


						** prepare vpcdec*_ch* (share of specifications including this choice) to be added into ch_variation plot (hbar1)
						local hbar1_i_beta = 1   //  running number of hbar1, will be revised below
						foreach rsltvar of local mainvars_cplot {
							local hbar1_add_`hbar1_i_beta' // keep empty for overall mean
							local hbar1_i_beta = `hbar1_i_beta' + 1
							ds dec*
							foreach dandc in `r(varlist)' {
								egen x2_forhbar1_N = count(`dandc')
								local forhbar1_N = x2_forhbar1_N
								if `forhbar1_N'!=0 {
									local ch_nx  = substr("`dandc'", -2,2)
									local dec_nx = substr("`dandc'", 4,2)	
									local ch_n  = subinstr("`ch_nx'", "h", "", .)   // remove strings from one-digit choice numbers
									local dec_n = subinstr("`dec_nx'", "_", "", .)	
									local hbar1_add_`hbar1_i_beta'  "`=vpcdec`dec_n'_ch`ch_n'[`rsltvar']'"
									if `hbar1_add_`hbar1_i_beta''!=. {   // skip empty bars
										local hbar1_i_beta = `hbar1_i_beta' + 1
									}
								}
								drop x2_*
							}
						}
						local hbar1_i_beta_count = `hbar1_i_beta' - 1
						
						forval ch_o = 1/`hbar1_i_beta_count' {
							local ch_r = `hbar1_i_beta_count' - `ch_o' + 1  // reverse order, because .Graph.plotregion1.barlabels[`i'] reads bars in reverse order
							local hbar1_add_rev`ch_r' `hbar1_add_`ch_o''
						}


						** prepare vpcdcn*x (share of specifications including this decision choice) to be added into dec_variation plot (hbar3)
						local hbar3_i_beta = 1   //  running number of hbar3, will be revised below
						foreach rsltvar of local mainvars_cplot {
							local hbar3_add_`hbar1_i_beta' // keep empty for overall mean
							local hbar3_i_beta = `hbar3_i_beta' + 1
							ds dcn*x
							foreach dcn in `r(varlist)' {
								egen x2_forhbar3_N = count(`dcn')
								local forhbar3_N = x2_forhbar3_N
								if `forhbar3_N'!=0 {
									local dcn_nx = substr("`dcn'", 4,2)	 
									local dcn_n = subinstr("`dcn_nx'", "_", "", .)	// remove strings from one-digit choice numbers
									local hbar3_add_`hbar3_i_beta'  "`=vpcdcn`dcn_n'[`rsltvar']'"
									if `hbar3_add_`hbar3_i_beta''!=. {   // skip empty bars
										local hbar3_i_beta = `hbar3_i_beta' + 1
									}
								}
								drop x2_*
							}
						}
						local hbar3_i_beta_count = `hbar3_i_beta' - 1
						
						forval dcn_o = 1/`hbar3_i_beta_count' {
							local dcn_r = `hbar3_i_beta_count' - `dcn_o' + 1  // reverse order, because .Graph.plotregion1.barlabels[`i'] reads bars in reverse order
							local hbar3_add_rev`dcn_r' `hbar3_add_`dcn_o''
						}


						** define plot notes and bar labels
						local hbar1_note_and_blabel  `"note("{it:[% of analysis paths including the choice variation]}", size(vsmall)) blabel(bar, color(gs5) position(base) size(vsmall))"'
						local hbar2_note_and_blabel   // empty local
						local hbar3_note_and_blabel  `"note("{it:[% of analysis paths including the original decision choice]}", size(vsmall)) blabel(bar, color(gs5) position(base) size(vsmall))"'


						** determine minimum value shown in the hbar plots as input for -local plotgap_left-
						egen x2_hbar1_min2 = rowmin(dec*)
						egen x2_hbar2_min2 = rowmin(vrts*)
						egen x2_hbar3_min2 = rowmin(dcn*x)
						for num 1/3: egen x_hbarX_min = min(x2_hbarX_min2)
						

						** split result labels that are too long and join them into `relabel_list' 
						foreach rsltvar of local mainvars_cplot {
							local rsltval_lab: label (mainvar_n) `rsltvar', strict	
							gen x_mainvar_r`rsltvar' = "`rsltval_lab'"
						}

						// workaround used to add special characters to the string variable label in contribution plots
						gen x_add1_str = "`"
						gen x_add2_str = `"" ""'
						gen x_add3_str = "'"
						gen x_add4_str = `"""'
						gen x_add5_str = `"" " " ""'
						
						forval hbar_n = 1/3 {
							** account for different reference values by mainvar_n to be shown in ch_deviation (hbar1) and dec_reversion (hbar3) plot
							if `hbar_n'==2 {
								foreach xtr in min max {
									local I_ref_`xtr' = .
								}
							}
							else {
								foreach xtr in min max {
									if `hbar_n'==1 {
										egen x2_I_ref_`xtr' = `xtr'(`I'_ch_deviation_ref)
									}
									if `hbar_n'==3 {
										egen x2_I_ref_`xtr' = `xtr'(`I'_dec_reversion_ref)
									}
									local   I_ref_`xtr' = x2_I_ref_`xtr'
								}
							}

							** main relabelling step
							local relabel_hbar_list
							foreach rsltvar of local mainvars_cplot {
								local mainvar_active = x_mainvar_r`rsltvar'

								gen x2_mainvar_str_word_count = wordcount(x_mainvar_r`rsltvar')

								gen     x2_str_first_part  = word(x_mainvar_r`rsltvar', 1) + " " + word(x_mainvar_r`rsltvar', 2)                              			if (x2_mainvar_str_word_count==3 | x2_mainvar_str_word_count==4)
								gen     x2_str_second_part = word(x_mainvar_r`rsltvar', 3)                              							    				if  x2_mainvar_str_word_count==3
								replace x2_str_second_part = word(x_mainvar_r`rsltvar', 3) + " " + word(x_mainvar_r`rsltvar', 4)                              			if  x2_mainvar_str_word_count==4

								replace x2_str_first_part  = word(x_mainvar_r`rsltvar', 1) + " " + word(x_mainvar_r`rsltvar', 2) + " " + word(x_mainvar_r`rsltvar', 3) 	if (x2_mainvar_str_word_count==5 | x2_mainvar_str_word_count==6)
								replace x2_str_second_part = word(x_mainvar_r`rsltvar', 4) + " " + word(x_mainvar_r`rsltvar', 5)                             			if  x2_mainvar_str_word_count==5
								replace x2_str_second_part = word(x_mainvar_r`rsltvar', 4) + " " + word(x_mainvar_r`rsltvar', 5) + " " + word(x_mainvar_r`rsltvar', 6) 	if  x2_mainvar_str_word_count==6

								replace x2_str_first_part  = word(x_mainvar_r`rsltvar', 1) + " " + word(x_mainvar_r`rsltvar', 2) + " " + word(x_mainvar_r`rsltvar', 3) + " " + word(x_mainvar_r`rsltvar', 4) 	if (x2_mainvar_str_word_count==7 | x2_mainvar_str_word_count==8)
								replace x2_str_second_part = word(x_mainvar_r`rsltvar', 5) + " " + word(x_mainvar_r`rsltvar', 6) + " " + word(x_mainvar_r`rsltvar', 7)                              			if  x2_mainvar_str_word_count==7
								replace x2_str_second_part = word(x_mainvar_r`rsltvar', 5) + " " + word(x_mainvar_r`rsltvar', 6) + " " + word(x_mainvar_r`rsltvar', 7) + " " + word(x_mainvar_r`rsltvar', 8)  	if  x2_mainvar_str_word_count==8

								** different reference labeling, depending on whether the references are identical across results
								local I_hbar1_ref "`=`I'_ch_deviation_ref[`rsltvar']'"
								local I_hbar3_ref "`=`I'_dec_reversion_ref[`rsltvar']'"		// "`I_hbar3_ref'" always corresponds to the norm value, see above under "add dec_reversion reference" 

								// case 1: reference added at bottom of figure for hbar1 and hbar3, as reference is always the same + hbar2
								local hbar_text		// empty local as default
								if (((`hbar_n'==1 | `hbar_n'==3) & `I_ref_min'==`I_ref_max') | `hbar_n'==2) {
									egen x2_mainvar_str1 = concat(x_add1_str x_add2_str  x2_str_first_part  x_add2_str  x2_str_second_part x_add2_str x_add3_str)   // splitted version of label
									egen x2_mainvar_str2 = concat(x_add4_str x_mainvar_r`rsltvar' x_add4_str)														// splitted version of label
									if (`hbar_n'==1 | `hbar_n'==3) {
										local hbar_text ref=`I_ref_max'%
										if `hbar_n'==1 & `ch_deviation_r`rsltvar'_adj'==1 {
											local hbar_text ref=`I_ref_max'%*			// add asterisk in hbar1 if reference is different original specification 
										}	
									}
								}
								// case 2: reference differs across mainvars and therefore needs to be included by mainvar_n
								if (`hbar_n'==1 | `hbar_n'==3) & `I_ref_min'!=`I_ref_max' {
									if `ch_deviation_r`rsltvar'_adj'==0 {				
										gen     x2_str_ref_part  = "{it:ref = " + "`I_hbar`hbar_n'_ref'" + "%}" 
									}
									if `ch_deviation_r`rsltvar'_adj'==1 {
										gen     x2_str_ref_part  = "{it:ref = " + "`I_hbar`hbar_n'_ref'" + "%}*"		// add asterisk in hbar1 if reference is different original specification 
									}
									egen x2_mainvar_str1 = concat(x_add1_str x_add2_str  x2_str_first_part  x_add2_str  x2_str_second_part  x_add5_str  x2_str_ref_part  x_add2_str x_add3_str) 
									egen x2_mainvar_str2 = concat(x_add1_str x_add2_str  x_mainvar_r`rsltvar' x_add5_str  x2_str_ref_part  x_add2_str x_add3_str) 
								}
						
								if `hbar_n'==1 & `ch_deviation_r`rsltvar'_adj'==1 & "`I'"=="SIGagr" {  // show note in results window only once (not for "`I'"=="ESrel")
									noi dis as text _newline(1) "Note on the Contribution Plots:"
									noi dis as text "* = reference for result -`mainvar_active'- is not the original specification, but the specification where all choices are set to the original specification choices except for decision(s) -`r`rsltvar'_bvrdnincl_name_list'-. This is done because the original choice(s) is (are) not included in the multiverse analysis for this (these) decision(s), whereas one alternative choice (each) is included in the multiverse analysis."  
								}

								gen     x2_mainvar_str = x2_mainvar_str1 if x2_mainvar_str_word_count>=3 & x2_mainvar_str_word_count<=8
								replace x2_mainvar_str = x2_mainvar_str2 if x2_mainvar_str_word_count<3  | x2_mainvar_str_word_count>8
								local relabel_hbar_str = x2_mainvar_str 
								local relabel_hbar_list `relabel_hbar_list' `rsltvar' `relabel_hbar_str'

								drop x2_*

								** additional figure note for the case of... 
								if `hbar_n'==1 & "`r`rsltvar'_cvrdnincl_name_list'"!="" {
									if "`I'"=="SIGagr" {		// show note in results window only once (not for "`I'"=="ESrel")
										noi dis as text _newline(1) "Additional note on Contribution Plots: For the result -`mainvar_active'-, the original choice(s) of the decision(s) -`r`rsltvar'_cvrdnincl_name_list'- is/ are modified in various ways in the multiverse analysis, but the original choice is not included in the multiverse analysis."  
									}
								}
							}

							** define hbar colorization
							for num 2/`hbar`hbar_n'_types_N': gen x2_hbars_cX = (`hbar`hbar_n'_types_N'-X+1)/`hbar`hbar_n'_types_N'	   // varying color intensity depending on the number of choices presented
							local hbars_show 			// populate local with bars to show in graph, depending on the number of decisions to be presented
							forval k = 2/`hbar`hbar_n'_types_N' {
								local hbars_c`k' = round(x2_hbars_c`k', 0.01)
								local hbars_show `hbars_show' bar(`k', fcolor(navy*`hbars_c`k'') lw(none))
							}
							drop x2_*

							** define plotgap_left 
							// conditionally increase gap at the left of the graph to make sure that text in plot does not overlap with y-axis
							local plotgap_left // empty local
							if  x_hbar`hbar_n'_min>-20 & x_hbar`hbar_n'_min<0 {
								local plotgap_left   plotregion(margin(large))
							} 

							if `hbar`hbar_n'_types_N'>1 {     // show plot only if more than one type to be presented
								** create hbar graph
								graph hbar `hbar`hbar_n'_main', over(mainvar_n, gap(200) relabel(`relabel_hbar_list'))  ///
								bargap(20) bar(1, fcolor(none) lw(thin)) `hbars_show'  ///
								ytitle(`hbar_ylab') text(0 0 "`hbar_text'", place(s) size(vsmall)) legend(`hbar`hbar_n'_leglab' bmargin(medium)) scheme(white_viridis) ///
								`hbar`hbar_n'_note_and_blabel' `plotgap_left'

								if `hbar_n'==1 | `hbar_n'==3  { 
									local nb=`.Graph.plotregion1.barlabels.arrnels'
									forval i=1/`nb' {
										.Graph.plotregion1.barlabels[`i'].text[1]="`: di `hbar`hbar_n'_add_rev`i'' '"
										if "`hbar`hbar_n'_add_rev`i''"!="" & "`hbar`hbar_n'_add_rev`i''"!="."  {
											.Graph.plotregion1.barlabels[`i'].text[1]="[`.Graph.plotregion1.barlabels[`i'].text[1]'%]"
										}
									}
									* .Graph.plotregion1.added_text[1].[SOMETHING] `I_hbar'    // ideally, if multiple hbar graphs were created, one would give the graph a name here, since name(`I_hbar', replace) cannot be applied under -graph hbar- in this setup with post hbar editing
									.Graph.drawgraph

									if `hbar_n'==1  { 
										graph export  "`filepath'/repframe_fig_ch_deviation_`I'_`fileidentifier'.`graphfmt'", replace as(`graphfmt')
									}
									if `hbar_n'==3 { 
										graph export  "`filepath'/repframe_fig_dec_reversion_`I'_`fileidentifier'.`graphfmt'", replace as(`graphfmt')
									}
								}
								if `hbar_n'==2 { 
									graph export  "`filepath'/repframe_fig_stepwise_`I'_`fileidentifier'.`graphfmt'", replace as(`graphfmt')
								}
							}
							else {
								noi dis as text "The Contribution Plots are only created if more than one choice / one dimension is varied."
							}
						}
					restore					
				}
			}
		}
	

*** Save dataset with one observation per analysis path
		drop x_* mainvar_in include_in_multiverse  // drop auxiliary variables 
		capture drop pval_05tF_i pval_01tF_i    // drop auxiliary variables if they were generated in the first place, because of tFinput() option
		drop beta_rel_i se_rel_i  se_rel_orig_j  beta_abs_orig_p`sigdigits_ra'_j se_orig_p`sigdigits_ra'_j    // drop derivative variables not required anymore - beta_rel_orig_j is later included in the indicator table
		
		preserve
			gen ref = "`shortref'"
			clonevar beta_i = `beta'
			
			local df_forsave   // include degrees of freedom if they were defined
			if "`df'"!="" {
				rename `df' df_i
				local df_forsave   df_i
				label var df_i "degrees of freedom in analysis paths of rob. test or original study"
			}

			local coeff2_forsave   // include variables on second coefficient that are not anyways created, if second coefficient is part of analysis
			capture confirm variable zscore2_i, exact  
			if !_rc {
				local coeff2_forsave   beta2_i se2_i pval2_i zscore2_i beta2_dir_i  beta2_orig_j se2_orig_j pval2_orig_j zscore2_orig_j beta2_orig_dir_j
							
				label var se2_i 			"s.e. of 2nd beta coeff. in analysis path of rob. test or original study"
				label var zscore2_i 		"t/z-score of 2nd estimate in analysis path of rob. test or original study"
				label var se2_orig_j 		"s.e. of 2nd beta coeff. in analysis path of original study"
				label var zscore2_orig_j 	"t/z-score of 2nd estimate in analysis path of original study"
			}

			local iva_forsave	// include first-age F-Stat if defined for IV estimations
			if "`ivadjust'"=="tF" {	
				rename `atFvar' ivF_i 
				rename pval_0`iva_level'iva_orig_j pval_0`iva_level'tF_orig_j
				local iva_forsave   ivF_i pval_0`iva_level'tF_orig_j
				label var ivF_i "First-stage F-Statistic for IV estimation in rob. test or original study"
				label var pval_0`iva_level'tF_orig_j	"p-value in analysis path of original study based on tF-adjusted critical values for `iva_level'% significance"
			}
			if "`ivadjust'"=="VtF" {	
				rename `atFvar' VtF_critval_i 
				local iva_forsave   VtF_critval_i
				label var VtF_critval_i "VtF critical value for IV estimation in rob. test or original stud
			}
			if "`ivadjust'"=="AR" {	
				local iva_forsave pval_ar_i	
				rename pval_0`iva_level'iva_orig_j pval_ar_orig_j
				label var pval_ar_i 		"AR p-value on stat. sign. of estimate in analysis path of rob. test or orig. study"
				label var pval_ar_orig_j 	"AR p-value on stat. sign. of estimate in analysis path of orig. study"
			}

			capture confirm variable decision_1x, exact   // check if `decisions' was defined by whether there is at least a variable callled decision_1 generated above
			if !_rc {
				ds decision_*x
				foreach var in `r(varlist)' {
					decode `var', gen(c_`var'_str)
				} 
				rename c_decision_*x_str choice_decision_*_str
				rename decision_*_ch* 	decision_*_ch*_name

				for num 1/`d_count': label var choice_decision_X_str    "choice in analytical decision variable #X, in string format"
				for num 1/`d_count': label var decision_X_name	 		"name of analytical decision variable #X"
				forval d = 1/`d_count' {
					levelsof decision_`d'x, local(dvar_val)
					foreach ch of local dvar_val {
						capture label var decision_`d'_ch`ch'_name "name of choice #`ch' of analytical decision variable #`d'" 
					}
				}
				drop decision_*x

				local decisions_forsave  choice_decision_*_str decision_*_name
			}

			local prefpath_forsave		// include variable with preferred paths if defined
			capture confirm variable prefpath_i, exact    
			if !_rc {
				local prefpath_forsave  prefpath_i
				label var prefpath_i 	"preferred analysis path of robustness test"
			}

			drop mainvar `beta' RF*  beta_rel_orig_j 

			order beta2_i pval2_i beta2_dir_i  beta2_orig_j pval2_orig_j beta2_orig_dir_j	// variables on second coefficient that are created irrespective of whether second coefficient is part of analysis
			order ref   mainvar_str   beta_i se_i pval_i zscore_i `df_forsave' beta_dir_i   origpath_i beta_orig_j se_orig_j pval_orig_j zscore_orig_j beta_orig_dir_j   `decisions_forsave'   mean_j mean_orig_j orig_in_multiverse_i `prefpath_forsave' sameunits_i `iva_forsave'  `coeff2_forsave' 
			label var ref 				"study reference"
			label var mainvar_str   	"result, in string format"
			label var beta_i 			"beta coeff. in analysis path of rob. test, incl. original beta coeff."
			label var se_i 				"s.e. of beta coeff. in analysis path of rob. test or original study"
			label var pval_i 			"p-value on stat. sign. of estimate in analysis path of rob. test or orig. study"
			label var zscore_i 			"t/z-score of estimate in analysis path of rob. test or original study"
			label var beta_dir_i   		"direction of beta coeff. in analysis path of rob. test, incl. orig. beta coeff."
			label var origpath_i 		"analysis path from original study"
			label var beta_orig_j 		"beta coeff. in analysis path of original study"
			label var se_orig_j 		"s.e. of beta coeff. in analysis path of original study"
			label var pval_orig_j 		"p-value on stat. sign. of estimate in analysis path of orig. study"
			label var zscore_orig_j 	"t/z-score of estimate in analysis path of original study"
			label var beta_orig_dir_j 	"direction of beta coeff. in analysis path of orig. beta coeff."

			label var mean_j 			"mean of result variable in the analysis path of rob. test and original study"
			label var mean_orig_j 		"mean of result variable in the analysis path of rob. test and original study"
			label var orig_in_multiverse_i "original specification incuded in set of analysis paths of rob. test"
			label var sameunits_i		"orig. study and analysis path of robustness test use same effect size unit"

			label var beta2_i 			"2nd beta coeff. in analysis path of rob. test, incl. original beta coeff."
			label var pval2_i 			"p-value on stat. sign. of 2nd estimate in an. path of rob. test or orig. study"
			label var beta2_dir_i   	"direction of 2nd beta coeff. in analysis path of rob. test, incl. orig. beta"
			label var beta2_orig_j 		"2nd beta coeff. in analysis path of original study"
			label var pval2_orig_j 		"p-value on stat. sign. of 2nd estimate in analysis path of orig. study"
			label var beta2_orig_dir_j 	"direction of 2nd beta coeff. in analysis path of orig. beta coeff."

			save "`filepath'/repframe_data_analysispaths_`fileidentifier'.dta", replace
		restore


*** Collapse indicator values to one observation per result  
		bysort mainvar: gen n_j = _n
		
		keep if n_j==1
		drop n_j  `beta' se_i pval_i zscore_i beta_dir_i `df' `atFvar'   beta2_i pval2_i beta2_dir_i   origpath_i orig_in_multiverse_i  sameunits_i   	// drop information at a different level than the aggregated level
		drop      se_orig_j zscore_orig_j   mean_j mean_orig_j	beta2_orig_j pval2_orig_j beta2_orig_dir_j		// drop information not required anymore 
		capture drop decision_*
		capture drop se2_i se2_orig_j zscore2_i zscore2_orig_j 
	}	

	if `studypooling'==1 {	

		preserve
			drop mainvar RF2_*
			rename *_oa_all *

			tempfile data_pooled_k			// data with k being the unit of observation = the study when pooling across studies
			save `data_pooled_k'
		restore

		order mainvar mainvar_str 

		rename *_osig_oa_all  *1
		rename *_onsig_oa_all *2
		rename *_osig_ra_all  *3
		rename *_onsig_ra_all *4
		
		
		reshape long `RF_list_nosfx' `RF2_osig_list_nosfx' RF2_SIGvar_sig RF2_SIGsw_btosig RF2_SIGsw_setosig, i(mainvar) j(level)
		
		** if pooled across studies, the reference for statistical significance may differ between oa and rep
		gen     pval_orig_oa = 0.`sigdigits_oa' - 0.01 if level==1 		// originally sig results have pval below 0.`sigdigits_oa' -> used to distinguish indicators below
		replace pval_orig_oa = 0.`sigdigits_oa' + 0.01 if level==2
		gen     pval_orig_ra = 0.`sigdigits_ra' - 0.01 if level==3 		
		replace pval_orig_ra = 0.`sigdigits_ra' + 0.01 if level==4

		** generate RF2_SIGagr_sigde2 analogously to the `studypooling'==0 case above
		bysort level: egen x_RF2_SIGagr_sigdef_any = min(RF2_SIGagr_sigdef)
 				       gen   RF2_SIGagr_sigde2     = .
		  		   replace   RF2_SIGagr_sigde2  = RF2_SIGagr_sigdef	if x_RF2_SIGagr_sigdef_any>0 & x_RF2_SIGagr_sigdef_any<.
			 	   replace   RF2_SIGagr_sigde2  = 0 				if x_RF2_SIGagr_sigdef_any>0 & x_RF2_SIGagr_sigdef_any<. & RF2_SIGagr!=. & RF2_SIGagr_sigde2==.

		drop level x_*
		
		ds mainvar mainvar_str, not 
		foreach var in `r(varlist)' {
			rename `var' `var'_j		// now _j stands for study
		}		
		
		order  mainvar mainvar_str `RF_list_j' `RF2_list_j'	
	}
				


************************************************************
***  PART 3.C  INDICATORS ACROSS ALL RESULTS/ STUDIES
************************************************************
	
*** Indicator Set RF
	if `studypooling'==1 {
		gen pval_orig_j = pval_orig_oa_j	//   if pooled across studies, pval_orig_j is first set to pval_orig_oa_j for the first Indicator Set, before it is set to pval_orig_ra_j below under the second Indicator Set; after that, it is set to missing
	}

	if `ivarweight'==0 {
		foreach RF_ind of local RF_list_nosfx {
			egen `RF_ind'_osig_oa_all  = mean(`RF_ind'_j) if pval_orig_j<=0.`sigdigits_oa'
			egen `RF_ind'_onsig_oa_all = mean(`RF_ind'_j) if pval_orig_j>0.`sigdigits_oa'
		}
	
		if `shelvedind'==1 {			
			foreach approach in A B {
				drop RF_pooledH_`approach'_osig_oa_all RF_pooledH_`approach'_onsig_oa_all  // different aggregation approach than the mean-based one applied above
				if `studypooling'==0 {
					 gen  x_RF_pooledH_`approach'_j2   		= 2*(1 - normal(abs(RF_pooledH_`approach'_j))) 	if (RF_pooledH_`approach'_j>=0 & beta_orig_dir_j==1) | (RF_pooledH_`approach'_j<0 & beta_orig_dir_j==0)
					 gen  x_RF_pooledH_`approach'_j   		= (x_RF_pooledH_`approach'_j2<=0.`sigdigits_oa')*100 if x_RF_pooledH_`approach'_j2!=.
				}
				else {
					gen  x_RF_pooledH_`approach'_j 			= RF_pooledH_`approach'_j
				}
					egen    RF_pooledH_`approach'_osig_oa_all  = mean(x_RF_pooledH_`approach'_j) if (pval_orig_j<=0.`sigdigits_oa')
					egen    RF_pooledH_`approach'_onsig_oa_all = mean(x_RF_pooledH_`approach'_j) if (pval_orig_j>0.`sigdigits_oa') 
			}
		}
		
		 gen  x_pval_orig_osig_oa_all  = pval_orig_j   					if (pval_orig_j<=0.`sigdigits_oa')	
		egen    pval_orig_osig_oa_all  = mean(x_pval_orig_osig_oa_all) 
		 gen  x_pval_orig_onsig_oa_all = pval_orig_j  					if (pval_orig_j>0.`sigdigits_oa')	
		egen    pval_orig_onsig_oa_all = mean(x_pval_orig_onsig_oa_all)
	}
		
	if `ivarweight'==1 {
		egen x_total_osig_weight  = total(weight_j) if (pval_orig_j<=0.`sigdigits_oa')
		egen x_total_onsig_weight = total(weight_j) if (pval_orig_j>0.`sigdigits_oa')
			
		foreach RF_indw of local RF_list_nosx {
			egen   `RF_indw'_osig_oa_all  = total(`RF_indw'_j*weight_j/x_total_osig_weight)      if (pval_orig_j<=0.`sigdigits_oa')
			egen   `RF_indw'_onsig_oa_all = total(`RF_indw'_j*weight_j/x_total_onsig_weight)     if (pval_orig_j>0.`sigdigits_oa')
		}
		
		if `shelvedind'==1 {
			foreach approachw in A B {
				drop RF_pooledH_`approachw'_osig_oa_all RF_pooledH_`approachw'_onsig_oa_all  // different aggregation approach than the mean-based one applied above

				 gen  x_RF_pooledH_`approachw'_j2   = 2*(1 - normal(abs(RF_pooledH_`approachw'_j))) 	if (RF_pooledH_`approachw'_j>=0 & beta_orig_dir_j==1) | (RF_pooledH_`approachw'_j<0 & beta_orig_dir_j==0)
				 gen  x_RF_pooledH_`approachw'_j    = (x_RF_pooledH_`approachw'_j2<=0.`sigdigits_oa')*100 
				 
				egen x_total_osig_weightp_`approachw'2  = total(weight_j)  											if (pval_orig_j<=0.`sigdigits_oa') & x_RF_pooledH_`approachw'_j2!=.
				egen x_total_osig_weightp_`approachw'   = mean(x_total_osig_weightp_`approachw'2)					if (pval_orig_j<=0.`sigdigits_oa')
				egen x_RF_pooledH_`approachw'_osig_oa_all  = total(x_RF_pooledH_`approachw'_j*weight_j)				if (pval_orig_j<=0.`sigdigits_oa')
				 gen   RF_pooledH_`approachw'_osig_oa_all  = x_RF_pooledH_`approachw'_osig_oa_all/x_total_osig_weightp_`approachw'	if (pval_orig_j<=0.`sigdigits_oa')   
				 
				egen x_total_onsig_weightp_`approachw'2 = total(weight_j) 											if (pval_orig_j>0.`sigdigits_oa') & x_RF_pooledH_`approachw'_j2!=.
				egen x_total_onsig_weightp_`approachw'  = mean(x_total_onsig_weightp_`approachw'2)					if (pval_orig_j>0.`sigdigits_oa')
				egen x_RF_pooledH_`approachw'_onsig_oa_all = total(x_RF_pooledH_`approachw'_j*weight_j)				if (pval_orig_j>0.`sigdigits_oa')
				 gen   RF_pooledH_`approachw'_onsig_oa_all = x_RF_pooledH_`approachw'_onsig_oa_all/x_total_onsig_weightp_`approachw'	if (pval_orig_j>0.`sigdigits_oa')   
			}
		}
		
		egen x_total_osig_weight_orig = total(weight_orig_j)			if (pval_orig_j<=0.`sigdigits_oa')
		gen  x_pval_orig_osig_j = pval_orig_j 							if (pval_orig_j<=0.`sigdigits_oa')
		egen   pval_orig_osig_oa_all = total(x_pval_orig_osig_j*weight_orig_j/x_total_osig_weight_orig) if (pval_orig_j<=0.`sigdigits_oa')
			
		egen x_total_onsig_weight_orig = total(weight_orig_j)			if (pval_orig_j>0.`sigdigits_oa')
		gen  x_pval_orig_onsig_j = pval_orig_j							if (pval_orig_j>0.`sigdigits_oa')
		egen   pval_orig_onsig_oa_all = total(x_pval_orig_onsig_j*weight_orig_j/x_total_onsig_weight_orig) if (pval_orig_j>0.`sigdigits_oa') 
			
		drop weight_*
	}
	drop x_* 
	capture drop beta_orig_dir_j   // only dropped if `studypooling'==0  


*** Indicator Set RF2
	if `studypooling'==1 {
		replace pval_orig_j = pval_orig_ra_j	   
	}

	if `ivarweight'==1 {
		egen x_total_weight 	   	= total(weight_j)
		egen x_total_osig_weight    = total(weight_j) 			if pval_orig_j<=0.`sigdigits_ra'
		egen x_total_onsig_weight 	= total(weight_j) 			if pval_orig_j>0.`sigdigits_ra'
	}
		
	** original indicator sig, revised indicator sig at `signum_ra'% level
	foreach o_inds in `RF2_osig_list_nosfx' RF2_SIGagr_sigde2 {
		if `ivarweight'==0 {
			egen `o_inds'_osig_ra_all  = mean(`o_inds'_j) 									if pval_orig_j<=0.`sigdigits_ra'
		}
		if `ivarweight'==1 {				
			egen `o_inds'_osig_ra_all  = total(`o_inds'_j*weight_j/x_total_osig_weight)   	if pval_orig_j<=0.`sigdigits_ra'
		}
	}			
	
	drop   RF2_SIGagr_sigdef_osig_ra_all   // RF2_SIGagr_sigdef_j is correct, but aggregating it across results requires some of the missings to be set to zero, which is done in RF2_SIGagr_sigde2_j 
	rename RF2_SIGagr_sigde2_osig_ra_all RF2_SIGagr_sigdef_osig_ra_all

	** original indicator insig, revised indicator sig at `signum_ra'% level
	foreach o_indn in `RF2_onsig_list_nosfx' RF2_SIGagr_sigde2 {
		if `ivarweight'==0 {
			egen `o_indn'_onsig_ra_all = mean(`o_indn'_j) 									if pval_orig_j>0.`sigdigits_ra'
		}
		if `ivarweight'==1 {		
			egen `o_indn'_onsig_ra_all = total(`o_indn'_j*weight_j/x_total_onsig_weight) 	if pval_orig_j>0.`sigdigits_ra'
		}
	}
	drop RF2_SIGagr_sigdef_onsig_ra_all 
	rename RF2_SIGagr_sigde2_onsig_ra_all RF2_SIGagr_sigdef_onsig_ra_all
	drop RF2_SIGagr_sigde2_j

	** any original indicator sig level, revised indicator sig at `signum_ra'% level
	if `ivarweight'==0 {
		egen rany_osig_ra_all = mean(pval_orig_j<=0.`sigdigits_ra')
	}
	if `ivarweight'==1 {
		gen  x_rany_osig_j  = (pval_orig_j<=0.`sigdigits_ra')
		egen   rany_osig_ra_all = total(x_rany_osig_j*weight_j/x_total_weight)	

		drop x_*
	}

	** droping and renaming variables for `studypooling'==1
	if `studypooling'==1 {
		drop pval_orig_j pval_orig_osig_* pval_orig_onsig_*	  RF2_SIGcfm_uni_j  

		rename RF2_SIGcfm_uni_all_j RF2_SIGcfm_uni_j 
		rename RF2_SIGcfm_oa_all_j  RF2_SIGcfm_oa_j 
	}

	** any original and any revised indicator sig level
	egen    RF2_SIGcfm_uni_all = mean(RF2_SIGcfm_uni_j)
	egen    RF2_SIGcfm_oa_all = mean(RF2_SIGcfm_oa_j)


*** Copy information to all results/ studies
	ds RF_*_all RF2_*_all
	foreach var in `r(varlist)' {
		egen c`var'0 = min(`var')
		egen c`var'1 = max(`var')
		if c`var'0!=c`var'1 {
			noi dis "{red: Error in the calculation of indicators across results or studies. Please reach out to the contact person of the {it:repframe} command.}"				
			use `inputdata', clear
			exit
		}    
		egen c`var'     = mean(`var')
		drop `var' c`var'0 c`var'1
		rename c`var' `var'
	}





********************************************************************************
*****  PART 4  INDICATOR DATASET AT STUDY LEVEL
********************************************************************************

*** Order and label dataset
	if `studypooling'==0 {
		order mainvar mainvar_str beta_orig_j beta_rel_orig_j pval_orig_j `RF_list_j' `RF2_list_j'  pval_orig_osig_oa_all `RF_list_osig_oa_k'  pval_orig_onsig_oa_all `RF_list_onsig_oa_k'  `RF2_list_osig_ra_k'  `RF2_list_onsig_ra_k'  rany_*
	
		local label_j 				", by result"
		local label_osig_oa_all  	", across results (originally significant wrt OA sig. level)"
		local label_onsig_oa_all 	", across results (originally insignificant wrt OA sig. level)"
		
		local label_osig_ra_all  ", across results (originally significant wrt REP sig. level)"
		local label_onsig_ra_all ", across results (originally insignificant wrt REP sig. level)"

		label var mainvar 			"Result"
		label var mainvar_str		"Result, in string format" 
		label var beta_orig_j 		"Original beta estimate" 												
		label var beta_rel_orig_j  	"Original beta estimate, expressed as % deviation from original mean of the result"
	}
	else {
		order mainvar mainvar_str 						 pval_orig_oa_j pval_orig_ra_j	`RF_list_j' `RF2_list_j'  					   `RF_list_osig_oa_k'                         `RF_list_onsig_oa_k'  `RF2_list_osig_ra_k'  `RF2_list_onsig_ra_k'  rany_*	

		local label_j 				", by study"
		local label_osig_oa_all  	", across studies (orig. sign. wrt OA alpha)"
		local label_onsig_oa_all 	", across studies (orig. insign. wrt OA alpha)"
		
		local label_osig_ra_all  ", across studies (orig. sign. wrt REP alpha)"
		local label_onsig_ra_all ", across studies (orig. insign. wrt REP alpha)"

		label var mainvar 			"Study reference"
		label var mainvar_str		"Study reference, in string format" 
	}


	foreach unit in j osig_oa_all onsig_oa_all {
		capture label var pval_orig_`unit'	"p-value of original estimate`label_`unit''" 
		label var RF_SIGagr_`unit' 	"(RF.1) Significance agreement`label_`unit''"	
		label var RF_ESrel_`unit'	"(RF.2) Relative effect size`label_`unit''"	
		label var RF_SIGrel_`unit' 	"(RF.3) Relative significance`label_`unit''"
		label var RF_ESvar_`unit' 	"(RF.4) Effect sizes variation`label_`unit''"
		label var RF_SIGvar_`unit' 	"(RF.5) Significance variation`label_`unit''"
		if `shelvedind'==1 { 
			label var RF_robratio_A_`unit' 	"(B1a) Robustness - sqrt of mn sq beta deviation divided by orig. s.e.`label_`unit''" 
			label var RF_robratio_B_`unit' 	"(B1b) Robustness - sqrt of mn sq t/z-value deviation`label_`unit''" 						
			label var RF_pooledH_A_`unit' 	"(B2a) Pooled hypothesis test - z-stat based on beta and se (inverse sign for neg. orig. results)`label_`unit''" 
			label var RF_pooledH_B_`unit' 	"(B2b) Pooled hypothesis test - z-stat based on t/z-score (inverse sign for neg. orig. results)`label_`unit''" 
		}
	}	

	foreach unit in j osig_ra_all onsig_ra_all {
		label var RF2_SIGagr_`unit' 		"(RF1') Significance agreement`label_`unit''"
		label var RF2_SIGagr_ndir_`unit' 	"(RF1') Significance agreement (opposite dir.)`label_`unit''"
		label var RF2_SIGvar_nsig_`unit' 	"(RF4') Significance variation for insig. rep. results`label_`unit''"
		label var RF2_SIGcfm_uni_`unit'		"(RF7'b*) Sig. agreement (uniform alpha=0.`sigdigits_ra' applied)`label_`unit''"
	}
	foreach unit in osig_ra_all onsig_ra_all {
		label var RF2_SIGcfm_oas_`unit'		"(RF7'b*) Sig. classification agreement (OA's alpha for orig. results, sig. rep. results only)`label_`unit''"
		label var RF2_SIGcfm_oan_`unit'		"(RF7'b*) Sig. classification agreement (OA's alpha for orig. results, insig. rep. results only)`label_`unit''"
		foreach cfmtype in oas oan uni {
			note RF2_SIGcfm_`cfmtype'_`unit': This is an auxiliary indicator required for the correct colouring of circles in Robustness Dashboards that are aggregated across results or studies   
		}
	}

	foreach unit in j osig_ra_all {
		label var RF2_SIGagr_sigdef_`unit'	"(RF6') Significance agreement (sig. due to more stringent OA sig. classif.)`label_`unit''"
		label var RF2_ESrel_`unit' 			"(RF2') Relative effect size`label_`unit''"
		label var RF2_ESvar_`unit'			"(RF3') Effect size variation`label_`unit''"
		label var RF2_ESagr_`unit'			"(RF5') Effect size agreement`label_`unit''"
		label var RF2_SIGsw_btonsig_`unit'  "(RF8') Significance switch (beta)`label_`unit''"	
		label var RF2_SIGsw_setonsig_`unit' "(RF9') Significance switch (se)`label_`unit''"	
	}
	foreach unit in j onsig_ra_all {
		label var RF2_SIGagr_sigdef_`unit'	"(RF6') Significance agreement (insig. due to less stringent OA sig. classif.)`label_`unit''"
		label var RF2_SIGvar_sig_`unit' 	"(RF4') Significance variation for sig. rep. results`label_`unit''"
		label var RF2_SIGsw_btosig_`unit'	"(RF8') Significance switch (beta)`label_`unit''"
		label var RF2_SIGsw_setosig_`unit'	"(RF9') Significance switch (se)`label_`unit''"
	}



	if `signum_ra'!=5 {
		foreach unit in j osig_ra_all onsig_ra_all {
			label var RF2_SIGagr_05_`unit'	"(RF1') Significance agreement (5% level)`label_`unit''"
		}
	}
	if `signum_ra'!=10 {
		foreach unit in j osig_ra_all onsig_ra_all {
			label var RF2_SIGagr_10_`unit'	"(RF1') Significance agreement (10% level)`label_`unit''"
		}
	}
	if "`ivadjust'"=="tF" | "`ivadjust'"=="AR"  {
		foreach unit in j {
			label var pval_0`iva_level'iva_orig_`unit' "weak-IV adjusted p-value in analysis path of original study (either tF or AR)`label_`unit''"
		}
	}
	if "`ivadjust'"!="0" {
		foreach unit in j {
			label var RF2_SIGagr_0`iva_level'iva_`unit' "(RF1') Significance agreement (`iva_level'% level, either tF, VtF or AR)`label_`unit''"
		}
	}
	if "`ivadjust'"=="AR" {
		foreach unit in osig_ra_all onsig_ra_all {
			label var RF2_SIGagr_0`iva_level'iva_`unit' "(RF1') Significance agreement (using AR p-values)`label_`unit''"
			capture note RF2_SIGagr_05iva_`unit': indicator calculation is identical with that of RF2_SIGagr_01iva_`unit'
			capture note RF2_SIGagr_01iva_`unit': indicator calculation is identical with that of RF2_SIGagr_05iva_`unit'
		}
	}
	
	label var RF2_SIGcfm_oa_j			"(RF7') Sig. classification agreement (OA's alpha applied to orig. results)`label_j'"
	label var RF2_SIGcfm_uni_all		"(RF7') Overall sig. agreement (uniform alpha=0.`sigdigits_ra' applied)"
	label var RF2_SIGcfm_oa_all			"(RF7') Overall sig. classification agreement (OA's alpha applied to orig. results)"
	label var rany_osig_ra_all			"Any rep. analysis is significant wrt REP sig. level`label_osig_ra_all'" 


*** Save temp dataset
	tempfile data_j			// data with j being the unit of observation
	save `data_j'
  

*** Create dataset at study level
  	if `studypooling'==0 {
		keep *_all 
		drop rany_osig_ra_all 
		duplicates drop
	
		gen results_N = `N_results'
		label var results_N  "Number of results studied"
		
		foreach set in oa ra {
			foreach origs in osig onsig {
				gen    `origs'_`set'_rslt_N =  ``origs'_`set'_rslt_N'					
			}
			label var osig_`set'_rslt_N   "Number of results with stat. sign. orig. est. (sig. level of `set' analysis)"
			label var onsig_`set'_rslt_N  "Number of results with stat. insign. orig. est. (sig. level of `set' analysis)"
		}

		gen siglevel_oa_stud = `signum_oa'
		label var siglevel_oa_stud  "Significance level of two-sided test applied to orig. study / by orig. author(s)"
		gen siglevel_ra_stud = `signum_ra'
		label var siglevel_ra_stud  "Significance level of two-sided test applied in robustness analysis"
		
		gen ivarweight_stud_d = `ivarweight'
		label var ivarweight_stud_d "Results in study weighted by the inverse variance"
		label def dummy 0 "no" 1 "yes"
		label val ivarweight_stud_d dummy 

		gen analysispaths_min_N = `N_specs_min'
		gen analysispaths_max_N = `N_specs_max'
		label var analysispaths_min_N  "Minimum number of analysis paths studied (across results)"
		label var analysispaths_max_N  "Maximum number of analysis paths studied (across results)"
			
		gen ref = "`shortref'"
		label var ref "Study reference"

		order ref results_N  siglevel_ra_stud siglevel_oa_stud osig_oa_rslt_N pval_orig_osig_oa_all `RF_list_osig_oa_k'  onsig_oa_rslt_N pval_orig_onsig_oa_all `RF_list_onsig_oa_k'  osig_ra_rslt_N `RF2_list_osig_ra_k'  onsig_ra_rslt_N `RF2_list_onsig_ra_k' ivarweight_stud_d

		save "`filepath'/repframe_data_studies_`fileidentifier'.dta", replace
	}





********************************************************************************
*****  PART 5  ROBUSTNESS DASHBOARD VISUALIZATION 
********************************************************************************
	
************************************************************
***  PART 5.A  PREPARE DASHBOARD GRAPH DATA
************************************************************

	if `dashboard'==1 {
		use `data_j'
		if `studypooling'==0 {
			keep mainvar mainvar_str beta_orig_j beta_rel_orig_j pval_orig_j `pval_iva_orig_j' RF2_* rany* 
			local ind_level rslt
		}
		else {
			rename pval_orig_ra_j pval_orig_j
			keep mainvar mainvar_str pval_orig_j RF2_* rany*
			keep if pval_orig_j!=.
			local ind_level stud
		}
	

*** Colour definition
		if (c(version)>=14.2) {
			colorpalette lin fruit, nograph
			local col p3
			local col_lowint  0.35
			local col_highint 0.8
		}
		else {	
			colorpalette9, nograph
			local col p1
			local col_lowint  0.25
			local col_highint 0.55
		}
		local r_col `r(`col')'
		 

*** Histogram on confirmatory results by result or study
		// needs to be done at this stage where 1 study = 1 obs (effectively twice in the dataset for `studypooling'==1, once for originally sig and once for originally insig results, but that does not change the look of the histogram)

		** aggregate confirmatory results statistics
		local share_confirm_uni_all = round(RF2_SIGcfm_uni_all)
		local share_confirm_oa_all  = round(RF2_SIGcfm_oa_all)
		local xlabadd
		local note_asterisk
		local note_share_cfm 
		if `sigdigits_ra'!=`sigdigits_oa' & `sigdigits_ra'!=999 & `share_confirm_uni_all'!=`share_confirm_oa_all' {
			local note_asterisk         *
			local note_share_cfm 		"{it: * = with uniform {&alpha}=0.`sigdigits_ra': `share_confirm_uni_all'%}"
		}

		gen     x_RF2_ESrel_abs_j     = abs(RF2_ESrel_j)
		replace x_RF2_ESrel_abs_j     = 102 if x_RF2_ESrel_abs_j>102 & x_RF2_ESrel_abs_j<.
		 gen x_RF2_ESrel_abs_above    = (x_RF2_ESrel_abs_j==102)
		egen x_RF2_ESrel_abs_anyabove = max(x_RF2_ESrel_abs_above)
		if x_RF2_ESrel_abs_anyabove==1 {
			label define abs_axis 105 "100+"  
		 	label val RF2_SIGcfm_oa_j abs_axis
			local xlabadd 105 
		}
		local   x_RF2_SIGcfm_intens = `col_lowint'+(RF2_SIGcfm_oa_all/100)*(`col_highint'-`col_lowint')  
        gen     x_RF2_SIGcfm_color = "`r_col'*`x_RF2_SIGcfm_intens'"
        
	
		set graphics off
		twoway (histogram RF2_SIGcfm_oa_j,  start(0) width(5) lcolor(white) fcolor("`=x_RF2_SIGcfm_color[1]'"))   ///    
		       (histogram x_RF2_ESrel_abs_j, start(0) width(5) lcolor(black) fcolor(none)),  ///
			   xline(`= RF2_SIGcfm_oa_all') /*xline(`= RF2_SIGcfm_uni_all', lcolor(gs6))*/  ///
			   xscale(range(-10 110) alt) xlabel(0(20)100 `xlabadd', labsize(vsmall) valuelabel) xtitle("%", size(vsmall))  yscale(off) ylabel(, nogrid) ///
			   legend(order(1 "`=ustrunescape("\u039A")'  (`=ustrunescape("\u0305\u039A")'=`share_confirm_oa_all'%`note_asterisk')"  2 "|`=ustrunescape("\u03B2")'| (double sig. results only)") holes(3 4) note("`note_share_cfm'", size(small))) ///
			   fysize(15) aspectratio(0.075) scheme(white_tableau) name(hist_SIGcfm, replace)
		set graphics on


*** Prepare data structure and y- and x-axis
		if `signum_ra'!=999 { 
			local siglab 	{it:p}>0.`sigdigits_ra'
		}
		else {
			local siglab 	varying sig. levels		// `signum_ra'==999 can effectively only occur for `studypooling'==1 
		}

		** create local indicating number of results/ studies with estimates falling into category of insig (sig) rep. analyses only because of more (less) stringent sig. level definition in rep. analysis than in orig. analysis
		egen x2_notes_sigdef = total(RF2_SIGagr_sigdef_j!=.)
		local notes_sigdef_N = x2_notes_sigdef 
		drop x2_*

		if `aggregation'==1 {
			keep if inlist(mainvar,1)       	// keep one observation across results/ studies
			drop mainvar mainvar_str *_j		// drop variables at result/ study level 
			if `studypooling'==0 {
				local ylab 1 `" "significant" " " "{it:`osig_ra_rslt_share' results}" "'      										2 `" "insignificant" "(`siglab')" " " "{it:`onsig_ra_rslt_share' results}" "'	// first y entry shows up at bottom of y-axis of the dashboard
			}
			else {
				local ylab 1 `" "significant" " " "{it:`osig_ra_rslt_share' results in}" "{it:`osig_ra_stud_share' studies}" "' 	2 `" "insignificant" "(`siglab')" " " "{it:`onsig_ra_rslt_share' results in}" "{it:`onsig_ra_stud_share' studies}" "'	
				duplicates drop
			}
			expand 2
			gen dashbrd_y = _n
			local yset_n = 2 
		}
		else { 
			sort mainvar
			rename mainvar dashbrd_y
			local yset_n = `N_results'			// # of items shown on y-axis = # of results
			
			** reverse order of result numbering as results are presented in reverse order on the y-axis of the dashboard
			tostring dashbrd_y, replace
			labmask dashbrd_y, values(mainvar_str) lblname(ylab)	
			
			** split result labels that are too long
			gen x_mainvar_str_word_count = wordcount(mainvar_str)

			gen     x_str_first_part  = word(mainvar_str, 1) + " " + word(mainvar_str, 2)                              if (x_mainvar_str_word_count==3 | x_mainvar_str_word_count==4)
			gen     x_str_second_part = word(mainvar_str, 3)                              							   if  x_mainvar_str_word_count==3
			replace x_str_second_part = word(mainvar_str, 3) + " " + word(mainvar_str, 4)                              if  x_mainvar_str_word_count==4

			replace x_str_first_part  = word(mainvar_str, 1) + " " + word(mainvar_str, 2) + " " + word(mainvar_str, 3) if (x_mainvar_str_word_count==5 | x_mainvar_str_word_count==6)
			replace x_str_second_part = word(mainvar_str, 4) + " " + word(mainvar_str, 5)                              if  x_mainvar_str_word_count==5
			replace x_str_second_part = word(mainvar_str, 4) + " " + word(mainvar_str, 5) + " " + word(mainvar_str, 6) if  x_mainvar_str_word_count==6

			replace x_str_first_part  = word(mainvar_str, 1) + " " + word(mainvar_str, 2) + " " + word(mainvar_str, 3) + " " + word(mainvar_str, 4) 	if (x_mainvar_str_word_count==7 | x_mainvar_str_word_count==8)
			replace x_str_second_part = word(mainvar_str, 5) + " " + word(mainvar_str, 6) + " " + word(mainvar_str, 7)                              	if  x_mainvar_str_word_count==7
			replace x_str_second_part = word(mainvar_str, 5) + " " + word(mainvar_str, 6) + " " + word(mainvar_str, 7) + " " + word(mainvar_str, 8)  	if  x_mainvar_str_word_count==8

			// workaround used to add special characters to the string variable label in dashboard graph
			// similar workaround used in Contribution Plots, but asterisks additionally had to be considered there 
			gen x_add1_str = "`"
			gen x_add2_str = `"" ""'
			gen x_add3_str = "'"
			egen x_mainvar_str1 = concat(x_add1_str x_add2_str  x_str_first_part  x_add2_str  x_str_second_part x_add2_str x_add3_str) 
			
			gen x_add4_str = `"""'
			egen x_mainvar_str2 = concat(x_add4_str mainvar_str x_add4_str) 

			replace mainvar_str = x_mainvar_str1 if x_mainvar_str_word_count>=3 & x_mainvar_str_word_count<=8
			replace mainvar_str = x_mainvar_str2 if x_mainvar_str_word_count<3 | x_mainvar_str_word_count>8

			egen x_mainvar_str_word_count_max = max(x_mainvar_str_word_count)
			
			if   x_mainvar_str_word_count_max>8 {
				noi dis as text _newline(1) "Consider using shorter labels for the variable {it:mainvar}."
			}

			** define y-xais label
			if `N_results'==1 {
				local ylab `"   `=dashbrd_y[1]' `=mainvar_str[1]'  "'
			}
			if `N_results'==2 | `N_results'==3 {
				recode dashbrd_y (1=`N_results') (`N_results'=1)
				local ylab `"   `=dashbrd_y[1]' `=mainvar_str[1]' `=dashbrd_y[2]' `=mainvar_str[2]'  "'
			}
			if `N_results'==3 {
				local ylab `"   `=dashbrd_y[1]' `=mainvar_str[1]' `=dashbrd_y[2]' `=mainvar_str[2]' `=dashbrd_y[3]' `=mainvar_str[3]' "'
			}	
			if `N_results'==4 {
				recode dashbrd_y (1=4) (4=1) (2=3) (3=2)
				local ylab `"   `=dashbrd_y[1]' `=mainvar_str[1]' `=dashbrd_y[2]' `=mainvar_str[2]' `=dashbrd_y[3]' `=mainvar_str[3]' `=dashbrd_y[4]' `=mainvar_str[4]'  "'
			}
			if `N_results'==5 {
				recode dashbrd_y (1=5) (5=1) (2=4) (4=2)
				local ylab `"   `=dashbrd_y[1]' `=mainvar_str[1]' `=dashbrd_y[2]' `=mainvar_str[2]' `=dashbrd_y[3]' `=mainvar_str[3]' `=dashbrd_y[4]' `=mainvar_str[4]' `=dashbrd_y[5]' `=mainvar_str[5]'  "'
			}
			
			if `N_results'>5 {
				noi dis "{red: Please use option -repframe, [...] aggregation(1)- with more than five results to be displayed.}"				
				use `inputdata', clear
				exit
			}									
			drop mainvar_str
		}
		
		local xset  insig  sig_ndir  sig_dir
		local xlab 1 `" "insignificant" "(`siglab')" "' 2 `" "significant," "opposite sign" "' 3 `" "significant," "same sign" "'
		local xset_n : word count `xset'
		
		expand `xset_n'
		bysort dashbrd_y: gen dashbrd_x = _n
		
		
		** labelling of y-axis 
		if `aggregation'==1 {
			local aux `" "Original" "results" "'
			local ytitle  ytitle(`aux', orient(horizontal))
		}
		else {
			local ytitle ytitle("") // empty local, no ytitle to show up
		}
		

*** Calculate main shares presented in Robustness Dashboard
		if `aggregation'==1 {
			// in order to calculate the shares in ALL original results [and not differentiated by originally sig or insig] multiply x_share_2x and `styper'_onsig_ra_all by (1 - rany_osig_ra_all) and x_share_1x and `styper'_osig_ra_all by rany_osig_ra_all
			gen x_share_21 =  100 - RF2_SIGagr_onsig_ra_all - RF2_SIGagr_ndir_onsig_ra_all	if dashbrd_y==2 & dashbrd_x==1	// top left     (insig orig & insig rev)            = (100 - sig rev)
			gen x_share_22 =                               	  RF2_SIGagr_ndir_onsig_ra_all	if dashbrd_y==2 & dashbrd_x==2	// top middle   (insig orig & sig   rev, diff sign) =        sig rev not dir
			gen x_share_23 =        RF2_SIGagr_onsig_ra_all					 				if dashbrd_y==2 & dashbrd_x==3	// top right    (insig orig & sig   rev, same sign) =        sig rev     dir
			
			gen x_share_11 =  100 - RF2_SIGagr_osig_ra_all - RF2_SIGagr_ndir_osig_ra_all	if dashbrd_y==1 & dashbrd_x==1  // bottom left   (sig & insig)			 	=   (100 - sig rev)
			gen x_share_12 =                                 RF2_SIGagr_ndir_osig_ra_all  	if dashbrd_y==1 & dashbrd_x==2	// bottom middle (sig & sig, diff sign)		=   (100 - sig rev not dir)
			gen x_share_13 =        RF2_SIGagr_osig_ra_all 			     			  		if dashbrd_y==1 & dashbrd_x==3	// bottom right  (sig & sig, same sign)		=	(100 - sig rev     dir)
			
			for num 1/3: replace x_share_1X  = 0 											if dashbrd_y==1 & dashbrd_x==X & rany_osig_ra_all==0 & x_share_1X==.			// replace missing by zero if none of the original estimates was sig
			for num 1/3: replace x_share_2X  = 0 											if dashbrd_y==2 & dashbrd_x==X & rany_osig_ra_all==1 & x_share_2X==.   		// replace missing by zero if all of the original estimates were sig								
			 
			foreach styper in `RF2_SIGagr_xx' {
				replace `styper'_onsig_ra_all 	= `styper'_onsig_ra_all  // top right  (insig orig & sig rev)
				replace `styper'_osig_ra_all   = `styper'_osig_ra_all    // bottom right (sig orig & sig rev)
			}
			// share2 = second circle to show share on analysis paths that are not confirmatory with OAs significance classification 																						
			gen share2_21 =    RF2_SIGagr_sigdef_onsig_ra_all  							if dashbrd_y==2 & dashbrd_x==1 	// !=. if original authors adopted different sig. level than rep. analysis
			gen share2_23 = .
			gen share2_11 = .
			gen share2_13 =    RF2_SIGagr_sigdef_osig_ra_all  							if dashbrd_y==1 & dashbrd_x==3
		}		
		else {
			for num 1/`yset_n': gen x_share_X1 = 100 - RF2_SIGagr_j - RF2_SIGagr_ndir_j	if dashbrd_y==X	& dashbrd_x==1	// insig result X
			for num 1/`yset_n': gen x_share_X2 =                      RF2_SIGagr_ndir_j if dashbrd_y==X	& dashbrd_x==2	//   sig result X, not dir
			for num 1/`yset_n': gen x_share_X3 =       RF2_SIGagr_j  					if dashbrd_y==X	& dashbrd_x==3	//   sig result X, same dir
		
			// create variables with indicator information available in all observations
			foreach var in beta_orig_j beta_rel_orig_j pval_orig_j `pval_iva_orig_j'  `RF2_list_j'  {
				for num 1/`yset_n': gen   x_`var'X = `var' if dashbrd_y==X
				for num 1/`yset_n': egen    `var'X = mean(x_`var'X)	
			}
			if `signum_ra'<`signum_oa' {
				for num 1/`yset_n': gen share2_X1 =	RF2_SIGagr_sigdef_j           			if dashbrd_y==X & dashbrd_x==1	
				for num 1/`yset_n': gen share2_X3 =	.					           			if dashbrd_y==X & dashbrd_x==3
			}
			if `signum_ra'>`signum_oa' {
				for num 1/`yset_n': gen share2_X1 =	.					           			if dashbrd_y==X & dashbrd_x==1	
				for num 1/`yset_n': gen share2_X3 =	RF2_SIGagr_sigdef_j           			if dashbrd_y==X & dashbrd_x==3	
			}
			if `signum_ra'==`signum_oa' {
				for num 1/`yset_n': gen share2_X1 =	. 					          			if dashbrd_y==X & dashbrd_x==1
				for num 1/`yset_n': gen share2_X3 =	. 					          			if dashbrd_y==X & dashbrd_x==3	
			}
		}
		

*** Round indicators for presentation in the dashboard to guarantee below that shares add up to 1 (i.e. 100%)
		forval qy = 1/`yset_n' {
			forval qx = 1/3 {
				// create the variables x_sharerounder_*, which contain information on the third+ digit and guarantee below that shares add up to 1 (i.e. 100%) 
				egen  share_`qy'`qx'   = min(x_share_`qy'`qx')
				gen x_share_`qy'`qx'_2 = floor(share_`qy'`qx')			
				gen x_sharerounder_`qy'`qx' = x_share_`qy'`qx' - x_share_`qy'`qx'_2
				// conventional rounding as the default
				replace share_`qy'`qx' = round(share_`qy'`qx')
			}
			replace share2_`qy'1 = round(share2_`qy'1)
			replace share2_`qy'3 = round(share2_`qy'3)
		}

		** create single variables share, x_sharerounder, and share2 from share_*, x_sharerounder_*, and share2_*
		foreach shvar3 in share x_sharerounder share2 {		
						    	gen     `shvar3' = .
			for num 1/`yset_n': replace `shvar3' = `shvar3'_X1 if dashbrd_y==X & dashbrd_x==1 & `shvar3'_X1!=.
			for num 1/`yset_n': replace `shvar3' = `shvar3'_X3 if dashbrd_y==X & dashbrd_x==3 & `shvar3'_X3!=.
		}
		foreach shvar2 in share x_sharerounder {		
			for num 1/`yset_n': replace `shvar2' = `shvar2'_X2 if dashbrd_y==X & dashbrd_x==2
		}		
		
		                    gen     x2_share_roundingdiff = .
		for num 1/`yset_n': replace x2_share_roundingdiff = 100-(share_X1 + share_X2 + share_X3) if dashbrd_y==X
		for num 1/`yset_n': replace x2_share_roundingdiff = 0 if dashbrd_y==X & (share_X1 + share_X2 + share_X3 == 0)   // no rounding if entire row is zero, which may happen with -aggregation(1)- if none of the studied results/ studies has (in)sig orig. estimates.
		
		** sum of shares exceeds 100%
		gen x2_sharerounderpool = (x_sharerounder>=0.5 & x2_share_roundingdiff<0)
		sort dashbrd_y x2_sharerounderpool share x_sharerounder  // make sure that, if two shares have the same digit (e.g. 62.5 and 37.5), the lower one is always rounded down (here: 37.5 to 37); -egen [...] rank(x_sharerounder), unique- would have been easier, but ranks arbitrarily if digits are identical 
		by dashbrd_y x2_sharerounderpool: gen x2_sharerounder = _n
		replace x2_sharerounder = . if x2_sharerounderpool==0	
		replace share     = share  - 1 if x2_sharerounder<=abs(x2_share_roundingdiff)    // the X shares with the lowest digits are reduced in cases where the sum of shares is 10X
		replace share2    = share2 - 1 if x2_sharerounder<=abs(x2_share_roundingdiff) & share2!=. & share2!=0
		drop x2_sharerounderpool x2_sharerounder

		** sum of shares falls below 100%
		gen x2_sharerounderpool = (x_sharerounder<0.5 & x2_share_roundingdiff>0)
		gsort dashbrd_y x2_sharerounderpool -share x_sharerounder  // make sure that, if two shares have the same digit (e.g. 54.4 and 22.4), the higher one is always rounded up (here: 54.4 to 55)  
		by dashbrd_y x2_sharerounderpool: gen x2_sharerounder = _n
		replace x2_sharerounder = . if x2_sharerounderpool==0
		replace share     = share  + 1 if x2_sharerounder<=x2_share_roundingdiff		// the X shares with the highest digits are increased in cases where the sum of shares is 100 - X
		replace share2    = share2 + 1 if x2_sharerounder<=abs(x2_share_roundingdiff) & share2!=.
		drop x2_sharerounderpool x2_sharerounder x2_share_roundingdiff

		** recreate variables with indicator information availabe in all observations for RF2_SIGagr_sigdef_j (after share2 has been properly rounded)
		if `aggregation'==0 {	
			drop x_RF2_SIGagr_sigdef_j*	RF2_SIGagr_sigdef_j*	
			if `signum_ra'<`signum_oa' {
				for num 1/`yset_n': gen   x_RF2_SIGagr_sigdef_jX = share2 if dashbrd_y==X & dashbrd_x==1	
			}
			if `signum_ra'>`signum_oa' {
				for num 1/`yset_n': gen   x_RF2_SIGagr_sigdef_jX = share2 if dashbrd_y==X & dashbrd_x==3
			}
			if `signum_ra'==`signum_oa' {
				for num 1/`yset_n': gen   x_RF2_SIGagr_sigdef_jX = .
			}
			for num 1/`yset_n': egen    RF2_SIGagr_sigdef_jX = mean(x_RF2_SIGagr_sigdef_jX)	
		}


		** ... now also for RF2_SIGagr_sigdef_onsig_ra_all and RF2_SIGagr_sigdef_osig_ra_all
		else {
			gen x_RF2_SIGagr_sigdef_onsig_ra_all = share2 if dashbrd_y==2 & dashbrd_x==1
			gen x_RF2_SIGagr_sigdef_osig_ra_all  = share2 if dashbrd_y==1 & dashbrd_x==3
			foreach o in onsig osig {
				drop  RF2_SIGagr_sigdef_`o'_ra_all   // replace by rounded indicator
				egen  RF2_SIGagr_sigdef_`o'_ra_all = mean(x_RF2_SIGagr_sigdef_`o'_ra_all)	
			}
		}

		** adjust colouring of circles according to significance classification agreement if `aggregation'==1
		if `aggregation'==1 {
			replace share2 = RF2_SIGcfm_oas_onsig_ra_all									if dashbrd_y==2 & dashbrd_x==3
			replace share2 = RF2_SIGcfm_uni_onsig_ra_all  - RF2_SIGcfm_oan_onsig_ra_all  	if dashbrd_y==2 & dashbrd_x==1 // share_21 - confirmatory part of share_21
			replace share2 = RF2_SIGcfm_oan_osig_ra_all 									if dashbrd_y==1 & dashbrd_x==1
			replace share2 = RF2_SIGcfm_uni_osig_ra_all   - RF2_SIGcfm_oas_osig_ra_all		if dashbrd_y==1 & dashbrd_x==3 // share_13 - confirmatory part of share_13 			
		}

		** separate share_size variable as basis for the size of circles in the dashboard given that share_size may differ from share if original authors applied different sig. level than rep. analysis
		gen     share_size = share
		replace share_size = share - share2 if share2!=.

		drop x_* share2_*

		gen     share2_size = share   // size of larger circle corresponds to share 


*** Further rounding of indicators for presentation in the dashboard
		if `aggregation'==0 {			
			foreach rI in  beta_rel_orig_j   RF2_ESagr_j    `RF2_SIGagr_j' 		   `RF2_SIGagr_xx_j'      RF2_ESrel_j 	 RF2_ESvar_j {
				for num 1/`yset_n': replace `rI'X = round(`rI'X)
			}
		}
		else {			
			foreach rI in                    RF2_ESagr_osig `RF2_SIGagr_xx_osig'   `RF2_SIGagr_xx_onsig'  RF2_ESrel_osig RF2_ESvar_osig {
				replace   `rI'_ra_all = round(`rI'_ra_all)		
			}
		}

		
			  
************************************************************
***  PART 5.B  PREPARE PLOTTING OF DASHBOARD GRAPH DATA
************************************************************
	  
*** Colouring of circles: lighter colour if non-confirmatory revised result, darker colour if confirmatory revised result
		// colour definition above under PART 5.A	
		gen     colorname_nonconfirm = "`r_col'*`col_lowint'"		// definition of colour used for non-confirmatory and confirmatory results - required for legend to dashboard graph
		gen     colorname_confirm    = "`r_col'*`col_highint'"
		
		gen     colorname     = colorname_nonconfirm
		gen     colorname_not = colorname_confirm		// required for overlapping two circles when original authors defined stat. significance differently from the rep. analysis
		if `aggregation'==0 {
			forval m = 1/`yset_n' {
				replace colorname     = colorname_confirm     if dashbrd_y==`m' & dashbrd_x==3 & pval_orig_j`m'<=0.`sigdigits_oa'
				replace colorname     = colorname_confirm     if dashbrd_y==`m' & dashbrd_x==1 & pval_orig_j`m'>0.`sigdigits_oa'

				replace colorname_not = colorname_nonconfirm  if dashbrd_y==`m' & dashbrd_x==1 & pval_orig_j`m'>0.`sigdigits_oa'
			}
		}
		else {
			replace colorname     = colorname_confirm     if (dashbrd_y==2 & dashbrd_x==1) | (dashbrd_y==1 & dashbrd_x==3)
			replace colorname_not = colorname_nonconfirm  if (dashbrd_y==2 & dashbrd_x==1) | (dashbrd_y==1 & dashbrd_x==3)
		}
	

*** Saving the plotting codes in locals
		local slist ""
		forval i = 1/`=_N' {
			local slist "`slist' (scatteri `=dashbrd_y[`i']' `=dashbrd_x[`i']'                                     , mlabposition(0) mlabsize(medsmall) msize(`=share2_size[`i']*0.5*(0.75^(`yset_n'-2))') mcolor("`=colorname_not[`i']'"))"    // first add second circle for different stat. sig. definitions adopted by original authors and in rep. analysis, respectively
			if `aggregation'==0 | (`aggregation'==1 & `=dashbrd_y[`i']'==1 & `=share[`i']'!=0 & `osig_ra_rslt_share'!=0) | (`aggregation'==1 & `=dashbrd_y[`i']'==2 & `=share[`i']'!=0 & `onsig_ra_rslt_share'!=0) {							// remove "0%" in aggregate dashboards, if 0 results contributed to the respective group of estimates (orig. sig. / orig. insig.)
				local slist "`slist' (scatteri `=dashbrd_y[`i']' `=dashbrd_x[`i']' "`: display %3.0f =share[`i'] "%" '", mlabposition(0) mlabsize(medsmall) msize(`=share_size[`i']*0.5*(0.75^(`yset_n'-2))')  mcolor("`=colorname[`i']'"))"    // msize defines the size of the circles
			}
		}
	
		if "`signfirst'"=="" {
			local yx0b   // empty local
		}
		else {
			local yx0b	`" "wrong-sign" "first stages:"  "`: display %3.0f `signfirst'*100 "%" '" "'	 
		}
		
		** # of loops in dashboard
		if `aggregation'==0  {
			local yset_n_dash `yset_n'
		}
		else {
			local yset_n_dash 1    // only needs to be looped once
		}

		forval m = 1/`yset_n_dash' {		
			if `aggregation'==0  {
				local case_s `m'
				local case_n `m'	// suffixes only differ for `aggregation'==1
				local sfx_s  j`m'
				local sfx_n  j`m'
				forval yt = 1(2)3 {
					local cond_n`yt' share_`m'`yt'>0 & pval_orig_j`m'>0.`sigdigits_ra'
					local cond_s`yt' share_`m'`yt'>0 & pval_orig_j`m'<=0.`sigdigits_ra'
				}
				local xleft = 0.0
			}
			else {			
				local case_s 1
				local case_n 2
				local sfx_s  osig_ra_all
				local sfx_n  onsig_ra_all
				forval yt = 1(2)3 {
					local cond_n`yt' share_2`yt'>0 & rany_osig_ra_all!=1
					local cond_s`yt' share_1`yt'>0 & rany_osig_ra_all!=0 
				}
				local xleft = 0.6
				
				local y2x0	""
				local y1x0	"" 			
			}

			** set signs - and column 0 of the dashboard for `aggregation'==0
			local sign_d_sig`m' ""		// `m' effectively not required if `aggregation'==1, but required to run the loop
			if RF2_ESrel_`sfx_s'>0 {
				local sign_d_sig`m' "+" 
			}
			if RF2_ESrel_`sfx_s'==0 {
				local sign_d_sig`m' "+/-" 
			}
			if `aggregation'==0  {
				local sign_d_orig`m' ""
				if beta_orig_j`m'>0 {
					local sign_d_orig`m' "+" 
				}
				if beta_orig_j`m'==0 {
					local sign_d_orig`m' "+/-" 
				}

				if beta_rel_orig_j`m'==. {
					if "`ivadjust'"!="tF" & "`ivadjust'"!="AR" {
						local y`m'x0		`" "`: display "{it:`ytitle_row0'}" '"	"`: display "{&beta}{sup:o}: " %3.2f beta_orig_j`m'[1]'"   													"`: display "{it:p}{sup:o}: " %3.2f pval_orig_j`m'[1]'" "'
					}
					if "`ivadjust'"=="tF" | "`ivadjust'"=="AR" {
						local y`m'x0		`" "`: display "{it:`ytitle_row0'}" '"	"`: display "{&beta}{sup:o}: " %3.2f beta_orig_j`m'[1]'"   													"`: display "{it:p}{sup:o}: " %3.2f pval_orig_j`m'[1]'" 	"`: display "({it:`ivadjust'}: "  %3.2f pval_0`iva_level'iva_orig_j`m'[1]')" "'
					}
				}
				else {
					if "`ivadjust'"!="tF" & "`ivadjust'"!="AR" {
						local y`m'x0		`" "`: display "{it:`ytitle_row0'}" '"	"`: display "{&beta}{sup:o}: " %3.2f beta_orig_j`m'[1] " [`sign_d_orig`m''" beta_rel_orig_j`m' "%]" '"   	"`: display "{it:p}{sup:o}: " %3.2f pval_orig_j`m'[1]'" "'
					}
					if "`ivadjust'"=="tF" | "`ivadjust'"=="AR" {
						local y`m'x0		`" "`: display "{it:`ytitle_row0'}" '"	"`: display "{&beta}{sup:o}: " %3.2f beta_orig_j`m'[1] " [`sign_d_orig`m''" beta_rel_orig_j`m' "%]" '"   	"`: display "{it:p}{sup:o}: " %3.2f pval_orig_j`m'[1]'" 	"`: display "({it:`ivadjust'}: "  %3.2f pval_0`iva_level'iva_orig_j`m'[1]')" "'
					}
				}
			}

			// if basic dashboard, add sig. agreement indicator for 5% level if siglevel(>5) below main indicator in bubble
			if "`customindicators'"=="SIGagronly" {
				if `signum_ra'>5  {
					if `cond_n3' {
						local y`case_n'x3	`" "`: display "{it:p}{&le}0.05: "  `=RF2_SIGagr_05_`sfx_n'' "%" '"  "'
					}
					if `cond_s3' {
						local y`case_s'x3	`" "`: display "{it:p}{&le}0.05: "  `=RF2_SIGagr_05_`sfx_s'' "%" '"  "'
					}
				}
				if `signum_ra'==5  {
					if `cond_n3' {
						local y`case_n'x3	`" "`: display "{it:p}{&le}0.10: "  `=RF2_SIGagr_10_`sfx_n'' "%" '"  "'
					}
					if `cond_s3' {
						local y`case_s'x3	`" "`: display "{it:p}{&le}0.10: "  `=RF2_SIGagr_10_`sfx_s'' "%" '"  "'
					}
				}
			}

			// if default or extended dashboard, add everything else below main indicator in bubble
			if "`customindicators'"!="SIGagronly" {
				** fill dashboard matrix, with originally significant [R=s] (insignificant [R=n]) rows and columns C=1, ..., n of the dashboard identified by cond_RC
				if `cond_n1' {
					if (RF2_SIGagr_sigdef_`sfx_n'!=. & `sigdigits_ra'<`sigdigits_oa' & `studypooling'==0) | (RF2_SIGagr_sigdef_`sfx_n'!=. & `studypooling'==1) {  
						local y`case_n'x1	`"  "`: display "{it:p}{&le}{&alpha}{sup:o}: " `=RF2_SIGagr_sigdef_`sfx_n'' "%" '"	"`: display "`=ustrunescape("\u0394\u0305\u0070")': " %3.2f RF2_SIGvar_nsig_`sfx_n''"  "'
					}
					else {
						local y`case_n'x1  	`"  	 																	    "`: display "`=ustrunescape("\u0394\u0305\u0070")': " %3.2f RF2_SIGvar_nsig_`sfx_n''"  "'
					}							
				}
				if `cond_n3' {
					if "`ivadjust'"=="0" {
						if `signum_ra'>5  {
								local y`case_n'x3	`" "`: display "{it:p}{&le}0.05: "  `=RF2_SIGagr_05_`sfx_n'' "%" '"  		"`: display "`=ustrunescape("\u0394\u0305\u0070")': " %3.2f RF2_SIGvar_sig_`sfx_n''" "'
							if "`customindicators'"=="SIGswitch" {
								local y`case_n'x3	`" "`: display "{it:p}{&le}0.05: "  `=RF2_SIGagr_05_`sfx_n'' "%" '"         "`: display "`=ustrunescape("\u0394\u0305\u0070")': " %3.2f RF2_SIGvar_sig_`sfx_n''"      										"`: display "high |{&beta}|: " %3.0f RF2_SIGsw_btosig_`sfx_n' "%;  low se: " %3.0f RF2_SIGsw_setosig_`sfx_n' "%" '" "'
							}
						}
						if `signum_ra'<=5  {
								local y`case_n'x3  	`" "`: display "{it:p}{&le}0.10: "  `=RF2_SIGagr_10_`sfx_n'' "%" '"			"`: display "`=ustrunescape("\u0394\u0305\u0070")': " %3.2f RF2_SIGvar_sig_`sfx_n''" "'				
							if "`customindicators'"=="SIGswitch" {
								local y`case_n'x3  	`" "`: display "{it:p}{&le}0.10: "  `=RF2_SIGagr_10_`sfx_n'' "%" '"			"`: display "`=ustrunescape("\u0394\u0305\u0070")': " %3.2f RF2_SIGvar_sig_`sfx_n''"											"`: display "high |{&beta}|: " %3.0f RF2_SIGsw_btosig_`sfx_n' "%;  low se: " %3.0f RF2_SIGsw_setosig_`sfx_n' "%" '"  "'			
							}
						}
					}
					if "`ivadjust'"!="0" {
						if `signum_ra'>5 {
								local y`case_n'x3	`" "`: display "{it:p}{&le}0.05: "  `=RF2_SIGagr_05_`sfx_n'' "% ({it:`ivadjust'}: "  `=RF2_SIGagr_05iva_`sfx_n'' "%)" '" 	"`: display "`=ustrunescape("\u0394\u0305\u0070")': " %3.2f RF2_SIGvar_sig_`sfx_n''" "'
							if "`customindicators'"=="SIGswitch" { 
								local y`case_n'x3	`" "`: display "{it:p}{&le}0.05: "  `=RF2_SIGagr_05_`sfx_n'' "% ({it:`ivadjust'}: "  `=RF2_SIGagr_05iva_`sfx_n'' "%)" '"   	"`: display "`=ustrunescape("\u0394\u0305\u0070")': " %3.2f RF2_SIGvar_sig_`sfx_n''" 	"`: display "high |{&beta}|: " %3.0f RF2_SIGsw_btosig_`sfx_n' "%;  low se: " %3.0f RF2_SIGsw_setosig_`sfx_n' "%" '" "'	
							}
						}
						if `signum_ra'<=5 & `signum_ra'>1 {
								local y`case_n'x3	`" "`: display                              			"{it:`ivadjust'}-adjusted: "  `=RF2_SIGagr_05iva_`sfx_n'' "%" '" 	"`: display "`=ustrunescape("\u0394\u0305\u0070")': " %3.2f RF2_SIGvar_sig_`sfx_n''" "'
							if "`customindicators'"=="SIGswitch" {
								local y`case_n'x3	`" "`: display                             	 			"{it:`ivadjust'}-adjusted: "  `=RF2_SIGagr_05iva_`sfx_n'' "%" '"	"`: display "`=ustrunescape("\u0394\u0305\u0070")': " %3.2f RF2_SIGvar_sig_`sfx_n''" 	"`: display "high |{&beta}|: " %3.0f RF2_SIGsw_btosig_`sfx_n' "%;  low se: " %3.0f RF2_SIGsw_setosig_`sfx_n' "%" '" "'	 
							}
						}
						if `signum_ra'==1 {
								local y`case_n'x3	`" "`: display                              			"{it:`ivadjust'}-adjusted: "  `=RF2_SIGagr_01iva_`sfx_n'' "%" '" 	"`: display "`=ustrunescape("\u0394\u0305\u0070")': " %3.2f RF2_SIGvar_sig_`sfx_n''" "'
							if "`customindicators'"=="SIGswitch" {
								local y`case_n'x3	`" "`: display                              			"{it:`ivadjust'}-adjusted: "  `=RF2_SIGagr_01iva_`sfx_n'' "%" '"	"`: display "`=ustrunescape("\u0394\u0305\u0070")': " %3.2f RF2_SIGvar_sig_`sfx_n''" 	"`: display "high |{&beta}|: " %3.0f RF2_SIGsw_btosig_`sfx_n' "%;  low se: " %3.0f RF2_SIGsw_setosig_`sfx_n' "%" '" "'	 
							}
						}
					}
				}

				if `cond_s1' {
					if "`customindicators'"=="default" {
						local y`case_s'x1 	`" "`: display "{&beta} in CI({&beta}{sup:o}): "  `=RF2_ESagr_`sfx_s'' "%" '"	"`: display "`=ustrunescape("\u0394\u0305\u0070")': " %3.2f RF2_SIGvar_nsig_`sfx_s''"  "'
					}
					if "`customindicators'"=="SIGswitch" {
						local y`case_s'x1 	`" "`: display "{&beta} in CI({&beta}{sup:o}): "  `=RF2_ESagr_`sfx_s'' "%" '"	"`: display "`=ustrunescape("\u0394\u0305\u0070")': " %3.2f RF2_SIGvar_nsig_`sfx_s''"    "`: display "low |{&beta}|: " %3.0f RF2_SIGsw_btonsig_`sfx_s' "%;  high se: " %3.0f RF2_SIGsw_setonsig_`sfx_s' "%" '" "' 
					}
				}
				if `cond_s3' {
					if "`ivadjust'"!="0" {
						if `signum_ra'>5 {
							if (RF2_SIGagr_sigdef_`sfx_s'!=. & `sigdigits_ra'>`sigdigits_oa' & `studypooling'==0) | (RF2_SIGagr_sigdef_`sfx_s'!=. & `studypooling'==1) {  
								local y`case_s'x3	`"  "`: display "{it:p}>{&alpha}{sup:o}: " `=RF2_SIGagr_sigdef_`sfx_s'' "%" '"	"`: display "{it:p}{&le}0.05: "  `=RF2_SIGagr_05_`sfx_s'' "% ({it:`ivadjust'}: "  `=RF2_SIGagr_05iva_`sfx_s'' "%)" '"  	"`: display "`=ustrunescape("\u03B2\u0303")': `sign_d_sig`m''" RF2_ESrel_`sfx_s' "% (`=ustrunescape("\u0394\u0305\u03B2\u0303")': " RF2_ESvar_`sfx_s' "%)" '"  "'
							}
							if RF2_SIGagr_sigdef_`sfx_s'==. {
								local y`case_s'x3	`" 																				"`: display "{it:p}{&le}0.05: "  `=RF2_SIGagr_05_`sfx_s'' "% ({it:`ivadjust'}: "  `=RF2_SIGagr_05iva_`sfx_s'' "%)" '"  	"`: display "`=ustrunescape("\u03B2\u0303")': `sign_d_sig`m''" RF2_ESrel_`sfx_s' "% (`=ustrunescape("\u0394\u0305\u03B2\u0303")': " RF2_ESvar_`sfx_s' "%)" '"  "'
							}
						}
						if `signum_ra'<=5 & `signum_ra'>1 {
							if (RF2_SIGagr_sigdef_`sfx_s'!=. & `sigdigits_ra'>`sigdigits_oa' & `studypooling'==0) | (RF2_SIGagr_sigdef_`sfx_s'!=. & `studypooling'==1) {  	
								local y`case_s'x3	`"  "`: display "{it:p}>{&alpha}{sup:o}: " `=RF2_SIGagr_sigdef_`sfx_s'' "%" '"	"`: display                              			"{it:`ivadjust'}-adjusted: "  `=RF2_SIGagr_05iva_`sfx_s'' "%" '"  	"`: display "`=ustrunescape("\u03B2\u0303")': `sign_d_sig`m''" RF2_ESrel_`sfx_s' "% (`=ustrunescape("\u0394\u0305\u03B2\u0303")': " RF2_ESvar_`sfx_s' "%)" '"  "'	
							}
							if RF2_SIGagr_sigdef_`sfx_s'==. {
								local y`case_s'x3	`" 																				"`: display                              			"{it:`ivadjust'}-adjusted: "  `=RF2_SIGagr_05iva_`sfx_s'' "%" '"  	"`: display "`=ustrunescape("\u03B2\u0303")': `sign_d_sig`m''" RF2_ESrel_`sfx_s' "% (`=ustrunescape("\u0394\u0305\u03B2\u0303")': " RF2_ESvar_`sfx_s' "%)" '"  "'
							}
						}
						if `signum_ra'==1 {
							if (RF2_SIGagr_sigdef_`sfx_s'!=. & `sigdigits_ra'>`sigdigits_oa' & `studypooling'==0) | (RF2_SIGagr_sigdef_`sfx_s'!=. & `studypooling'==1) {  	
								local y`case_s'x3	`"  "`: display "{it:p}>{&alpha}{sup:o}: " `=RF2_SIGagr_sigdef_`sfx_s'' "%" '"	"`: display                              			"{it:`ivadjust'}-adjusted: "  `=RF2_SIGagr_01iva_`sfx_s'' "%" '"  	"`: display "`=ustrunescape("\u03B2\u0303")': `sign_d_sig`m''" RF2_ESrel_`sfx_s' "% (`=ustrunescape("\u0394\u0305\u03B2\u0303")': " RF2_ESvar_`sfx_s' "%)" '"  "'	
							}
							if RF2_SIGagr_sigdef_`sfx_s'==. {
								local y`case_s'x3	`" 																				"`: display                              			"{it:`ivadjust'}-adjusted: "  `=RF2_SIGagr_01iva_`sfx_s'' "%" '"  	"`: display "`=ustrunescape("\u03B2\u0303")': `sign_d_sig`m''" RF2_ESrel_`sfx_s' "% (`=ustrunescape("\u0394\u0305\u03B2\u0303")': " RF2_ESvar_`sfx_s' "%)" '"  "'
							}
						}
					}
					if "`ivadjust'"=="0" {
						if `signum_ra'>5 {
							if (RF2_SIGagr_sigdef_`sfx_s'!=. & `sigdigits_ra'>`sigdigits_oa' & `studypooling'==0) | (RF2_SIGagr_sigdef_`sfx_s'!=. & `studypooling'==1) {  	
								local y`case_s'x3	`" 	"`: display "{it:p}>{&alpha}{sup:o}: " `=RF2_SIGagr_sigdef_`sfx_s'' "%" '"	"`: display "{it:p}{&le}0.05: "  `=RF2_SIGagr_05_`sfx_s'' "%" '"                                              	"`: display "`=ustrunescape("\u03B2\u0303")': `sign_d_sig`m''" RF2_ESrel_`sfx_s' "% (`=ustrunescape("\u0394\u0305\u03B2\u0303")': " RF2_ESvar_`sfx_s' "%)" '"  "'
							}
							if RF2_SIGagr_sigdef_`sfx_s'==. {
								local y`case_s'x3	`" 																				"`: display "{it:p}{&le}0.05: "  `=RF2_SIGagr_05_`sfx_s'' "%" '"                                              	"`: display "`=ustrunescape("\u03B2\u0303")': `sign_d_sig`m''" RF2_ESrel_`sfx_s' "% (`=ustrunescape("\u0394\u0305\u03B2\u0303")': " RF2_ESvar_`sfx_s' "%)" '"  "'
							}
						}
						if `signum_ra'<=5 {
							if (RF2_SIGagr_sigdef_`sfx_s'!=. & `sigdigits_ra'>`sigdigits_oa' & `studypooling'==0) | (RF2_SIGagr_sigdef_`sfx_s'!=. & `studypooling'==1) {
								local y`case_s'x3	`" "`: display "{it:p}>{&alpha}{sup:o}: " `=RF2_SIGagr_sigdef_`sfx_s'' "%" '"	"`: display "{it:p}{&le}0.10: "  `=RF2_SIGagr_10_`sfx_s'' "%" '"												"`: display "`=ustrunescape("\u03B2\u0303")': `sign_d_sig`m''" RF2_ESrel_`sfx_s' "% (`=ustrunescape("\u0394\u0305\u03B2\u0303")': " RF2_ESvar_`sfx_s' "%)" '"  "'  	
							}
							if RF2_SIGagr_sigdef_`sfx_s'==. {
								local y`case_s'x3	`" 																				"`: display "{it:p}{&le}0.10: "  `=RF2_SIGagr_10_`sfx_s'' "%" '"												"`: display "`=ustrunescape("\u03B2\u0303")': `sign_d_sig`m''" RF2_ESrel_`sfx_s' "% (`=ustrunescape("\u0394\u0305\u03B2\u0303")': " RF2_ESvar_`sfx_s' "%)" '"  "'
							}
						}
					}
				}	
			}	
		}


*** Specifying location of indicators in dashboard depending on the number of results/ y-axis entries presented
		local tsize vsmall
		local t_col0  ""
		if `aggregation'==1 {
			local t_col0b "text(`=1/2*`yset_n'+0.5'                      0.75 `yx0b' , size(`tsize'))"
		}
		else {
			local t_col0b "text(`=1/2*`yset_n'+0.5'                      0.6  `yx0b' , size(`tsize'))"
		}
		local t_col1  ""
		local t_col3  ""
		// for newer Stata versions, the dashboard looks better when line spacing is increased 
		if (c(version)>=16) {
			local lgap linegap(1pt)
		}
		else {
			local lgap
		}
		forval m = 1/`yset_n' {
			local t_col0  "`t_col0'  text(`m'                        0.2 `y`m'x0', size(`tsize') `lgap')"  
			local t_col1  "`t_col1'  text(`=`m'-0.2-(`yset_n'-2)*0.05' 1 `y`m'x1', size(`tsize') `lgap')"
			local t_col3  "`t_col3'  text(`=`m'-0.2-(`yset_n'-2)*0.05' 3 `y`m'x3', size(`tsize') `lgap')"
		}
		
		local yupper = 2.5 + (`yset_n'-2)*0.9


*** Legend subtitle
		if `sigdigits_ra'!=`sigdigits_oa' & `sigdigits_oa'!=999 & `sigdigits_ra'!=999 {
			local subtitle_sigagr	`" "Significance classification agreement ({&kappa})" "({&alpha}{sup:o}=0.`sigdigits_oa' applied to original results)" "' 
		}
		if `sigdigits_oa'==999 {
			local subtitle_sigagr	`" "Significance classification agreement ({&kappa})" "(varying {&alpha}{sup:o} applied to original results)" "' 
		}
		if `sigdigits_ra'==`sigdigits_oa' {
			local subtitle_sigagr	Significance agreement ({&kappa})
		}


			
************************************************************
***  PART 5.C  PLOTTING OF THE DASHBOARD
************************************************************

		twoway (scatteri `=dashbrd_y[0]' `=dashbrd_x[0]', mcolor("`=colorname_confirm[1]'") msize(*2)) (scatteri `=dashbrd_y[0]' `=dashbrd_x[0]', mcolor("`=colorname_nonconfirm[1]'") msize(*2)) ///
			`slist', ///
			`ytitle' xtitle("Robustness results") ///
			xscale(range(`xleft' 3.5) /*alt*/) yscale(range(0.5 `yupper')) ///
			xlabel(`xlab', labsize(2.5)) ylabel(`ylab', labsize(2.5)) ///
			`t_col0' `t_col0b' `t_col1' `t_col3'  ///
			legend(rows(1) order(1 "yes" 2 "no") position(6) bmargin(tiny) size(2) subtitle(`subtitle_sigagr', size(vsmall)))  ///
			graphregion(color(white) margin(medium)) scheme(white_tableau) name(dashboard_main, replace)
				// first line of this twoway command does not show up in the dashboard but is required to make the legend show up with the correct colours 
			
		if `aggregation'==1 {
			graph combine dashboard_main hist_SIGcfm, hole(2) imargin(zero) commonscheme scheme(white_tableau)
		}

		graph export "`filepath'/repframe_fig_dashboard_`ind_level'_`fileidentifier'.`graphfmt'", replace as(`graphfmt')

	
			
************************************************************
***  PART 5.D  NOTES TO DASHBOARD IN STATA RESULTS WINDOW
************************************************************
		
*** Specifying components of figure note
		local specs "analysis paths"  
		if (`N_specs_min'==`N_specs_max' & `N_specs_max'==1) {
		   local specs "analysis path" 
		}
		if  `N_specs_min'==`N_specs_max' {
			local N_specs `N_specs_max'
		}
		
		
		if `aggregation'==0 {
			local notes_shares_shown 	shares of analysis paths
			local notes_spec 	based on `N_specs' `specs'
			if `N_results'>1 &  `N_specs_min'==`N_specs_max' {
				local notes_spec 	based on `N_specs' `specs' for each of the `N_results' results
			}
			local notes_sigdef
		}
		else {
			local notes_spec 	based on `N_results' results with `N_specs' `specs' each
			local notes_sigdef
			if `studypooling'==0 {
				local notes_shares_shown 	shares of analysis paths
				if `signum_oa'>`signum_ra' { 
					local notes_sigdef 			- `notes_sigdef_N' of the results with estimates that are stat. insig. in rep. analyses only because more stringent stat. sig. level is appplied in rep. analysis than in original analysis  
				}
				if `signum_oa'<`signum_ra' { 
					local notes_sigdef 			- `notes_sigdef_N' of the results with estimates that are stat. sig. in rep. analyses may only be so because less stringent stat. sig. level is appplied in rep. analysis than in original analysis  
				}
			}
			else {
				local notes_shares_shown 	mean shares of analysis paths across studies
				if `notes_sigdef_N'>0 {
					local notes_sigdef 			- `notes_sigdef_N' of the studies with estimates that are stat. insig. (sig) in rep. analyses only because more (less) stringent classification of what constitutes stat. significance is appplied in rep. analysis than in original analysis  
				}
			}
		}	
		if  `N_specs_min'!=`N_specs_max' {
			local N_specs "`N_specs_min' (`spec_min') to `N_specs_max' (`spec_max')"
			local notes_spec 	based on `N_results' results with `N_specs' `specs'
		}


*** Display figure note
		noi dis as text _newline(1)	"Robustness Dashboard stored under `filepath'/repframe_fig_dashboard_`ind_level'_`fileidentifier'.`graphfmt'"
		noi dis as text _newline(1)	"Dashboard shows `notes_shares_shown' - `notes_spec' `notes_sigdef'"
		noi dis as text _newline(2) "Legend:"
		noi dis as text    			"`=ustrunescape("\u03B2")' = beta coefficient"
		noi dis	as text 			"`=ustrunescape("\u03B2\u0303")' = median beta coefficient of reproducability or replicability analysis, measured as % deviation from original beta coefficient; generally, tildes indicate median values"
		noi dis as text 			"CI = confidence interval"
		if `pval_provided'==1 {
			noi dis as text         "{it:p} = {it:p}-value" 
		}
		else {
			noi dis as text         "{it:p} = {it:p}-value (relies on two-sided test assuming an approximately normal distribution)" 
		}
		if `studypooling'==0 {
			noi dis	as text 		"{it:X}`=ustrunescape("\u0366")' = parameter {it:X} from original study {it:o}" 
		}
		else {
			noi dis	as text 		"{it:X}`=ustrunescape("\u0366")' = parameter {it:X} from original studies {it:o}" 
		}
		if `notes_sigdef_N'>0 { 
			noi dis as text 		"`=ustrunescape("\u03B1")' = significance level"
		}
		noi dis as text 			"{it:X}`=ustrunescape("\u0305")' = mean of parameter {it:X}"
		noi dis as text 			"`=ustrunescape("\u0394")' = absolute deviation"
		if `aggregation'==0 {
			if beta_rel_orig_j!=. {
				noi dis as text 	"[+/-xx%] = Percentage in squared brackets refers to the original beta coefficient, expressed as % deviation from original mean of the result"
			}
		} 
		else {
			noi dis as text 		"|{it:X}| = absolute value of parameter {it:X}"
			if `sigdigits_ra'==`sigdigits_oa' {
				noi dis as text 	"`=ustrunescape("\u039A")' = significance agreement"  
			}
			if `sigdigits_ra'!=`sigdigits_oa' {
				noi dis as text 	"`=ustrunescape("\u039A")' = significance classification agreement"  
			}
		}   
		if "`customindicators'"=="SIGswitch" {
			noi dis as text 	   	"low |`=ustrunescape("\u03B2")'| (high se) refers to the share of analysis paths of the reproducability or replicability analysis where the revised absolute value of the beta coefficient (standard error) is sufficiently low (high) to turn the overall estimate insignificant at the `signum_ra'% level, keeping the standard error (beta coefficient) constant"
			noi dis as text    		"Conversely, high |`=ustrunescape("\u03B2")'| (low se) refers to the share of analysis paths of the reproducability or replicability analysis where the revised absolute value of the beta coefficient (standard error) is sufficiently high (low) to turn the overall estimate significant at the `signum_ra'% level, keeping the standard error (beta coefficient) constant"   
		}
		if "`ivadjust'"=="tF" | "`ivadjust'"=="VtF" {
			if `signum_ra'>1 { 
				noi dis as text  	"{it:`ivadjust'} indicates the share of statistically significant estimates in the reproducability or replicability analysis at the {it:`ivadjust'}-adjusted 5% level, using the {it:`ivadjust'} adjustment proposed by Lee et al."
			}
			if `signum_ra'==1 {
				noi dis as text  	"{it:`ivadjust'} indicates the share of statistically significant estimates in the reproducability or replicability analysis at the {it:`ivadjust'}-adjusted 1% level, using the {it:`ivadjust'} adjustment proposed by Lee et al."
			}
		}
		if "`ivadjust'"=="AR" {
			noi dis as text   		"{it:`ivadjust'} indicates the share of statistically significant estimates in the reproducability or replicability analysis when robustness analyses apply weak-IV robust Anderson-Rubin {it:p}-values."
		}
		noi dis as text 			"More details on indicator definitions under https://github.com/guntherbensch/repframe"
	}
	


	
	
********************************************************************************
***  PART 6  COMPILE REPRODUCIBILITY AND REPLICABILITY INDICATORS 
********************************************************************************
	
************************************************************
***  PART 6.A  PREPARE INDICATOR TABLE DATA
************************************************************

	use `data_j', clear
	capture drop `signfirst'
	capture drop pval_0`iva_level'iva_orig_j
	drop RF2_* rany_*

	if `studypooling'==0 {
		foreach b in beta beta_rel {	 
			gen    `b'_orig_osig_oa_all = .
			gen    `b'_orig_onsig_oa_all = .
		}
	}


	preserve
		keep mainvar *_all
		
		if `studypooling'==0 {
			rename *_osig_oa_all  *2
			rename *_onsig_oa_all *5
			
			reshape long `RF_list_nosfx' pval_orig beta_orig beta_rel_orig, i(mainvar) j(panel)
			
			drop mainvar 
			gen     mainvar_str = "All results (originally sig.)"   if panel==2
			replace mainvar_str = "All results (originally insig.)" if panel==5
		}
		else {
			rename *_oa_all  *

			drop mainvar
			gen mainvar_str = "All studies" 
			gen panel = 4
		}

		duplicates drop
		tempfile RF_all_long
		save `RF_all_long'
	restore


	if `studypooling'==0 {
		drop mainvar *_all
		rename *_j *
		
		gen     panel = 1 if pval_orig<=0.`sigdigits_oa'
		replace panel = 4 if pval_orig>0.`sigdigits_oa'

		label var mainvar_str "Result"

		** formatting of indicators
		format beta_orig  %10.4f
		format beta_rel_orig  %10.2f
		format pval_orig  %3.2f
		format RF_SIGagr  %5.4f
		format RF_ESrel RF_SIGrel RF_ESvar RF_SIGvar  %10.4f
		if `shelvedind'==1 {
			format RF_pooledH_A  RF_pooledH_B  %10.4f
		}
	}
	else {
		use `data_pooled_k', clear

		gen     panel = 1
		
		label var mainvar_str "Study reference"

		** formatting of indicators
		format RF_SIGagr_osig RF_SIGagr_onsig  %5.4f
		format RF_ESrel_osig RF_SIGrel_osig RF_ESvar_osig RF_SIGvar_osig  RF_ESrel_onsig RF_SIGrel_onsig RF_ESvar_onsig RF_SIGvar_onsig  %10.4f
	}

	set obs `=_N+1'
	replace panel = 3 							if mainvar_str==""
	replace mainvar_str = "__________________" 	if mainvar_str==""
	sort mainvar_str
	gen list_n = _n



************************************************************
***  PART 6.B  COMPILING REPRODUCIBILITY AND REPLICATION FRAMEWORK INDICATOR RESULTS 
************************************************************

	append using `RF_all_long'
	sort panel list_n
	drop panel list_n 
	set obs `=_N+1'
	replace mainvar_str = "__________________" 	if mainvar_str==""


	** create gap between originally sig. and originally insig. indicators
	if `studypooling'==1 {
		gen     gap = "|"   
		replace gap = "__________________" 		if mainvar_str == "__________________"
		label var gap "|"
		order gap, before(RF_SIGagr_onsig)
	}


	** add notes 
	set obs `=_N+1'   // backward-compatible alternative to insobs 1 in order to add an observation at bottom of dataset to include notes
	replace mainvar_str = "Notes:" if mainvar_str==""
	set obs `=_N+1'
	if `studypooling'==0 {
		if "`siglevel_orig'"!="" {
			local osignote "applying original authors' sig. level (`signum_oa'% level)"
		}
		if "`siglevel_orig'"=="" & `signum_oa'==`signum_ra' { 
			local osignote "applying sig. level (`signum_oa'% level) as defined in rep. analysis"
		}
		replace mainvar_str = "`osig_oa_rslt_share' results originally significant `osignote'" if mainvar_str==""
		
		if `ivarweight'==1 {
			set obs `=_N+1'
			replace mainvar_str = "Indicators across results are derived by weighting individual results in inverse proportion to their variance" if mainvar_str==""
		}

		local ind_level rslt
	}
	else {
		replace mainvar_str = "`osig_oa_rslt_share' results originally significant" if mainvar_str==""

		foreach olevel in 05 10 {
			foreach rlevel in 05 10 {
				if `siglevel_o`olevel'_r`rlevel'_N'>0 {
					set obs `=_N+1'
					replace mainvar_str = "`siglevel_o`olevel'_r`rlevel'_N' of the studies with `olevel'% sig. level applied to original estimates and `rlevel'% sig. level applied to rep. analyses" if mainvar_str=="" 
				}
			}
		}

		set obs `=_N+1'
		replace mainvar_str = "In `ivarweight_stud_N' of the studies, indicators across results are derived by weighting individual results in inverse proportion to their variance" if mainvar_str==""
	
		local ind_level stud
	}

	set obs `=_N+1'
	replace mainvar_str = "repframe `repframe_vs'" if mainvar_str==""

	if "`tabfmt'"=="csv" {
		set obs `=_N+1'
		replace mainvar_str = "   " if mainvar_str==""
		if `studypooling'==0 {
			set obs `=_N+1'	
			replace mainvar_str = "pval_orig - p-value of original estimate; beta_orig - original beta estimate; beta_rel_orig - original beta estimate, expressed as % deviation from original mean of the result" if mainvar_str=="" 
		}
		set obs `=_N+1'	
		replace mainvar_str = "RF_SIGagr - (RF1) Statistical significance indicator" if mainvar_str==""
		set obs `=_N+1'	
		replace mainvar_str = "RF_ESrel - (RF2) Relative effect size indicator; RF_SIGrel - (RF3) Relative significance indicator" if mainvar_str==""
		set obs `=_N+1'
		replace mainvar_str = "RF_ESvar - (RF4) Effect sizes variation indicator; RF_SIGvar - (RF5) Significance variation indicator" if mainvar_str==""
		if `studypooling'==1 {
			set obs `=_N+1'
			replace mainvar_str = "osig - originally significant; onsig - originally insignificant" if mainvar_str==""
		}
		set obs `=_N+1'
		replace mainvar_str = "More details on indicator definitions under https://github.com/guntherbensch/repframe" if mainvar_str=="" 
		
		export delimited "`filepath'/repframe_tab_indicators_`ind_level'_`fileidentifier'.csv", replace delimiter(;) datafmt
	}
	if "`tabfmt'"=="xlsx" {
		set obs `=_N+1'
		replace mainvar_str = "More details on indicator definitions under https://github.com/guntherbensch/repframe" if mainvar_str=="" 

		export excel "`filepath'/repframe_tab_indicators_`ind_level'_`fileidentifier'.xlsx", firstrow(varlabels) replace
	}
	noi dis as text _newline(1)	"Reproducibility and Replicability Indicators table stored under `filepath'/repframe_tab_indicators_`ind_level'_`fileidentifier'.`tabfmt'"
	noi dis as text _newline(2)
	
	use `inputdata', clear
}	
end
*** End of file