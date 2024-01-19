/*
*** PURPOSE:	
	This Stata do-file contains the program repframe to produce Reproducibility and Replicability Indicators and Sensitivity Dashboards based on multiverse analyses.
	repframe requires version 12.0 of Stata or newer.

	
*** OUTLINE:	PART 1.  INITIATE PROGRAM REPFRAME
			
				PART 2.  AUXILIARY VARIABLE GENERATION

				PART 3.  INDICATOR DEFINITIONS BY OUTCOME
				
				PART 4.  SENSITIVITY DASHBOARD VISUALIZATION
				
				PART 5.  COMPILE REPRODUCIBILITY AND REPLICABILITY INDICATORS

					
***  AUTHOR:	Gunther Bensch, RWI - Leibniz Institute for Economic Research, gunther.bensch@rwi-essen.de
*/	




********************************************************************************
*****  PART 1  INITIATE PROGRAM REPFRAME
********************************************************************************


cap prog drop repframe
prog def repframe, sortpreserve


#delimit ;
	
syntax varlist(numeric max=1) [if] [in], 
beta(varname numeric) beta_orig(varname numeric)   
[se(varname numeric) se_orig(varname numeric)] [pval(varname numeric) pval_orig(varname numeric) zscore(varname numeric) zscore_orig(varname numeric)] 
[siglevel(numlist max=1 integer)]  [df(varname numeric) df_orig(varname numeric)] [mean(varname numeric)] [mean_orig(varname numeric)] 
[orig_in_multiverse(numlist max=1 integer)] [ivarweight(numlist max=1 integer)] 
[outputtable(string)] [sameunits(varname numeric)] [shelvedind(numlist max=1 integer)]  
[beta2(varname numeric) beta2_orig(varname numeric)]  [se2(varname numeric) se2_orig(varname numeric)]  [pval2(varname numeric) pval2_orig(varname numeric)]  [zscore2(varname numeric) zscore2_orig(varname numeric)]
[sensd(numlist max=1 integer)] [outputgraph(string)] [shorttitle_orig(string)] [extended(numlist max=1 integer)] [aggregation(numlist max=1 integer)] [ivF(varname numeric)]  [signfirst(varname numeric)];

#delimit cr


qui {
	
	tempfile inputdata   // instead of preserve given that different datasets will be used for the table of Indicators and for the Sensitivity Dashboard
	save `inputdata'
	
	if "`sensd'"=="" {
		local sensd = 1
	} 
	if `sensd'==1 {
	
	*** Install packages from SSC
		capture which colrspace.sthlp 
		if _rc == 111 {                 
			noi dis "Installing colrspace"
			ssc install colrspace, replace
		}
		capture which labmask
		if _rc == 111 {                 
			noi dis "Installing labutil"
			ssc install labutil, replace
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
	
*** implement [if] and [in] condition
	marksample to_use
	keep if `to_use' == 1
  
*** keep required variables
	keep `varlist' `beta' `beta_orig'   `se' `se_orig' `pval' `pval_orig' `zscore' `zscore_orig'   `df' `df_orig' `mean' `mean_orig'   `sameunits'   `beta2' `beta2_orig' `se2' `se2_orig' `pval2' `pval2_orig' `zscore2' `zscore2_orig'  `ivF' `signfirst' 
	
		
	
	
********************************************************************************
*****  PART 2  AUXILIARY VARIABLE GENERATION
********************************************************************************			

*** add _j suffix to beta_orig (and below to se_orig etc) to make explicit that this is information at the outcome level 
		// the suffix _j refers to the outcome level, _i to the level of individual analysis paths
	gen beta_orig_j = `beta_orig'
	drop `beta_orig'
	
