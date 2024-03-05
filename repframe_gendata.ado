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

	repframe_gendata requires version 14.0 of Stata or newer.
					
***  AUTHOR:	Gunther Bensch, RWI - Leibniz Institute for Economic Research, gunther.bensch@rwi-essen.de
*/	




cap program drop repframe_gendata

program define repframe_gendata
			
	syntax , STUDYPOOLing(numlist max=1 integer) 
	
	qui {
		if `studypooling'==0 {
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
		if `studypooling'==1 {
			clear
			
			*** input appended study-level indicator data as matrix
			matrix RFx = (6, 2, 5, 10, 2, .0082176356, .27517629, .68582135, .40483445, 370.49109, 1.4022906, 0, ., ., ., ., ., ., 2, 27.517628, .48344016, 3.3854551, 47.685406, .41954255, 31.95549, 65.533859, 55.159859, 0, ., ., ., ., ., ., ., 0, 3900, 7200\2, 5, 5, 10, 4, .022648577, .057499997, .22945449, .23103143, .63143605, .62807679, 1, .11389022, .38999999, ., ., 23.943708, .82998937, 3, 6.5, 1, -33.51984, 13.913999, .4823457, 11.589976, 97.550743, 2.5257518, 2, 32.25, 11.5, 0, .18320209, .069054969, 48.360657, 54.918034, 0, 200, 200\3, 4, 5, 10, 4, .00098652905, .26625001, .3186768, .45327455, .5366891, .60016006, 0, ., ., ., ., ., ., 4, 26.625, 0, -52.310844, 9.5202055, .2619305, 15.499557, 98.052307, 1.4927974, 0, ., ., ., ., ., ., ., 0, 200, 200\4, 2, 5, 10, 0, ., ., ., ., ., ., 2, .71760833, .4425, ., ., .90148735, .80527323, 0, ., ., ., ., ., ., ., ., 2, 49, ., 6.75, .47869346, .70261729, 100, 0, 0, 200, 200\5, 3, 5, 10, 3, .006592033, .0099999998, .035533853, .041855894, .69525707, .63315201, 0, ., ., ., ., ., ., 3, 1, 2, -29.474079, 10.946845, .43154976, 19.751516, 95.53067, 6.4313078, 0, ., ., ., ., ., ., ., 0, 200, 200\7, 3, 5, 10, 1, .032177683, 0, -.090766363, -.090731561, .51920128, .47109264, 2, .24948081, .73500001, ., ., 206.76668, .72556853, 1, 0, 0, ., ., .67627907, 18, 99, 31, 2, 26, ., .5, .28001302, .21931636, 100, 0, 0, 200, 200\1, 4, 5, 5, 4, .011543697, .86842108, .97206974, .9531936, .38703936, .31969121, 0, ., ., ., ., ., ., 4, 86.842102, 0, 3.0321226, 6.9325366, .045850128, 100, 90, 0, 0, ., ., ., ., ., ., ., 0, 7, 19)


			*** define variable names 
			matrix coln RFx = reflist outcomes_N siglevel_ra_stud siglevel_oa_stud osig_oa_out_N pval_orig_osig_oa_all RF_SIGagr_osig_oa_all RF_ESrel_osig_oa_all RF_SIGrel_osig_oa_all RF_ESvar_osig_oa_all RF_SIGvar_osig_oa_all onsig_oa_out_N pval_orig_onsig_oa_all RF_SIGagr_onsig_oa_all RF_ESrel_onsig_oa_all RF_SIGrel_onsig_oa_all RF_ESvar_onsig_oa_all RF_SIGvar_onsig_oa_all osig_ra_out_N RF2_SIGagr_osig_ra_all RF2_SIGagr_ndir_osig_ra_all RF2_ESrel_osig_ra_all RF2_ESvar_osig_ra_all RF2_SIGvar_nsig_osig_ra_all RF2_ESagr_osig_ra_all RF2_SIGsw_btonsig_osig_ra_all RF2_SIGsw_setonsig_osig_ra_all onsig_ra_out_N RF2_SIGagr_onsig_ra_all RF2_SIGagr_sigdef_onsig_ra_all RF2_SIGagr_ndir_onsig_ra_all RF2_SIGvar_nsig_onsig_ra_all RF2_SIGvar_sig_onsig_ra_all RF2_SIGsw_btosig_onsig_ra_all RF2_SIGsw_setosig_onsig_ra_all ivarweight_stud_d analysispaths_min_N analysispaths_max_N


			*** convert matrix to dataset
			svmat RFx, names(col)


			*** value labels
			label def reflist 1 "Study 1" 2 "Study 2" 3 "Study 3" 4 "Study 4" 5 "Study 5" 6 "Study 6" 7 "Study 7", modify
			label val reflist reflist

			label def dummy 0 "no" 1 "yes"
			label val ivarweight_stud_d dummy 
			
			
			*** variable labels, as assigned in PART 4, INDICATOR DATASET AT STUDY LEVEL of repframe.ado
			local label_osig_oa_all  	", across studies (originally significant wrt OA sig. level)"
			local label_onsig_oa_all 	", across studies (originally insignificant wrt OA sig. level)"

			local label_osig_ra_all  	", across studies (originally significant wrt REP sig. level)"
			local label_onsig_ra_all 	", across studies (originally insignificant wrt REP sig. level)"

			label var reflist 			"Study reference"

			foreach unit in osig_oa_all onsig_oa_all {
				capture label var pval_orig_`unit'	"p-value of original estimate`label_`unit''" 
				label var RF_SIGagr_`unit' 	"(RF.1) Significance agreement`label_`unit''"
				label var RF_ESrel_`unit'	"(RF.2) Relative effect size`label_`unit''"	
				label var RF_SIGrel_`unit' 	"(RF.3) Relative significance`label_`unit''"
				label var RF_ESvar_`unit' 	"(RF.4) Effect sizes variation`label_`unit''"
				label var RF_SIGvar_`unit' 	"(RF.5) Significance variation`label_`unit''"
			}	

			foreach unit in osig_ra_all {
				label var RF2_SIGagr_`unit' 		"(RF2.1) Significance agreement`label_`unit''"
				label var RF2_SIGagr_ndir_`unit' 	"(RF2.2) Significance agreement`label_`unit''"
				label var RF2_ESrel_`unit' 			"(RF2.3) Relative effect size`label_`unit''"
				label var RF2_ESvar_`unit'			"(RF2.4) Effct size variation`label_`unit''"
				label var RF2_SIGvar_nsig_`unit' 	"(RF2.5) Significance Variation for insig. rep. results`label_`unit''"
				label var RF2_ESagr_`unit'			"(RF2.6) Effect size agreement`label_`unit''"
				label var RF2_SIGsw_btonsig_`unit'  "(RF2.7a) Significance switch (beta)`label_`unit''"	
				label var RF2_SIGsw_setonsig_`unit' "(RF2.7b) Significance switch (se)`label_`unit''"	
			}

			foreach unit in onsig_ra_all {
				label var RF2_SIGagr_`unit' 		"(RF2.1) Significance agreement`label_`unit''"
				label var RF2_SIGagr_sigdef_`unit'	"(RF2.1+) Significance agreement (insig. because of less stringent OA sig. definition)`label_`unit''"
				label var RF2_SIGagr_ndir_`unit' 	"(RF2.2) Significance agreement`label_`unit''"
				label var RF2_SIGvar_nsig_`unit' 	"(RF2.5) Significance Variation for insig. rep. results`label_`unit''"
				label var RF2_SIGvar_sig_`unit' 	"(RF2.5) Significance Variation for sig. rep. results`label_`unit''"
				label var RF2_SIGsw_btosig_`unit'	"(RF2.7a) Significance switch (beta)`label_`unit''"
				label var RF2_SIGsw_setosig_`unit'	"(RF2.7b) Significance switch (se)`label_`unit''"
			}


			label var outcomes_N  "Number of outcomes studied"
			
			foreach set in oa ra {
				label var osig_`set'_out_N   "Number of outcomes in original study with stat. significant estimate according to sig. level of `set' analysis"
				label var onsig_`set'_out_N  "Number of outcomes in original study with stat. insignificant estimate according to sig. level of `set' analysis"
			}
			
			label var siglevel_oa_stud  "Significance level of two-sided test applied to original study / by original author(s)"
			label var siglevel_ra_stud  "Significance level of two-sided test applied in reproducability or replicability analyses of study"
			
			label var ivarweight_stud_d "Outcomes in study weighted by the inverse variance"
			label var analysispaths_min_N  "Minimum number of analysis paths studied (across outcomes)"
			label var analysispaths_max_N  "Maximum number of analysis paths studied (across outcomes)"
		}
	}
end
