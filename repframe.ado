*! version 1.4.1  29feb2024 Gunther Bensch
* remember to also keep -local repframe_vs- updated at the beginning of PART 1

/*
*** PURPOSE:	
	This Stata do-file contains the program repframe to calculate, tabulate and visualize Reproducibility and Replicability Indicators based on multiverse analyses.
	repframe requires version 12.0 of Stata or newer.

	
*** OUTLINE:	PART 1.  INITIATE PROGRAM REPFRAME
			
				PART 2.  OPTIONS, AUXILIARY VARIABLE GENERATION, AND MAIN LOCALS

				PART 3.  INDICATOR DEFINITIONS BY OUTCOME/ STUDY AND ACROSS OUTCOMES/ STUDIES
				
				PART 4.  INDICATOR DATASET AT STUDY LEVEL
				
				PART 5.  SENSITIVITY DASHBOARD VISUALIZATION
				
				PART 6.  COMPILE REPRODUCIBILITY AND REPLICABILITY INDICATORS

					
***  AUTHOR:	Gunther Bensch, RWI - Leibniz Institute for Economic Research, gunther.bensch@rwi-essen.de



*** Syntax components used in the following
	_all  - across outcomes (studies)
	_d    - dummy variable
	_i    - level of individual analysis paths
	_j    - outcome (study) level
	_k    - study (across study) level 
	_N    - running number
	_N	  - total number
	_orig - original study
	oa    - original analyis OR original author(s)
	osig  - significant in original study
	onsig - insignificant in original study
	ra    - reproducibility or replicability analysis
	x_    - temporary variables
*/	




********************************************************************************
*****  PART 1  INITIATE PROGRAM REPFRAME
********************************************************************************


cap prog drop repframe
prog def repframe, sortpreserve


#delimit ;
	
syntax varlist(numeric max=1) [if] [in], 
[ 
beta(varname numeric) beta_orig(varname numeric) shortref(string)  siglevel(numlist max=1 integer) siglevel_orig(numlist max=1 integer)  
se(varname numeric) se_orig(varname numeric)  pval(varname numeric) pval_orig(varname numeric)  zscore(varname numeric) zscore_orig(varname numeric)
STUDYPOOLing(numlist max=1 integer) 
df(varname numeric) df_orig(varname numeric)  mean(varname numeric) mean_orig(varname numeric)  sameunits(varname numeric) 
filepath(string)] [FILEIDentifier(string)  IVARWeight(numlist max=1 integer)  orig_in_multiverse(numlist max=1 integer) 
shelvedind(numlist max=1 integer) 
beta2(varname numeric) beta2_orig(varname numeric)  se2(varname numeric) se2_orig(varname numeric)  pval2(varname numeric) pval2_orig(varname numeric)  zscore2(varname numeric) zscore2_orig(varname numeric) 
SENSDash(numlist max=1 integer)  vshortref_orig(string)  extended(numlist max=1 integer) aggregation(numlist max=1 integer)  graphfmt(string)  ivF(varname numeric) signfirst(varname numeric)
];

#delimit cr


qui {

*** Record the version of the repframe package
	local repframe_vs  "version 1.4.1  29feb2024"

*** Preserve initial dataset 
	tempfile inputdata   // -tempfile- used instead of command -preserve- because -repframe- would require multiple -preserve- (which is not ossible) as different datasets will be used for the table of Indicators and for the Sensitivity Dashboard
	save `inputdata'
	
*** Syntax components that have to be defined early on in PART 1
	if "`sensdash'"=="" {
		local sensdash = 1
	}
	if "`studypooling'"=="" {
		local studypooling = 0 
	}
	
*** Install user-written packages from SSC, mainly required for the Sensibility Dashboard
	capture which labmask
	if _rc == 111 {                 
		noi dis "Installing labutil"
		ssc install labutil, replace
	}
	
	if `sensdash'==1 {
		capture which colrspace.sthlp 
		if _rc == 111 {                 
			noi dis "Installing colrspace"
			ssc install colrspace, replace
		}
		capture which colorpalette
		if _rc == 111 {                 
			noi dis "Installing palettes"
			ssc install palettes, replace
		}
		capture which schemepack.sthlp
		if _rc == 111 {                 
			noi dis "Installing schemepack"
			ssc install schemepack, replace
		}
	}
	
*** Implement [if] and [in] condition
	marksample to_use
	keep if `to_use' == 1
  
*** Keep required variables
	if `studypooling'==0 {
		keep `varlist' `beta' `beta_orig'   `se' `se_orig' `pval' `pval_orig' `zscore' `zscore_orig'   `df' `df_orig' `mean' `mean_orig'   `sameunits'   `beta2' `beta2_orig' `se2' `se2_orig' `pval2' `pval2_orig' `zscore2' `zscore2_orig'  `ivF' `signfirst' 
	}
	// if studypooling==1: the repframe command creates datasets as input to studypooling==1 that are already tailored to the set of required variables
		
	



********************************************************************************
*****  PART 2  OPTIONS, AUXILIARY VARIABLE GENERATION, AND MAIN LOCALS
********************************************************************************			

************************************************************
***  PART 2.A  COMMAND OPTIONS
************************************************************

*** Option studypooling
	if ("`studypooling'"!="" & "`studypooling'"!="0" & "`studypooling'"!="1") {
		noi dis "{red: If {opt studypooling} is defined, it needs to take on the value 0 (no) or 1 (yes).}"	
		use `inputdata', clear
		exit
	}
	