*** direction of effect, required, among others, for the two-coefficient case
	gen beta_dir_i      = (`beta'>=0)
	recode beta_dir_i (0 = -1)
	if "`beta2'"!="" {
		gen beta2_dir_i     = (`beta2'>=0)
		recode beta2_dir_i (0 = -1)
	}
	gen beta_orig_dir_j = (beta_orig_j>=0)
	recode beta_orig_dir_j (0 = -1)
	if "`beta2_orig'"!="" {
		gen beta2_orig_dir_j     = (`beta2_orig'>=0)
		recode beta2_orig_dir_j (0 = -1)
	}
	
	
*** semi-optional syntax components
	if (("`se'"=="" & "`se_orig'"!="") | ("`se'"!="" & "`se_orig'"=="")) | (("`pval'"=="" & "`pval_orig'"!="") | ("`pval'"!="" & "`pval_orig'"=="")) | (("`zscore'"=="" & "`zscore_orig'"!="") | ("`zscore'"!="" & "`zscore_orig'"=="")) {
		noi dis "{red: Please specify both {it:se()} and {it:se_orig()} and/or both {it:pval()} and {it:pval_orig()} and/or both {it:zscore()} and {it:zscore_orig()}, but not only one of them, respectively}"	
		use `inputdata', clear
		exit
	}

	if "`se'"=="" & "`zscore'"=="" & "`df'"=="" {
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
	
	
*** optional syntax components
	if "`siglevel'"=="" {
		local siglevel 5
	}
	if "`siglevel'"!="" {
		local siglevelnum = "`siglevel'"
		
		if `siglevelnum'<10 {
			local sigdigits 0`siglevel'
		}
		if `siglevelnum'>=10 {
			local sigdigits `siglevel'
		}
		if `siglevelnum'<0 | `siglevelnum'>100 {
			noi dis "{red: Please specify a significance level ({it:siglevel}) between 0 and 100}"
			use `inputdata', clear
			exit
		}
	}
	
	if "`mean'"=="" {
		gen mean_j = .
	}
	else {
	    gen mean_j = `mean'
		drop `mean'
	}
	if "`mean_orig'"=="" {
		gen mean_orig_j = mean_j
	}
	else {
	    gen mean_orig_j = `mean_orig'
		drop `mean_orig'
	}

	
	if ("`orig_in_multiverse'"!="" & "`orig_in_multiverse'"!="0" & "`orig_in_multiverse'"!="1") {
		noi dis "{red: If {it:orig_in_multiverse} is defined, it needs to take on the value 0 (no) or 1 (yes)}"	
		use `inputdata', clear
		exit
	}
	if "`orig_in_multiverse'"=="" {
		local orig_in_multiverse = 0
	}
	
	if ("`ivarweight'"!="" & "`ivarweight'"!="0" & "`ivarweight'"!="1") {
		noi dis "{red: If {it:ivarweight} is defined, it needs to take on the value 0 (no) or 1 (yes)}"	
		use `inputdata', clear
		exit
	}
	if "`ivarweight'"=="" {
		local ivarweight = 0
	}
	if `ivarweight'==1 & (mean_j==. | mean_orig_j==.) {
		noi dis "{red: The option {it:ivarweight(1)} requires that the options {it:mean(varname)} and {it:mean_orig(varname)} are also defined}"
		use `inputdata', clear
		exit
	}

	
	** optional syntax components related to the Indicator output table only
	if "`outputtable'"=="" {
		if c(os)=="Windows" {
			local outputtable "C:/Users/`c(username)'/Downloads/reproframe_indicators.csv" 
		}
		else {
			local outputtable "~/Downloads/reproframe_indicators.csv"
		}
	}
	
	if "`sameunits'"=="" {
		gen sameunits_i = 1
	}
	else {
		gen sameunits_i = `sameunits'
		drop `sameunits'
	}
	
	if ("`shelvedind'"!="" & "`shelvedind'"!="0" & "`shelvedind'"!="1") {
		noi dis "{red: If {it:shelvedind} is defined, it needs to take on the value 0 (no) or 1 (yes)}"	
		use `inputdata', clear
		exit
	}
	if "`shelvedind'"=="" {
		local shelvedind = 0
	}
	
	** optional syntax components related to cases with second estimates
	if ("`beta2'"!="" & ("`se2'"=="" & "`pval2'"=="" & "`zscore2'"=="")) {
		noi dis "{red: If {it:beta2()} is specified, please also specify either {it:se2()}, {it:pval2()}, or {it:zscore2()}.}"	
		use `inputdata', clear
		exit
	}
	if ("`beta2_orig'"!="" & ("`se2_orig'"=="" & "`pval2_orig'"=="" & "`zscore2_orig'"=="")) {
		noi dis "{red: If {it:beta2_orig()} is specified, please also specify either {it:se2_orig()}, {it:pval2_orig()}, or {it:zscore2_orig()}.}"	
		use `inputdata', clear
		exit
	}	

	
	if "`se2'"=="" & "`zscore2'"=="" & "`df'"=="" & "`beta2'"!="" & "`pval2'"!="" {
		gen     se2_i   	= abs(`beta2'/invnormal(`pval2'/2))	
	}
	if "`se2'"=="" & "`zscore2'"=="" & "`df'"!="" & "`beta2'"!="" & "`pval2'"!="" {
		gen     se2_i   	= abs(`beta2'/invt(`df', `pval2'/2))
	}
	if "`se2'"=="" & "`zscore2'"!="" {
		gen     se2_i   	= `beta2'/`zscore2'			
	}
	if "`se2'"!="" {
		gen se2_i        =  `se2'	
		drop `se2'
	}	
	if "`zscore2'"=="" & "`beta2'"!="" {
		gen zscore2_i        = `beta2'/se2_i
		
		replace zscore_i  = zscore_i*-1  if beta_orig_dir_j==-1 // if two coefficients in a reproducability or replicability analysis, t/z-value for each must be assigned a positive (negative) sign if coefficient is in the same (opposite) direction as the original coefficient (assumes that there is only one original coefficient)
		replace zscore2_i = zscore2_i*-1 if beta_orig_dir_j==-1
		
		replace zscore_i = (zscore_i+zscore2_i)/2  // if two coefficients in a reproducability or replicability analysis, zscore should be calculated as average of two zscores		
	}
	if "`zscore2'"!="" & "`beta2'"!="" {
		gen zscore2_i        = `zscore2'
		drop `zscore2'
		
		replace zscore_i  = zscore_i*-1  if beta_orig_dir_j==-1 
		replace zscore2_i = zscore2_i*-1 if beta_orig_dir_j==-1
		
		replace zscore_i = (zscore_i+zscore2_i)/2
	}	
	
	if "`se2_orig'"=="" & "`zscore2_orig'"=="" & "`df_orig'"=="" & "`beta2_orig'"!="" & "`pval2_orig'"!="" {
		gen     se2_orig_j   = abs(`beta2_orig'/invnormal(`pval2_orig'/2))	
	}
	if "`se2_orig'"=="" & "`zscore2_orig'"=="" & "`df_orig'"!="" & "`beta2_orig'"!="" & "`pval2_orig'"!="" {
		gen     se2_orig_j   = abs(`beta2_orig'/invt(`df_orig', `pval2_orig'/2)) 	
	}	
	if "`se2_orig'"=="" & "`zscore2_orig'"!="" {
		gen     se2_orig_j  	= `beta2_orig'/`zscore2_orig'	
	}
	if "`se2_orig'"!="" {
		gen     se2_orig_j   =  `se2_orig'	
		drop `se2_orig'
	}
	if "`zscore2_orig'"=="" & "`beta2_orig'"!="" {
		gen zscore2_orig_j   = `beta2_orig'/se2_orig_j
		
		replace zscore_orig_j = (zscore_orig_j+zscore2_orig_j)/2
		replace zscore_orig_j = (abs(zscore_orig_j)+abs(zscore2_orig_j))/2 if ((zscore_orig_j>=0 & zscore2_orig_j<0) | (zscore_orig_j<0 & zscore2_orig_j>=0))  // if one original coefficient is positive and one negative, the two original t/z-values must both be assigned positive signs
	}
	if "`zscore2_orig'"!="" & "`beta2_orig'"!="" {
		gen zscore2_orig_j   = `zscore2_orig'
		drop `zscore2_orig'
		
		replace zscore_orig_j = (zscore_orig_j+zscore2_orig_j)/2
		replace zscore_orig_j = (abs(zscore_orig_j)+abs(zscore2_orig_j))/2 if ((zscore_orig_j>=0 & zscore2_orig_j<0) | (zscore_orig_j<0 & zscore2_orig_j>=0))
	}
	
	if "`pval2'"=="" & "`df'"=="" & "`beta2'"!="" {
		gen pval2_i = 2*(1 - normal(abs(`beta2'/se2_i)))
	}
	if "`pval'"=="" & "`df'"!=""  & "`beta2'"!="" {	
		gen pval2_i = 2*ttail(`df', abs(`beta2'/se2_i))
	}
	if "`pval2'"!="" {
		gen pval2_i = `pval2'
		drop `pval2'
	}
	if "`pval2_orig'"=="" & "`df_orig'"=="" & "`beta2_orig'"!="" {
		gen pval2_orig_j = 2*(1 - normal(abs(`beta2_orig'/se2_orig_j)))
	}
	if "`pval2_orig'"=="" & "`df_orig'"!="" & "`beta2_orig'"!="" {
		gen pval2_orig_j = 2*ttail(`df_orig', abs(`beta2_orig'/se2_orig_j))
	}
	if "`pval2_orig'"!="" {
		gen pval2_orig_j = `pval2_orig'
		drop `pval2_orig'
	}
	
	
	** optional syntax components related to the Sensitivity Dashboard only
	if ("`beta2'"!="" | "`beta2_orig'"!="") {
		local sensd = 0
		noi dis "If {it:beta2()} or {it:beta2_orig()} is specified, no Sensitivity Dashboard is prepared."	
	}
			
	if `sensd'==1 {
		if "`outputgraph'"=="" {
			if c(os)=="Windows" {
				local outputgraph "C:/Users/`c(username)'/Downloads/sensitivity_dashboard.emf" 
			}
			else {
				local outputgraph "~/Downloads/sensitivity_dashboard.emf"
			}
		}
	
		if "`extended'"=="" {
			local extended = 0
		}
		
		if "`aggregation'"=="" {
			local aggregation = 0
		}
		
		** tF Standard Error Adjustment presented in Sensitivity Dashboard - based on lookup Table from Lee et al. (2022)
		if "`ivF'"!="" {
			global tFinclude  1
			
			matrix tF_c05 = (4,4.008,4.015,4.023,4.031,4.04,4.049,4.059,4.068,4.079,4.09,4.101,4.113,4.125,4.138,4.151,4.166,4.18,4.196,4.212,4.229,4.247,4.265,4.285,4.305,4.326,4.349,4.372,4.396,4.422,4.449,4.477,4.507,4.538,4.57,4.604,4.64,4.678,4.717,4.759,4.803,4.849,4.897,4.948,5.002,5.059,5.119,5.182,5.248,5.319,5.393,5.472,5.556,5.644,5.738,5.838,5.944,6.056,6.176,6.304,6.44,6.585,6.741,6.907,7.085,7.276,7482,7.702,7.94,8.196,8.473,8.773,9.098,9.451,9.835,10.253,10.711,11.214,11.766,12.374,13.048,13.796,14.631,15.566,16.618,17.81,19.167,20.721,22.516,24.605,27.058,29.967,33.457,37.699,42.93,49.495,57.902,68.93,83.823,104.68,100000\9.519,9.305,9.095,8.891,8.691,8.495,8.304,8.117,7.934,7.756,7.581,7.411,7.244,7.081,6.922,6.766,6.614,6.465,6.319,6.177,6.038,5.902,5.77,5.64,5.513,5.389,5.268,5.149,5.033,4.92,4.809,4.701,4.595,4.492,4.391,4.292,4.195,4.101,4.009,3.919,3.83,3.744,3.66,3.578,3.497,3.418,3.341,3.266,3.193,3.121,3.051,2.982,2.915,2.849,2.785,2.723,2.661,2.602,2.543,2.486,2.43,2.375,2.322,2.27,2.218,2.169,2.12,2.072,2.025,1.98,1.935,1.892,1.849,1.808,1.767,1.727,1.688,1.65,1.613,1.577,1.542,1.507,1.473,1.44,1.407,1.376,1.345,1.315,1.285,1.256,1.228,1.2,1.173,1.147,1.121,1.096,1.071,1.047,1.024,1,1)
				
			foreach b in lo hi {
				gen IVF_`b' = .
				gen adj_`b' = .
			}
			forvalues i = 1(1)100 {
				local j = `i'+1
				qui replace IVF_lo = tF_c05[1,`i'] if `ivF' >= tF_c05[1,`i'] & `ivF' < tF_c05[1,`j']
				qui replace IVF_hi = tF_c05[1,`j'] if `ivF' >= tF_c05[1,`i'] & `ivF' < tF_c05[1,`j']
				qui replace adj_hi = tF_c05[2,`i'] if `ivF' >= tF_c05[1,`i'] & `ivF' < tF_c05[1,`j']
				qui replace adj_lo = tF_c05[2,`j'] if `ivF' >= tF_c05[1,`i'] & `ivF' < tF_c05[1,`j']
			}
			local IVF_inf = 4 // to be precise, this value - the threshold where the standard error adjustment factor turn infinite - should be ivF=3.8416, but the matrix from Lee et al. only delivers adjustment values up to 4  ("tends to infinity as F approaches 3.84")
		
			gen     tF_adj = adj_lo + (IVF_hi  - `ivF')/(IVF_hi  - IVF_lo)  * (adj_hi - adj_lo)  //  "tF Standard Error Adjustment value, according to Lee et al. (2022)" 
				
			label var tF_adj "tF Standard Error Adjustment value, according to Lee et al. (2022)"
			drop IVF_* adj_* 						
					
					
			** tF-adjusted SE and p-val
			gen     se_tF = se_i*tF_adj
							
			gen     pval_tF = 2*(1 - normal(abs(`beta'/se_tF)))
			replace pval_tF = 1 if `ivF'<`IVF_inf' 
		}
		** different indicators to be shown in Sensitivity Dashboard depending on whether IV/ tF is included
		if "$tFinclude"=="1" {
			if `siglevelnum'!=5 {
				local sig05dir        sig05dir        sig05tFdir
				local sig05dir_j      sig05dir_j      sig05tFdir_j
				local sig05dir_`sigdigits'o    sig05dir_`sigdigits'o    sig05tFdir_`sigdigits'o
				local sig05dir_insigo sig05dir_insigo sig05tFdir_insigo
			}
			if `siglevelnum'==5 {
				local sig05dir        sig05tFdir
				local sig05dir_j      sig05tFdir_j
				local sig05dir_`sigdigits'o    sig05tFdir_`sigdigits'o
				local sig05dir_insigo sig05tFdir_insigo
			}
		}
		if "$tFinclude"!="1" {
			if `siglevelnum'!=5 {
				local sig05dir        sig05dir
				local sig05dir_j      sig05dir_j
				local sig05dir_`sigdigits'o    sig05dir_`sigdigits'o
				local sig05dir_insigo sig05dir_insigo
			}
			if `siglevelnum'==5 {
				local sig05dir        
				local sig05dir_j      
				local sig05dir_`sigdigits'o    
				local sig05dir_insigo 
			}
		}
	}
	if "`ivF'"=="" {
		global tFinclude  0
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
	capture gen pval2_i = .
	capture gen beta2_dir_i = .

	
*** additional variable generation, e.g. on the effect direction and the relative effect size based on the raw dataset	
	gen beta_rel_i       = `beta'/mean_j*100
	gen se_rel_i          = se_i/mean_j
	
	gen beta_rel_orig_j = beta_orig_j/mean_orig_j*100
	gen se_rel_orig_j   = se_orig_j/mean_orig_j

	if `sensd'==1 {	
		gen x_beta_abs_orig_p`sigdigits'_j =  se_orig_j*invnormal(1-0.`sigdigits'/2)
		gen x_se_orig_p`sigdigits'_j       =  abs(beta_orig_j)/invnormal(1-0.`sigdigits'/2)
		foreach var in beta_abs se {
			bysort `varlist': egen `var'_orig_p`sigdigits'_j = min(x_`var'_orig_p`sigdigits'_j)
		}	
	}
	
	
*** information on share of outcomes with originally sig./ insig. estimates	
	qui tab `varlist' 
	local N_outcomes = `r(r)'
	bysort `varlist': gen x_n_j = _n
	gen x_pval_osig_d_j = (pval_orig_j<0.`sigdigits') if x_n_j==1
	egen x_pval_osig_d  = total(x_pval_osig_d_j)    
	gen x_pval_onsig_d_j = (pval_orig_j>=0.`sigdigits') if x_n_j==1
	egen x_pval_onsig_d  = total(x_pval_onsig_d_j)
	local osig_N  = x_pval_osig_d
	local onsig_N = x_pval_onsig_d
	local shareosig  "`: display x_pval_osig_d  "`=char(47)'"  `N_outcomes' '"
	
	
	if `sensd'==1 {	
		local shareonsig "`: display x_pval_onsig_d  "`=char(47)'"  `N_outcomes' '"

		
		*** information presented in figure note on the number of analysis paths that are captured by the dashboard 
		qui tab `varlist' 
		local N_outcomes = `r(r)'
		
		bysort `varlist': gen x_N_specs_by_outcome = _N
		qui sum x_N_specs_by_outcome
		local N_specs_min = `r(min)'
		local N_specs_max = `r(max)'
		
		egen x_N_outcomes_min2 = group(`varlist') if x_N_specs_by_outcome==`N_specs_min'
		egen x_N_outcomes_max2 = group(`varlist') if x_N_specs_by_outcome==`N_specs_max'
		egen x_N_outcomes_min = max(x_N_outcomes_min2)
		egen x_N_outcomes_max = max(x_N_outcomes_max2)
		
		decode `varlist', gen(outcome_str)
		gen x_spec_min_outcome = outcome_str if x_N_specs_by_outcome==`N_specs_min'
		gen x_spec_max_outcome = outcome_str if x_N_specs_by_outcome==`N_specs_max'	
		gsort -x_spec_min_outcome
		local spec_min = x_spec_min_outcome
		if x_N_outcomes_min>1 {
			local spec_min "multiple outcomes"
		}
		gsort -x_spec_max_outcome
		local spec_max = x_spec_max_outcome
		if x_N_outcomes_max>1 {
			local spec_max "multiple outcomes"
		}
	}

	drop x_*
	
	
	
********************************************************************************
*****  PART 3  INDICATOR DEFINITIONS BY OUTCOME
********************************************************************************

	** 1. Statistical significance indicator
					   gen x_RF_stat_sig_i = (pval_i<0.`sigdigits' ///
											  & beta_dir_i==beta_orig_dir_j)*100	if pval_orig_j<0.`sigdigits'  & beta2_i==.
				   replace x_RF_stat_sig_i = (pval_i>=0.`sigdigits')*100			if pval_orig_j>=0.`sigdigits' & beta2_i==.
				   

				   replace x_RF_stat_sig_i = (pval_i<0.`sigdigits' ///
											  & beta_dir_i==beta_orig_dir_j ///
											  & pval2_i<0.`sigdigits' ///
											  & beta2_dir_i==beta_orig_dir_j)*100	if pval_orig_j<0.`sigdigits' & beta2_i!=.
					   // if two coefficients and if the original results was significant, both coefficients need to be significant in the original direction  
				   replace x_RF_stat_sig_i = (pval_i>=0.`sigdigits' | (pval2_i>=0.`sigdigits' & pval2_i<.))*100	if pval_orig_j>=0.`sigdigits' & beta2_i!=.  
					   // if two coefficients and if the original result was a null result, at least one of the two coefficients need to be insignificant    
				   
	bysort `varlist': egen   RF_stat_sig_j = mean(x_RF_stat_sig_i) 						  	 
			
				
	** 1+. Statistical significance indicator (opposite direction)
		// only for original results reported as statistically significant at the 0.`sigdigits' level
		// only for beta2_i==.
					   gen x_RF_stat_sig_ndir_i	= (pval_i<0.`sigdigits' ///
											  & beta_dir_i!=beta_orig_dir_j)*100	if pval_orig_j<0.`sigdigits' & beta2_i==.
									
	bysort `varlist': egen   RF_stat_sig_ndir_j	= mean(x_RF_stat_sig_ndir_i) 
	
	
	** 2. Relative effect size 
		// only for original results reported as statistically significant at the 0.`sigdigits' level
		// only for sameunits_i==1 & beta2_orig_j==.
	bysort `varlist': egen x_RF_relES_j = mean(`beta')   							if (pval_orig_j<0.`sigdigits') & sameunits_i==1 & beta2_orig_j==.
					   gen   RF_relES_j = x_RF_relES_j/beta_orig_j

		
	** 2+. Relative effect size - deviation of median estimate as % of original result, if same direction
		// only for original results reported as statistically significant at the 0.`sigdigits' level
		// + only for analysis paths of reproducability or replicability analyses reported as statistically significant at the 0.`sigdigits' level
	bysort `varlist': egen x_RF_relES2_j2 	= median(`beta')	 					if pval_i<0.`sigdigits' & beta_dir_i==beta_orig_dir_j & pval_orig_j<0.`sigdigits'						
					   gen x_RF_relES2_j 	= x_RF_relES2_j2/beta_orig_j 
					   gen   RF_relES2_j 	= ((x_RF_relES2_j) - 1)*100

	** 2b+. if aggregated: Relative effect size - s.d. of deviation of median estimate as % of original result, if same direction
		// only for original results reported as statistically significant at the 0.`sigdigits' level
					   gen RF_relES2sd_j = .   // is calculated below once data is aggregated to outcome level
					   
					   
	** 3. Relative t/z-value
		// only for original results reported as statistically significant at the 0.`sigdigits' level
					   gen x_RF_reltz_i = zscore_i/zscore_orig_j
	bysort `varlist': egen   RF_reltz_j = mean(x_RF_reltz_i)   						if pval_orig_j<0.`sigdigits'
	

	*** preparation for Variation Indicators 4 and 5: add original estimate as additional observation if included as one analysis path of reproducability or replicability analysis
	if `orig_in_multiverse'==1 {
		bysort `varlist': gen outcome_n = _n
		expand 2 if outcome_n==1, gen(add_orig)

		replace `beta'      = beta_orig_j    if add_orig==1
		replace beta_dir_i = beta_orig_dir_j if add_orig==1
		replace sameunits_i = 1 			 if add_orig==1
		replace pval_i 	    = pval_orig_j 	 if add_orig==1
		replace zscore_i    = zscore_orig_j  if add_orig==1
		
		bysort `varlist': egen x_RF_relES2_j3 = mean(x_RF_relES2_j2)
		replace x_RF_relES2_j2 = x_RF_relES2_j3 if add_orig==1 & pval_orig_j<0.`sigdigits'   // set x_RF_relES2_j2 for original results with pval_orig_j(=pval_i for add_orig==1)<0.`sigdigits'
		// other *_j variables do not need to be adjusted, as they are already generated by the expand command
	}
	
	
	** 4. Variation indicator: effect sizes
		// only for sameunits_i==1 & beta2_orig_j==.
	bysort `varlist': egen x_RF_relVAR_ES_j = sd(`beta')						if sameunits_i==1 & beta2_orig_j==.
					   gen   RF_relVAR_ES_j = x_RF_relVAR_ES_j/se_orig_j        
	
	
	** A4+. Variation indicator - mean abs. deviation of estimates from median estimate, as % of original result
		// only for original results reported as statistically significant at the 0.`sigdigits' level
		// + only for analysis paths of reproducability or replicability analyses reported as statistically significant at the 0.`sigdigits' level
					   gen x_RF_relVAR_ES2_i = abs(`beta'-x_RF_relES2_j2) 	    	
	bysort `varlist': egen x_RF_relVAR_ES2_j = mean(x_RF_relVAR_ES2_i)     			if pval_i<0.`sigdigits' & beta_dir_i==beta_orig_dir_j & pval_orig_j<0.`sigdigits'
					   gen   RF_relVAR_ES2_j = (x_RF_relVAR_ES2_j/abs(beta_orig_j))*100
	
	
	** 5. Variation indicator: t/z-value
	bysort `varlist': egen   RF_relVAR_tz_j = sd(zscore_i)	

	
	** A5+. Variation indicator - mean abs. deviation of p-values of insig. reproducability or replicability tests from original p-value		
					  gen x_RF_stat_insig_i  = abs(pval_i-pval_orig_j)				if pval_i>=0.`sigdigits'
	bysort `varlist': egen  RF_stat_insig_j  = mean(x_RF_stat_insig_i)
	
	
	if `orig_in_multiverse'==1 {
		drop if add_orig==1  // better remove these added observations before collapsing as they have incomplete information
		drop outcome_n add_orig
	}
	
	local collapselast  RF_stat_insig_j
	
	
	** shelved indicators					  
	if `shelvedind'==1 {
						       gen x_RF_robratio_A_i = (`beta'-beta_orig_j)^2 	
						       gen x_RF_robratio_B_i = (zscore_i-zscore_orig_j)^2     	
		foreach approach in A B {
			bysort `varlist': egen x_RF_robratio_`approach'_j  = mean(x_RF_robratio_`approach'_i) 
		}
						       gen RF_robratio_A_j = sqrt(x_RF_robratio_A_j)/se_orig_j
						       gen RF_robratio_B_j = sqrt(x_RF_robratio_B_j)
		
		
		bysort `varlist': egen x_RF_pooledH_A_j1 	= mean(`beta')
		bysort `varlist': egen x_RF_pooledH_A_j2 	= mean(se_i^2)    
						   gen   RF_pooledH_A_j 	= x_RF_pooledH_A_j1/sqrt(x_RF_pooledH_A_j2)
					   replace   RF_pooledH_A_j 	= -1*RF_pooledH_A_j  if beta_orig_dir_j==-1	
		
		bysort `varlist': egen   RF_pooledH_B_j 	= mean(zscore_i)
					   replace   RF_pooledH_B_j 	= -1*RF_pooledH_B_j  if beta_orig_dir_j==-1
					   		   
		local collapselast  RF_pooledH_B_j 
	}
	
	
	** indicators for Sensitivity Dashboard
	if `sensd'==1 {
		** column 1
		// beta_orig_j  pval_orig_j 
		
		
		** column 2
		clonevar d_pval_insigrep_j = RF_stat_insig_j // corresponds completely to RF_stat_insig_j
		
						   gen x_b_op`sigdigits'_insigrep_i  = (abs(`beta')<=beta_abs_orig_p`sigdigits'_j)*100	if pval_i>=0.`sigdigits'		// multiples of 0.1 cannot be held exactly in binary in Stata -> shares converted to range from 1/100, not from 0.01 to 1.00
		bysort `varlist': egen   b_op`sigdigits'_insigrep_j	 = mean(x_b_op`sigdigits'_insigrep_i)
						   gen x_se_op`sigdigits'_insigrep_i = (se_i>=se_orig_p`sigdigits'_j)*100				if pval_i>=0.`sigdigits'
		bysort `varlist': egen   se_op`sigdigits'_insigrep_j = mean(x_se_op`sigdigits'_insigrep_i)

		
		** column 3
						   gen x_sig`sigdigits'ndir_i		= (pval_i<0.`sigdigits' & beta_dir_i!=beta_orig_dir_j)*100
																	// corresponds to x_RF_stat_sig_ndir_i [...], here calculated also for pval_orig_j>=0.`sigdigits'
		bysort `varlist': egen   sig`sigdigits'ndir_j      	= mean(x_sig`sigdigits'ndir_i) 
				
		
		** column 4
						   gen x_sig`sigdigits'dir_i		= (pval_i<0.`sigdigits' & beta_dir_i==beta_orig_dir_j)*100
																	// corresponds to RF_stat_sig_i [...] if (pval_orig_j<0.`sigdigits'), here calculated also for pval_orig_j>=0.`sigdigits'
		bysort `varlist': egen   sig`sigdigits'dir_j    	= mean(x_sig`sigdigits'dir_i)    			

		if "$tFinclude"=="1" {
							   gen x_sig05tFdir_i			= (pval_tF<0.05 & beta_dir_i==beta_orig_dir_j)*100
			bysort `varlist': egen   sig05tFdir_j  			= mean(x_sig05tFdir_i)	
		}
		
		if `siglevelnum'!=5  {
							   gen x_sig05dir_i				= (pval_i<0.05  & beta_dir_i==beta_orig_dir_j)*100
			bysort `varlist': egen   sig05dir_j  			= mean(x_sig05dir_i)
		}
		
						   gen x_b_up`sigdigits'_sig`sigdigits'rep_i  = (abs(`beta')>beta_abs_orig_p`sigdigits'_j)*100	if beta_dir_i==beta_orig_dir_j & pval_i<0.`sigdigits'
		bysort `varlist': egen   b_up`sigdigits'_sig`sigdigits'rep_j  = mean(x_b_up`sigdigits'_sig`sigdigits'rep_i)
						   gen x_se_up`sigdigits'_sig`sigdigits'rep_i = (se_i<se_orig_p`sigdigits'_j)*100				if beta_dir_i==beta_orig_dir_j & pval_i<0.`sigdigits'
		bysort `varlist': egen   se_up`sigdigits'_sig`sigdigits'rep_j = mean(x_se_up`sigdigits'_sig`sigdigits'rep_i)

		
		clonevar x_b_rlmd_sig`sigdigits'rep_j2 = x_RF_relES2_j2		// corresponds completely to x_RF_relES2_j2  (required for next indicator below)
		clonevar   b_rlmd_sig`sigdigits'rep_j  = RF_relES2_j   		// corresponds completely to RF_relES2_j

		clonevar d_b_rlmd_sig`sigdigits'rep_j = RF_relVAR_ES2_j		// corresponds completely to RF_relVAR_ES2_j
								   
		local collapselast  d_b_rlmd_sig`sigdigits'rep_j
	}
	
	
	** Weights for inverse-variance weighting 
	if `ivarweight'==1 {
		bysort `varlist': egen x_se_rel_mean_j = mean(se_rel_i)	
						   gen        weight_j = 1/(x_se_rel_mean_j^2)

						   gen    weight_orig_j = 1/(se_rel_orig_j^2)
						   
		local collapselast weight_orig_j
	}
	

