/*
*** PURPOSE:	
	This Stata do-file contains the program repframe to calculate Reproducibility and Replication Framework Indicators for multiverses of replication estimates.
	repframe requires version 14.0 of Stata or newer.

	
*** OUTLINE:	PART 1.  INITIATE PROGRAM REPFRAME
			
				PART 2.  AUXILIARY VARIABLE GENERATION

				PART 3.  INDICATOR DEFINITIONS
				
				PART 4.  REPRODUCIBILITY AND REPLICATION FRAMEWORK INDICATOR RESULTS

					
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
[outputfile(string)] [siglevel(numlist max=1 integer)]  
[df(varname numeric) df_orig(varname numeric)] [mean(varname numeric)] [mean_orig(varname numeric)] 
[beta2(varname numeric) beta2_orig(varname numeric)] 
[orig_in_multiverse(numlist max=1 integer)] [ivarweight(numlist max=1 integer)] [sameunits(varname numeric)] [indset(numlist max=1 integer)];

#delimit cr


qui {
	
	preserve
	
*** implement [if] and [in] condition
	marksample to_use
	qui keep if `to_use' == 1
  
*** keep variables needed for the dashboard
	keep `varlist' `beta' `beta_orig'   `se' `se_orig' `pval' `pval_orig' `zscore' `zscore_orig'   `mean' `mean_orig' `beta2' `beta2_orig' `sameunits'
	
		
	
	
********************************************************************************
*****  PART 2  AUXILIARY VARIABLE GENERATION
********************************************************************************			
		
*** add _j suffix to beta_orig (and below to se_orig) to make explicit that this is information at the outcome level 
		// the suffix _j refers to the outcome level, _i to the specification level
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
	if ("`indset'"!="" & "`indset'"!="1" & "`indset'"!="2") {
		noi dis "{red: If {it:indset} is defined, it needs to take on the value 1 (main Indicator set) or 2 (alternative Indicator set)}"	
		exit
	}
	if "`indset'"=="" {
		local indset = 1
	}
	
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
		exit
	}
	if "`orig_in_multiverse'"=="" {
		local orig_in_multiverse = 0
	}
	
	if ("`ivarweight'"!="" & "`ivarweight'"!="0" & "`ivarweight'"!="1") {
		noi dis "{red: If {it:ivarweight} is defined, it needs to take on the value 0 (no) or 1 (yes)}"	
		exit
	}
	if "`ivarweight'"=="" {
		local ivarweight = 0
	}
	if `ivarweight'==1 & (mean_j==. | mean_orig_j==.) {
		noi dis "{red: The option {it:ivarweight(1)} requires that the options {it:mean(varname)} and {it:mean_orig(varname)} are also defined}"
		exit
	}
	if "`sameunits'"=="" {
		gen sameunits_i = 1
	}
	else {
		gen sameunits_i = `sameunits'
		drop `sameunits'
	}
	
	** optional syntax components related to cases with second estimates
	if ("`beta2'"!="" & ("`se2'"=="" & "`pval2'"=="" & "`zscore2'"=="")) {
		noi dis "{red: If {it:beta2()} is specified, please also specify either {it:se2()}, {it:pval2()}, or {it:zscore2()}.}"	
		exit
	}
	if ("`beta2_orig'"!="" & ("`se2_orig'"=="" & "`pval2_orig'"=="" & "`zscore2_orig'"=="")) {
		noi dis "{red: If {it:beta2_orig()} is specified, please also specify either {it:se2_orig()}, {it:pval2_orig()}, or {it:zscore2_orig()}.}"	
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
		
		replace zscore_i  = zscore_i*-1  if beta_orig_dir_j==-1 // if two coefficients in a robustness test analysis, t/z-value for each must be assigned a positive (negative) sign if coefficient is in the same (opposite) direction as the original coefficient (assumes that there is only one original coefficient)
		replace zscore2_i = zscore2_i*-1 if beta_orig_dir_j==-1
		
		replace zscore_i = (zscore_i+zscore2_i)/2  // if two coefficients in a robustness test analysis, zscore should be calculated as average of two zscores		
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
		gen pval2_orig_j = 2*(1 - normal(abs(beta2_orig_j/se2_orig_j)))
	}
	if "`pval2_orig'"=="" & "`df_orig'"!="" & "`beta2_orig'"!="" {
		gen pval2_orig_j = 2*ttail(`df_orig', abs(beta2_orig_j/se2_orig_j))
	}
	if "`pval2_orig'"!="" {
		gen pval2_orig_j = `pval2_orig'
		drop `pval2_orig'
	}
		
	if "`beta2_orig'"!="" {
		gen beta2_orig_j = `beta2_orig'
		drop `beta2_orig'
	}
	else {
		gen beta2_orig_j = .
	}
	
	
*** additional variable generation, e.g. on the effect direction and the relative effect size based on the raw dataset	
	gen beta_rel_i       = `beta'/mean_j*100
	gen se_rel_i          = se_i/mean_j
	
	gen beta_rel_orig_j = beta_orig_j/mean_orig_j*100
	gen se_rel_orig_j   = se_orig_j/mean_orig_j

	
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
	
	
	
	
********************************************************************************
*****  PART 3  INDICATOR DEFINITIONS 
********************************************************************************
	
************************************************************
***  PART 3.A  INDICATORS BY OUTCOME
************************************************************	
		
	if `indset'==1 {
		** 1. Statistical significance indicator
						   gen x_RF_stat_sig_i = (pval_i<0.`sigdigits' ///
												  & beta_dir_i==beta_orig_dir_j)*100	if (pval_orig_j<0.`sigdigits')  & "`beta2'"==""
					   replace x_RF_stat_sig_i = (pval_i>=0.`sigdigits')*100			if (pval_orig_j>=0.`sigdigits') & "`beta2'"==""
					   
		if  "`beta2'"!="" {
					   replace x_RF_stat_sig_i = (pval_i<0.`sigdigits' ///
												  & beta_dir_i==beta_orig_dir_j ///
												  & pval2_i<0.`sigdigits' ///
												  & beta2_dir_i==beta_orig_dir_j)*100	if (pval_orig_j<0.`sigdigits')  
						   // if two coefficients and if the original results was significant, both coefficients need to be significant in the original direction  
					   replace x_RF_stat_sig_i = (pval_i>=0.`sigdigits' | (pval2_i>=0.`sigdigits' & pval2_i<.)*100	if (pval_orig_j>=0.`sigdigits')   
						   // if two coefficients and if the original result was a null result, at least one of the two coefficients need to be insignificant    
		}
					   
		bysort `varlist': egen   RF_stat_sig_j = mean(x_RF_stat_sig_i) 						  	 
				
						   
		** 2. Relative effect size 
			// only for original results reported as statistically significant at the 0.`sigdigits' level
			// only for sameunits_i==1 & beta2_orig_j==.
		bysort `varlist': egen x_RF_relES_j = mean(`beta')   							if (pval_orig_j<0.`sigdigits') & sameunits_i==1 & beta2_orig_j==.
						   gen   RF_relES_j = x_RF_relES_j/beta_orig_j

						   
		** 3. Relative t/z-value
			// only for original results reported as statistically significant at the 0.`sigdigits' level
						   gen x_RF_reltz_i = zscore_i/zscore_orig_j
		bysort `varlist': egen   RF_reltz_j = mean(x_RF_reltz_i)   						if (pval_orig_j<0.`sigdigits')
		
	
		*** preparation for Variation Indicators 4 and 5: add original estimate as additional observation if included as one analysis path in the multiverse robustness test
		if `orig_in_multiverse'==1 {
			bysort `varlist': gen outcome_n = _n
			expand 2 if outcome_n==1, gen(add_orig)

			gen     x_beta_i_vi   = `beta' 
			replace x_beta_i_vi   = beta_orig_j   if add_orig==1
			gen 	x_zscore_i_vi = zscore_i
			replace x_zscore_i_vi = zscore_orig_j if add_orig==1
		}
		else {
			gen     x_beta_i_vi   = `beta'
			gen     x_zscore_i_vi = zscore_i
		}
		
		
		** 4. Variation indicator: effect sizes
			// only for sameunits_i==1 & beta2_orig_j==.
		bysort `varlist': egen x_RF_relVAR_ES_j = sd(x_beta_i_vi)						if sameunits_i==1 & beta2_orig_j==.
						   gen   RF_relVAR_ES_j = x_RF_relVAR_ES_j/se_orig_j        
		
		
		** 5. Variation indicator: t/z-value
		bysort `varlist': egen   RF_relVAR_tz_j = sd(x_zscore_i_vi)	

		
		if `orig_in_multiverse'==1 {
			drop if add_orig==1  // better remove these added observations before collapsing as they have incomplete information
			drop outcome_n add_orig
		}
						   
		local collapsefirst RF_stat_sig_j
		local collapselast  RF_relVAR_tz_j
	}
	
	** alternative indicators					  
	if `indset'==2 {
		gen x_RF_stat_sig_dir_i = (pval_i<0.`sigdigits' & beta_dir_i==beta_orig_dir_j)*100	    
		bysort `varlist': egen   RF_stat_sig_dir_j = mean(x_RF_stat_sig_dir_i) 	
		
						   gen x_RF_stat_sig_ndir_i	= (pval_i<0.`sigdigits' & beta_dir_i!=beta_orig_dir_j)*100
		bysort `varlist': egen   RF_stat_sig_ndir_j	= mean(x_RF_stat_sig_ndir_i) 
		
		
		bysort `varlist': egen x_RF_relES_C_j2 	= median(`beta')	 			if pval_i<0.`sigdigits' & beta_dir_i==beta_orig_dir_j						
						   gen x_RF_relES_C_j 	= x_RF_relES_C_j2/beta_orig_j 
						   gen   RF_relES_C_j 	= ((x_RF_relES_C_j) - 1)*100

						   gen RF_relES_Csd_j = .
								
									
						   gen x_RF_robratio_C_i = abs(`beta'-x_RF_relES_C_j2) 	    	
		bysort `varlist': egen x_RF_robratio_C_j = mean(x_RF_robratio_C_i)     	if pval_i<0.`sigdigits' & beta_dir_i==beta_orig_dir_j
						   gen   RF_robratio_C_j = (x_RF_robratio_C_j/abs(beta_orig_j))*100
		
		
						  gen x_RF_stat_insig_i 	= abs(pval_i-pval_orig_j)					if pval_i>=0.`sigdigits'
		bysort `varlist': egen  RF_stat_insig_j 	= mean(x_RF_stat_insig_i)
		
		
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
					   
		local collapsefirst RF_stat_sig_dir_j
		local collapselast  RF_pooledH_B_j 
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
	ds `collapsefirst' - `collapselast'   
	foreach var in `r(varlist)' {
		bysort outcome: egen c`var' = min(`var') 
		drop `var'
		rename c`var' `var'
	}
	
	bysort outcome: gen n_j = _n
	
	keep if n_j==1
	drop n_j  `beta' se_i pval_i beta_dir_i beta_rel_i se_rel_i zscore_i  `df'   // drop information at a different level than the aggregated level
	drop      se_orig_j   mean_j mean_orig_j se_rel_orig_j zscore_orig_j `df_orig' beta2_orig_j sameunits_i	// drop information not required anymore
	 
	 
	
************************************************************
***  PART 3.B  INDICATORS OVER ALL OUTCOMES
************************************************************ 
		 
	gen    beta_orig_osig_all = .
	gen    beta_orig_onsig_all = .
	gen    beta_rel_orig_osig_all = .
	gen    beta_rel_orig_onsig_all = .
	
	if `indset'==1 {
		local RF_ind_list 	stat_sig relES reltz relVAR_ES relVAR_tz
	}
	if `indset'==2 {
		local RF_ind_list 	stat_sig_dir stat_sig_ndir relES_C robratio_C stat_insig robratio_A robratio_B
	}
			
	if `ivarweight'==0 {
		foreach RF_ind of local RF_ind_list {
			egen RF_`RF_ind'_osig_all  = mean(RF_`RF_ind'_j) if (pval_orig_j<0.`sigdigits')
			egen RF_`RF_ind'_onsig_all = mean(RF_`RF_ind'_j) if (pval_orig_j>=0.`sigdigits')
		}
	
		if `indset'==2 {
			egen RF_relES_Csd_osig_all   = sd(RF_relES_C_j) if (pval_orig_j<0.`sigdigits')
			egen RF_relES_Csd_onsig_all  = sd(RF_relES_C_j) if (pval_orig_j>=0.`sigdigits') 
						
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
			
		if `indset'==2 {
			gen RF_relES_Csd_osig_all   = .   // formula may be added
			gen RF_relES_Csd_onsig_all  = .
		
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
***  PART 3.C  ROUNDING OF SHARES AND OTHER VARIABLES
************************************************************

	if `indset'==1 {
		local roundtozerodigits   beta_rel_orig_j beta_rel_orig_osig_all beta_rel_orig_onsig_all   RF_stat_sig_j RF_stat_sig_osig_all RF_stat_sig_onsig_all   
	}
	if `indset'==2 {
		local roundtozerodigits   beta_rel_orig_j beta_rel_orig_osig_all beta_rel_orig_onsig_all   RF_stat_sig_dir_j RF_stat_sig_dir_osig_all RF_stat_sig_dir_onsig_all   RF_stat_sig_ndir_j RF_stat_sig_ndir_osig_all RF_stat_sig_ndir_onsig_all   RF_relES_C_j RF_relES_C_osig_all RF_relES_C_onsig_all   RF_relES_Csd_j RF_relES_Csd_osig_all RF_relES_Csd_onsig_all   RF_robratio_C_j RF_robratio_C_osig_all RF_robratio_C_onsig_all  RF_pooledH_A_osig_all RF_pooledH_A_onsig_all  RF_pooledH_B_osig_all RF_pooledH_B_onsig_all 
	}
	
	foreach var0 of local roundtozerodigits {
	    replace `var0'  = round(`var0')
	}
	
	ds outcome `roundtozerodigits', not
	foreach var2 in `r(varlist)' {
	    replace `var2'  = round(`var2', .01)
	}

	
	
	
************************************************************
***  PART 4  REPRODUCIBILITY AND REPLICATION FRAMEWORK INDICATOR RESULTS 
************************************************************

	order beta_orig_j beta_orig_osig_all beta_orig_onsig_all  beta_rel_orig_j beta_rel_orig_osig_all beta_rel_orig_onsig_all  pval_orig_j pval_orig_osig_all pval_orig_onsig_all

	if `indset'==1 {
		local reshapelist beta_orig_ beta_rel_orig_ pval_orig_   RF_stat_sig_  RF_relES_ RF_reltz_  RF_relVAR_ES_ RF_relVAR_tz_   
	}
	if `indset'==2 { 
		local reshapelist beta_orig_ beta_rel_orig_ pval_orig_   RF_stat_sig_dir_ RF_stat_sig_ndir_  RF_relES_C_ RF_relES_Csd_   RF_robratio_C_  RF_stat_insig_  RF_robratio_A_ RF_robratio_B_  RF_pooledH_A_ RF_pooledH_B_
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
	
	if `indset'==2 {
		order RF_relES_Csd, after(RF_relES_C)
	}
	
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
	replace indicator = "p-value of original estimate*" 									if indicator=="pval_orig"
	if `indset'==2 {
		replace indicator = "p-value of original estimate" 									if indicator=="pval_orig"
	}
	replace indicator = "(1) Stat. significance - % of results (in same direction if original was stat. sig.)" 	if indicator=="RF_stat_sig"
	replace indicator = "(2) Relative effect size"				 							if indicator=="RF_relES"	
	replace indicator = "(3) Relative t/z-value"  											if indicator=="RF_reltz"
	replace indicator = "(4) Variation indicator: effect sizes"	 							if indicator=="RF_relVAR_ES"
    replace indicator = "(5) Variation indicator: t/z-value" 								if indicator=="RF_relVAR_tz"

	*** indicators of indset 2
	replace indicator = "(A1) Stat. significance - % of results in same direction" 			if indicator=="RF_stat_sig_dir"
	replace indicator = "(A2) Stat. significance - % of results in opposite direction"  	if indicator=="RF_stat_sig_ndir"
	replace indicator = "(A3) Point estimate - deviation of median estimate as % of original result, if same direction"  if indicator=="RF_relES_C"
	replace indicator = "(A3b) if aggregated: Point estimate - s.d. of deviation of median estimate as % of original result, if same direction"  if indicator=="RF_relES_Csd"
	replace indicator = "(A4) Variability - mean abs. deviation of replication results from median estimate, as % of original result" 	if indicator=="RF_robratio_C"
	replace indicator = "(A5) Stat. insignificance - mean abs. deviation of p-values of insig. replications from original p-value" 	if indicator=="RF_stat_insig"
	replace indicator = "(B1a) Robustness - sqrt of mean squared beta deviation divided by original s.e." 	if indicator=="RF_robratio_A"
	replace indicator = "(B1b) Robustness - sqrt of mean squared t/z-value deviation" 						if indicator=="RF_robratio_B"
	replace indicator = "(B2a) Pooled hypothesis test - z-statistic based on beta and se (inverse sign for negative original results)*" if indicator=="RF_pooledH_A"
	replace indicator = "(B2b) Pooled hypothesis test - z-statistic based on t/z-score (inverse sign for negative original results)*"    if indicator=="RF_pooledH_B"
	
	
	insobs 1  // add an observation at bottom of dataset to include notes
	replace indicator = "`shareosig' outcomes originally significant (`siglevelnum'% level)" if indicator==""
	insobs 1
	replace indicator = "* = if across all outcomes: Share in % of statistically significant outcomes (`siglevelnum'% level); for the pooled hypothesis tests, if same direction" if indicator==""
	if `ivarweight'==1 {
		insobs 1
		replace indicator = "Note: Indicators across outcomes are derived by weighting individual outcomes in inverse proportion to their variance" if indicator==""
	}
	
	if "`outputfile'"!="" {
		export excel "`outputfile'", firstrow(variables) replace keepcellfmt
	}
	else {
		if c(os)=="Windows" {
			export excel "C:/Users/`c(username)'/Downloads/reproframe_indicators.csv", firstrow(variables) replace keepcellfmt 
		}
		else {
			export excel "~/Downloads/reproframe_indicators.csv", firstrow(variables) replace keepcellfmt
		}
	}
	
	restore
}	
end
*** End of file