*** Options beta, beta_orig, se, se_orig, pval, pval_orig, zscore, zscore_orig (& df, df_orig)
	if `studypooling'==0 {	
		if ("`beta'"=="" | "`beta_orig'"=="") & "`shortref'"=="" { 
			noi dis "{red: Unless {opt studypooling(1)} is specified, both {opt beta()} and {opt beta_orig()} as well as {opt shortref()} has to be specified}"	
			use `inputdata', clear
			exit
		}			
			
		if "`beta'"=="" | "`beta_orig'"=="" { 
			noi dis "{red: Unless {opt studypooling(1)} is specified, both {opt beta()} and {opt beta_orig()} has to be specified}"	
			use `inputdata', clear
			exit
		}

		if "`shortref'"=="" { 
			noi dis "{red: Unless {opt studypooling(1)} is specified, {opt shortref()} has to be specified}"	
			use `inputdata', clear
			exit
		}

		** add _j suffix to beta_orig (and below to se_orig etc) to make explicit that this is information at the outcome level 
		gen beta_orig_j = `beta_orig'
		drop `beta_orig'
	
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
		gen beta_orig_dir_j = (beta_orig_j>=0)
		recode beta_orig_dir_j (0 = -1)
		if "`beta2_orig'"!="" {
			gen beta2_orig_dir_j     = (`beta2_orig'>=0)
			recode beta2_orig_dir_j (0 = -1)
		}
		else {
			gen beta2_orig_dir_j     = .
		}
	
		if (("`se'"=="" | "`se_orig'"=="") & ("`pval'"=="" | "`pval_orig'"=="") & ("`zscore'"=="" | "`zscore_orig'"=="")) {
			noi dis "{red: Please specify both {opt se()} and {opt se_orig()} and/or both {opt pval()} and {opt pval_orig()} and/or both {opt zscore()} and {opt zscore_orig()}, but not only one of them, respectively}"	
			use `inputdata', clear
			exit
		}
		
		if (("`se'"=="" & "`se_orig'"=="") | ("`pval'"=="" & "`pval_orig'"=="")) {
			noi dis "It is recommended to specify both sets of variables {opt se()} & {opt se_orig()} and {opt pval()} & {opt pval_orig()}. The command {cmd:repframe} determines the non-specified variables based on the conventional {it:t}-test formula, which may not be appropriate in all cases, e.g. when using {opt svy:} in the original estimations."
		}

		if "`se'"=="" & "`zscore'"=="" & "`df'"=="" {
			noi dis "{opt pval()} and {opt pval_orig()} are specified. Note that it is assumed that these p-values are derived from two-sided t-tests."
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
		if "`se_orig'"=="" & "`zscore_orig'"=="" & "`df_orig'"=="" {
			gen     se_orig_j   = abs(beta_orig_j/invnormal(`pval_orig'/2))	
		}
		if "`se_orig'"=="" & "`zscore_orig'"=="" & "`df_orig'"!="" {
			gen     se_orig_j   = abs(beta_orig_j/invt(`df_orig', `pval_orig'/2)) 	
		}	
		if "`se_orig'"=="" & "`zscore_orig'"!="" {
			gen     se_orig_j  	= beta_orig_j/`zscore_orig'	
		}
		if "`se_orig'"!="" {
			gen     se_orig_j   =  `se_orig'	
			drop `se_orig'
		}

		if "`zscore'"=="" {
			gen zscore_i        = `beta'/se_i
		}
		else {
			gen zscore_i        = `zscore'
			drop `zscore'
		}
		if "`zscore_orig'"=="" {
			gen zscore_orig_j   = beta_orig_j/se_orig_j
		}
		else {
			gen zscore_orig_j   = `zscore_orig'
			drop `zscore_orig'
		}
		
		if "`pval'"=="" & "`df'"=="" {
			gen pval_i = 2*(1 - normal(abs(`beta'/se_i)))
		}
		if "`pval'"=="" & "`df'"!="" {	
			gen pval_i = 2*ttail(`df', abs(`beta'/se_i))
		}
		if "`pval'"!="" {
			gen pval_i = `pval'
			drop `pval'
		}
		if "`pval_orig'"=="" & "`df_orig'"=="" {
			gen pval_orig_j = 2*(1 - normal(abs(beta_orig_j/se_orig_j)))
		}
		if "`pval_orig'"=="" & "`df_orig'"!="" {
			gen pval_orig_j = 2*ttail(`df_orig', abs(beta_orig_j/se_orig_j))
		}
		if "`pval_orig'"!="" {
			gen pval_orig_j = `pval_orig'
			drop `pval_orig'
		}
	}

*** Options siglevel, siglevel_orig
	if `studypooling'==1 {
		if "`siglevel'"!="" | "`siglevel_orig'"!="" {
			noi dis "{red: If {opt studypooling(1)}, significance levels will be retrieved from the input data so that ({opt siglevel}) and ({opt siglevel_orig}) are not meant to be used together with option {opt studypooling(1)}.}"
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
			noi dis "{red: Unless {opt studypooling(1)} is specified, both {opt siglevel()} and {opt siglevel_orig()} has to be specified}"	
			use `inputdata', clear
			exit
		}			
			
		if "`siglevel'"=="" { 
			noi dis "{red: Unless {opt studypooling(1)} is specified, {opt siglevel()} has to be specified}"	
			use `inputdata', clear
			exit
		}		
		else {
			local signum_ra = "`siglevel'"
		}
		if `signum_ra'<0 | `signum_ra'>100 {
			noi dis "{red: Please specify a significance level ({opt siglevel}) between 0 and 100}"
			use `inputdata', clear
			exit
		}
		
		if "`siglevel_orig'"=="" { 
			noi dis "{red: Unless {opt studypooling(1)} is specified, {opt shortref()} has to be specified}"	
			use `inputdata', clear
			exit
		}
		else {
			local signum_oa = "`siglevel_orig'"
		}
		if `signum_oa'<0 | `signum_oa'>100 {
			noi dis "{red: Please specify a significance level ({opt siglevel_orig}) between 0 and 100}"
			use `inputdata', clear
			exit
		}
	}
	if `signum_ra'<10 {
		local sigdigits_ra 0`signum_ra'
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
		
*** Options mean, mean_orig, sameunits
	if `studypooling'==0 {
		if "`mean_orig'"=="" {
			gen mean_orig_j = .
		}
		else {
			gen mean_orig_j = `mean_orig'
			drop `mean_orig'
		}
		if "`mean'"=="" {
			gen mean_j = mean_orig_j
		}
		else {
			gen mean_j = `mean'
			drop `mean'
		}
	
		if "`sameunits'"=="" {
			gen sameunits_i = 1
		}
		else {
			gen sameunits_i = `sameunits'
			drop `sameunits'
		}
	}

*** Options filepath, fileidentifier, ivarweight, orig_in_multiverse
	if "`filepath'"=="" {
		if c(os)=="Windows" {
			local filepath "C:/Users/`c(username)'/Downloads/" 
		}
		else {
			local filepath "~/Downloads/"
		}
	}
	
	if "`fileidentifier'"=="" {
		local fileidentifier = string( d(`c(current_date)'), "%dCY-N-D" )
	}
	
	if `studypooling'==1 {
		if "`ivarweight'"=="1" {
			noi dis "{red: The option {opt ivarweight(1) cannot be used together with the option {opt studypooling(1)}. The input data should instead include a variable {it:ivarweight_stud_d} containing information on ionverse variance weighting at study level}.}"
			use `inputdata', clear
			exit
		}
		local ivarweight = 0 
	}
	else {
		if ("`ivarweight'"!="" & "`ivarweight'"!="0" & "`ivarweight'"!="1") {
			noi dis "{red: If {opt ivarweight} is defined, it needs to take on the value 0 (no) or 1 (yes)}"	
			use `inputdata', clear
			exit
		}
		if "`ivarweight'"=="" {
			local ivarweight = 0
		}
		if `ivarweight'==1 & (mean_j==. | mean_orig_j==.) {
			noi dis "{red: The option {opt ivarweight(1)} requires that the options {opt mean(varname)} and {opt mean_orig(varname)} are also defined}"
			use `inputdata', clear
			exit
		}
		
		if ("`orig_in_multiverse'"!="" & "`orig_in_multiverse'"!="0" & "`orig_in_multiverse'"!="1") {
			noi dis "{red: If {opt orig_in_multiverse} is defined, it needs to take on the value 0 (no) or 1 (yes)}"	
			use `inputdata', clear
			exit
		}
		if "`orig_in_multiverse'"=="" {
			local orig_in_multiverse = 0
		}
	}

*** Option shelvedind  
	if ("`shelvedind'"!="" & "`shelvedind'"!="0" & "`shelvedind'"!="1") {
		noi dis "{red: If {opt shelvedind} is defined, it needs to take on the value 0 (no) or 1 (yes)}"	
		use `inputdata', clear
		exit
	}
	if "`shelvedind'"=="" {
		local shelvedind = 0
	}

*** Options beta2, beta2_orig, se2, se2_orig, pval2, pval2_orig, zscore2, zscore2_orig
	if `studypooling'==0 {
		if ("`beta2'"!="" & ("`se2'"=="" & "`pval2'"=="" & "`zscore2'"=="")) {
			noi dis "{red: If {opt beta2()} is specified, please also specify either {opt se2()}, {opt pval2()}, or {opt zscore2()}.}"	
			use `inputdata', clear
			exit
		}
		if ("`beta2_orig'"!="" & ("`se2_orig'"=="" & "`pval2_orig'"=="" & "`zscore2_orig'"=="")) {
			noi dis "{red: If {opt beta2_orig()} is specified, please also specify either {opt se2_orig()}, {opt pval2_orig()}, or {opt zscore2_orig()}.}"	
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
		if "`zscore2'"=="" & "`beta2'"!="" {
			gen zscore2_i     = `beta2'/se2_i
			
			replace zscore_i  = zscore_i*-1  if beta_orig_dir_j==-1 // if two coefficients in a reproducability or replicability analysis, t/z-value for each must be assigned a positive (negative) sign if coefficient is in the same (opposite) direction as the original coefficient (assumes that there is only one original coefficient)
			replace zscore2_i = zscore2_i*-1 if beta_orig_dir_j==-1
			
			replace zscore_i = (zscore_i+zscore2_i)/2  // if two coefficients in a reproducability or replicability analysis, zscore should be calculated as average of two zscores		
		}
		if "`zscore2'"!="" & "`beta2'"!="" {
			gen zscore2_i     = `zscore2'
			drop `zscore2'
			
			replace zscore_i  = zscore_i*-1  if beta_orig_dir_j==-1 
			replace zscore2_i = zscore2_i*-1 if beta_orig_dir_j==-1
			
			replace zscore_i  = (zscore_i+zscore2_i)/2
		}	
		
		if "`se2_orig'"=="" & "`zscore2_orig'"=="" & "`df_orig'"=="" & "`beta2_orig'"!="" & "`pval2_orig'"!="" {
			gen     se2_orig_j 	= abs(`beta2_orig'/invnormal(`pval2_orig'/2))	
		}
		if "`se2_orig'"=="" & "`zscore2_orig'"=="" & "`df_orig'"!="" & "`beta2_orig'"!="" & "`pval2_orig'"!="" {
			gen     se2_orig_j 	= abs(`beta2_orig'/invt(`df_orig', `pval2_orig'/2)) 	
		}	
		if "`se2_orig'"=="" & "`zscore2_orig'"!="" {
			gen     se2_orig_j 	= `beta2_orig'/`zscore2_orig'	
		}
		if "`se2_orig'"!="" {
			gen     se2_orig_j  =  `se2_orig'	
			drop `se2_orig'
		}
		if "`zscore2_orig'"=="" & "`beta2_orig'"!="" {
			gen zscore2_orig_j  = `beta2_orig'/se2_orig_j
			
			replace zscore_orig_j = (zscore_orig_j+zscore2_orig_j)/2
			replace zscore_orig_j = (abs(zscore_orig_j)+abs(zscore2_orig_j))/2 if ((zscore_orig_j>=0 & zscore2_orig_j<0) | (zscore_orig_j<0 & zscore2_orig_j>=0))  // if one original coefficient is positive and one negative, the two original t/z-values must both be assigned positive signs
		}
		if "`zscore2_orig'"!="" & "`beta2_orig'"!="" {
			gen zscore2_orig_j  = `zscore2_orig'
			drop `zscore2_orig'
			
			replace zscore_orig_j = (zscore_orig_j+zscore2_orig_j)/2
			replace zscore_orig_j = (abs(zscore_orig_j)+abs(zscore2_orig_j))/2 if ((zscore_orig_j>=0 & zscore2_orig_j<0) | (zscore_orig_j<0 & zscore2_orig_j>=0))
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
				gen pval2_i = .
			}
		}
				
		if "`pval2_orig'"!="" {
			gen pval2_orig_j = `pval2_orig'
			drop `pval2_orig'
		}
		else {
			if "`beta2_orig'"!="" {
				if "`df_orig'"=="" { 
					gen pval2_orig_j = 2*(1 - normal(abs(`beta2_orig'/se2_orig_j)))
				}
				if "`df_orig'"!="" {
					gen pval2_orig_j = 2*ttail(`df_orig', abs(`beta2_orig'/se2_orig_j))
				}
			}
			else {
				gen pval2_orig_j = .
			}
		}
		if "`beta2'"!="" {
			gen beta2_i = `beta2'
			drop `beta2'
		}
		else {
			gen beta2_i = .
		}
		if "`beta2_orig'"!="" {
			gen beta2_orig_j = `beta2_orig'
			drop `beta2_orig'
		}
		else {
			gen beta2_orig_j = .
		}

*** Option sensdash
		if (beta2_i!=. | beta2_orig_j!=.) {
			local sensdash = 0
			noi dis "If {opt beta2()} or {opt beta2_orig()} is specified, no Sensitivity Dashboard is prepared."	
		}
	}
 
*** Options vshortref_orig, extended, aggregation, graphfmt, ivF, signfirst
	if "`ivF'"=="" {
		local tFinclude = 0
	}
	if `sensdash'==0 & "`ivF'"!=""  {
		noi dis "{red: The option {opt ivF()} is not meant to be used together with option {opt sensdash(0)}.}"
		use `inputdata', clear
		exit
	}
	if `sensdash'==1 {
		if "`vshortref_orig'"!="" {
			local ytitle_row0 `vshortref_orig'
		}
		else {
			local ytitle_row0 "original estimate"			
		}

		if ("`extended'"!="" & "`extended'"!="0" & "`extended'"!="1") {
			noi dis "{red: If {opt extended} is defined, it needs to take on the value 0 (no) or 1 (yes)}"	
			use `inputdata', clear
			exit
		}
		if "`extended'"=="" {
			local extended = 0
		}
			
		if ("`aggregation'"!="" & "`aggregation'"!="0" & "`aggregation'"!="1") {
			noi dis "{red: If {opt aggregation} is defined, it needs to take on the value 0 (no) or 1 (yes)}"	
			use `inputdata', clear
			exit
		}
		if "`aggregation'"=="" & `studypooling'==0 {
			local aggregation = 0
		}
		if `studypooling'==1 {
			if "`aggregation'"=="0" { 
				noi dis "The option {opt aggregation(0)} is not meant to be used together with the option {opt studypooling(1)}. Use instead the option {opt aggregation(1)} at the study level."	
			}
			local aggregation = 1
		}

		if "`graphfmt'"=="" {
			local graphfmt emf
		}
			
		** tF Standard Error Adjustment presented in Sensitivity Dashboard - based on lookup Table from Lee et al. (2022)
		if "`ivF'"!="" {
			local tFinclude = 1
				
			matrix tF_c05 = (4,4.008,4.015,4.023,4.031,4.04,4.049,4.059,4.068,4.079,4.09,4.101,4.113,4.125,4.138,4.151,4.166,4.18,4.196,4.212,4.229,4.247,4.265,4.285,4.305,4.326,4.349,4.372,4.396,4.422,4.449,4.477,4.507,4.538,4.57,4.604,4.64,4.678,4.717,4.759,4.803,4.849,4.897,4.948,5.002,5.059,5.119,5.182,5.248,5.319,5.393,5.472,5.556,5.644,5.738,5.838,5.944,6.056,6.176,6.304,6.44,6.585,6.741,6.907,7.085,7.276,7482,7.702,7.94,8.196,8.473,8.773,9.098,9.451,9.835,10.253,10.711,11.214,11.766,12.374,13.048,13.796,14.631,15.566,16.618,17.81,19.167,20.721,22.516,24.605,27.058,29.967,33.457,37.699,42.93,49.495,57.902,68.93,83.823,104.68,100000\9.519,9.305,9.095,8.891,8.691,8.495,8.304,8.117,7.934,7.756,7.581,7.411,7.244,7.081,6.922,6.766,6.614,6.465,6.319,6.177,6.038,5.902,5.77,5.64,5.513,5.389,5.268,5.149,5.033,4.92,4.809,4.701,4.595,4.492,4.391,4.292,4.195,4.101,4.009,3.919,3.83,3.744,3.66,3.578,3.497,3.418,3.341,3.266,3.193,3.121,3.051,2.982,2.915,2.849,2.785,2.723,2.661,2.602,2.543,2.486,2.43,2.375,2.322,2.27,2.218,2.169,2.12,2.072,2.025,1.98,1.935,1.892,1.849,1.808,1.767,1.727,1.688,1.65,1.613,1.577,1.542,1.507,1.473,1.44,1.407,1.376,1.345,1.315,1.285,1.256,1.228,1.2,1.173,1.147,1.121,1.096,1.071,1.047,1.024,1,1)
					
			foreach b in lo hi {
				gen IVF_`b' = .
				gen adj_`b' = .
			}
			forval i = 1(1)100 {
				local j = `i'+1
				qui replace IVF_lo = tF_c05[1,`i'] if `ivF' >= tF_c05[1,`i'] & `ivF' < tF_c05[1,`j']
				qui replace IVF_hi = tF_c05[1,`j'] if `ivF' >= tF_c05[1,`i'] & `ivF' < tF_c05[1,`j']
				qui replace adj_hi = tF_c05[2,`i'] if `ivF' >= tF_c05[1,`i'] & `ivF' < tF_c05[1,`j']
				qui replace adj_lo = tF_c05[2,`j'] if `ivF' >= tF_c05[1,`i'] & `ivF' < tF_c05[1,`j']
			}
			local IVF_inf = 4 // to be precise, this value - the threshold where the standard error adjustment factor turn infinite - should be ivF=3.8416, but the matrix from Lee et al. only delivers adjustment values up to 4  ("tends to infinity as F approaches 3.84")
			
			gen     tF_adj = adj_lo + (IVF_hi  - `ivF')/(IVF_hi  - IVF_lo)  * (adj_hi - adj_lo)  //  "tF Standard Error Adjustment value, according to Lee et al. (2022)" 		
			label var tF_adj "tF Standard Error Adjustment value, according to Lee et al. (2022)"						
						
			** tF-adjusted SE and p-val
			gen     se_tF = se_i*tF_adj
								
			gen     pval_tF = 2*(1 - normal(abs(`beta'/se_tF)))
			replace pval_tF = 1 if `ivF'<`IVF_inf' 
			drop IVF_* adj_* tF_adj
		}
		
		** different indicators to be shown in Sensitivity Dashboard depending on whether IV/ tF is included
		if `studypooling'==0 {
			local check_05_osig = 1
		}
		else {
			capture confirm variable RF2_SIGagr_05_osig_ra_all, exact   // check if variable is part of dataset across studies 
    		if !_rc {
				local check_05_osig = 1
			}
			else {
				local check_05_osig = 0
			}
		}
		if `tFinclude'==1 {			
			if `signum_ra'!=5 & `check_05_osig'==1 {
				local RF2_SIGagr_05        			RF2_SIGagr_05        		RF2_SIGagr_05tF
				local RF2_SIGagr_05_j      			RF2_SIGagr_05_j      		RF2_SIGagr_05tF_j
				local RF2_SIGagr_05_osig    		RF2_SIGagr_05_osig 			RF2_SIGagr_05tF_osig
				local RF2_SIGagr_05_osig_ra_all 	RF2_SIGagr_05_osig_ra_all 	RF2_SIGagr_05tF_osig_ra_all
				local RF2_SIGagr_05_onsig_ra_all 	RF2_SIGagr_05_onsig_ra_all 	RF2_SIGagr_05tF_onsig_ra_all
			}
			if `signum_ra'==5 & `check_05_osig'==1 {
				local RF2_SIGagr_05       			RF2_SIGagr_05tF
				local RF2_SIGagr_05_j      			RF2_SIGagr_05tF_j
				local RF2_SIGagr_05_osig    		RF2_SIGagr_05tF_osig
				local RF2_SIGagr_05_osig_ra_all 	RF2_SIGagr_05tF_osig_ra_all
				local RF2_SIGagr_05_onsig_ra_all 	RF2_SIGagr_05tF_onsig_ra_all
			}
		}
		if `tFinclude'!=1 & `signum_ra'!=5 & `check_05_osig'==1 {
			local RF2_SIGagr_05        			RF2_SIGagr_05
			local RF2_SIGagr_05_j      			RF2_SIGagr_05_j
			local RF2_SIGagr_05_osig   			RF2_SIGagr_05_osig
			local RF2_SIGagr_05_osig_ra_all 	RF2_SIGagr_05_osig_ra_all
			local RF2_SIGagr_05_onsig_ra_all 	RF2_SIGagr_05_onsig_ra_all
		}
		if (`tFinclude'!=1 & `signum_ra'==5) | `check_05_osig'==0 {
			local RF2_SIGagr_05        
			local RF2_SIGagr_05_j      
			local RF2_SIGagr_05_osig    
			local RF2_SIGagr_05_osig_ra_all
			local RF2_SIGagr_05_onsig_ra_all
		}
	}



************************************************************
***  PART 2.B  ADDITIONAL VARIABLE GENERATION AND MAIN LOCALS
************************************************************

*** Additional variable generation, e.g. on the effect direction and the relative effect size based on the raw data	
	decode `varlist', gen(mainlist_str)
	egen mainlist = group(`varlist')
	labmask mainlist, values(mainlist_str)
	drop `varlist'
	order mainlist mainlist_str 
	
	if `studypooling'==0 {
		gen beta_rel_i      = `beta'/mean_j*100
		gen se_rel_i        = se_i/mean_j
		
		gen beta_rel_orig_j = beta_orig_j/mean_orig_j*100
		gen se_rel_orig_j   = se_orig_j/mean_orig_j

		gen x_beta_abs_orig_p`sigdigits_ra'_j =  se_orig_j*invnormal(1-0.`sigdigits_ra'/2)
		gen x_se_orig_p`sigdigits_ra'_j       =  abs(beta_orig_j)/invnormal(1-0.`sigdigits_ra'/2)
		foreach var in beta_abs se {
				bysort mainlist: egen `var'_orig_p`sigdigits_ra'_j = min(x_`var'_orig_p`sigdigits_ra'_j)
		}	
	
	
*** Information on share of outcomes with originally sig./ insig. estimates
	// definition of whether orginal results is statistically significant may differ by whether level of stat. sig. from original study (_oa) or rep. analysis (_ra) is applied
	// hence four different locals each for number (`origs'_`set'_out_N) and share (`origs'_`set'_out_share)	
		qui tab mainlist 
		local N_outcomes = `r(r)'
		bysort mainlist: gen x_n_j = _n
		foreach set in oa ra {
		 	 gen x_osig_`set'_d_out    = (pval_orig_j<=0.`sigdigits_`set'') if x_n_j==1    
			 gen x_onsig_`set'_d_out   = (pval_orig_j>0.`sigdigits_`set'')  if x_n_j==1	
			foreach origs in osig onsig {
				egen x_`origs'_`set'_out_N  = total(x_`origs'_`set'_d_out)
				local  `origs'_`set'_out_N  = x_`origs'_`set'_out_N
			}
			local osig_`set'_out_share  "`: display x_osig_`set'_out_N  "`=char(47)'"  `N_outcomes' '"
		}
		
		foreach set in oa ra {
			local onsig_`set'_out_share "`: display x_onsig_`set'_out_N  "`=char(47)'"  `N_outcomes' '"
		}
			
*** Information on the number of analysis paths 
		bysort mainlist: gen x_N_specs_by_outcome = _N
		qui sum x_N_specs_by_outcome
		local N_specs_min = `r(min)'
		local N_specs_max = `r(max)'
		foreach x in min max {				
			egen x_N_outcomes_`x'2 = group(mainlist) if x_N_specs_by_outcome==`N_specs_`x''
			egen x_N_outcomes_`x' = max(x_N_outcomes_`x'2)
			gen x_spec_`x'_outcome = mainlist_str if x_N_specs_by_outcome==`N_specs_`x''
			gsort -x_spec_`x'_outcome
			local spec_`x' = x_spec_`x'_outcome
			if x_N_outcomes_`x'>1 {
				local spec_`x' "multiple outcomes"
			}	
		}
	}
	
	if `studypooling'==1 {
*** Information on share of outcomes/ studies etc for `studypooling'==1, i.e. at the study level
		** studies
		qui tab mainlist 
		local N_studies = `r(r)'
		foreach set in oa ra {
			foreach origs in osig onsig {
				 gen x_`origs'_`set'_d_stud = (`origs'_`set'_out_N>0)   
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

		** outcomes
		bysort mainlist: gen x_n_j = _n
		foreach ovar in outcomes osig_oa_out onsig_oa_out osig_ra_out onsig_ra_out {
			egen x_`ovar'_N2 = total(`ovar'_N) if x_n_j==1
			egen  x_`ovar'_N = min(x_`ovar'_N2)
		}
		local N_outcomes = x_outcomes_N
		foreach set in oa ra {
			foreach origs in osig onsig {
				local `origs'_`set'_out_N   = x_`origs'_`set'_out_N
			}
			local osig_`set'_out_share  "`: display x_osig_`set'_out_N  "`=char(47)'"  `N_outcomes' '"
		}
		
		foreach set in oa ra {	
			local onsig_`set'_out_share  "`: display x_onsig_`set'_out_N  "`=char(47)'"  `N_outcomes' '"
			local onsig_`set'_stud_share "`: display x_onsig_`set'_stud_N  "`=char(47)'"  `N_studies' '"
		}
		qui sum analysispaths_min_N
		local N_specs_min = `r(min)'
		qui sum analysispaths_max_N
		local N_specs_max = `r(max)'
		foreach x in min max {				
			egen x_N_studies_`x'2 = group(mainlist) if analysispaths_`x'_N==`N_specs_`x''
			egen x_N_studies_`x' = max(x_N_studies_`x'2)
			gen x_spec_`x'_study = mainlist_str if analysispaths_`x'_N==`N_specs_`x''
			gsort -x_spec_`x'_study
			local spec_`x' = x_spec_`x'_study
			if x_N_studies_`x'>1 {
				local spec_`x' "multiple studies"
			}
		}
		drop outcomes_N siglevel_ra_stud siglevel_oa_stud osig_oa_out_N onsig_oa_out_N osig_ra_out_N  onsig_ra_out_N   analysispaths_min_N analysispaths_max_N  ivarweight_stud_d  // information transferred to locals
		drop beta beta_orig  // empty variables that were only inputted to be able to run the command	
		drop pval_orig_*   // drop variables not required for the Indicator construction
		capture drop __000000 __000001   // sometimes temporary variables are created by marksample command above
	}
	
	drop x_*
	
	
	


********************************************************************************
*****  PART 3  INDICATOR DEFINITIONS BY OUTCOME AND ACROSS OUTCOMES/ STUDIES
********************************************************************************
	// for verbal description of indicators, see the readme on GitHub

************************************************************
***  PART 3.A  INDICATORS BY OUTCOME
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
	
	local RF2_list_j 			RF2_SIGagr_j `RF2_SIGagr_05_j' RF2_SIGagr_ndir_j  RF2_ESrel_j RF2_ESvar_j  RF2_SIGvar_j RF2_ESagr_j  RF2_SIGsw_btonsig_j RF2_SIGsw_setonsig_j  RF2_SIGagr_sigdef_j  RF2_SIGsw_btosig_j RF2_SIGsw_setosig_j      
	local RF2_list_osig_ra_k	RF2_SIGagr_osig_ra_all  `RF2_SIGagr_05_osig_ra_all'                                  RF2_SIGagr_ndir_osig_ra_all   RF2_ESrel_osig_ra_all RF2_ESvar_osig_ra_all  RF2_SIGvar_osig_ra_all  RF2_ESagr_osig_ra_all  RF2_SIGsw_btonsig_osig_ra_all RF2_SIGsw_setonsig_osig_ra_all 
	local RF2_list_onsig_ra_k	RF2_SIGagr_onsig_ra_all `RF2_SIGagr_05_onsig_ra_all'  RF2_SIGagr_sigdef_onsig_ra_all RF2_SIGagr_ndir_onsig_ra_all  											    RF2_SIGvar_onsig_ra_all		  			       RF2_SIGsw_btosig_onsig_ra_all RF2_SIGsw_setosig_onsig_ra_all 
	local RF2_osig_list_nosfx 	RF2_SIGagr `RF2_SIGagr_05'                    RF2_SIGagr_ndir  RF2_ESrel RF2_ESvar  RF2_SIGvar RF2_ESagr  RF2_SIGsw_btonsig RF2_SIGsw_setonsig 		 	 
	local RF2_onsig_list_nosfx	RF2_SIGagr `RF2_SIGagr_05'  RF2_SIGagr_sigdef RF2_SIGagr_ndir                       RF2_SIGvar            RF2_SIGsw_btosig  RF2_SIGsw_setosig  			 					


	if `studypooling'==0 {
		** 1. Significance agreement
					    gen x_RF_SIGagr_i = (pval_i<=0.`sigdigits_ra' ///
											  & beta_dir_i==beta_orig_dir_j)*100	if pval_orig_j<=0.`sigdigits_oa' & beta2_i==.
					replace x_RF_SIGagr_i = (pval_i>0.`sigdigits_ra')*100			if pval_orig_j>0.`sigdigits_oa'  & beta2_i==.
					   		// if one orig. coefficient and one rep. coefficient & 
							// if two orig. coefficients and one rep. coefficient, rep. coefficient needs to be in the same direction as the first orig. coefficient
					   
					replace x_RF_SIGagr_i = (pval_i<=0.`sigdigits_ra' ///
											  & beta_dir_i==beta_orig_dir_j ///
											  & pval2_i<=0.`sigdigits_ra' ///
											  & beta2_dir_i==beta_orig_dir_j)*100	if pval_orig_j<=0.`sigdigits_oa' & beta2_orig_j==. & beta2_i!=.
						   // if one orig. coefficient and two rep. coefficients and if the orig. results was significant, both rep. coefficients need to be significant in the orig. direction  

					replace x_RF_SIGagr_i = (pval_i<=0.`sigdigits_ra' ///
											  & beta_dir_i==beta_orig_dir_j ///
											  & pval2_i<=0.`sigdigits_ra' ///
											  & beta2_dir_i==beta2_orig_dir_j)*100	if pval_orig_j<=0.`sigdigits_oa' & pval2_orig_j<=0.`sigdigits_oa' & beta2_orig_j!=. & beta2_i!=.
						   // if two orig. coefficient and two rep. coefficients and if both orig. coefficients were significant, both rep. coefficients need to be significant in the orig. directions  

					replace x_RF_SIGagr_i = (pval_i>0.`sigdigits_ra' | (pval2_i>0.`sigdigits_ra' & pval2_i<.))*100	if pval_orig_j>0.`sigdigits_oa' & beta2_orig_j==. & beta2_i!=.  
						   // if one orig. coefficient and two rep. coefficients and if the orig. result was a null result, at least one of the two rep. coefficients need to be insignificant    
					   
					replace x_RF_SIGagr_i = (pval_i>0.`sigdigits_ra' | (pval2_i>0.`sigdigits_ra' & pval2_i<.))*100	if (pval_orig_j>0.`sigdigits_oa' | pval2_orig_j>0.`sigdigits_oa') & beta2_orig_j!=. & beta2_i!=.  
						   // if two orig. coefficients and two rep. coefficients and if at least one of the orig. coefficients was insig., at least one of the two rep. coefficients need to be insignificant 

		bysort mainlist: egen RF_SIGagr_j = mean(x_RF_SIGagr_i) 						  	 
				
			
		** 1+. Significance agreement - alternative indicator set	
			// not for beta2_orig_j==1 | beta2_i==1
						  gen x_RF2_SIGagr_i		= (pval_i<=0.`sigdigits_ra' & beta_dir_i==beta_orig_dir_j)*100 	if beta2_orig_j==. & beta2_i==.
		bysort mainlist: egen   RF2_SIGagr_j    	= mean(x_RF2_SIGagr_i) 

		if `tFinclude'==1 {
						  gen x_RF2_SIGagr_05tF_i	= (pval_tF<0.05 & beta_dir_i==beta_orig_dir_j)*100 				if beta2_orig_j==. & beta2_i==.
		bysort mainlist: egen   RF2_SIGagr_05tF_j 	= mean(x_RF2_SIGagr_05tF_i)	
		}
		if `signum_ra'!=5  {
						  gen x_RF2_SIGagr_05_i		= (pval_i<0.05  & beta_dir_i==beta_orig_dir_j)*100	 			if beta2_orig_j==. & beta2_i==.
		bysort mainlist: egen   RF2_SIGagr_05_j  	= mean(x_RF2_SIGagr_05_i)
		}


		** 1+. Significance agreement (insig. because of less stringent significance definition)
			// not for beta2_orig_j==1 | beta2_i==1
		   	 			  gen x_RF2_SIGagr_sigdef_i = (pval_i>0.`sigdigits_ra' & pval_i<=0.`sigdigits_oa')*100		if pval_orig_j>0.`sigdigits_ra' & beta2_orig_j==. & beta2_i==. & pval_orig_j<0.`sigdigits_oa'
		bysort mainlist: egen   RF2_SIGagr_sigdef_j = mean(x_RF2_SIGagr_sigdef_i)


		** 1+. Significance agreement (opposite direction)
			// not for beta2_orig_j==1 | beta2_i==1
					      gen x_RF2_SIGagr_ndir_i	= (pval_i<=0.`sigdigits_ra' ///
												    & beta_dir_i!=beta_orig_dir_j)*100	if beta2_orig_j==. & beta2_i==.										
		bysort mainlist: egen   RF2_SIGagr_ndir_j	= mean(x_RF2_SIGagr_ndir_i) 


		** 2. Relative effect size 
			// only for original results reported as statistically significant at the 0.`sigdigits_oa' level
			// only for sameunits_i==1 and not for beta2_orig_j==1 | beta2_i==1
		bysort mainlist: egen x_RF_ESrel_j = mean(`beta')   					if (pval_orig_j<=0.`sigdigits_oa') & sameunits_i==1 & beta2_orig_j==. & beta2_i==.
						  gen   RF_ESrel_j = x_RF_ESrel_j/beta_orig_j


		** 2+. Relative effect size - alternative indicator set
				// only for original results reported as statistically significant at the 0.`sigdigits_ra' level
				// + only for analysis paths of reproducability or replicability analyses reported as statistically significant at the 0.`sigdigits_ra' level
				// only for sameunits_i==1 and not for beta2_orig_j==1 | beta2_i==1
		bysort mainlist: egen x_RF2_ESrel_j2 	= median(`beta')	 			if pval_i<=0.`sigdigits_ra' & beta_dir_i==beta_orig_dir_j & pval_orig_j<=0.`sigdigits_ra' & sameunits_i==1 & beta2_orig_j==. & beta2_i==.						
						  gen x_RF2_ESrel_j 	= x_RF2_ESrel_j2/beta_orig_j 
						  gen   RF2_ESrel_j 	= ((x_RF2_ESrel_j) - 1)*100

			   
		** 3. Relative significance
			// only for original results reported as statistically significant at the 0.`sigdigits_oa' level
			// zscore already averaged above for cases where there are two coefficients
						  gen x_RF_SIGrel_i = zscore_i/zscore_orig_j
		bysort mainlist: egen   RF_SIGrel_j = mean(x_RF_SIGrel_i)   			if pval_orig_j<=0.`sigdigits_oa'
		

		// preparation for Variation Indicators 4 and 5: add original estimate as additional observation if included as one analysis path of reproducability or replicability analysis
		if `orig_in_multiverse'==1 {
			bysort mainlist: gen outcome_n = _n
			expand 2 if outcome_n==1, gen(add_orig)

			replace `beta'      = beta_orig_j    if add_orig==1
			replace beta_dir_i = beta_orig_dir_j if add_orig==1
			replace sameunits_i = 1 			 if add_orig==1
			replace pval_i 	    = pval_orig_j 	 if add_orig==1
			replace zscore_i    = zscore_orig_j  if add_orig==1
			
			bysort mainlist: egen x_RF2_ESrel_j3 = median(`beta')	 			if pval_i<=0.`sigdigits_ra' & beta_dir_i==beta_orig_dir_j & pval_orig_j<=0.`sigdigits_ra'  // redo x_RF2_ESrel_j2
			replace x_RF2_ESrel_j2 = x_RF2_ESrel_j3 
			// other *_j variables do not need to be adjusted, as they are already generated by the expand command
		}
		
		
		** 4. Effect sizes variation
			// only for sameunits_i==1 and not for beta2_orig_j==1 | beta2_i==1
		bysort mainlist: egen x_RF_ESvar_j = sd(`beta')							if sameunits_i==1 & beta2_orig_j==. & beta2_i==.
						  gen   RF_ESvar_j = x_RF_ESvar_j/se_orig_j        
		
		
		** A4+. Effect sizes variation - alternative indicator set
			// only for original results reported as statistically significant at the 0.`sigdigits_ra' level
			// + only for analysis paths of reproducability or replicability analyses reported as statistically significant at the 0.`sigdigits_ra' level
			// only for sameunits_i==1 and not for beta2_orig_j==1 | beta2_i==1
						  gen x_RF2_ESvar_i = abs(`beta'-x_RF2_ESrel_j2) 	    	
		bysort mainlist: egen x_RF2_ESvar_j = mean(x_RF2_ESvar_i)     			if pval_i<=0.`sigdigits_ra' & beta_dir_i==beta_orig_dir_j & pval_orig_j<=0.`sigdigits_ra' & sameunits_i==1 & beta2_orig_j==. & beta2_i==.
						  gen   RF2_ESvar_j = (x_RF2_ESvar_j/abs(beta_orig_j))*100
		
		
		** 5. Significance variation
			// zscore already averaged above for cases where there are two coefficients
		bysort mainlist: egen   RF_SIGvar_j = sd(zscore_i)	

		
		** A5+. Significance variation - alternative indicator set
			// not for beta2_orig_j==1 | beta2_i==1
						  gen x_RF2_SIGvar_i  = abs(pval_i-pval_orig_j)			if pval_i>0.`sigdigits_ra' &  beta2_orig_j==. & beta2_i==.
		bysort mainlist: egen   RF2_SIGvar_j  = mean(x_RF2_SIGvar_i)
		
		
		if `orig_in_multiverse'==1 {
			drop if add_orig==1  // better remove these added observations before collapsing as they have incomplete information
			drop outcome_n add_orig
		}
		

		** A6+. Effect size agreement - alternative indicator set
			// only for sameunits_i==1 and not for beta2_orig_j==1 | beta2_i==1
		if `signum_ra'==5 {
			gen x_critval = 1.96
		}
		if `signum_ra'==10 {
			gen x_critval = 1.645
		}
		gen x_RF2_ESagr_ci_up_`signum_ra' = beta_orig_j + x_critval*se_orig_j   
		gen x_RF2_ESagr_ci_lo_`signum_ra' = beta_orig_j - x_critval*se_orig_j

		                  gen x_RF2_ESagr_i  = (`beta'>=x_RF2_ESagr_ci_lo_`signum_ra' & `beta'<=x_RF2_ESagr_ci_up_`signum_ra')  if sameunits_i==1 & beta2_orig_j==. & beta2_i==.
		bysort mainlist: egen   RF2_ESagr_j  = mean(x_RF2_ESagr_i)     		if pval_i>0.`sigdigits_ra'
		               replace  RF2_ESagr_j  = RF2_ESagr_j*100


		** A7+. Significance switch - alternative indicator set
			// not for beta2_orig_j==1 | beta2_i==1	
						   gen  x_RF2_SIGsw_btonsig_i = (abs(`beta')<=beta_abs_orig_p`sigdigits_ra'_j)*100	if pval_i>0.`sigdigits_ra' & beta2_orig_j==. & beta2_i==.	// multiples of 0.1 cannot be held exactly in binary in Stata -> shares converted to range from 1/100, not from 0.01 to 1.00
						   gen x_RF2_SIGsw_setonsig_i = (se_i>=se_orig_p`sigdigits_ra'_j)*100				if pval_i>0.`sigdigits_ra' & beta2_orig_j==. & beta2_i==.
		bysort mainlist: egen    RF2_SIGsw_btonsig_j = mean(x_RF2_SIGsw_btonsig_i)
		bysort mainlist: egen   RF2_SIGsw_setonsig_j = mean(x_RF2_SIGsw_setonsig_i)
				
						   gen  x_RF2_SIGsw_btosig_i = (abs(`beta')>beta_abs_orig_p`sigdigits_ra'_j)*100	if beta_dir_i==beta_orig_dir_j & pval_i<=0.`sigdigits_ra' & beta2_orig_j==. & beta2_i==.
						   gen x_RF2_SIGsw_setosig_i = (se_i<se_orig_p`sigdigits_ra'_j)*100					if beta_dir_i==beta_orig_dir_j & pval_i<=0.`sigdigits_ra' & beta2_orig_j==. & beta2_i==.
		bysort mainlist: egen    RF2_SIGsw_btosig_j = mean(x_RF2_SIGsw_btosig_i)
		bysort mainlist: egen   RF2_SIGsw_setosig_j = mean(x_RF2_SIGsw_setosig_i)


		local collapselast  RF2_SIGsw_setosig_j
		
		
		** shelved indicators					  
		if `shelvedind'==1 {
								   gen x_RF_robratio_A_i = (`beta'-beta_orig_j)^2 		if sameunits_i==1 & beta2_orig_j==. & beta2_i==.
								   gen x_RF_robratio_B_i = (zscore_i-zscore_orig_j)^2   if                  beta2_orig_j==. & beta2_i==.   	
			
			
			foreach approach in A B {
				bysort mainlist: egen x_RF_robratio_`approach'_j  = mean(x_RF_robratio_`approach'_i) 
			}
								   gen RF_robratio_A_j = sqrt(x_RF_robratio_A_j)/se_orig_j
								   gen RF_robratio_B_j = sqrt(x_RF_robratio_B_j)
			
			bysort mainlist: egen x_RF_pooledH_A_j1 	= mean(`beta')					if beta2_orig_j==. & beta2_i==.
			bysort mainlist: egen x_RF_pooledH_A_j2 	= mean(se_i^2)					if beta2_orig_j==. & beta2_i==. 
							  gen    RF_pooledH_A_j 	= x_RF_pooledH_A_j1/sqrt(x_RF_pooledH_A_j2)
						   replace   RF_pooledH_A_j 	= -1*RF_pooledH_A_j 			if beta_orig_dir_j==-1	
			
			bysort mainlist: egen    RF_pooledH_B_j 	= mean(zscore_i)			 	if beta2_orig_j==. & beta2_i==.
						   replace   RF_pooledH_B_j 	= -1*RF_pooledH_B_j  			if beta_orig_dir_j==-1
								   
			local collapselast  RF_pooledH_B_j 
		}
				
		
		** Weights for inverse-variance weighting 
		if `ivarweight'==1 {
			bysort mainlist: egen x_se_rel_mean_j = mean(se_rel_i)	
							   gen        weight_j = 1/(x_se_rel_mean_j^2)

							   gen    weight_orig_j = 1/(se_rel_orig_j^2)
							   
			local collapselast weight_orig_j
		}
	

*** Collapse indicator values to one observation per outcome
		drop x_* 
		ds RF_SIGagr_j - `collapselast'   
		foreach var in `r(varlist)' {
			bysort mainlist: egen c`var' = min(`var') 
			drop `var'
			rename c`var' `var'
		}
		
		bysort mainlist: gen n_j = _n
		
		keep if n_j==1
		drop n_j  `beta' se_i pval_i beta_dir_i beta_rel_i se_rel_i zscore_i  `df'  beta2_i pval2_i beta2_dir_i   beta2_dir_i  pval2_i  sameunits_i // drop information at a different level than the aggregated level
		drop      se_orig_j   mean_j mean_orig_j se_rel_orig_j zscore_orig_j `df_orig' beta2_orig_j  beta2_orig_dir_j  pval2_orig_j					// drop information not required anymore 
		capture drop beta_abs_orig_p`sigdigits_ra'_j se_orig_p`sigdigits_ra'_j
		capture drop se2_i se2_orig_j zscore2_i zscore2_orig_j
		capture drop `ivF' se_tF pval_tF
	}	

	if `studypooling'==1 {	

		preserve
			drop mainlist RF2_*
			rename *_oa_all *

			tempfile data_pooled_k			// data with k being the unit of observation = the study when pooling across studies
			save `data_pooled_k'
		restore

		order mainlist mainlist_str `RF_list_osig_oa_k' `RF2_list_osig_ra_k' RF2_SIGagr_sigdef_onsig_ra_all RF2_SIGsw_btosig_onsig_ra_all RF2_SIGsw_setosig_onsig_ra_all 

		rename *_osig_oa_all  *1
		rename *_onsig_oa_all *2
		rename *_osig_ra_all  *3
		rename *_onsig_ra_all *4
		
		
		reshape long `RF_list_nosfx' `RF2_osig_list_nosfx' RF2_SIGagr_sigdef RF2_SIGsw_btosig RF2_SIGsw_setosig, i(mainlist) j(level)
		
		** if pooled across studies, the reference for statistical significance differs between oa and rep
		gen     pval_orig_oa = 0.`sigdigits_oa' - 0.01 if level==1 		// originally sig outcomes have pval below 0.`sigdigits_oa' -> used to distinguish indicators below
		replace pval_orig_oa = 0.`sigdigits_oa' + 0.01 if level==2
		gen     pval_orig_ra = 0.`sigdigits_ra' - 0.01 if level==3 		
		replace pval_orig_ra = 0.`sigdigits_ra' + 0.01 if level==4
		drop level
		
		ds mainlist mainlist_str, not 
		foreach var in `r(varlist)' {
			rename `var' `var'_j		// now _j stands for study
		}		
		
		order  mainlist mainlist_str `RF_list_j' `RF2_list_j'			
	}
				


************************************************************
***  PART 3.B  INDICATORS ACROSS ALL OUTCOMES/ STUDIES
************************************************************
	
*** Indicator Set RF
	if `studypooling'==1 {
		gen pval_orig_j = pval_orig_oa_j	//   if pooled across studies, first set pval_orig_j to pval_orig_oa_j, before setting it to pval_orig_ra_j under the second Indicator Set, and then setting it to missing
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
		
	** original indicator sig, revised indicator sig at `sigdigits_ra'% level
	foreach o_inds of local RF2_osig_list_nosfx {
		if `ivarweight'==0 {
			egen `o_inds'_osig_ra_all  = mean(`o_inds'_j) 									if pval_orig_j<=0.`sigdigits_ra'
		}
		if `ivarweight'==1 {				
			egen `o_inds'_osig_ra_all  = total(`o_inds'_j*weight_j/x_total_osig_weight)   	if pval_orig_j<=0.`sigdigits_ra'
		}
	}			
		
	** original indicator insig, revised indicator sig at `sigdigits_ra'% level
	foreach o_indn of local RF2_onsig_list_nosfx {
		if `ivarweight'==0 {
			egen `o_indn'_onsig_ra_all = mean(`o_indn'_j) 									if pval_orig_j>0.`sigdigits_ra'
		}
		if `ivarweight'==1 {		
			egen `o_indn'_onsig_ra_all = total(`o_indn'_j*weight_j/x_total_onsig_weight) 	if pval_orig_j>0.`sigdigits_ra'
		}
	}
		
	** any original indicator sig level, revised indicator sig at `sigdigits_ra'% level
	if `ivarweight'==0 {
		egen rany_osig_ra_all = mean(pval_orig_j<=0.`sigdigits_ra')
	}
	if `ivarweight'==1 {
		gen  x_rany_osig_j  = (pval_orig_j<=0.`sigdigits_ra')
		egen   rany_osig_ra_all = total(x_rany_osig_j*weight_j/x_total_weight)	

		drop x_*
	}

	if `studypooling'==1 {
		drop pval_orig_j pval_orig_osig_* pval_orig_onsig_*	   
	}


*** Copy information to all outcomes/ studies
	ds RF_*_all RF2_*_all
	foreach var in `r(varlist)' {
		egen c`var'0 = min(`var')
		egen c`var'1 = max(`var')
		if c`var'0!=c`var'1 {
			noi dis "{red: Error in the calculation of indicators across outcomes or studies. Please reach out to the contact person of the {it:repframe} command}"				
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
		order mainlist mainlist_str beta_orig_j beta_rel_orig_j pval_orig_j  `RF_list_j' `RF2_list_j'  pval_orig_osig_oa_all `RF_list_osig_oa_k'  pval_orig_onsig_oa_all `RF_list_onsig_oa_k'  `RF2_list_osig_ra_k'  `RF2_list_onsig_ra_k'  rany_*
	
		local label_j 				", by outcome"
		local label_osig_oa_all  	", across outcomes (originally significant wrt OA sig. level)"
		local label_onsig_oa_all 	", across outcomes (originally insignificant wrt OA sig. level)"
		
		local label_osig_ra_all  ", across outcomes (originally significant wrt REP sig. level)"
		local label_onsig_ra_all ", across outcomes (originally insignificant wrt REP sig. level)"

		label var mainlist 					"Outcome"
		label var mainlist_str				"Outcome, in string format" 
		capture label var beta_orig_j 		"Original beta estimate" 												
		capture label var beta_rel_orig_j  	"Original beta estimate, expressed as % deviation from original mean of the outcome"
	}
	else {
		order mainlist mainlist_str pval_orig_oa_j pval_orig_ra_j  			 `RF_list_j' `RF2_list_j'  						 `RF_list_osig_oa_k'                         `RF_list_onsig_oa_k'  `RF2_list_osig_ra_k'  `RF2_list_onsig_ra_k'  rany_*	

		local label_j 				", by study"
		local label_osig_oa_all  	", across studies (originally significant wrt OA sig. level)"
		local label_onsig_oa_all 	", across studies (originally insignificant wrt OA sig. level)"
		
		local label_osig_ra_all  ", across studies (originally significant wrt REP sig. level)"
		local label_onsig_ra_all ", across studies (originally insignificant wrt REP sig. level)"

		label var mainlist 					"Study reference"
		label var mainlist_str				"Study reference, in string format" 
	}
	

	foreach unit in j osig_oa_all onsig_oa_all {
		capture label var pval_orig_`unit'	"p-value of original estimate`label_`unit''" 
		label var RF_SIGagr_`unit' 	"(RF.1) Significance agreement`label_`unit''"
		label var RF_ESrel_`unit'	"(RF.2) Relative effect size`label_`unit''"	
		label var RF_SIGrel_`unit' 	"(RF.3) Relative significance`label_`unit''"
		label var RF_ESvar_`unit' 	"(RF.4) Effect sizes variation`label_`unit''"
		label var RF_SIGvar_`unit' 	"(RF.5) Significance variation`label_`unit''"
		if `shelvedind'==1 { 
			label var RF_robratio_A_`unit' 	"(B1a) Robustness - sqrt of mean squared beta deviation divided by original s.e." 
			label var RF_robratio_B_`unit' 	"(B1b) Robustness - sqrt of mean squared t/z-value deviation" 						
			label var RF_pooledH_A_`unit' 	"(B2a) Pooled hypothesis test - z-statistic based on beta and se (inverse sign for negative original results)" 
			label var RF_pooledH_B_`unit' 	"(B2b) Pooled hypothesis test - z-statistic based on t/z-score (inverse sign for negative original results)" 
		}
	}	

	foreach unit in j osig_ra_all {
		label var RF2_SIGagr_`unit' 		"(RF2.1) Significance agreement`label_`unit''"
		label var RF2_SIGagr_ndir_`unit' 	"(RF2.2) Significance agreement`label_`unit''"
		label var RF2_ESrel_`unit' 			"(RF2.3) Relative effect size`label_`unit''"
		label var RF2_ESvar_`unit'			"(RF2.4) Effct size variation`label_`unit''"
		label var RF2_SIGvar_`unit' 		"(RF2.5) Significance Variation`label_`unit''"
		label var RF2_ESagr_`unit'			"(RF2.6) Effect size agreement`label_`unit''"
		label var RF2_SIGsw_btonsig_`unit'  "(RF2.7a) Significance switch (beta)`label_`unit''"	
		label var RF2_SIGsw_setonsig_`unit' "(RF2.7b) Significance switch (se)`label_`unit''"	

	}
	foreach unit in j onsig_ra_all {
		label var RF2_SIGagr_`unit' 		"(RF2.1) Significance agreement`label_`unit''"
		label var RF2_SIGagr_sigdef_`unit'	"(RF2.1+) Significance agreement (insig. because of less stringent OA sig. definition)`label_`unit''"
		label var RF2_SIGagr_ndir_`unit' 	"(RF2.2) Significance agreement`label_`unit''"
		label var RF2_SIGvar_`unit' 		"(RF2.5) Significance Variation`label_`unit''"
		label var RF2_SIGsw_btosig_`unit'	"(RF2.7a) Significance switch (beta)`label_`unit''"
		label var RF2_SIGsw_setosig_`unit'	"(RF2.7b) Significance switch (se)`label_`unit''"
	}

	if `signum_ra'!=5 {
		foreach unit in j osig_ra_all onsig_ra_all {
			label var RF2_SIGagr_05_`unit'	"(RF2.1b) Significance agreement (5% level)`label_`unit''"
		}
	}
	if `tFinclude'==1 {
		foreach unit in j osig_ra_all onsig_ra_all {
			label var RF2_SIGagr_05tF_`unit' "(RF2.1c) Significance agreement (5% tF level)`label_`unit''"
		}
	}
	
	label var rany_osig_ra_all			"Any rep. analysis is significant wrt REP sig. level`label_osig_ra_all'" 


*** Save temp dataset
	tempfile data_j			// data with j being the unit of observation
	save `data_j'
  

*** Create dataset at study level
  	if `studypooling'==0 {
		keep *_all 
		drop rany_osig_ra_all
		duplicates drop
	
		gen outcomes_N = `N_outcomes'
		label var outcomes_N  "Number of outcomes studied"
		
		foreach set in oa ra {
			foreach origs in osig onsig {
				gen    `origs'_`set'_out_N =  ``origs'_`set'_out_N'					
			}
			label var osig_`set'_out_N   "Number of outcomes in original study with stat. significant estimate according to sig. level of `set' analysis"
			label var onsig_`set'_out_N  "Number of outcomes in original study with stat. insignificant estimate according to sig. level of `set' analysis"
		}

		gen siglevel_oa_stud = `signum_oa'
		label var siglevel_oa_stud  "Significance level of two-sided test applied to original study / by original author(s)"
		gen siglevel_ra_stud = `signum_ra'
		label var siglevel_ra_stud  "Significance level of two-sided test applied in reproducability or replicability analyses of study"
		
		gen ivarweight_stud_d = `ivarweight'
		label var ivarweight_stud_d "Outcomes in study weighted by the inverse variance"
		label def dummy 0 "no" 1 "yes"
		label val ivarweight_stud_d dummy 

		gen analysispaths_min_N = `N_specs_min'
		gen analysispaths_max_N = `N_specs_max'
		label var analysispaths_min_N  "Minimum number of analysis paths studied (across outcomes)"
		label var analysispaths_max_N  "Maximum number of analysis paths studied (across outcomes)"
			
		gen ref = "`shortref'"
		label var ref "Study reference"

		order ref outcomes_N  siglevel_ra_stud siglevel_oa_stud osig_oa_out_N pval_orig_osig_oa_all `RF_list_osig_oa_k'  onsig_oa_out_N pval_orig_onsig_oa_all `RF_list_onsig_oa_k'  osig_ra_out_N `RF2_list_osig_ra_k'  onsig_ra_out_N `RF2_list_onsig_ra_k' ivarweight_stud_d

		save "`filepath'/reproframe_data_`fileidentifier'.dta", replace
	}





********************************************************************************
*****  PART 5  SENSITIVITY DASHBOARD VISUALIZATION 
********************************************************************************
	
************************************************************
***  PART 5.A  PREPARE DASHBOARD GRAPH DATA
************************************************************

	if `sensdash'==1 {
		use `data_j'
		if `studypooling'==0 {
			keep mainlist mainlist_str beta_orig_j beta_rel_orig_j pval_orig_j RF2_* rany* 
		}
		else {
			rename pval_orig_ra_j pval_orig_j
			keep mainlist mainlist_str pval_orig_j RF2_* rany*
		}

*** Prepare data structure and y- and x-axis
		if `signum_ra'!=999 { 
			local siglab 	{it:p}{&ge}0.`sigdigits_ra'
		}
		else {
			local siglab 	varying sig. levels		// `signum_ra'==999 can effectively only occur for `studypooling'==1 
		}

		** create local indicating number of outcomes/ studies with estimates falling into category of insig rep. analyses only because of more stringent sig. level definition in rep. analysis than in orig. analysis
		egen x_notes_sigdef = total(RF2_SIGagr_sigdef_j!=.)
		local notes_sigdef_N = x_notes_sigdef 
		drop x_notes_sigdef

		if `aggregation'==1 {
			keep if inlist(mainlist,1)       	// keep one observation across outcomes/ studies
			drop mainlist mainlist_str *_j		// drop variables at outcome/ study level 
			if `studypooling'==0 {
				local ylab 1 `" "significant" " " "{sup:`osig_ra_out_share' outcomes}" "'      										2 `" "insignificant" "(`siglab')" " " "{sup:`onsig_ra_out_share' outcomes}" "'	// first y entry shows up at bottom of y-axis of the dashboard
			}
			else {
				local ylab 1 `" "significant" " " "{sup:`osig_ra_out_share' outcomes in}" "{sup:`osig_ra_stud_share' studies}" "' 	2 `" "insignificant" "(`siglab')" " " "{sup:`onsig_ra_out_share' outcomes in}" "{sup:`onsig_ra_stud_share' studies}" "'	
				duplicates drop
			}
			expand 2
			gen sensd_y = _n
			local yset_n = 2 
		}
		else { 
			sort mainlist
			rename mainlist sensd_y
			local yset_n = `N_outcomes'			// # of items shown on y-axis = # of outcomes
			
			** reverse order of outcome numbering as outcomes are presented in reverse order on the y-axis of the dashboard
			tostring sensd_y, replace
			labmask sensd_y, values(mainlist_str) lblname(ylab)	
			
			if `N_outcomes'==2 | `N_outcomes'==3 {
				recode sensd_y (1=`N_outcomes') (`N_outcomes'=1)
				local ylab `"   `=sensd_y[1]' "`=mainlist_str[1]'" `=sensd_y[2]' "`=mainlist_str[2]'"  "'
			}
			if `N_outcomes'==3 {
				local ylab `"   `=sensd_y[1]' "`=mainlist_str[1]'" `=sensd_y[2]' "`=mainlist_str[2]'" `=sensd_y[3]' "`=mainlist_str[3]'" "'
			}	
			if `N_outcomes'==4 {
				recode sensd_y (1=4) (4=1) (2=3) (3=2)
				local ylab `"   `=sensd_y[1]' "`=mainlist_str[1]'" `=sensd_y[2]' "`=mainlist_str[2]'" `=sensd_y[3]' "`=mainlist_str[3]'" `=sensd_y[4]' "`=mainlist_str[4]'"  "'
			}
			if `N_outcomes'==5 {
				recode sensd_y (1=5) (5=1) (2=4) (4=2)
				local ylab `"   `=sensd_y[1]' "`=mainlist_str[1]'" `=sensd_y[2]' "`=mainlist_str[2]'" `=sensd_y[3]' "`=mainlist_str[3]'" `=sensd_y[4]' "`=mainlist_str[4]'" `=sensd_y[5]' "`=mainlist_str[5]'"  "'
			}
			
			if `N_outcomes'>5 {
				noi dis "{red: Please use option -repframe, [...] aggregation(1)- with more than five outcomes to be displayed}"				
				use `inputdata', clear
				exit
			}									
			drop mainlist_str
		}
		
		local xset  insig  sig_ndir  sig_dir
		local xlab 1 `" "insignificant" "(`siglab')" "' 2 `" "significant," "opposite sign" "' 3 `" "significant," "same sign" "'
		local xset_n : word count `xset'
		
		expand `xset_n'
		bysort sensd_y: gen sensd_x = _n
		
		
		** labelling of y-axis 
		if `aggregation'==1 {
			local aux `" "Original" "results" "'
			local ytitle  ytitle(`aux', orient(horizontal))
		}
		else {
			local ytitle ytitle("") // empty local, no ytitle to show up
		}
		

*** Calculate main shares presented in Sensitivity Dashboard
		if `aggregation'==1 {
			// in order to calculate the shares in ALL original results [and not differentiated by originally sig or insig] multiply x_share_2x and `styper'_onsig_ra_all by (1 - rany_osig_ra_all) and x_share_1x and `styper'_osig_ra_all by rany_osig_ra_all
			gen x_share_21 =  100 - RF2_SIGagr_onsig_ra_all - RF2_SIGagr_ndir_onsig_ra_all	if sensd_y==2 & sensd_x==1	// top left     (insig orig & insig rev)            = (100 - sig rev)
			gen x_share_22 =                               	  RF2_SIGagr_ndir_onsig_ra_all	if sensd_y==2 & sensd_x==2	// top middle   (insig orig & sig   rev, diff sign) =        sig rev not dir
			gen x_share_23 =        RF2_SIGagr_onsig_ra_all					 				if sensd_y==2 & sensd_x==3	// top right    (insig orig & sig   rev, same sign) =        sig rev     dir
			
			gen x_share_11 =  100 - RF2_SIGagr_osig_ra_all - RF2_SIGagr_ndir_osig_ra_all	if sensd_y==1 & sensd_x==1  // bottom left   (sig & insig)			 	=   (100 - sig rev)
			gen x_share_12 =                                 RF2_SIGagr_ndir_osig_ra_all  	if sensd_y==1 & sensd_x==2	// bottom middle (sig & sig, diff sign)		=   (100 - sig rev not dir)
			gen x_share_13 =        RF2_SIGagr_osig_ra_all 			     			  		if sensd_y==1 & sensd_x==3	// bottom right  (sig & sig, same sign)		=	(100 - sig rev     dir)
			
			for num 1/3: replace x_share_1X  = 0 											if sensd_y==1 & sensd_x==X & rany_osig_ra_all==0 & x_share_1X==.			// replace missing by zero if none of the original estimates was sig
			for num 1/3: replace x_share_2X  = 0 											if sensd_y==2 & sensd_x==X & rany_osig_ra_all==1 & x_share_2X==.   		// replace missing by zero if all of the original estimates were sig								
			 
			foreach styper in `RF2_SIGagr_05' {
				replace `styper'_onsig_ra_all 	= `styper'_onsig_ra_all  // top right  (insig orig & sig rev)
				replace `styper'_osig_ra_all   = `styper'_osig_ra_all    // bottom right (sig orig & sig rev)
			}
			gen share2_11 = . 
			gen share2_21 =    RF2_SIGagr_sigdef_onsig_ra_all  							if sensd_y==2 & sensd_x==1 // !=. if original authors adopted different sig. level than rep. analysis
		}		
		else {
			for num 1/`yset_n': gen x_share_X1 = 100 - RF2_SIGagr_j - RF2_SIGagr_ndir_j	if sensd_y==X	& sensd_x==1	// insig outcome X
			for num 1/`yset_n': gen x_share_X2 =                      RF2_SIGagr_ndir_j if sensd_y==X	& sensd_x==2	//   sig outcome X, not dir
			for num 1/`yset_n': gen x_share_X3 =       RF2_SIGagr_j  					if sensd_y==X	& sensd_x==3	//   sig outcome X, same dir
		
			// create variables with indicator information availabe in all observations
			foreach var in beta_orig_j beta_rel_orig_j pval_orig_j  `RF2_list_j'  {
				for num 1/`yset_n': gen   x_`var'X = `var' if sensd_y==X
				for num 1/`yset_n': egen    `var'X = mean(x_`var'X)	
			}
			for num 1/`yset_n': gen share2_X1 =	RF2_SIGagr_sigdef_j           			if sensd_y==X & sensd_x==1	
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
		}
		
		** create single variables share, x_sharerounder, and share2 from share_*, x_sharerounder_*, and share2_*
		foreach shvar3 in share x_sharerounder share2 {		
						    	gen     `shvar3' = .
			for num 1/`yset_n': replace `shvar3' = `shvar3'_X1 if sensd_y==X & sensd_x==1
		}
		foreach shvar2 in share x_sharerounder {		
			for num 1/`yset_n': replace `shvar2' = `shvar2'_X2 if sensd_y==X & sensd_x==2
			for num 1/`yset_n': replace `shvar2' = `shvar2'_X3 if sensd_y==X & sensd_x==3
		}		
		
		                    gen     share_roundingdiff = 100-(share_11 + share_12 + share_13) if sensd_y==1
		for num 2/`yset_n': replace share_roundingdiff = 100-(share_X1 + share_X2 + share_X3) if sensd_y==X
		for num 1/`yset_n': replace share_roundingdiff = 0 if sensd_y==X & (share_X1 + share_X2 + share_X3 == 0)   // no rounding if entire row is zero, which may happen with -aggregation(1)- if none of the studied outcomes/ studies has (in)sig orig. estimates.
		
		** sum of shares exceeds 100%
		bysort sensd_y: egen sharerounder = rank(x_sharerounder) if x_sharerounder>=0.5 & share_roundingdiff<0, unique
		replace share     = share  - 1 if sharerounder<=abs(share_roundingdiff)    // the X shares with the lowest digits are reduced in cases where the sum of shares is 10X
		replace share2    = share2 - 1 if sharerounder<=abs(share_roundingdiff) & share2!=. & share2!=0
		drop sharerounder

		** sum of shares falls below 100% 
		bysort sensd_y: egen sharerounder = rank(x_sharerounder) if x_sharerounder<0.5 & share_roundingdiff>0, field
		replace share     = share  + 1 if sharerounder<=share_roundingdiff		// the X shares with the highest digits are increased in cases where the sum of shares is 100 - X
		replace share2    = share2 + 1 if sharerounder<=abs(share_roundingdiff) & share2!=.
		
		** recreate variables with indicator information availabe in all observations for RF2_SIGagr_sigdef_j (after share2 has been properly rounded)
		if `aggregation'==0 {	
			drop x_RF2_SIGagr_sigdef_j*	RF2_SIGagr_sigdef_j*	
			for num 1/`yset_n': gen   x_RF2_SIGagr_sigdef_jX = share2 if sensd_y==X & sensd_x==1	
			for num 1/`yset_n': egen    RF2_SIGagr_sigdef_jX = mean(x_RF2_SIGagr_sigdef_jX)	
		}

		** ... now also for RF2_SIGagr_sigdef_onsig_ra_all
		else {
			gen x_RF2_SIGagr_sigdef_onsig_ra_all = share2 if sensd_y==2 & sensd_x==1
			drop  RF2_SIGagr_sigdef_onsig_ra_all   // replace by rounded indicator
			egen  RF2_SIGagr_sigdef_onsig_ra_all = mean(x_RF2_SIGagr_sigdef_onsig_ra_all)	
		}

		** separate share_size variable as basis for the size fo circles in the dashboard given that share_size may differ from share if original authors applied different sig. level than rep. analysis
		gen     share_size = share
		replace share_size = share - share2 if share2!=.

		drop x_* share_roundingdiff share2 share2_*
		capture drop sharerounder

		gen     share2_size = share   // size of larger circle corresponds to share 


*** Further rounding of indicators for presentation in the dashboard 
		if `aggregation'==0 {			
			foreach rI in  beta_rel_orig_j   RF2_ESagr_j    `RF2_SIGagr_j' 		   `RF2_SIGagr_05_j'      RF2_ESrel_j 	 RF2_ESvar_j {
				for num 1/`yset_n': replace `rI'X = round(`rI'X)
			}
		}
		else {			
			foreach rI in                    RF2_ESagr_osig `RF2_SIGagr_05_osig'   `RF2_SIGagr_05_onsig'  RF2_ESrel_osig RF2_ESvar_osig {
				replace   `rI'_ra_all = round(`rI'_ra_all)		
			}
		}

		
			  