*** Collapse indicator values to one obs per outcome
	drop x_* 
	ds RF_stat_sig_j - `collapselast'   
	foreach var in `r(varlist)' {
		bysort `varlist': egen c`var' = min(`var') 
		drop `var'
		rename c`var' `var'
	}
	
	bysort `varlist': gen n_j = _n
	
	keep if n_j==1
	drop n_j  `beta' se_i pval_i beta_dir_i beta_rel_i se_rel_i zscore_i  `df'  beta2_i pval2_i beta2_dir_i  sameunits_i 	// drop information at a different level than the aggregated level
	drop      se_orig_j   mean_j mean_orig_j se_rel_orig_j zscore_orig_j `df_orig' beta2_orig_j     						// drop information not required anymore 
	capture drop beta_abs_orig_p`sigdigits'_j se_orig_p`sigdigits'_j
	capture drop se2_i se2_orig_j pval2_orig_j zscore2_i zscore2_orig_j  beta2_orig_dir_j
	capture drop `ivF' tF_adj se_tF pval_tF
	tempfile data_j
	save `data_j'
					

					
		
	
********************************************************************************
*****  PART 4  SENSITIVITY DASHBOARD VISUALIZATION 
********************************************************************************
	
************************************************************
***  PART 4.A  INDICATORS OVER ALL OUTCOMES
************************************************************
	
	if `sensd'==1 {
		if `aggregation'==1 {
			if `ivarweight'==1 {
				egen x_total_weight 	   			= total(weight_j)
				egen x_total_`sigdigits'o_weight    = total(weight_j) 			if pval_orig_j<0.`sigdigits'
				egen x_total_insigo_weight 			= total(weight_j) 			if pval_orig_j>=0.`sigdigits'
			}
			
			** original indicator sig, revised indicator sig at `sigdigits'% level
			foreach o_inds in d_pval_insigrep b_op`sigdigits'_insigrep  se_op`sigdigits'_insigrep   sig`sigdigits'dir sig`sigdigits'ndir   b_rlmd_sig`sigdigits'rep d_b_rlmd_sig`sigdigits'rep		`sig05dir' {
				if `ivarweight'==0 {
					egen `o_inds'_`sigdigits'o_all  = mean(`o_inds'_j) 											if pval_orig_j<0.`sigdigits'
				}
				if `ivarweight'==1 {				
					egen `o_inds'_`sigdigits'o_all  = total(`o_inds'_j*weight_j/x_total_`sigdigits'o_weight)   	if pval_orig_j<0.`sigdigits'
				}
			}			
			
			** original indicator insig, revised indicator sig at `sigdigits'% level
			foreach o_indi in d_pval_insigrep b_up`sigdigits'_sig`sigdigits'rep se_up`sigdigits'_sig`sigdigits'rep  sig`sigdigits'dir sig`sigdigits'ndir   b_rlmd_sig`sigdigits'rep d_b_rlmd_sig`sigdigits'rep 	`sig05dir' {
				if `ivarweight'==0 {
					egen `o_indi'_insigo_all = mean(`o_indi'_j) 		if pval_orig_j>=0.`sigdigits'
				}
				if `ivarweight'==1 {		
					egen `o_indi'_insigo_all = total(`o_indi'_j*weight_j/x_total_insigo_weight) if pval_orig_j>=0.`sigdigits'
				}
			}
				
			** any original indicator sig level, revised indicator sig at `sigdigits'% level
			foreach o_indi in                                                                 				   b_rlmd_sig`sigdigits'rep d_b_rlmd_sig`sigdigits'rep                       {
				if `ivarweight'==0 {
					egen `o_indi'_anyo_all = mean(`o_indi'_j)
				}
				if `ivarweight'==1 {
					egen `o_indi'_anyo_all = total(`o_indi'_j*weight_j/x_total_weight)
				}
			}
			if `ivarweight'==0 {
				egen anyrep_o`sigdigits'_all = mean(pval_orig_j<0.`sigdigits')
			}
			if `ivarweight'==1 {
				gen  x_anyrep_o`sigdigits'_j  = (pval_orig_j<0.`sigdigits')
				egen   anyrep_o`sigdigits'_all = total(x_anyrep_o`sigdigits'_j*weight_j/x_total_weight)		
			}
			
			** copy information to all outcomes
			ds *_all
			foreach var in `r(varlist)' {
				egen c`var' = mean(`var') 
				drop `var'
				rename c`var' `var'
			}
		}	


	
