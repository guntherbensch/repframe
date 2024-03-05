{smcl}
{findalias asfradohelp}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[R] help" "help help"}{...}
{viewerjumpto "Syntax" "repframe##syntax"}{...}
{viewerjumpto "Description" "repframe##description"}{...}
{viewerjumpto "Options" "repframe##options"}{...}
{viewerjumpto "Remarks" "repframe##remarks"}{...}
{viewerjumpto "Examples" "repframe##examples"}{...}
{hi:help repframe}{...}
{right:}
{hline}

{title:Title}

{phang}
{bf:repframe} {hline 2} Calculate, tabulate and visualize Reproducibility and Replicability Indicators

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:repframe}
{it:mainvar}
{ifin}
{cmd:,} [{it:parameters required in study-level analyses}] [{it:semi-optional parameters}] [{it:optional parameters}]

{pstd}
where {cmd:mainvar} is the name of the labelled variable that specifies either{p_end}
{p 8 17 2}- the outcome(s) studied in a single reproducibility or replicability analysis study, or{p_end}
{p 8 17 2}- the study references of reproducibility or replicability analyses studies, if to be pooled across studies ({cmd:studypooling(1)}).{p_end}


{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:parameters required in analyses at study level {help repframe##options:[+]}}
{synopt:{opt beta(varname)}}beta coefficients in analysis paths of robustness tests{p_end}
{synopt:{opt beta_orig(varname)}}original beta coefficient for respective outcome{p_end}
{synopt:{opt siglevel(#)}}significance level{p_end}
{synopt:{opt siglevel_orig(#)}}maximum significance level labelled as statically significant by original authors{p_end}
{synopt:{opt shortref(string)}}short study reference{p_end}

{syntab:parameters being semi-optional in analyses at study level {help repframe##dsemioptional_para:[+]}}
{synopt:{opt pval(varname)}}{it:p}-values on statistical significance of estimates in analysis paths of robustness tests{p_end}
{synopt:{opt pval_orig(varname)}}{it:p}-values on statistical significance of original estimate for respective outcome{p_end}
{synopt:{opt se(varname)}}standard errors of beta coefficients in analysis paths of robustness tests{p_end}
{synopt:{opt se_orig(varname)}}standard errors of the original beta coefficient for respective outcome{p_end}
{synopt:{opt zscore(varname)}}{it:t}/{it:z} scores of estimates in analysis paths of robustness tests{p_end}
{synopt:{opt zscore_orig(varname)}}{it:t}/{it:z} scores of original estimates for respective outcome{p_end}

{syntab:optional parameters {help repframe##optional_para:[+]}}
{synopt:{opt studypool:ing(0/1)}}pool Reproducibility and Replicability Indicators across studies{p_end}
{synopt:{opt df(varname)}}degrees of freedom in analysis paths of robustness tests{p_end}
{synopt:{opt df_orig(varname)}}degrees of freedom in the original study outcome{p_end}
{synopt:{opt mean(varname)}}mean of the outcome variables in the analysis paths of robustness tests{p_end}
{synopt:{opt mean_orig(varname)}}mean of the outcome variables in the original study{p_end}
{synopt:{opt sameunits(varname)}}indicator on whether original study and analysis paths of robustness tests use same effect size units{p_end}
{synopt:{opt filepath(string)}}file storage location{p_end}
{synopt:{opt fileid:entifier(string)}}file version identifier{p_end}
{synopt:{opt orig_in_multiverse(0/1)}}original analysis is part of multiverse robustness test{p_end}
{synopt:{opt ivarw:eight(0/1)}}show Reproducibility and Replicability Indicators across all outcomes weighted by the inverse variance{p_end}

{syntab:optional parameters related to table of Reproducibility and Replicability Indicators {help repframe##optional_para_RRI:[+]}}
{synopt:{opt shelvedind(0/1)}}shelved Reproducibility and Replicability Indicators to be additionally shown{p_end}
{synopt:{opt beta2(varname)}}second beta coefficients in analysis paths of robustness tests{p_end}
{synopt:{opt pval2(varname)}}{it:p}-values on second estimates in analysis paths of robustness tests{p_end}
{synopt:{opt se2(varname)}}standard errors of second beta coefficients in analysis paths of robustness tests{p_end}
{synopt:{opt zscore2(varname)}}{it:t}/{it:z} scores of second beta coefficients in analysis paths of robustness tests{p_end}
{synopt:{opt beta2_orig(varname)}}original second beta coefficient for the respective outcome{p_end}
{synopt:{opt pval2_orig(varname)}}{it:p}-values on second estimates in analysis paths of robustness tests{p_end}
{synopt:{opt se2_orig(varname)}}standard errors of second beta coefficients in analysis paths of robustness tests{p_end}
{synopt:{opt zscore2_orig(varname)}}{it:t}/{it:z} scores of second beta coefficients in analysis paths of robustness tests{p_end}

{syntab:optional parameters related to Sensitivity Dashboard {help repframe##optional_para_SensDash:[+]}}
{synopt:{opt sensd:ash(0/1)}}create Sensitivity Dashboard{p_end}
{synopt:{opt vshortref_orig(string)}}very short reference to original study{p_end}
{synopt:{opt extended(string)}}show indicators from extended set of Reproducibility and Replicability Indicators in the dashboard{p_end}
{synopt:{opt aggregation(0/1)}}show outcomes in the dashboard aggregated across outcomes instead of individually{p_end}
{synopt:{opt graphfmt(string)}}file format of Sensitivity Dashboard graph{p_end}
{synopt:{opt ivF(varname)}}first-stage {it:F}-Statistics, if IV/2SLS estimations{p_end}
{synopt:{opt signfirst(varname)}}share of first stages with wrong sign{p_end}
{synoptline}
{p2colreset}{...}

			
{marker description}{...}
{title:Description}

{pstd}
{cmd:repframe} calculates Reproducibility and Replicability Indicators to compare estimates from a multiverse of analysis paths 
of robustness tests - be they reproducibility or replicability analyses - to the original estimate(s).
The command can be applied to calculate indicators across outcomes of a single study or alternatively across studies, the latter requiring the option {cmd:studypooling(1)}.  
The command produces three outputs: 
first, a table with the main set of indicators. 
Second, a so-called Sensitivity Dashboard that visualizes a second set of indicators.
Third - if the analysis is at the study level -, a dataset with study-level indicators that is ready to be re-introduced into the command using the option {cmd:studypooling(1)}.  
The required data structure and the output data with the different indicators is described in the {help repframe##see_also:online Readme on GitHub}.{p_end}


{marker options}{...}
{title:Options}

{dlgtab:parameters required in analyses at study level}

{phang}
{opt beta(varname)} specifies the variable {it:varname} that includes the beta coefficients in analysis paths of robustness tests at study level.

{phang}
{opt beta_orig(varname)} specifies the variable {it:varname} that includes the original beta coefficient for the respective outcome at study level.

{phang}
{opt siglevel(#)} gives the significance level for two-sided tests at study level; {cmd:siglevel(5)}, for example, stands for a 5% level.

{phang}
{opt siglevel_orig(#)} gives the maximum level of statistical significance labelled as statically significant by original authors, assuming two-sided tests; 
if specified, original results will be classified as statistically significant against this benchmark; 
{cmd:siglevel_orig(5)}, for example, stands for a 5% level applied by original authors. 

{phang}
{opt shortref(string)} provides a short reference in string format for the study, such as "[first author] et al. (year)".
This reference can either be a reference to the original study or to the reproducability or replicability analysis study.


{marker semioptional_para}{...}
{dlgtab:parameters being semi-optional in analyses at study level}

{phang}
The command {it:repframe} requires that either both {cmd:pval()} and {cmd:pval_orig()} are specified or both {cmd:se()} and {cmd:se_orig()}
or both {cmd:zscore()} and {cmd:zscore_orig()}. The command {it:repframe} determines the non-specified variables based on
the {it:t}-test formula and making assumptions on normality of the data, which may not be appropriate in all cases.
It is therefore recommended to specify both the information on {it:p}-values and standard errors
(see also the discussion on defaults applied by the command {it:repframe} in the {help repframe##see_also:online Readme on GitHub}).

{phang}
{opt pval(varname)} specifies the variable {it:varname} that includes the {it:p}-values on statistical significance of estimates in analysis paths
of robustness tests; {it:p}-values are assumed to be derived from two-sided {it:t}-tests; if {cmd:pval()} is not specified,
it is calculated based on {cmd:beta()} and {cmd:se()} or {cmd:beta()} and {cmd:zscore()}.

{phang}
{opt pval_orig(varname)} specifies the variable {it:varname} that includes the {it:p}-value on statistical significance of the original estimate
for the respective outcome; {it:p}-values are assumed to be derived from two-sided {it:t}-tests; if {cmd:pval_orig()} is not specified,
it is calculated based on {cmd:beta_orig()} and {cmd:se_orig()} or {cmd:beta_orig()} and {cmd:zscore_orig()}.

{phang}
{opt se(varname)} specifies the variable {it:varname} that includes the standard errors of beta coefficients in analysis paths of robustness tests;
if {cmd:se()} is not specified, it is calculated based on {cmd:beta()} and {cmd:pval()} or {cmd:beta()} and {cmd:zscore()}. 

{phang}
{opt se_orig(varname)} specifies the variable {it:varname} that includes the standard errors of the original beta coefficient for the respective outcome;
if {cmd:se_orig()} is not specified, it is calculated based on {cmd:beta_orig()} and {cmd:pval_orig()} or {cmd:beta_orig()} and {cmd:zscore_orig()}.

{phang}
{opt zscore(varname)} specifies the variable {it:varname} that includes the {it:t}/{it:z} scores of estimates in analysis paths of robustness tests;
if {cmd:zscore()} is not specified, it is calculated based on {cmd:beta()} and {cmd:se()} or {cmd:beta()} and {cmd:pval()}.

{phang}
{opt zscore_orig(varname)} specifies the variable {it:varname} that includes the {it:t}/{it:z} score of the original estimate for the respective outcome;
if {cmd:zscore_orig()} is not specified, it is calculated based on {cmd:beta_orig()} and {cmd:se_orig()} or {cmd:beta_orig()} and {cmd:pval_orig()}.


{marker optional_para}{...}
{dlgtab:optional parameters}

{phang}
{opt studypool:ing(0/1)} is a binary indicator on whether input data are Reproducibility and Replicability Indicators on individual studies, 
for which Indicators pooled across studies are to be calculated; default is {cmd:studypooling(0)}.

{phang}			
{opt df(varname)} specifies the variable {it:varname} that includes the degrees of freedom in analysis paths of robustness tests; if {cmd:df()} is not specified,
an approximately normal distribution is assumed.

{phang}
{opt df_orig(varname)} specifies the variable {it:varname} that includes the degrees of freedom in the original study outcome; if {cmd:df_orig()} is not specified,
an approximately normal distribution is assumed.

{phang}
{opt mean(varname)} specifies the variable {it:varname} that includes the mean of the outcome variables in the analysis paths of robustness tests,
ideally being the baseline mean in the control group; if {cmd:mean()} is not specified, it is assumed to be equal to {cmd:mean_orig()}.

{phang}
{opt mean_orig(varname)} specifies the variable {it:varname} that includes the mean of the outcome variables in the original study,
ideally being the baseline mean in the control group.

{phang}
{opt sameunits(varname)} specifies the variable {it:varname} that contains for each and every observation a binary indicator
on whether the original study and analysis paths of robustness tests use same effect size units ({it:varname}==1)
or not ({it:varname}==0); default is that {it:varname} is assumed to be always equal to one.

{phang}
{opt filepath(string)} provides the full file path under which the output files (table, graph, and data) of the {it:repframe} command are stored. 
If {cmd: filepath(string)} is not defined, outputs are stores in the operating system's standard /Downloads folder.

{phang}
{opt fileid:entifier(string)} allows to specifiy an identifier by which to differentiate versions of the output files (table, graph, and data) of the {it:repframe} command.
This identifier serves as a suffix to these files. If {cmd: fileidentifier(string)} is not defined, the current date is used as {cmd: fileidentifier(string)}.

{phang}
{opt orig_in_multiverse(0/1)} is a binary indicator on whether the original analysis is included as one analysis path in the multiverse robustness test
(yes=1, no=0); default is {cmd:orig_in_multiverse(0)}. This choice affects the variation indicators among the Reproducibility and Replicability Indicators.
{ul:It is important to note} that, irrespective of whether the original analysis is included
as one analysis path in the multiverse robustness test or not, the dataset should only include the information on the original analysis
in the *_orig variables, and not in the variables on the analysis paths of robustness tests. 

{phang}
{opt ivarweight(0/1)} is a binary indicator on whether to show Reproducibility and Replicability Indicators across all outcomes weighted by the inverse variance (yes=1, no=0);
default is {cmd:ivarweight(0)}. This option requires that the options {cmd:mean(varname)} and {cmd:mean_orig(varname)} are also defined.


{marker optional_para_RRI}{...}		
{dlgtab:optional parameters related to table of Reproducibility and Replicability Indicators}

{phang}
{opt shelvedind(0/1)} is a binary indicator on whether to also show shelved indicators from among the indicators 
proposed in a previous version of {help repframe##references:Dreber and Johannesson (2023)} (yes=1, no=0); default is {cmd:shelvedind(0)}. 

{phang}
{opt beta2(varname)} specifies the variable {it:varname} that includes the second beta coefficients in analysis paths of robustness tests,
if such second coefficients exist. This may, for example, be the case if the robustness test involves the coefficient of a variable
and the coefficient of the squared variable in order to test non-linear relationships.

{phang}
{opt pval2(varname)} specifies the variable {it:varname} that includes the {it:p}-values on statistical significance of second estimates
in analysis paths of robustness tests, if such second estimates exist;
if {cmd:pval2()} is not specified, it is calculated based on {cmd:beta2()} and {cmd:se2()} or {cmd:beta2()} and {cmd:zscore2()}.

{phang}
{opt se2(varname)} specifies the variable {it:varname} that includes the standard errors of second beta coefficients in analysis paths of robustness tests,
if such second beta coefficients exist; if {cmd:se2()} is not specified, it is calculated based on {cmd:beta2()} and {cmd:pval2()}
or {cmd:beta2()} and {cmd:zscore2()}.

{phang}
{opt zscore2(varname)} specifies the variable {it:varname} that includes the {it:t}/{it:z} scores of second estimates in analysis paths of robustness tests,
if such second estimates exist; if {cmd:zscore2()} is not specified, it is calculated based on {cmd:beta2()} and {cmd:se2()} or {cmd:beta2()} and {cmd:pval2()}.

{phang}
{opt beta2_orig(varname)} specifies the variable {it:varname} that includes the original second beta coefficient for the respective outcome,
if such a second original coefficient exists. This may, for example, be the case if the original analysis involves the coefficient of a variable
and the coefficient of the squared variable in order to test non-linear relationships.

{phang}
{opt pval2_orig(varname)} specifies the variable {it:varname} that includes the {it:p}-value on statistical significance of the original estimate
for the respective outcome, if such a second original estimate exists;
if {cmd:pval2_orig()} is not specified, it is calculated based on {cmd:beta2_orig()} and {cmd:se2_orig()} or {cmd:beta2_orig()} and {cmd:zscore2_orig()}.

{phang}
{opt se2_orig(varname)} specifies the variable {it:varname} that includes the standard errors of the second original beta coefficient
for the respective outcome, if such a second original beta coefficient exists; if {cmd:se2_orig()} is not specified,
it is calculated based on {cmd:beta2_orig()} and {cmd:pval2_orig()} or {cmd:beta2_orig()} and {cmd:zscore2_orig()}.

{phang}
{opt zscore2_orig(varname)} specifies the variable {it:varname} that includes the {it:t}/{it:z} score of the second original estimate
for the respective outcome, if such a second original estimate exists; if {cmd:zscore2_orig()} is not specified,
it is calculated based on {cmd:beta2_orig()} and {cmd:se2_orig()} or {cmd:beta2_orig()} and {cmd:pval2_orig()}.


{marker optional_para_SensDash}{...}
{dlgtab:optional parameters related to Sensitivity Dashboard}

{phang}
{opt sensd:ash(0/1)} is a binary indicator on whether to create the Sensitivity Dashboard (yes=1, no=0);
default is {cmd:sensdash(1)}.

{phang}
{opt vshortref_orig(string)} provides a very short reference to the original study, for example "[first letters of original authors] (year)";
default is {cmd vshortref_orig("original estimate")}. This reference is included in the Sensitivity Dashboard.

{phang}
{opt extended(string)} provides the type of indicator from the extended set of Reproducibility and Replicability Indicators that is to be shown in the dashboard;
the options are "none" (no indicator from the extended set), "ESagree" (Effect size agreement indicator) "SIGswitch" (Significance switch indicator),
or "both" (both indicators); default is {cmd:extended("none")}.

{phang}
{opt aggregation(0/1)} is a binary indicator on whether to show outcomes in the dashboard individually (=0) or aggregated across outcomes (=1);
default at study level is {cmd:aggregation(0)}; if pooled across studies, {cmd:aggregation()} is always set to 1.

{phang}
{opt graphfmt(string)} provides the file format under which the Sensitivity Dashboard is stored; default is {cmd:graphfmt(emf)}. 

{phang}
{opt ivF(varname)} specifies the variable {it:varname} that includes the first-stage {it:F}-Statistics,
if estimates are based on IV/2SLS estimations.

{phang}
{opt signfirst(varname)} specifies the (uniform) variable {it:varname} that includes the share of first stages with wrong sign in a range between 0 and 1,
if IV/2SLS estimations (cf. {help repframe##references:Angrist and Kolesár (2024)}). This option should only be used if the share is identical for all outcomes.	


{marker examples}{...}
{title:Examples}

{phang}	
{bf:Data preparation for analyses at study level}

{p 8 12}. {stata "use http://www.stata-press.com/data/mus2/mus206nhanes.dta"}{p_end}
{p 8 12}(Data from the second US National health and Nutrition Examination Survey (NHANES II), 1976-1980){p_end}

{p 8 12}({stata "repframe_gendata, studypooling(0)":{it:click to generate multiverse dataset at study level}}){p_end}

{phang}	
{bf:Reproducibility and Replicability Indicators table and Sensitivity Dashboard #1}

{p 8 12}. {stata "repframe outcome, beta(b) beta_orig(b_og) pval(p) pval_orig(p_og) se(se) se_orig(se_og) siglevel(5) siglevel_orig(10) shortref(repframe_ex)"}{p_end}

{p 8 12}
[{it:note that this example requires that the output table can be stored in the operating system's standard /Downloads folder. If this does not work, specify the file location with the option} {cmd:filepath(string)}.]{p_end}

{phang}	
{bf:Same output as #1, now based on information on the degrees of freedom instead of {it:p}-values}

{p 8 12}. {stata "repframe outcome, beta(b) beta_orig(b_og) df(df) df_orig(df_og) se(se) se_orig(se_og) siglevel(5) siglevel_orig(10) shortref(repframe_ex)"}{p_end}

{phang}	
{bf:Variation of #1, now including information in the Dashboard on the deviation of the original results from their mean}

{p 8 12}. {stata "repframe outcome, beta(b) beta_orig(b_og) pval(p) pval_orig(p_og) se(se) se_orig(se_og) siglevel(5) siglevel_orig(10) shortref(repframe_ex)  mean(out_mn) mean_orig(out_mn_og)"}{p_end}

{phang}	
{bf:Same table output as #1, Dashboard now with the extended set of indicators}

{p 8 12}. {stata "repframe outcome, beta(b) beta_orig(b_og) pval(p) pval_orig(p_og) se(se) se_orig(se_og) siglevel(5) siglevel_orig(10) shortref(repframe_ex)  extended(both)"}{p_end}

{phang}	
{bf:Same table output as #1, Dashboard now on aggregated outcomes}

{p 8 12}. {stata "repframe outcome, beta(b) beta_orig(b_og) pval(p) pval_orig(p_og) se(se) se_orig(se_og) siglevel(5) siglevel_orig(10) shortref(repframe_ex)  aggregation(1)"}{p_end}

{phang}	
{bf:Variation of #1, now including the original estimate in the multiverse of robustness analysis paths}

{p 8 12}. {stata "repframe outcome, beta(b) beta_orig(b_og) pval(p) pval_orig(p_og) se(se) se_orig(se_og) siglevel(5) siglevel_orig(10) shortref(repframe_ex) orig_in_multiverse(1)"}{p_end}


{phang}	
{bf:Data preparation for analyses across studies}

{p 8 12}({stata "repframe_gendata, studypooling(1)":{it:click to generate illustrative study-level indicator data}}){p_end}

{phang}	
{bf:Reproducibility and Replicability Indicators table and Sensitivity Dashboard #2 (across studies)}

{p 8 12}. {stata "repframe reflist, studypooling(1)"}

{phang}	
{bf:Same table output as #2, Dashboard now with the extended set of indicators}

{p 8 12}. {stata "repframe reflist, studypooling(1) extended(both)"}


{marker references}{...}
{title:References}

{p 4 8 2}
Angrist, J., & Kolesár, M. (2024). One instrument to rule them all: The bias and coverage of just-ID IV. {it:Journal of Econometrics}.{p_end}
{p 4 8 2}
Dreber, A. & Johanneson, M. (2023). A Framework for Evaluating Reproducibility and Replicability in Economics. Available at SSRN: {browse "https://ssrn.com/abstract=4458153"} or {browse "http://dx.doi.org/10.2139/ssrn.4458153"}.{p_end}


{marker see_also}{...}
{title:Also see}

{p 4 8 2} Online Readme on GitHub, among others with an explanation of the required input data structure: {browse "https://github.com/guntherbensch/repframe"}{p_end}


{title:Authors}

      Gunther Bensch, bensch@rwi-essen.de
      RWI
	  