************************************************************
***  PART 5.B  PREPARE PLOTTING OF DASHBOARD GRAPH DATA
************************************************************
	  
*** Colouring of circles: lighter colour if non-confirmatory revised result, darker colour if confirmatory revised result
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
		
		gen     colorname_nonconfirm = "`r(`col')'*`col_lowint'"		// definition of colour used for non-confirmatory and confirmatory results - required for legend to dashboard graph
		gen     colorname_confirm    = "`r(`col')'*`col_highint'"
		
		gen     colorname     = colorname_nonconfirm
		gen     colorname_not = colorname_confirm		// required for overlapping two circles when original authors defined stat. significance differently from the rep. analysis
		if `aggregation'==0 {
			forval m = 1/`yset_n' {
				replace colorname     = colorname_confirm     if sensd_y==`m' & sensd_x==3 & pval_orig_j`m'<=0.`sigdigits_ra'
				replace colorname     = colorname_confirm     if sensd_y==`m' & sensd_x==1 & pval_orig_j`m'>0.`sigdigits_ra'

				replace colorname_not = colorname_nonconfirm  if sensd_y==`m' & sensd_x==1 & pval_orig_j`m'>0.`sigdigits_ra'
			}
		}
		else {
			replace colorname     = colorname_confirm     if (sensd_y==2 & sensd_x==1) | (sensd_y==1 & sensd_x==3)
			replace colorname_not = colorname_nonconfirm  if (sensd_y==2 & sensd_x==1)
		}
	