************************************************************
***  PART 4.B  PREPARE DASHBOARD GRAPH DATA
************************************************************
		
*** Prepare data structure and y- and x-axis

		if `aggregation'==1 {
			keep if inlist(`varlist',1)       	// keep one observation across outcomes
			drop `varlist' outcome_str *_j		// drop variables at outcome level 
			expand 2
			gen y = _n
			local yset_n = 2 
			global ylab 1 `" "significant" " " "{sup:`shareosig' outcomes}" "' 2 `" "insignificant" "({it:p}{&ge}0.`sigdigits')" " " "{sup:`shareonsig' outcomes}" "'	// first y entry shows up at bottom of y-axis of the dashboard	
		}
		else { 
			sort `varlist'
			egen y = group(`varlist')    // make sure that varlist is numbered consecutively from 1 on
			local yset_n = `N_outcomes'			// # of items shown on y-axis = # of outcomes
			
			** reverse order of outcome numbering as outcomes are presented in reverse order on the y-axis of the dashboard
			tostring `varlist', replace
			labmask y, values(outcome_str) lblname(ylab)	
			
			if `N_outcomes'==2 | `N_outcomes'==3 {
				recode y (1=`N_outcomes') (`N_outcomes'=1)
				global ylab `"   `=y[1]' "`=outcome_str[1]'" `=y[2]' "`=outcome_str[2]'"  "'
			}
			if `N_outcomes'==3 {
				global ylab `"   `=y[1]' "`=outcome_str[1]'" `=y[2]' "`=outcome_str[2]'" `=y[3]' "`=outcome_str[3]'" "'
			}	
			if `N_outcomes'==4 {
				recode y (1=4) (4=1) (2=3) (3=2)
				global ylab `"   `=y[1]' "`=outcome_str[1]'" `=y[2]' "`=outcome_str[2]'" `=y[3]' "`=outcome_str[3]'" `=y[4]' "`=outcome_str[4]'"  "'
			}
			if `N_outcomes'==5 {
				recode y (1=5) (5=1) (2=4) (4=2)
				global ylab `"   `=y[1]' "`=outcome_str[1]'" `=y[2]' "`=outcome_str[2]'" `=y[3]' "`=outcome_str[3]'" `=y[4]' "`=outcome_str[4]'" `=y[5]' "`=outcome_str[5]'"  "'
			}
			
			if `N_outcomes'>5 {
				noi dis "{red: Please use option -sensdash, [...] aggregation(1)- with more than five outcomes to be displayed}"				
				use `inputdata', clear
				exit
			}									
			drop `varlist' outcome_str
		}
		
		local xset  insig  sig_ndir  sig_dir
		local xlab 1 `" "insignificant" "({it:p}{&ge}0.`sigdigits')" "' 2 `" "significant," "opposite sign" "' 3 `" "significant," "same sign" "'
		local xset_n : word count `xset'
		
		expand `xset_n'
		bysort y: gen x = _n
		
		
		** labelling of y-axis 
		if `aggregation'==1 {
			local aux `" "Original" "results" "'
			local ytitle  ytitle(`aux', orient(horizontal))
		}
		else {
			local ytitle ytitle("") // empty global, no ytitle to show up
		}
		

*** Calculate sensitivity indicators
		if `aggregation'==1 {
			// in order to calculate the shares in ALL original results [and not differentiated by originally sig or insig] multiply x_share_2x and `styper'_insigo_all by (1 - anyrep_o`sigdigits'_all) and x_share_1x and `styper'_`sigdigits'o_all by anyrep_o`sigdigits'_all
			gen x_share_21 =  (100 - sig`sigdigits'dir_insigo_all - sig`sigdigits'ndir_insigo_all)	if y==2 & x==1	// top left     (insig orig & insig rev)            = (100 - sig rev)
			gen x_share_22 =                               			sig`sigdigits'ndir_insigo_all	if y==2 & x==2	// top middle   (insig orig & sig   rev, diff sign) =      sig rev not dir
			gen x_share_23 =         sig`sigdigits'dir_insigo_all						 			if y==2 & x==3	// top right    (insig orig & sig   rev, same sign) = sig rev     dir
			
			gen x_share_11 =  (100 - sig`sigdigits'dir_`sigdigits'o_all - sig`sigdigits'ndir_`sigdigits'o_all)  if y==1 & x==1  // bottom left   (sig & insig)			 			=      (100 - sig rev)
			gen x_share_12 =                            			sig`sigdigits'ndir_`sigdigits'o_all 		if y==1 & x==2	// bottom middle (sig & sig, diff sign)				=      (100 - sig rev not dir)
			gen x_share_13 =         sig`sigdigits'dir_`sigdigits'o_all 				    if y==1 & x==3	// bottom right  (sig & sig, same sign)				=      (100 - sig rev     dir)
			
			for num 1/3: replace x_share_1X = 0 											if y==1 & x==X & anyrep_o`sigdigits'_all==0 & x_share_1X==.			// replace missing by zero if none of the original estimates was sig
			for num 1/3: replace x_share_2X = 0 											if y==2 & x==X & anyrep_o`sigdigits'_all==1 & x_share_2X==.   		// replace missing by zero if all of the original estimates were sig
			 
			 
			foreach styper in `sig05dir' {
				replace `styper'_insigo_all 		= `styper'_insigo_all  // top right  (insig orig & sig rev)
				replace `styper'_`sigdigits'o_all   = `styper'_`sigdigits'o_all     // bottom right (sig orig & sig rev)
			}
		}		
		else {
			for num 1/`yset_n': gen x_share_X1 = 100 - sig`sigdigits'dir_j - sig`sigdigits'ndir_j  	if y==X		// insig outcome X
			for num 1/`yset_n': gen x_share_X2 =       sig`sigdigits'ndir_j  						if y==X		//   sig outcome X, not dir
			for num 1/`yset_n': gen x_share_X3 =       sig`sigdigits'dir_j  						if y==X		//   sig outcome X, same dir
		
			foreach var in beta_orig_j beta_rel_orig_j pval_orig_j sig`sigdigits'dir_j `sig05dir_j'  d_pval_insigrep_j   se_op`sigdigits'_insigrep_j b_op`sigdigits'_insigrep_j   b_up`sigdigits'_sig`sigdigits'rep_j se_up`sigdigits'_sig`sigdigits'rep_j      b_rlmd_sig`sigdigits'rep_j d_b_rlmd_sig`sigdigits'rep_j {
				for num 1/`yset_n': gen   x_`var'X = `var' if y==X
				for num 1/`yset_n': egen    `var'X = mean(x_`var'X)	
			}
		}
		

*** Format indicators for presentation in the dashboard
		forval qy = 1/`yset_n' {
			forval qx = 1/3 {
				egen    share_`qy'`qx' = min(x_share_`qy'`qx')
				gen x_share_`qy'`qx'_2 = floor(share_`qy'`qx')			
				gen x_sharerounder_`qy'`qx' = x_share_`qy'`qx' - x_share_`qy'`qx'_2	// these variables contain information on the third+ digit and guarantee below that shares add up to 1 (i.e. 100%) 
				replace share_`qy'`qx' = round(share_`qy'`qx')
			}
		}
		
		foreach shvar in share x_sharerounder {		
			gen     `shvar' = `shvar'_11 if y==1 & x==1
			for num 2/3: replace `shvar' = `shvar'_1X if y==1 & x==X
			for num 2/`yset_n': replace `shvar' = `shvar'_X1 if y==X & x==1
			for num 2/`yset_n': replace `shvar' = `shvar'_X2 if y==X & x==2
			for num 2/`yset_n': replace `shvar' = `shvar'_X3 if y==X & x==3
		}
		
		
		*if `aggregation'==1 {
		*		gen share_roundingdiff = (100-(share_21 + share_22 + share_23 + share_11 + share_12 + share_13))
		*}
		*else {
				gen     share_roundingdiff = (100-(share_11 + share_12 + share_13)) if y==1
				for num 2/`yset_n': replace share_roundingdiff = (1-(share_X1 + share_X2 + share_X3))*100 if y==X
		*}
		
		if share_roundingdiff<0 {		// sum of shares exceeds 100%
				egen sharerounder = rank(x_sharerounder) if x_sharerounder>=0.5, unique
				replace share = share - 1 if sharerounder<=abs(share_roundingdiff)    // the X shares with the lowest digits are reduced in cases where the sum of shares is 10X
		} 
		if share_roundingdiff>0 {		// sum of shares falls below 100%
				egen sharerounder = rank(x_sharerounder) if x_sharerounder<0.5, field
				replace share = share + 1 if sharerounder<=share_roundingdiff		// the X shares with the highest digits are increased in cases where the sum of shares is 100 - X
		} 
		
		drop x_* share_roundingdiff
		capture drop sharerounder
		
		
			  
************************************************************
***  PART 4.C  PREPARE PLOTTING OF DASHBOARD GRAPH DATA
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
		
		gen     colorname_nonconfirm = "`r(`col')'*`col_lowint'"		// definition of colour used for non-fonfirmatory and confirmatory results - required for legend to dashboard graph
		gen     colorname_confirm    = "`r(`col')'*`col_highint'"
		
		gen     colorname   = colorname_nonconfirm
		if `aggregation'==1 {
			replace colorname = colorname_confirm  if (y==2 & x==1) | (y==1 & x==3)
		}
		if `aggregation'==0 {
			forval k = 1/`yset_n' {
				replace colorname = colorname_confirm  if y==`k' & x==3 & pval_orig_j`k'<0.`sigdigits'
				replace colorname = colorname_confirm  if y==`k' & x==1 & pval_orig_j`k'>=0.`sigdigits'
			}
		}
	

*** Saving the plotting codes in locals
		local slist ""
		forval i = 1/`=_N' {
			local slist "`slist' (scatteri `=y[`i']' `=x[`i']' "`: display %3.0f =share[`i'] "%" '", mlabposition(0) mlabsize(medsmall) msize(`=share[`i']*0.5*(0.75^(`yset_n'-2))') mcolor("`=colorname[`i']'"))"     // msize defines the size of the circles
		}
			  
		if "`signfirst'"=="" {
			local yx0b   // empty local
		}
		else {
			local yx0b	`" "wrong-sign" "first stages:"  "`: display %3.0f `signfirst'*100 "%" '" "'	 
		}
		
		
		** aggregation across outcomes
		if `aggregation'==1 {			
			foreach r0 in  b_rlmd_sig`sigdigits'rep_`sigdigits'o d_b_rlmd_sig`sigdigits'rep_`sigdigits'o   b_rlmd_sig`sigdigits'rep_insigo d_b_rlmd_sig`sigdigits'rep_insigo   `sig05dir_10o'   `sig05dir_insigo' {
				replace   `r0'_all = round(`r0'_all)		
			}
			
			local sign_d_insig ""
			if b_rlmd_sig`sigdigits'rep_insigo_all>0 {
				local sign_d_insig "+"
			}
			if b_rlmd_sig`sigdigits'rep_insigo_all==0 {
				local sign_d_insig "+/-"
			}
			local sign_d_sig ""
			if b_rlmd_sig`sigdigits'rep_`sigdigits'o_all>0 {
				local sign_d_sig "+" 
			}
			if b_rlmd_sig`sigdigits'rep_`sigdigits'o_all==0 {
				local sign_d_sig "+/-" 
			}
			local xleft = 0.6
			
			local y2x0	""
			local y1x0	"" 			

			local y2x1	"" 
			if share_21>0 & anyrep_o`sigdigits'_all!=1 {
				local y2x1	`" "`: display "`=ustrunescape("\u0394\u0305\u0070")': " %3.2f d_pval_insigrep_insigo_all'" "'	 
			}
		
			if `extended'==0 {
				if share_23>0 & anyrep_o`sigdigits'_all!=1 {
					if "$tFinclude"=="1" {
						if `siglevelnum'!=5 {
							local y2x3	`" "`: display "{it:p}<0.05: "  `=sig05dir_insigo_all' "% ({it:tF}: "  `=sig05tFdir_insigo_all' "%)" '" "'
						}
						if `siglevelnum'==5 {
							local y2x3	`" "`: display "{it:tF}: "  `=sig05tFdir_insigo_all' "%)" '" "'
						}
					}
					if "$tFinclude"!="1" & `siglevelnum'!=5  {
						local y2x3	`" "`: display "{it:p}<0.05: "  `=sig05dir_insigo_all' "%" '"  "'
					}
				}
				if share_11>0 & anyrep_o`sigdigits'_all!=0 {
					local y1x1 	`" "`: display "`=ustrunescape("\u0394\u0305\u0070")': " %3.2f d_pval_insigrep_`sigdigits'o_all'"  "'
				}
				if share_13>0 & anyrep_o`sigdigits'_all!=0 {
					if "$tFinclude"=="1" {
						if `siglevelnum'!=5 {
							local y1x3	`" "`: display "{it:p}<0.05: "  `=sig05dir_`sigdigits'o_all' "% ({it:tF}: "  `=sig05tFdir_`sigdigits'o_all' "%)" '"     "`: display "`=ustrunescape("\u03B2\u0303")': `sign_d_sig'" b_rlmd_sig`sigdigits'rep_`sigdigits'o_all "% (`=ustrunescape("\u0394\u0305\u03B2\u0303")': " d_b_rlmd_sig`sigdigits'rep_`sigdigits'o_all "%)" '"  "'
						}
						if `siglevelnum'==5 {
							local y1x3	`" "`: display "{it:tF}: "  `=sig05tFdir_`sigdigits'o_all' "%)" '"     "`: display "`=ustrunescape("\u03B2\u0303")': `sign_d_sig'" b_rlmd_sig`sigdigits'rep_`sigdigits'o_all "% (`=ustrunescape("\u0394\u0305\u03B2\u0303")': " d_b_rlmd_sig`sigdigits'rep_`sigdigits'o_all "%)" '"  "'
						}
					}
					if "$tFinclude"!="1" {
						if `siglevelnum'!=5 {
							local y1x3	`" "`: display "{it:p}<0.05: "  `=sig05dir_`sigdigits'o_all' "%" '"                                            "`: display "`=ustrunescape("\u03B2\u0303")': `sign_d_sig'" b_rlmd_sig`sigdigits'rep_`sigdigits'o_all "% (`=ustrunescape("\u0394\u0305\u03B2\u0303")': " d_b_rlmd_sig`sigdigits'rep_`sigdigits'o_all "%)" '"  "'
						}
						if `siglevelnum'==5 {
							local y1x3	`" "`: display "`=ustrunescape("\u03B2\u0303")': `sign_d_sig'" b_rlmd_sig`sigdigits'rep_`sigdigits'o_all "% (`=ustrunescape("\u0394\u0305\u03B2\u0303")': " d_b_rlmd_sig`sigdigits'rep_`sigdigits'o_all "%)" '"  "'
						}
					}
				}	
			}
			else {
				if share_23>0 & anyrep_o`sigdigits'_all!=1 {
					if "$tFinclude"=="1" {
						if `siglevelnum'!=5 {
							local y2x3	`" "`: display "{it:p}<0.05: "  `=sig05dir_insigo_all' "% ({it:tF}: "  `=sig05tFdir_insigo_all' "%)" '"   "`: display "high |{&beta}|: " %3.0f b_up`sigdigits'_sig`sigdigits'rep_insigo_all "%" '"   "`: display "low se: " %3.0f se_up`sigdigits'_sig`sigdigits'rep_insigo_all "%" '" "'	 
						}
						if `siglevelnum'==5 {
							local y2x3	`" "`: display "{it:tF}: "  `=sig05tFdir_insigo_all' "%)" '"   "`: display "high |{&beta}|: " %3.0f b_up`sigdigits'_sig`sigdigits'rep_insigo_all "%" '"   "`: display "low se: " %3.0f se_up`sigdigits'_sig`sigdigits'rep_insigo_all "%" '" "'	 
						}
					}
					if "$tFinclude"!="1" {
						if `siglevelnum'!=5 {
							local y2x3	`" "`: display "{it:p}<0.05: "  `=sig05dir_insigo_all' "%" '"                                             "`: display "high |{&beta}|: " %3.0f b_up`sigdigits'_sig`sigdigits'rep_insigo_all "%" '"   "`: display "low se: " %3.0f se_up`sigdigits'_sig`sigdigits'rep_insigo_all "%" '" "'
						}
						if `siglevelnum'==5 {
							local y2x3	`" "`: display "high |{&beta}|: " %3.0f b_up`sigdigits'_sig`sigdigits'rep_insigo_all "%" '"   "`: display "low se: " %3.0f se_up`sigdigits'_sig`sigdigits'rep_insigo_all "%" '" "'
						}
					}
				}
				if share_11>0 & anyrep_o`sigdigits'_all!=0 {
					local y1x1 	`" "`: display "`=ustrunescape("\u0394\u0305\u0070")': " %3.2f d_pval_insigrep_`sigdigits'o_all'"    "`: display "low |{&beta}|: " %3.0f b_op`sigdigits'_insigrep_`sigdigits'o_all "%" '"   "`: display "high se: " %3.0f se_op`sigdigits'_insigrep_`sigdigits'o_all "%" '" "' 
				}
				if share_13>0 & anyrep_o`sigdigits'_all!=0 { 
					if "$tFinclude"=="1" {
						if `siglevelnum'!=5 {
							local y1x3	`" "`: display "{it:p}<0.05: "  `=sig05dir_`sigdigits'o_all' "% ({it:tF}: "  `=sig05tFdir_`sigdigits'o_all' "%)" '"     "`: display "`=ustrunescape("\u03B2\u0303")': `sign_d_sig'" b_rlmd_sig`sigdigits'rep_`sigdigits'o_all "% (`=ustrunescape("\u0394\u0305\u03B2\u0303")': " d_b_rlmd_sig`sigdigits'rep_`sigdigits'o_all "%)" '"  "'
						}
						if `siglevelnum'==5 {
							local y1x3	`" "`: display "{it:tF}: "  `=sig05tFdir_`sigdigits'o_all' "%)" '"     "`: display "`=ustrunescape("\u03B2\u0303")': `sign_d_sig'" b_rlmd_sig`sigdigits'rep_`sigdigits'o_all "% (`=ustrunescape("\u0394\u0305\u03B2\u0303")': " d_b_rlmd_sig`sigdigits'rep_`sigdigits'o_all "%)" '"  "'
						}
					}
					if "$tFinclude"!="1" {
						if `siglevelnum'!=5 {
							local y1x3	`" "`: display "{it:p}<0.05: "  `=sig05dir_`sigdigits'o_all' "%" '"                                            "`: display "`=ustrunescape("\u03B2\u0303")': `sign_d_sig'" b_rlmd_sig`sigdigits'rep_`sigdigits'o_all "% (`=ustrunescape("\u0394\u0305\u03B2\u0303")': " d_b_rlmd_sig`sigdigits'rep_`sigdigits'o_all "%)" '"  "'
						}
						if `siglevelnum'==5 {
							local y1x3	`" "`: display "`=ustrunescape("\u03B2\u0303")': `sign_d_sig'" b_rlmd_sig`sigdigits'rep_`sigdigits'o_all "% (`=ustrunescape("\u0394\u0305\u03B2\u0303")': " d_b_rlmd_sig`sigdigits'rep_`sigdigits'o_all "%)" '"  "'
						}
					}
				}
			}
		}	
		** no aggregation across outcomes
		else {
			foreach var2 in  beta_rel_orig_j   sig`sigdigits'dir_j `sig05dir_j'   b_rlmd_sig`sigdigits'rep_j d_b_rlmd_sig`sigdigits'rep_j {
				for num 1/`yset_n': replace `var2'X = round(`var2'X)
			}
			
			local xleft = 0.0
			
			forval k = 1/`yset_n' {
				local sign_d_orig`k' ""
				if beta_orig_j`k'>0 {
					local sign_d_orig`k' "+" 
				}
				if beta_orig_j`k'==0 {
					local sign_d_orig`k' "+/-" 
				}
				
				local sign_d_sig`k' ""
				if b_rlmd_sig`sigdigits'rep_j`k'>0 {
					local sign_d_sig`k' "+" 
				}
				if b_rlmd_sig`sigdigits'rep_j`k'==0 {
					local sign_d_sig`k' "+/-" 
				}
				
				if beta_rel_orig_j==. {
					local y`k'x0		`" "`: display "{it:`ytitle_row0'}" '"	"`: display "{&beta}: " %3.2f beta_orig_j`k'[1]'"   	"`: display "{it:p}: " %3.2f pval_orig_j`k'[1]'" "'
				}
				else {
					local y`k'x0		`" "`: display "{it:`ytitle_row0'}" '"	"`: display "{&beta}: " %3.2f beta_orig_j`k'[1] " [`sign_d_orig`k''" beta_rel_orig_j`k' "%]" '"   	"`: display "{it:p}: " %3.2f pval_orig_j`k'[1]'" "'
				}
				
				if `extended'==0 {
					if share_`k'1>0 {
						local y`k'x1  	`" "`: display "`=ustrunescape("\u0394\u0305\u0070")': " %3.2f d_pval_insigrep_j`k''"  "'				
					}
					if share_`k'3>0 {
						if pval_orig_j`k'<0.`sigdigits' {
							if "$tFinclude"=="1" {
								if `siglevelnum'!=5 {
									local y`k'x3  	`" "`: display "{it:p}<0.05: "  `=sig05dir_j`k'' "% ({it:tF}: "  `=sig05tFdir_j`k'' "%)" '"    		"`: display "`=ustrunescape("\u03B2\u0303")': `sign_d_sig`k''" b_rlmd_sig`sigdigits'rep_j`k' "% (`=ustrunescape("\u0394\u0305\u03B2\u0303")': " d_b_rlmd_sig`sigdigits'rep_j`k' "%)" '"  "'
								}
								if `siglevelnum'==5 {
									local y`k'x3  	`" "`: display "{it:tF}: "  `=sig05tFdir_j`k'' "%)" '"    		"`: display "`=ustrunescape("\u03B2\u0303")': `sign_d_sig`k''" b_rlmd_sig`sigdigits'rep_j`k' "% (`=ustrunescape("\u0394\u0305\u03B2\u0303")': " d_b_rlmd_sig`sigdigits'rep_j`k' "%)" '"  "'
								}		
							}
							if "$tFinclude"!="1" {
								if `siglevelnum'!=5 {
									local y`k'x3  	`" "`: display "{it:p}<0.05: "  `=sig05dir_j`k'' "%" '"    		                                    "`: display "`=ustrunescape("\u03B2\u0303")': `sign_d_sig`k''" b_rlmd_sig`sigdigits'rep_j`k' "% (`=ustrunescape("\u0394\u0305\u03B2\u0303")': " d_b_rlmd_sig`sigdigits'rep_j`k' "%)" '"  "'
								}
								if `siglevelnum'==5 {
									local y`k'x3  	`" "`: display "`=ustrunescape("\u03B2\u0303")': `sign_d_sig`k''" b_rlmd_sig`sigdigits'rep_j`k' "% (`=ustrunescape("\u0394\u0305\u03B2\u0303")': " d_b_rlmd_sig`sigdigits'rep_j`k' "%)" '"  "'
								}						
							}
						}
						if pval_orig_j`k'>=0.`sigdigits' {
							if "$tFinclude"=="1" {
								if `siglevelnum'!=5 {
									local y`k'x3  	`" "`: display "{it:p}<0.05: "  `=sig05dir_j`k'' "% ({it:tF}: "  `=sig05tFdir_j`k'' "%)" '"  "'
								}
								if `siglevelnum'==5 {
									local y`k'x3  	`" "`: display "{it:tF}: "  `=sig05tFdir_j`k'' "%)" '"  "'
								}
							}
							if "$tFinclude"!="1" & `siglevelnum'!=5 {
								local y`k'x3  	`" "`: display "{it:p}<0.05: "  `=sig05dir_j`k'' "%" '" "'
							}
						}
					}				
				}
				else {
					if share_`k'1>0 {
						if pval_orig_j`k'<0.`sigdigits' {
							local y`k'x1  	`" "`: display "`=ustrunescape("\u0394\u0305\u0070")': " %3.2f d_pval_insigrep_j`k''"    "`: display "low |{&beta}|: " %3.0f b_op`sigdigits'_insigrep_j`k' "%" '"    "`: display "high se: " %3.0f se_op`sigdigits'_insigrep_j`k' "%" '" "'
						}
						if pval_orig_j`k'>=0.`sigdigits' {
							local y`k'x1  	`" "`: display "`=ustrunescape("\u0394\u0305\u0070")': " %3.2f d_pval_insigrep_j`k''"  "'
						}						
					}
					if share_`k'3>0 {
						if pval_orig_j`k'<0.`sigdigits' {
							if "$tFinclude"=="1" {
								if `siglevelnum'!=5 {
									local y`k'x3  	`" "`: display "{it:p}<0.05: "  `=sig05dir_j`k'' "% ({it:tF}: "  `=sig05tFdir_j`k'' "%)" '"    		"`: display "`=ustrunescape("\u03B2\u0303")': `sign_d_sig`k''" b_rlmd_sig`sigdigits'rep_j`k' "% (`=ustrunescape("\u0394\u0305\u03B2\u0303")': " d_b_rlmd_sig`sigdigits'rep_j`k' "%)" '"  "'
								}
								if `siglevelnum'==5 {
									local y`k'x3  	`" "`: display "{it:tF}: "  `=sig05tFdir_j`k'' "%)" '"    		"`: display "`=ustrunescape("\u03B2\u0303")': `sign_d_sig`k''" b_rlmd_sig`sigdigits'rep_j`k' "% (`=ustrunescape("\u0394\u0305\u03B2\u0303")': " d_b_rlmd_sig`sigdigits'rep_j`k' "%)" '"  "'
								}
							}
							if "$tFinclude"!="1" {
								if `siglevelnum'!=5 {
									local y`k'x3  	`" "`: display "{it:p}<0.05: "  `=sig05dir_j`k'' "%" '"    		                                    "`: display "`=ustrunescape("\u03B2\u0303")': `sign_d_sig`k''" b_rlmd_sig`sigdigits'rep_j`k' "% (`=ustrunescape("\u0394\u0305\u03B2\u0303")': " d_b_rlmd_sig`sigdigits'rep_j`k' "%)" '"  "'
								}
								if `siglevelnum'==5 {
									local y`k'x3  	`" "`: display "`=ustrunescape("\u03B2\u0303")': `sign_d_sig`k''" b_rlmd_sig`sigdigits'rep_j`k' "% (`=ustrunescape("\u0394\u0305\u03B2\u0303")': " d_b_rlmd_sig`sigdigits'rep_j`k' "%)" '"  "'
								}
							}
						}
						if pval_orig_j`k'>=0.`sigdigits' {
							if "$tFinclude"=="1" {
								if `siglevelnum'!=5 {
									local y`k'x3  	`" "`: display "{it:p}<0.05: "  `=sig05dir_j`k'' "% ({it:tF}: "  `=sig05tFdir_j`k'' "%)" '"    		"`: display "high |{&beta}|: " %3.0f b_up`sigdigits'_sig`sigdigits'rep_j`k' "%" '"    "`: display "low se: " %3.0f se_up`sigdigits'_sig`sigdigits'rep_j`k' "%" '"  "'
								}
								if `siglevelnum'==5 {
									local y`k'x3  	`" "`: display "{it:tF}: "  `=sig05tFdir_j`k'' "%)" '"    		"`: display "high |{&beta}|: " %3.0f b_up`sigdigits'_sig`sigdigits'rep_j`k' "%" '"    "`: display "low se: " %3.0f se_up`sigdigits'_sig`sigdigits'rep_j`k' "%" '"  "'
								}
							}
							if "$tFinclude"!="1" {
								if `siglevelnum'!=5 {
								local y`k'x3  	`" "`: display "{it:p}<0.05: "  `=sig05dir_j`k'' "%" '"    											"`: display "high |{&beta}|: " %3.0f b_up`sigdigits'_sig`sigdigits'rep_j`k' "%" '"    "`: display "low se: " %3.0f se_up`sigdigits'_sig`sigdigits'rep_j`k' "%" '"  "'
								}
								if `siglevelnum'==5 {
								local y`k'x3  	`" "`: display "high |{&beta}|: " %3.0f b_up`sigdigits'_sig`sigdigits'rep_j`k' "%" '"    "`: display "low se: " %3.0f se_up`sigdigits'_sig`sigdigits'rep_j`k' "%" '"  "'
								}
							}
						}
					}
				}	
			}
		}
		
			
*** Specifying content of figure note
		local tsize vsmall
		local specs "analysis paths"  
		if (`N_specs_min'==`N_specs_max' & `N_specs_max'==1) {
		   local specs "analysis path" 
		}
		if  `N_specs_min'==`N_specs_max' {
			local N_specs `N_specs_max'
		}
		
		
		if `aggregation'==1 {
			local notes_spec 	based on `N_outcomes' outcomes with `N_specs' `specs' each
		}	
		if  `N_specs_min'!=`N_specs_max' {
			local N_specs "`N_specs_min' (`spec_min') to `N_specs_max' (`spec_max')"
			if `aggregation'==1 {
				local notes_spec 	based on `N_outcomes' outcomes with `N_specs' `specs'
			}
		}
		if `aggregation'==0 {
			local notes_spec 	based on `N_specs' `specs'
			if `N_outcomes'>1 &  `N_specs_min'==`N_specs_max' {
				local notes_spec 	based on `N_specs' `specs' for each outcome
			}
		}


