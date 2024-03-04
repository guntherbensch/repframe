/*
*** PURPOSE:	
	This Stata command exemplifies how to run multiple specifications for a multiverse analysis and store the estimates as a dataset 
	including information on
		- the outcome
		- the beta coefficient of the multiple analysis paths
		- the related standard error (se)
		- the various decision choices taken (beyond the outcome, if applicable), for example on the set of covariates
		- additional parameters, such as the number of observation and the outcome mean

	The command is applied in the help file of the command -repframe-, where it is applied to data from the
	second US National health and Nutrition Examination Survey (NHANES II), 1976-1980, made available by
	A.C.Cameron & P.K.Trivedi (2022): Microeconometrics Using Stata, 2e, under http://www.stata-press.com/data/mus2/mus206nhanes.dta.
	The specific choices for the different analytical decisions made below do not all represent justifiable decisions for a multiverse analysis
	but partly have the purpose of retrieving a Sensitivity Dashboard that shows three outcomes with varying indicator outputs while presenting
	different ways to include certain analytical decisions into to Stata loop for estimation.    

	repframe_gendata requires version 12.0 of Stata or newer.
					
***  AUTHOR:	Gunther Bensch, RWI - Leibniz Institute for Economic Research, gunther.bensch@rwi-essen.de
*/	




cap program drop repframe_gendata

program define repframe_gendata
			
	syntax
	
	qui {
		*** Set main locals 
		local panel_list   outcome_vs cov1 cov2 cov3 cov4 ifcond
		local m_max = 3*(1^1*2^4*3^1)   // 1 decision with 1 choice (outcome_vs), 4 with 2, and 1 with 3 (ifcond)
		local n_max = 13		// # entries for each of the estimation results: outcome - beta_wgt - se_wgt - outcome_mean - N (outcome var) - df_wgt - outcome_vs - cov1 - cov2 - cov3 - cov4 - ifcond - pval_wgt
		matrix R = J(`m_max', `n_max', .)   				
		local R_matrix_col outcome beta_wgt se_wgt outcome_mean_wgt N df_wgt `panel_list' pval_wgt
		matrix coln R =  `R_matrix_col'
		
			
		local i = 1
		local j = 1


		*** make datset-specific adjustments 
		
		** keep necessary data
		keep strata psu region location age height weight bpsystol bpdiast hlthstat diabetes finalwgt leadwt vitaminc lead female black orace hsizgp rural loglead highbp highlead

		** make some random sample restrictions 
		keep if region==1 | region==2 

		** choose outcomes 
		rename highlead lead_vs1    
		*rename lead     lead_vs2 // not used as these alternative outcomes are in different units
		*rename loglead  lead_vs3
		*rename highbp   bp_vs1
		*rename bpdiast  bp_vs2
		*rename bpsystol bp_vs3
		rename vitaminc vitaminc_vs1
		gen hlthstat_vs1 = (hlthstat==1 | hlthstat==2)

		rename finalwgt weight_hlthstat
		rename leadwt   weight_lead
		clonevar weight_vitaminc = weight_hlthstat


		** run estimations and retrieve estimates
		foreach outcome in hlthstat lead vitaminc {
			local lastvs 1
			if "`outcome'"=="vitaminc" {
				local lastvs 1
			}
			forval outcome_vs = 1(1)`lastvs' {
				foreach cov1 in "" "age black orace" {
					foreach cov2 in "" "height" {
						foreach cov3 in "" "i.hsizgp" {
							foreach cov4 in "" "rural" {
								foreach ifcond in "if region==1" "" "if region==1 & diabetes!=1 & female!=1 & black!=1" {
									svyset psu [pweight=weight_`outcome'], strata(strata)
									svy: reg `outcome'_vs`outcome_vs' weight `cov1' `cov2' `cov3' `cov4' i.location `ifcond'
							
									foreach var of local panel_list {
										estadd scalar `var' = 0
									}
										
									estadd scalar outcome_vs = `outcome_vs', replace
				
									if "`cov1'"=="age black orace" {
										estadd scalar cov1 = 1, replace
									}	
									if  "`cov2'"=="height" {
										estadd scalar cov2 = 1, replace
									}
									if  "`cov3'"=="i.hsizgp" {
										estadd scalar cov3 = 1, replace
									}
									if  "`cov4'"=="rural" {
										estadd scalar cov4 = 1, replace
									}
									if  "`ifcond'"=="" {
										estadd scalar ifcond = 1, replace
									}
										if  "`ifcond'"=="if region==1 & diabetes!=1 & female!=1 & black!=1" {
										estadd scalar ifcond = 2, replace
									}
									
									test weight
									estadd scalar pval = `r(p)'

									sum `outcome'_vs`outcome_vs' if e(sample)==1   // in this specific example only would actually have to account for svy, e.g. via -svy: mean- 
									matrix R[`i',1] = `j', _b[weight], _se[weight], r(mean), r(N), e(df_r), e(outcome_vs), e(cov1), e(cov2), e(cov3), e(cov4), e(ifcond), e(pval)
									local i = `i' + 1								
									
								}
							}
						}
					}
				}			
			}
			local j = `j' + 1
		}
		
		
		*** create multiverse dataset
		svmat R, names(col)
		keep `R_matrix_col'
		
		label define outcome    1 "excellent or very good health status" 2 "blood lead level" 3 "Vitamic C"
		label val outcome outcome   	
		
		egen nmiss=rmiss(*)
		drop if nmiss==`n_max'	
		drop nmiss

		*** define original estimate
			// here (random choice): - outcome_vs==1 & cov1==1 & cov2==0 & cov3==1 & cov4==1 & ifcond==0 -
		foreach var in beta se pval outcome_mean df {
			bysort outcome:  gen `var'_wgt_orig_x = `var'_wgt if outcome_vs==1 & cov1==1 & cov2==0 & cov3==1 & cov4==1 & ifcond==0
			bysort outcome: egen `var'_wgt_orig   = mean(`var'_wgt_orig_x)
		}
		drop if outcome_vs==1 & cov1==1 & cov2==0 & cov3==1 & cov4==1 & ifcond==0 // original estimate is not supposed to be part of the multiverse
		drop *_x

		*** shorten varnames as the {stata ""} option in the stata help file only allows for a certain number of characters 
		rename outcome_mean_wgt			out_mn
		rename outcome_mean_wgt_orig	out_mn_og 
		rename beta_wgt					b
		rename beta_wgt_orig			b_og
		rename se_wgt  					se
		rename se_wgt_orig				se_og  
		rename pval_wgt					p
		rename pval_wgt_orig			p_og
		rename df_wgt					df
		rename df_wgt_orig				df_og
	}

end