*** Saving the plotting codes in locals
		local slist ""
		forval i = 1/`=_N' {
			local slist "`slist' (scatteri `=sensd_y[`i']' `=sensd_x[`i']'                                     , mlabposition(0) mlabsize(medsmall) msize(`=share2_size[`i']*0.5*(0.75^(`yset_n'-2))') mcolor("`=colorname_not[`i']'"))"     // first add second circle for different stat. sig. definitions adopted by original authors and in rep. analysis, respectively
			local slist "`slist' (scatteri `=sensd_y[`i']' `=sensd_x[`i']' "`: display %3.0f =share[`i'] "%" '", mlabposition(0) mlabsize(medsmall) msize(`=share_size[`i']*0.5*(0.75^(`yset_n'-2))')  mcolor("`=colorname[`i']'"))"     // msize defines the size of the circles
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
				local case_n `m'
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

				if beta_rel_orig_j==. {
					local y`m'x0		`" "`: display "{it:`ytitle_row0'}" '"	"`: display "{&beta}{sup:o}: " %3.2f beta_orig_j`m'[1]'"   													"`: display "{it:p}{sup:o}: " %3.2f pval_orig_j`m'[1]'" "'
				}
				else {
					local y`m'x0		`" "`: display "{it:`ytitle_row0'}" '"	"`: display "{&beta}{sup:o}: " %3.2f beta_orig_j`m'[1] " [`sign_d_orig`m''" beta_rel_orig_j`m' "%]" '"   	"`: display "{it:p}{sup:o}: " %3.2f pval_orig_j`m'[1]'" "'
				}
			}

			** fill dashboard matrix, with originally significant [R=s] (insignificant [R=n]) rows and columns C=1, ..., n of the dashboard identified by cond_RC
			if `cond_n1' {
				if RF2_SIGagr_sigdef_`sfx_n'!=. {  
					local y`case_n'x1	`"  "`: display "{it:p}<{&alpha}{sup:o}: " `=RF2_SIGagr_sigdef_`sfx_n'' "%" '"	"`: display "`=ustrunescape("\u0394\u0305\u0070")': " %3.2f RF2_SIGvar_`sfx_n''"  "'
				}
				else {
					local y`case_n'x1  	`"  	 																	    "`: display "`=ustrunescape("\u0394\u0305\u0070")': " %3.2f RF2_SIGvar_`sfx_n''"  "'
				}							
			}
			if `cond_n3' {
				if `tFinclude'!=1 {
					if `signum_ra'!=5  {
							local y`case_n'x3	`" "`: display "{it:p}<0.05: "  `=RF2_SIGagr_05_`sfx_n'' "%" '"  "'
						if `extended'==1 {
							local y`case_n'x3	`" "`: display "{it:p}<0.05: "  `=RF2_SIGagr_05_`sfx_n'' "%" '"                                             	"`: display "high |{&beta}|: " %3.0f RF2_SIGsw_btosig_`sfx_n' "%" '"   "`: display "low se: " %3.0f RF2_SIGsw_setosig_`sfx_n' "%" '" "'
						}
					}
					if `signum_ra'==5  {
						// empty
						if `extended'==1 {
							local y`case_n'x3  	`"        																										"`: display "high |{&beta}|: " %3.0f RF2_SIGsw_btosig_`sfx_n' "%" '"    "`: display "low se: " %3.0f RF2_SIGsw_setosig_`sfx_n' "%" '"  "'			
						}
					}
				}
				if `tFinclude'==1 {
					if `signum_ra'!=5 {
							local y`case_n'x3	`" "`: display "{it:p}<0.05: "  `=RF2_SIGagr_05_`sfx_n'' "% ({it:tF}: "  `=RF2_SIGagr_05tF_`sfx_n'' "%)" '" "'
						if `extended'==1 { 
							local y`case_n'x3	`" "`: display "{it:p}<0.05: "  `=RF2_SIGagr_05_`sfx_n'' "% ({it:tF}: "  `=RF2_SIGagr_05tF_`sfx_n'' "%)" '"   	"`: display "high |{&beta}|: " %3.0f RF2_SIGsw_btosig_`sfx_n' "%" '"   "`: display "low se: " %3.0f RF2_SIGsw_setosig_`sfx_n' "%" '" "'	
						}
					}
					if `signum_ra'==5 {
							local y`case_n'x3	`" "`: display                              "{it:tF}-adjusted {it:p}: "  `=RF2_SIGagr_05tF_`sfx_n'' "%" '" "'
						if `extended'==1 {
							local y`case_n'x3	`" "`: display                              "{it:tF}-adjusted {it:p}: "  `=RF2_SIGagr_05tF_`sfx_n'' "%" '"		"`: display "high |{&beta}|: " %3.0f RF2_SIGsw_btosig_`sfx_n' "%" '"   "`: display "low se: " %3.0f RF2_SIGsw_setosig_`sfx_n' "%" '" "'	 
						}
					}
				}
			}

			if `cond_s1' {
					local y`case_s'x1 	`" "`: display "{&beta} in CI({&beta}{sup:o}): "  `=RF2_ESagr_`sfx_s'' "%" '"   "`: display "`=ustrunescape("\u0394\u0305\u0070")': " %3.2f RF2_SIGvar_`sfx_s''"  "'
				if `extended'==1 {
					local y`case_s'x1 	`" "`: display "{&beta} in CI({&beta}{sup:o}): "  `=RF2_ESagr_`sfx_s'' "%" '"   "`: display "`=ustrunescape("\u0394\u0305\u0070")': " %3.2f RF2_SIGvar_`sfx_s''"    "`: display "low |{&beta}|: " %3.0f RF2_SIGsw_btonsig_`sfx_s' "%" '"   "`: display "high se: " %3.0f RF2_SIGsw_setonsig_`sfx_s' "%" '" "' 
				}
			}
			if `cond_s3' {
				if `tFinclude'==1 {
					if `signum_ra'!=5 {
						local y`case_s'x3	`" "`: display "{it:p}<0.05: "  `=RF2_SIGagr_05_`sfx_s'' "% ({it:tF}: "  `=RF2_SIGagr_05tF_`sfx_s'' "%)" '"  	"`: display "`=ustrunescape("\u03B2\u0303")': `sign_d_sig`m''" RF2_ESrel_`sfx_s' "% (`=ustrunescape("\u0394\u0305\u03B2\u0303")': " RF2_ESvar_`sfx_s' "%)" '"  "'
					}
					if `signum_ra'==5 {
						local y`case_s'x3	`" "`: display                              "{it:tF}-adjusted {it:p}: "  `=RF2_SIGagr_05tF_`sfx_s'' "%" '"  	"`: display "`=ustrunescape("\u03B2\u0303")': `sign_d_sig`m''" RF2_ESrel_`sfx_s' "% (`=ustrunescape("\u0394\u0305\u03B2\u0303")': " RF2_ESvar_`sfx_s' "%)" '"  "'
					}
				}
				if `tFinclude'!=1 {
					if `signum_ra'!=5 {
						local y`case_s'x3	`" "`: display "{it:p}<0.05: "  `=RF2_SIGagr_05_`sfx_s'' "%" '"                                              	"`: display "`=ustrunescape("\u03B2\u0303")': `sign_d_sig`m''" RF2_ESrel_`sfx_s' "% (`=ustrunescape("\u0394\u0305\u03B2\u0303")': " RF2_ESvar_`sfx_s' "%)" '"  "'
					}
					if `signum_ra'==5 {
						local y`case_s'x3	`" 																												"`: display "`=ustrunescape("\u03B2\u0303")': `sign_d_sig`m''" RF2_ESrel_`sfx_s' "% (`=ustrunescape("\u0394\u0305\u03B2\u0303")': " RF2_ESvar_`sfx_s' "%)" '"  "'
					}
				}
			}	
		}	


*** Specifying location of indicators in dashboard depending on the number of outcomes/ y-axis entries presented
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
		forval m = 1/`yset_n' {
			local t_col0  "`t_col0'  text(`m'                        0.2 `y`m'x0', size(`tsize'))"  
			local t_col1  "`t_col1'  text(`=`m'-0.2-(`yset_n'-2)*0.05' 1 `y`m'x1', size(`tsize'))"
			local t_col3  "`t_col3'  text(`=`m'-0.2-(`yset_n'-2)*0.05' 3 `y`m'x3', size(`tsize'))"
		}
		
		local yupper = 2.5 + (`yset_n'-2)*0.9
		

			
************************************************************
***  PART 5.C  PLOTTING OF THE DASHBOARD
************************************************************

		twoway (scatteri `=sensd_y[0]' `=sensd_x[0]', mcolor("`=colorname_confirm[1]'")) (scatteri `=sensd_y[0]' `=sensd_x[0]', mcolor("`=colorname_nonconfirm[1]'")) ///
			`slist', ///
			`ytitle' xtitle("Robustness results") ///
			xscale(range(`xleft' 3.5) /*alt*/) yscale(range(0.5 `yupper')) ///
			xlabel(`xlab', labsize(2.5)) ylabel(`ylab', labsize(2.5)) ///
			`t_col0' `t_col0b' `t_col1' `t_col3'  ///
			legend(rows(1) order(1 "confirmatory robustness results" 2 "non-confirmatory robustness results") size(2.5) position(6) bmargin(tiny))  ///
			graphregion(color(white)) scheme(white_tableau)  
				// first line of this twoway command does not show up in the dashboard but is required to make the legend show up with the correct colours 
			
		graph export "`filepath'/reproframe_sensdash_`fileidentifier'.`graphfmt'", replace

	
			
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
			local notes_spec 	based on `N_specs' `specs'
			if `N_outcomes'>1 &  `N_specs_min'==`N_specs_max' {
				local notes_spec 	based on `N_specs' `specs' for each of the `N_outcomes' outcomes
			}
			local notes_sigdef
		}
		else {
			local notes_spec 	based on `N_outcomes' outcomes with `N_specs' `specs' each
			local notes_sigdef
			if `studypooling'==0 {
				local notes_shares_shown 	shares of analysis paths
				if `signum_oa'>`signum_ra' { 
					local notes_sigdef 			- `notes_sigdef_N' of the outcomes with estimates that are stat. insig. in rep. analyses only because more stringent stat. sig. level is appplied in rep. analysis than in original analysis  
				}
				if `signum_oa'<`signum_ra' { 
					local notes_sigdef 			- part of the outcomes with estimates that are stat. sig. in rep. analyses may only be so because less stringent stat. sig. level is appplied in rep. analysis than in original analysis  
				}
			}
			else {
				local notes_shares_shown 	mean shares of analysis paths across studies
				if `notes_sigdef_N'>0 {
					local notes_sigdef 			- `notes_sigdef_N' of the studies with estimates that are stat. insig. in rep. analyses only because more stringent stat. sig. level is appplied in rep. analysis than in original analysis  
				}
			}
		}	
		if  `N_specs_min'!=`N_specs_max' {
			local N_specs "`N_specs_min' (`spec_min') to `N_specs_max' (`spec_max')"
			local notes_spec 	based on `N_outcomes' outcomes with `N_specs' `specs'
		}


*** Display figure note
		noi dis _newline(1)	"Sensitivity Dashboard shows `notes_shares_shown' - `notes_spec' `notes_sigdef'"
		noi dis _newline(1)	"`=ustrunescape("\u03B2")' = beta coefficient"
		noi dis				"`=ustrunescape("\u03B2\u0303")' = median beta coefficient of reproducability or replicability analysis, measured as % deviation from original beta coefficient; generally, tildes indicate median values"
		noi dis 			"CI = confidence interval"
		noi dis             "{it:p} = {it:p}-value (default relies on two-sided test assuming an approximately normal distribution)" 
		noi dis				"{it:X}`=ustrunescape("\u0366")' = parameter {it:X} from original study {it:o}" 
		if `notes_sigdef_N'>0 { 
			noi dis 			"`=ustrunescape("\u03B1")' = significance level"
		}
		noi dis 			"`=ustrunescape("\u0394\u0305")' = mean absolute deviation"
		if `aggregation'==0 {
			if beta_rel_orig_j!=. {
				noi dis 		"[+/-xx%] = Percentage in squared brackets refers to the original beta coefficient, expressed as % deviation from original mean of the outcome"
			}
		}    
		if `extended'==1 {
			noi dis 	   		   "low |`=ustrunescape("\u03B2")'| (high se) refers to the share of analysis paths of the reproducability or replicability analysis where the revised absolute value of the beta coefficient (standard error) is sufficiently low (high) to turn the overall estimate insignificant at the `signum_ra'% level, keeping the standard error (beta coefficient) constant"
			noi dis    "Conversely, high |`=ustrunescape("\u03B2")'| (low se) refers to the share of analysis paths of the reproducability or replicability analysis where the revised absolute value of the beta coefficient (standard error) is sufficiently high (low) to turn the overall estimate significant at the `signum_ra'% level, keeping the standard error (beta coefficient) constant"   
		}
		if `tFinclude'==1 {
			noi dis  		"{it:tF} indicates the share of statistically significant estimates in the reproducability or replicability analysis at the {it:tF}-adjusted 5% level, using the {it:tF} adjustment proposed by Lee et al. (2022, AER)"
		}
	}
	


	
	
********************************************************************************
***  PART 6  COMPILE REPRODUCIBILITY AND REPLICABILITY INDICATORS 
********************************************************************************
	
************************************************************
***  PART 6.A  PREPARE INDICATOR TABLE DATA
************************************************************

	use `data_j', clear
	capture drop `signfirst'
	drop RF2_* rany_*

	if `studypooling'==0 {
		foreach b in beta beta_rel {	 
			gen    `b'_orig_osig_oa_all = .
			gen    `b'_orig_onsig_oa_all = .
		}
	}


	preserve
		keep mainlist *_all
		
		if `studypooling'==0 {
			rename *_osig_oa_all  *2
			rename *_onsig_oa_all *5
			
			reshape long `RF_list_nosfx' pval_orig beta_orig beta_rel_orig, i(mainlist) j(panel)
			
			drop mainlist 
			gen     mainlist_str = "All outcomes (originally sig.)"   if panel==2
			replace mainlist_str = "All outcomes (originally insig.)" if panel==5
		}
		else {
			rename *_oa_all  *

			drop mainlist
			gen mainlist_str = "All studies" 
			gen panel = 4
		}

		duplicates drop
		tempfile RF_all_long
		save `RF_all_long'
	restore


	if `studypooling'==0 {
		drop mainlist *_all
		rename *_j *
		
		gen     panel = 1 if pval_orig<=0.`sigdigits_oa'
		replace panel = 4 if pval_orig>0.`sigdigits_oa'

		label var mainlist_str "Outcome"

		local roundtozerodigits  beta_rel_orig RF_SIGagr
		if `shelvedind'==1 {
			local roundtozerodigits   `roundtozerodigits'   RF_pooledH_A  RF_pooledH_B
		}
	}
	else {
		use `data_pooled_k', clear

		gen     panel = 1
		
		label var mainlist_str "Study reference"

		local roundtozerodigits  RF_SIGagr_osig RF_SIGagr_onsig 
		if `shelvedind'==1 {
			local roundtozerodigits   `roundtozerodigits'   RF_pooledH_A_osig RF_pooledH_A_onsig  RF_pooledH_B_osig RF_pooledH_B_onsig 
		}
	}

	set obs `=_N+1'
	replace panel = 3 								if mainlist_str==""
	replace mainlist_str = "__________________" 	if mainlist_str==""
	sort mainlist_str
	gen list_n = _n



************************************************************
***  PART 6.B  COMPILING REPRODUCIBILITY AND REPLICATION FRAMEWORK INDICATOR RESULTS 
************************************************************

	append using `RF_all_long'
	sort panel list_n
	drop panel list_n 
	set obs `=_N+1'
	replace mainlist_str = "__________________" 	if mainlist_str==""


	** rounding of shares and other variables 
	foreach var0 of local roundtozerodigits {
	    replace `var0'  = round(`var0')
	}
	
	ds mainlist_str `roundtozerodigits', not
	foreach var2 in `r(varlist)' {
	    replace `var2'  = round(`var2', .01)
	}


	** create gap between originally sig. and originally insig. indicators
	if `studypooling'==1 {
		gen     gap = "|"   
		replace gap = "__________________" 	if mainlist_str == "__________________"
		label var gap "|"
		order gap, before(RF_SIGagr_onsig)
	}


	** add notes 
	set obs `=_N+1'   // backward-compatible alternative to insobs 1 in order to add an observation at bottom of dataset to include notes
	replace mainlist_str = "Notes:" if mainlist_str==""
	set obs `=_N+1'
	if `studypooling'==0 {
		if "`siglevel_orig'"!="" {
			local osignote "applying original authors' sig. level (`signum_oa'% level)"
		}
		if "`siglevel_orig'"=="" & `signum_oa'==`signum_ra' { 
			local osignote "applying sig. level (`signum_oa'% level) as defined in rep. analysis"
		}
		replace mainlist_str = "`osig_oa_out_share' outcomes originally significant `osignote'" if mainlist_str==""
		
		if `ivarweight'==1 {
			set obs `=_N+1'
			replace mainlist_str = "Indicators across outcomes are derived by weighting individual outcomes in inverse proportion to their variance" if mainlist_str==""
		}

		local ind_level out
	}
	else {
		replace mainlist_str = "`osig_oa_out_share' outcomes originally significant" if mainlist_str==""

		foreach olevel in 05 10 {
			foreach rlevel in 05 10 {
				if `siglevel_o`olevel'_r`rlevel'_N'>0 {
					set obs `=_N+1'
					replace mainlist_str = "`siglevel_o`olevel'_r`rlevel'_N' of the studies with `olevel'% sig. level applied to original estimates and `rlevel'% sig. level applied to rep. analyses" if mainlist_str=="" 
				}
			}
		}

		set obs `=_N+1'
		replace mainlist_str = "In `ivarweight_stud_N' of the studies, indicators across outcomes are derived by weighting individual outcomes in inverse proportion to their variance" if mainlist_str==""
	
		local ind_level stud
	}

	set obs `=_N+1'
	replace mainlist_str = "repframe `repframe_vs'" if mainlist_str==""
	

	export excel "`filepath'/reproframe_indicators_`ind_level'_`fileidentifier'.csv", firstrow(varlabels) replace

	use `inputdata', clear
}	
end
*** End of file