*** Specifying location of indicators in dashboard depending on the number of outcomes/ y-axis entries presented
		local t_col0  ""
		if `aggregation'==1 {
			local t_col0b "text(`=1/2*`yset_n'+0.5'                      0.75 `yx0b' , size(`tsize'))"
		}
		else {
			local t_col0b "text(`=1/2*`yset_n'+0.5'                      0.6  `yx0b' , size(`tsize'))"
		}
		local t_col1  ""
		local t_col3  ""
		forval k = 1/`yset_n' {
			local t_col0  "`t_col0'  text(`k'                        0.2 `y`k'x0', size(`tsize'))"  
			local t_col1  "`t_col1'  text(`=`k'-0.2-(`yset_n'-2)*0.05' 1 `y`k'x1', size(`tsize'))"
			local t_col3  "`t_col3'  text(`=`k'-0.2-(`yset_n'-2)*0.05' 3 `y`k'x3', size(`tsize'))"
		}
		
		local yupper = 2.5 + (`yset_n'-2)*0.9
		

			
************************************************************
***  PART 4.D  PLOTTING OF THE DASHBOARD
************************************************************

		twoway (scatteri `=y[0]' `=x[0]', mcolor("`=colorname_confirm[1]'")) (scatteri `=y[0]' `=x[0]', mcolor("`=colorname_nonconfirm[1]'")) ///
			`slist', ///
			`ytitle' xtitle("Robustness results") ///
			xscale(range(`xleft' 3.5) /*alt*/) yscale(range(0.5 `yupper')) ///
			xlabel(`xlab', labsize(2.5)) ylabel($ylab, labsize(2.5)) ///
			`t_col0' `t_col0b' `t_col1' `t_col3'  ///
			legend(rows(1) order(1 "confirmatory robustness results" 2 "non-confirmatory robustness results") size(2.5) position(6) bmargin(tiny))  ///
			graphregion(color(white)) scheme(white_tableau)  
				// first line of this twoway command does not show up in the dashboard but is required to make the legend show up with the correct colours 
			
		graph export "`outputgraph'", replace

	
			
************************************************************
***  PART 4.E  NOTES TO DASHBOARD IN STATA RESULTS WINDOW
************************************************************

		noi dis _newline(1) "{it:Notes:} graph shows shares of analysis paths - `notes_spec'"
		noi dis _newline(1) "`=ustrunescape("\u03B2")' = beta coefficient"
		noi dis             "{it:p} = {it:p}-value (default relies on two-sided test assuming an approximately normal distribution)" 
		noi dis				"`=ustrunescape("\u03B2\u0303")' = median beta coefficient of reproducability or replicability analysis, measured as % deviation from original beta coefficient; generally, tildes indicate median values"
		noi dis 			"`=ustrunescape("\u0394\u0305")' = mean absolute deviation"
		if `aggregation'==0 {
			if beta_rel_orig_j!=. {
				noi dis 		"[+/-xx%] = Percentage in squared brackets refers to the original beta coefficient, expressed as % deviation from mean of the outcome"
			}
		}    
		if `extended'==1 {
			noi dis 		"low |`=ustrunescape("\u03B2")'| (high se) refers to the share of analysis paths of the reproducability or replicability analysis where the revised absolute value of the beta coefficient (standard error) is sufficiently low (high) to turn the overall estimate insignificant at the `siglevelnum'% level" 
		}
		if "$tFinclude"=="1" {
			noi dis  		"{it:tF} indicates the share of statistically significant estimates in the reproducability or replicability analysis at the {it:tF}-adjusted 5% level, using the {it:tF} adjustment proposed by Lee et al. (2022, AER)"
		}
	}
	
	
	
************************************************************
***  PART 5  COMPILE REPRODUCIBILITY AND REPLICABILITY INDICATORS 
************************************************************
	
	use `data_j', clear
	if `sensd'==1 {
		drop outcome_str  d_pval_insigrep_j - d_b_rlmd_sig`sigdigits'rep_j
	}
	capture drop `signfirst'
	
	
************************************************************
***  PART 5.A  INDICATORS OVER ALL OUTCOMES
************************************************************ 
		 
	gen    beta_orig_osig_all = .
	gen    beta_orig_onsig_all = .
	gen    beta_rel_orig_osig_all = .
	gen    beta_rel_orig_onsig_all = .
	
	local RF_ind_list 	stat_sig relES reltz relVAR_ES relVAR_tz   stat_sig_ndir relES2 relVAR_ES2 stat_insig
	if `shelvedind'==1 {
		local RF_ind_list 	`RF_ind_list'  robratio_A robratio_B
	}
			
	if `ivarweight'==0 {
		foreach RF_ind of local RF_ind_list {
			egen RF_`RF_ind'_osig_all  = mean(RF_`RF_ind'_j) if pval_orig_j<0.`sigdigits'
			egen RF_`RF_ind'_onsig_all = mean(RF_`RF_ind'_j) if pval_orig_j>=0.`sigdigits'
		}
	
		egen RF_relES2sd_osig_all   = sd(RF_relES2_j) if (pval_orig_j<0.`sigdigits')
		 gen RF_relES2sd_onsig_all  = .   // only for original results reported as statistically significant at the 0.`sigdigits' level

		if `shelvedind'==1 {
			foreach approach in A B {
				gen  x_RF_pooledH_`approach'_j2   		= 2*(1 - normal(abs(RF_pooledH_`approach'_j))) 	if (RF_pooledH_`approach'_j>=0 & beta_orig_dir_j==1) | (RF_pooledH_`approach'_j<0 & beta_orig_dir_j==0)
				 gen  x_RF_pooledH_`approach'_j   		= (x_RF_pooledH_`approach'_j2<0.`sigdigits')*100 if x_RF_pooledH_`approach'_j2!=.
				egen    RF_pooledH_`approach'_osig_all  = mean(x_RF_pooledH_`approach'_j) if (pval_orig_j<0.`sigdigits')
				egen    RF_pooledH_`approach'_onsig_all = mean(x_RF_pooledH_`approach'_j) if (pval_orig_j>=0.`sigdigits') 
			}
		}
		
		 gen  x_pval_orig_osig_all  = pval_orig_j   				if (pval_orig_j<0.`sigdigits')	
		egen    pval_orig_osig_all  = mean(x_pval_orig_osig_all) 
		 gen  x_pval_orig_onsig_all = pval_orig_j  					if (pval_orig_j>=0.`sigdigits')	
		egen    pval_orig_onsig_all = mean(x_pval_orig_onsig_all)
	}
		
	if `ivarweight'==1 {
		egen x_total_osig_weight  = total(weight_j) if (pval_orig_j<0.`sigdigits')
		egen x_total_onsig_weight = total(weight_j) if (pval_orig_j>=0.`sigdigits')
			
		foreach RF_indw of local RF_ind_list {
			egen   RF_`RF_indw'_osig_all  = total(RF_`RF_indw'_j*weight_j/x_total_osig_weight)      if (pval_orig_j<0.`sigdigits')
			egen   RF_`RF_indw'_onsig_all = total(RF_`RF_indw'_j*weight_j/x_total_onsig_weight)     if (pval_orig_j>=0.`sigdigits')
		}
			
		gen RF_relES2sd_osig_all   = .   // formula may be added
		gen RF_relES2sd_onsig_all  = .
		
		if `shelvedind'==1 {
			foreach approachw in A B {
				 gen  x_RF_pooledH_`approachw'_j2   = 2*(1 - normal(abs(RF_pooledH_`approachw'_j))) 	if (RF_pooledH_`approachw'_j>=0 & beta_orig_dir_j==1) | (RF_pooledH_`approachw'_j<0 & beta_orig_dir_j==0)
				 gen  x_RF_pooledH_`approachw'_j    = (x_RF_pooledH_`approachw'_j2<0.`sigdigits')*100 
				 
				egen x_total_osig_weightp_`approachw'2  = total(weight_j) if x_RF_pooledH_`approachw'_j2!=.			if (pval_orig_j<0.`sigdigits')
				egen x_total_osig_weightp_`approachw'   = mean(x_total_osig_weightp_`approachw'2)					if (pval_orig_j<0.`sigdigits')
				egen x_RF_pooledH_`approachw'_osig_all  = total(x_RF_pooledH_`approachw'_j*weight_j)				if (pval_orig_j<0.`sigdigits')
				 gen   RF_pooledH_`approachw'_osig_all  = x_RF_pooledH_`approachw'_osig_all/x_total_osig_weightp_`approachw'	if (pval_orig_j<0.`sigdigits')   
				 
				egen x_total_onsig_weightp_`approachw'2 = total(weight_j) if x_RF_pooledH_`approachw'_j2!=.			if (pval_orig_j>=0.`sigdigits')
				egen x_total_onsig_weightp_`approachw'  = mean(x_total_onsig_weightp_`approachw'2)					if (pval_orig_j>=0.`sigdigits')
				egen x_RF_pooledH_`approachw'_onsig_all = total(x_RF_pooledH_`approachw'_j*weight_j)				if (pval_orig_j>=0.`sigdigits')
				 gen   RF_pooledH_`approachw'_onsig_all = x_RF_pooledH_`approachw'_onsig_all/x_total_onsig_weightp_`approachw'	if (pval_orig_j>=0.`sigdigits')   
			}
		}
		
		egen x_total_osig_weight_orig = total(weight_orig_j)			if (pval_orig_j<0.`sigdigits')
		gen  x_pval_orig_osig_j = pval_orig_j 							if (pval_orig_j<0.`sigdigits')
		egen   pval_orig_osig_all = total(x_pval_orig_osig_j*weight_orig_j/x_total_osig_weight_orig) if (pval_orig_j<0.`sigdigits')
			
		egen x_total_onsig_weight_orig = total(weight_orig_j)			if (pval_orig_j>=0.`sigdigits')
		gen  x_pval_orig_onsig_j = pval_orig_j							if (pval_orig_j>=0.`sigdigits')
		egen   pval_orig_onsig_all = total(x_pval_orig_onsig_j*weight_orig_j/x_total_onsig_weight_orig) if (pval_orig_j>=0.`sigdigits') 
			
		drop weight_*
	}
		
	drop beta_orig_dir_j  x_* 

	

************************************************************
***  PART 5.B  ROUNDING OF SHARES AND OTHER VARIABLES
************************************************************

	local roundtozerodigits   beta_rel_orig_j beta_rel_orig_osig_all beta_rel_orig_onsig_all   RF_stat_sig_j RF_stat_sig_osig_all RF_stat_sig_onsig_all   RF_stat_sig_ndir_j RF_stat_sig_ndir_osig_all RF_stat_sig_ndir_onsig_all   RF_relES2_j RF_relES2_osig_all RF_relES2_onsig_all   RF_relES2sd_j RF_relES2sd_osig_all RF_relES2sd_onsig_all   RF_relVAR_ES2_j RF_relVAR_ES2_osig_all RF_relVAR_ES2_onsig_all  	
	if `shelvedind'==1 {
		local roundtozerodigits   `roundtozerodigits'   RF_pooledH_A_osig_all RF_pooledH_A_onsig_all  RF_pooledH_B_osig_all RF_pooledH_B_onsig_all 
	}
	
	foreach var0 of local roundtozerodigits {
	    replace `var0'  = round(`var0')
	}
	
	ds `varlist' `roundtozerodigits', not
	foreach var2 in `r(varlist)' {
	    replace `var2'  = round(`var2', .01)
	}

	
	
