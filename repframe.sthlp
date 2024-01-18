{smcl}
{* *! version 1.1  17jan2024 Gunther Bensch}{...}
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
{bf:repframe} {hline 2} Calculate Reproducibility and Replication Framework Indicators

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:repframe}
{it:outcome}
{ifin}
{cmd:,} beta({it:varname}) beta_orig({it:varname}) [{it:semi-optional parameters}] [{it:optional parameters}]


{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:semi-optional parameters}
{synopt:{opt pval(varname)}}{it:p}-values on statistical significance of estimates in analysis paths of robustness tests{p_end}
{synopt:{opt pval_orig(varname)}}{it:p}-values on statistical significance of original estimate for respective outcome{p_end}
{synopt:{opt se(varname)}}standard errors of beta coefficients in analysis paths of robustness tests{p_end}
{synopt:{opt se_orig(varname)}}standard errors of the original beta coefficient for respective outcome{p_end}
{synopt:{opt zscore(varname)}}{it:t}/{it:z} scores of estimates in analysis paths of robustness tests{p_end}
{synopt:{opt zscore_orig(varname)}}{it:t}/{it:z} scores of original estimates for respective outcome{p_end}
			
{syntab:optional parameters}
{synopt:{opt outputfile(filename)}}path of output file with Reproducibility and Replication Framework Indicators{p_end}
{synopt:{opt siglevel(#)}}significance level{p_end}
{synopt:{opt df(varname)}}degrees of freedom in analysis paths of robustness tests{p_end}
{synopt:{opt df_orig(varname)}}degrees of freedom in the original study outcome{p_end}
{synopt:{opt mean(varname)}}mean of the outcome variables in the analysis paths of robustness tests{p_end}
{synopt:{opt mean_orig(varname)}}mean of the outcome variables in the original study{p_end}
{synopt:{opt beta2(varname)}}second beta coefficients in analysis paths of robustness tests{p_end}
{synopt:{opt pval2(varname)}}{it:p}-values on second estimates in analysis paths of robustness tests{p_end}
{synopt:{opt se2(varname)}}standard errors of second beta coefficients in analysis paths of robustness tests{p_end}
{synopt:{opt zscore2(varname)}}{it:t}/{it:z} scores of second beta coefficients in analysis paths of robustness tests{p_end}
{synopt:{opt beta2_orig(varname)}}original second beta coefficient for the respective outcome{p_end}
{synopt:{opt pval2_orig(varname)}}{it:p}-values on second estimates in analysis paths of robustness tests{p_end}
{synopt:{opt se2_orig(varname)}}standard errors of second beta coefficients in analysis paths of robustness tests{p_end}
{synopt:{opt zscore2_orig(varname)}}{it:t}/{it:z} scores of second beta coefficients in analysis paths of robustness tests{p_end}
{synopt:{opt orig_in_multiverse(0/1)}}original analysis is part of multiverse robustness test{p_end}
{synopt:{opt ivarweight(0/1)}}show Indicators across all outcomes weighted by the inverse variance{p_end}
{synopt:{opt sameunits(varname)}}indicator on whether original study and analysis paths of robustness tests use same effect size units{p_end}
{synopt:{opt indset(#)}}Indicator set to be shown{p_end}
{synoptline}
{p2colreset}{...}

{p 4 6 2}
{cmd:outcome} is the variable name of the outcome variable, which should be numeric and with value labels, 
where the value label should not begin with a number (such as "1. income").{p_end}
{p 4 6 2}
{cmd:beta({it:varname})} specifies the variable {it:varname} that includes the beta coefficients in analysis paths of robustness tests.{p_end}
{p 4 6 2}
{cmd:beta_orig({it:varname})} specifies the variable {it:varname} that includes the original beta coefficient for the respective outcome.{p_end}

			
{marker description}{...}
{title:Description}

{pstd}
{cmd:repframe} calculates Reproducibility and Replication Framework Indicators across {it:outcome} to compare multiple estimates
from analysis paths of robustness tests, beta({it:varname}), to the original estimate, beta_orig({it:varname}).{p_end}


{marker options}{...}
{title:Options}

{dlgtab:semi-optional parameters}

{phang}
The command {it:repframe} requires that either both {cmd:pval()} and {cmd:pval_orig()} are specified or both {cmd:se()} and {cmd:se_orig()} 
or both {cmd:zscore()} and {cmd:zscore_orig()}.

{phang}
{opt pval(varname)} specifies the variable {it:varname} that includes the {it:p}-values on statistical significance of estimates in analysis paths
of robustness tests; if {cmd:pval()} is not specified, it is calculated based on {cmd:beta()} and {cmd:se()} or {cmd:beta()} and {cmd:zscore()}.

{phang}
{opt pval_orig(varname)} specifies the variable {it:varname} that includes the {it:p}-value on statistical significance of the original estimate
for the respective outcome; if {cmd:pval_orig()} is not specified, it is calculated based on {cmd:beta_orig()} and {cmd:se_orig()} or {cmd:beta_orig()}
and {cmd:zscore_orig()}.

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

			
{dlgtab:optional parameters}

{phang}
{opt outputfile(filename)} specifies the Excel {it:filename}, including full path and file format (.xls, .xlsx, or .csv, for example),
of the output file that stores the Reproducibility and Replication Framework Indicators.
If no {cmd:outputfile()} is defined, a file called {it:reproframe_indicators.csv} is stored in the operating system's standard /Downloads folder.

{phang}
{opt siglevel(#)} gives the significance level (e.g. 1,5,10); default is siglevel(5) (i.e. 5% level).

{phang}			
{opt df(varname)} gives the degrees of freedom in analysis paths of robustness tests; if {cmd:df()} is not specified,
an approximately normal distribution is assumed.

{phang}
{opt df_orig(varname)} gives the degrees of freedom in the original study outcome; if {cmd:df_orig()} is not specified,
an approximately normal distribution is assumed.

{phang}
{opt mean(varname)} specifies the variable {it:varname} that includes the mean of the outcome variables in the analysis paths of robustness tests,
ideally being the baseline mean in the control group.

{phang}
{opt mean_orig(varname)} specifies the variable {it:varname} that includes the mean of the outcome variables in the original study,
ideally being the baseline mean in the control group; if {cmd:mean_orig()} is not specified, it is assumed to be equal to {cmd:mean()}.

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

{phang}
{opt orig_in_multiverse(0/1)} is a binary indicator on whether the original analysis is included as one analysis path in the multiverse robustness test;
default is {cmd:orig_in_multiverse(0)}. {ul:It is important to note} that, irrespective of whether the original analysis is included
as one analysis path in the multiverse robustness test or not, the dataset should only include the information on the original analysis
in the *_orig variables, and not in the variables on the analysis paths of robustness tests. 

{phang}
{opt ivarweight(0/1)} is a binary indicator on whether to show Indicators across all outcomes weighted by the inverse variance (yes=1, no=0);
default is {cmd:ivarweight(0)}. This option requires that the options {cmd:mean(varname)} and {cmd:mean_orig(varname)} are also defined.

{phang}
{opt sameunits(varname)} specifies the variable {it:varname} that contains for each and every observation a binary indicator
on whether the original study and analysis paths of robustness tests use same effect size units ({it:varname}==1)
or not ({it:varname}==0); default is that {it:varname} is assumed to be always equal to one.

{phang}
{opt indset(#)} defines the Indicator set to be shown, where 1 refers to the original set that should generally be used,
and 2 provides an alternative set of indicators; default is {cmd:indset(1)}.	


{marker examples}{...}
{title:Examples}

{phang}	
{bf:Data preparation}

{p 8 12}{stata "use http://fmwww.bc.edu/ec-p/data/hayashi/griliches76.dta" : . use http://fmwww.bc.edu/ec-p/data/hayashi/griliches76.dta}{p_end}
{p 8 12}(Wages of Very Young Men, Zvi Griliches, J.Pol.Ec. 1976)

{p 8 12}({stata "repframe_gendata":{it:click to generate multiverse dataset}})

{phang}	
{bf:Basic Reproducibility and Replication Framework Indicators using beta and se information}

{p 8 12}{stata "repframe outcome, beta(beta_iqiv) beta_orig(beta_iqiv_orig)  se(se_iqiv) se_orig(se_iqiv_orig)" : . repframe outcome, beta(beta_iqiv) beta_orig(beta_iqiv_orig)  se(se_iqiv) se_orig(se_iqiv_orig)}{p_end}

{p 8 12}{it:[note that this example requires that the output file can be stored in the operating system's standard /Downloads folder. If this does not work, specify the output file with the option {cmd:outputfile({it:filename})}.]}{p_end}


{title:References}

{p 4 8 2}
Angrist, J., & Kolesár, M. (2024). One instrument to rule them all: The bias and coverage of just-ID IV. {it:Journal of Econometrics}.


{title:Also see}

{p 4 8 2} Online Readme on GitHub, among others with an explanation of the required input data structure: {browse "https://github.com/guntherbensch/repframe"} 


{title:Authors}

      Gunther Bensch, bensch@rwi-essen.de
      RWI
	  