************************************************************
***  PART 5.C  COMPILING REPRODUCIBILITY AND REPLICATION FRAMEWORK INDICATOR RESULTS 
************************************************************

	order beta_orig_j beta_orig_osig_all beta_orig_onsig_all  beta_rel_orig_j beta_rel_orig_osig_all beta_rel_orig_onsig_all  pval_orig_j pval_orig_osig_all pval_orig_onsig_all

	local reshapelist beta_orig_ beta_rel_orig_ pval_orig_   RF_stat_sig_  RF_relES_ RF_reltz_  RF_relVAR_ES_ RF_relVAR_tz_   RF_stat_sig_ndir_  RF_relES2_ RF_relES2sd_   RF_relVAR_ES2_  RF_stat_insig_	
	if `shelvedind'==1 { 
		local reshapelist `reshapelist'   RF_robratio_A_ RF_robratio_B_  RF_pooledH_A_ RF_pooledH_B_
	}
	rename *_osig_all  *_2
	rename *_onsig_all *_3	
	rename *_j    	   *_1
	
	reshape long `reshapelist', i(`varlist') j(level)
	rename *_ *
	 
	// drop empty rows that do not get dropped below under duplicates drop (indicators on originally sig. outcome estimates reported with originally insig. outcome estimates and vice versa)
						 gen x_pval_orig_d_i  = (pval_orig<0.`sigdigits') if level==1
	bysort `varlist':	egen x_pval_orig_d_j  = mean(x_pval_orig_d_i)
	drop if level==2 &  x_pval_orig_d_j==0
	drop if level==3 &  x_pval_orig_d_j==1
	drop x_*
	
	order RF_relES2sd, after(RF_relES2)
	
	decode `varlist', gen(outcome_str)
	replace outcome_str = "_All outcomes osig"  if level==2
	replace outcome_str = "_All outcomes onsig" if level==3
	
	decode `varlist', gen(header)
	replace header = "_All outcomes osig"  if level==2
	replace header = "_All outcomes onsig" if level==3
	if `osig_N'!=0 & `onsig_N'!=0 {
		local orderall _All_outcomes_osig _All_outcomes_onsig
	}
	if `osig_N'==0 & `onsig_N'!=0 {
		local orderall _All_outcomes_onsig
	}
	if `osig_N'!=0 & `onsig_N'==0 {
		local orderall _All_outcomes_osig
	}
	
	replace header = subinstr(header," ", "_",.)
	foreach badchar in . ( ) % : - $ {
		replace header = subinstr(header,"`badchar'", "",.)
	}
	
	drop `varlist' level    
	duplicates drop
	
	sort header
	levelsof header, local(headerlist) 
	qui tab header   // added because r(r) as stored result of levelsof was only added after Stata 14 
	local var_N = r(r)
	levelsof outcome_str, local(headerlablist)
	drop outcome_str
	
	xpose, clear varname
		
	forval i = 1/`var_N' {
	    local nextheaderlab: word `i' of `headerlablist' 
		label var v`i' "`nextheaderlab'"
		local nextheader: word `i' of `headerlist' 
		rename v`i' `nextheader'
	}
	drop if _varname=="header"
	
	order _varname
	rename _varname indicator
	order `orderall', last
	 
	ds indicator `orderall', not
	foreach var in `r(varlist)' {
		format `var' %9.2f
		local pval_orig_l = `var' in 3 
		if `pval_orig_l'<0.`sigdigits' {
			char  `var'[osig] 1  
		}
		if `pval_orig_l'>=0.`sigdigits' {
			char  `var'[onsig] 1 
		}
	}
	
	capture label var _All_outcomes_osig 	"All outcomes (sig. original)"
	capture label var _All_outcomes_onsig 	"All outcomes (insig. original)"
	ds, has(c osig)
	local  osiglist `r(varlist)' 
	ds, has(c onsig)
	local  onsiglist `r(varlist)' 
	if `onsig_N'==0 {
		order  indicator `osiglist'
	}
	if `onsig_N'!=0 {
		order  indicator `osiglist' _All_outcomes_osig `onsiglist'
	}
	
	*** indicators of indset 1	
	replace indicator = "Original beta estimate" 											if indicator=="beta_orig" 
	replace indicator = "Original beta estimate, expressed as % deviation from mean of the outcome" 	if indicator=="beta_rel_orig"
	replace indicator = "p-value of original estimate" 										if indicator=="pval_orig"
	replace indicator = "(1) Stat. significance - % of results (in same direction if original was stat. sig.)" 	if indicator=="RF_stat_sig"
	replace indicator = "(2) Relative effect size"				 							if indicator=="RF_relES"	
	replace indicator = "(3) Relative t/z-value"  											if indicator=="RF_reltz"
	replace indicator = "(4) Variation indicator: effect sizes"	 							if indicator=="RF_relVAR_ES"
    replace indicator = "(5) Variation indicator: t/z-value" 								if indicator=="RF_relVAR_tz"

	replace indicator = "(A1+) Stat. significance - % of results in opposite direction"  	if indicator=="RF_stat_sig_ndir"
	replace indicator = "(A2+) Relative effect size - deviation of median estimate as % of original result, if same direction"  		if indicator=="RF_relES2"
	replace indicator = "(A2b+) if aggregated: Relative effect size - s.d. of deviation of median estimate as % of original result, if same direction"  if indicator=="RF_relES2sd"
	replace indicator = "(A4+) Variation indicator - mean abs. deviation of estimates from median estimate, as % of original result" 	if indicator=="RF_relVAR_ES2"
	replace indicator = "(A5+) Variation indicator - mean abs. deviation of p-values of insig. reproducability or replication tests from original p-value" 	if indicator=="RF_stat_insig"

	if `shelvedind'==1 { 
		replace indicator = "(B1a) Robustness - sqrt of mean squared beta deviation divided by original s.e." 	if indicator=="RF_robratio_A"
		replace indicator = "(B1b) Robustness - sqrt of mean squared t/z-value deviation" 						if indicator=="RF_robratio_B"
		replace indicator = "(B2a) Pooled hypothesis test - z-statistic based on beta and se (inverse sign for negative original results)*" if indicator=="RF_pooledH_A"
		replace indicator = "(B2b) Pooled hypothesis test - z-statistic based on t/z-score (inverse sign for negative original results)*"    if indicator=="RF_pooledH_B"
	}	
	
	set obs `=_N+1'   // backward-compatible alternative to insobs 1 in order to add an observation at bottom of dataset to include notes
	replace indicator = "`shareosig' outcomes originally significant (`siglevelnum'% level)" if indicator==""
	
	if `shelvedind'==1 { 
		set obs `=_N+1'
		replace indicator = "* = if across all outcomes: Share in % of statistically significant outcomes (`siglevelnum'% level); for the pooled hypothesis tests, if same direction" if indicator==""
	}
	
	if `ivarweight'==1 {
		set obs `=_N+1'
		replace indicator = "Note: Indicators across outcomes are derived by weighting individual outcomes in inverse proportion to their variance" if indicator==""
	}
	
	export excel "`outputtable'", firstrow(varlabels) replace
	
	
	use `inputdata', clear
}	
end
*** End of file
